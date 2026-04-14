import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/wallet_document.dart';

class AdminWalletRow {
  AdminWalletRow({required this.wallet, this.user});

  final WalletDocument wallet;
  final UserDocument? user;
}

class AdminWalletsController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final AuthService _auth = Get.find<AuthService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final rows = <AdminWalletRow>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  /// '' | 'user' | 'engineer'
  final userTypeFilter = ''.obs;
  final busyUserId = Rxn<String>();

  final Map<String, UserDocument?> _userCache = {};
  StreamSubscription<List<WalletDocument>>? _walletsSub;

  @override
  void onInit() {
    super.onInit();
    _walletsSub = _firestore.streamAllWallets().listen(
      _onWallets,
      onError: (e) {
        isLoading.value = false;
        Get.snackbar('error'.tr, e.toString());
      },
    );
  }

  @override
  void onClose() {
    _walletsSub?.cancel();
    super.onClose();
  }

  Future<void> _onWallets(List<WalletDocument> wallets) async {
    final uids = wallets.map((w) => w.userId).where((id) => id.isNotEmpty).toSet();
    await _loadUsers(uids);
    rows.assignAll(
      wallets.map((w) => AdminWalletRow(wallet: w, user: _userCache[w.userId])).toList(),
    );
    isLoading.value = false;
  }

  Future<void> _loadUsers(Set<String> uids) async {
    final missing = uids.where((id) => !_userCache.containsKey(id)).toList();
    const chunk = 24;
    for (var i = 0; i < missing.length; i += chunk) {
      final end = i + chunk > missing.length ? missing.length : i + chunk;
      final part = missing.sublist(i, end);
      await Future.wait(
        part.map((uid) async {
          try {
            final u = await _firestore.getUser(uid);
            _userCache[uid] = u;
          } catch (_) {
            _userCache[uid] = null;
          }
        }),
      );
    }
  }

  List<AdminWalletRow> get filteredRows {
    var list = List<AdminWalletRow>.from(rows);
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        if (r.wallet.userId.toLowerCase().contains(q)) return true;
        final u = r.user;
        if (u != null) {
          if (u.name.toLowerCase().contains(q)) return true;
          if (u.phone.contains(q)) return true;
          if ((u.email ?? '').toLowerCase().contains(q)) return true;
        }
        return false;
      }).toList();
    }
    final f = userTypeFilter.value;
    if (f == 'user') {
      list = list.where((r) => r.user?.userType == 'user').toList();
    } else if (f == 'engineer') {
      list = list.where((r) => r.user?.userType == 'engineer').toList();
    }
    list.sort((a, b) => b.wallet.balance.compareTo(a.wallet.balance));
    return list;
  }

  String _mapErr(Object e) {
    final s = e.toString();
    if (s.contains('invalid_amount')) return 'invalid_amount'.tr;
    if (s.contains('insufficient_balance')) return 'insufficient_balance'.tr;
    if (s.contains('wallet_not_found')) return 'admin_wallet_not_found'.tr;
    if (s.contains('wallet_not_empty')) return 'admin_wallet_not_empty'.tr;
    return s;
  }

  Future<void> creditUser(String userId, double amount, String? note) async {
    busyUserId.value = userId;
    try {
      await _firestore.adminCreditWallet(
        userId,
        amount,
        note: note,
        adminUserId: _auth.currentUserId,
      );
      await _notif.notifyAdminWalletCredit(userId: userId, amount: amount, note: note);
      Get.snackbar('', 'admin_wallet_credited'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, _mapErr(e));
    } finally {
      busyUserId.value = null;
    }
  }

  Future<void> debitUser(String userId, double amount, String? note) async {
    busyUserId.value = userId;
    try {
      await _firestore.adminDebitWallet(
        userId,
        amount,
        note: note,
        adminUserId: _auth.currentUserId,
      );
      await _notif.notifyAdminWalletDebit(userId: userId, amount: amount, note: note);
      Get.snackbar('', 'admin_wallet_debited'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, _mapErr(e));
    } finally {
      busyUserId.value = null;
    }
  }

  Future<void> ensureWallet(String userId) async {
    final uid = userId.trim();
    if (uid.length < 10) {
      Get.snackbar('error'.tr, 'admin_uid_invalid'.tr);
      return;
    }
    busyUserId.value = uid;
    try {
      await _firestore.getOrCreateWallet(uid);
      await _loadUsers({uid});
      Get.snackbar('', 'admin_wallet_ensured'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      busyUserId.value = null;
    }
  }

  Future<void> deleteEmptyWallet(String userId) async {
    busyUserId.value = userId;
    try {
      await _firestore.adminDeleteEmptyWallet(userId);
      Get.snackbar('', 'admin_wallets_deleted'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, _mapErr(e));
    } finally {
      busyUserId.value = null;
    }
  }

  void promptAmount({required String userId, required bool credit}) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    Get.dialog<void>(
      AlertDialog(
        title: Text(credit ? 'admin_wallets_add'.tr : 'admin_wallets_take'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'admin_wallets_amount'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'admin_wallets_note_optional'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () async {
              final raw = amountCtrl.text.replaceAll(',', '.').trim();
              final v = double.tryParse(raw);
              if (v == null || v <= 0) {
                Get.snackbar('error'.tr, 'invalid_amount'.tr);
                return;
              }
              Get.back();
              if (credit) {
                await creditUser(userId, v, noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
              } else {
                await debitUser(userId, v, noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
              }
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    ).whenComplete(() {
      amountCtrl.dispose();
      noteCtrl.dispose();
    });
  }

  void promptEnsureWallet() {
    final uidCtrl = TextEditingController();
    Get.dialog<void>(
      AlertDialog(
        title: Text('admin_wallets_ensure'.tr),
        content: TextField(
          controller: uidCtrl,
          decoration: InputDecoration(
            labelText: 'admin_project_owner_uid'.tr,
            hintText: 'admin_wallets_ensure_hint'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () async {
              final uid = uidCtrl.text.trim();
              Get.back();
              await ensureWallet(uid);
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    ).whenComplete(uidCtrl.dispose);
  }
}
