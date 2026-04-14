import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/models/withdrawal_request_row.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminWithdrawalsController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final requests = <WithdrawalRequestRow>[].obs;
  /// Cached users for withdrawal rows ([null] = user doc missing).
  final userById = <String, UserDocument?>{}.obs;
  final prefetchingUserIds = <String>[].obs;
  /// 0 = pending, 1 = history (processed), 2 = all
  final tabIndex = 0.obs;
  final processingId = RxnString();
  final searchQuery = ''.obs;

  StreamSubscription<List<WithdrawalRequestRow>>? _sub;
  final Map<String, Future<void>> _userLoadFutures = {};

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _sub = _firestore.streamWithdrawalRequestsForAdmin().listen(
      (list) {
        requests.value = list;
        for (final r in list) {
          unawaited(ensureWithdrawalUserLoaded(r.userId));
        }
      },
      onError: (e) => Get.snackbar('error'.tr, e.toString()),
    );
  }

  /// Loads [UserDocument] once per [uid]; concurrent callers share the same future.
  Future<void> ensureWithdrawalUserLoaded(String uid) async {
    if (uid.isEmpty || userById.containsKey(uid)) return;
    _userLoadFutures[uid] ??= _loadWithdrawalUser(uid);
    await _userLoadFutures[uid]!;
  }

  Future<void> _loadWithdrawalUser(String uid) async {
    prefetchingUserIds.add(uid);
    prefetchingUserIds.refresh();
    try {
      final u = await _firestore.getUser(uid);
      userById[uid] = u;
      userById.refresh();
    } finally {
      prefetchingUserIds.remove(uid);
      prefetchingUserIds.refresh();
      _userLoadFutures.remove(uid);
    }
  }

  List<WithdrawalRequestRow> filteredRowsForTab(int tab) {
    final all = List<WithdrawalRequestRow>.of(requests);
    final byTab = switch (tab) {
      0 => all.where((r) => r.isPending).toList(),
      1 => all.where((r) => !r.isPending).toList(),
      _ => all,
    };
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return byTab;
    return byTab.where((r) => _withdrawalMatchesSearch(r, q)).toList();
  }

  bool _withdrawalMatchesSearch(WithdrawalRequestRow r, String q) {
    if (r.id.toLowerCase().contains(q)) return true;
    if (r.amount.toString().contains(q)) return true;
    if ((r.bankAccount ?? '').toLowerCase().contains(q)) return true;
    if (r.userId.toLowerCase().contains(q)) return true;
    final label = displayNameForWithdrawalUser(r.userId).toLowerCase();
    if (label.contains(q)) return true;
    return false;
  }

  String displayNameForWithdrawalUser(String uid) {
    if (uid.isEmpty) return 'admin_withdrawal_user_unknown'.tr;
    if (prefetchingUserIds.contains(uid) || !userById.containsKey(uid)) {
      return 'admin_withdrawal_user_loading'.tr;
    }
    final u = userById[uid];
    if (u == null) return 'admin_withdrawal_user_unknown'.tr;
    final n = u.name.trim();
    return n.isNotEmpty ? n : 'admin_withdrawal_user_unknown'.tr;
  }

  Future<void> openWithdrawalUserDetails(WithdrawalRequestRow row) async {
    if (row.userId.isEmpty) return;
    await ensureWithdrawalUserLoaded(row.userId);
    final u = userById[row.userId];
    final name = (u?.name.trim().isNotEmpty == true)
        ? u!.name.trim()
        : 'admin_withdrawal_user_unknown'.tr;
    final iban = u?.payoutIban?.trim() ?? '';
    final note = row.bankAccount?.trim();

    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(name, style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (iban.isEmpty)
                Text(
                  'admin_withdrawal_no_iban_on_profile'.tr,
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else ...[
                Text(
                  'payout_iban'.tr,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  iban,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: iban));
                    Get.snackbar('', 'copied_to_clipboard'.tr);
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text('admin_withdrawal_copy_iban'.tr),
                ),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'withdrawal_request_bank_note'.tr,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  note,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: note));
                    Get.snackbar('', 'copied_to_clipboard'.tr);
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text('admin_withdrawal_copy_note'.tr),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr, style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> markTransferred(WithdrawalRequestRow r) async {
    if (!r.isPending || processingId.value != null) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('admin_withdrawal_confirm_transfer_title'.tr),
        content: Text('admin_withdrawal_confirm_transfer_body'.trParams({'amount': r.amount.toStringAsFixed(2)})),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Get.back(result: true), child: Text('confirm'.tr)),
        ],
      ),
    );
    if (ok != true) return;
    processingId.value = r.id;
    try {
      await _firestore.adminSetWithdrawalOutcome(requestId: r.id, markTransferred: true);
      await _notif.notifyWithdrawalTransferred(
        userId: r.userId,
        amount: r.amount,
        withdrawalRequestId: r.id,
      );
      Get.snackbar('', 'admin_withdrawal_marked_transferred'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      processingId.value = null;
    }
  }

  Future<void> markRejected(WithdrawalRequestRow r) async {
    if (!r.isPending || processingId.value != null) return;
    final reasonCtrl = TextEditingController();
    try {
      final ok = await Get.dialog<bool>(
        AlertDialog(
          title: Text('admin_withdrawal_reject_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('admin_withdrawal_reject_hint'.tr),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'withdrawal_admin_reason'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text('withdrawal_status_rejected'.tr),
            ),
          ],
        ),
      );
      if (ok != true) return;
      processingId.value = r.id;
      await _firestore.adminSetWithdrawalOutcome(
        requestId: r.id,
        markTransferred: false,
        adminMessage: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      );
      Get.snackbar('', 'admin_withdrawal_marked_rejected'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      processingId.value = null;
      reasonCtrl.dispose();
    }
  }

  /// Correct status / note on already processed withdrawals (does not move wallet funds).
  Future<void> changeWithdrawalStatus(WithdrawalRequestRow r) async {
    if (r.isPending || processingId.value != null) return;
    var picked = (r.status == 'transferred' || r.status == 'rejected') ? r.status : 'transferred';
    final noteCtrl = TextEditingController(text: r.adminMessage ?? '');
    try {
      final ok = await Get.dialog<bool>(
        StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: Text(
                'admin_withdrawal_change_status_title'.tr,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'admin_withdrawal_status_change_warning'.tr,
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: Text(
                        'withdrawal_status_transferred'.tr,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: 'transferred',
                      groupValue: picked,
                      onChanged: (v) {
                        if (v != null) {
                          picked = v;
                          setSt(() {});
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'withdrawal_status_rejected'.tr,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: 'rejected',
                      groupValue: picked,
                      onChanged: (v) {
                        if (v != null) {
                          picked = v;
                          setSt(() {});
                        }
                      },
                    ),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'withdrawal_admin_reason'.tr,
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
                FilledButton(onPressed: () => Get.back(result: true), child: Text('confirm'.tr)),
              ],
            );
          },
        ),
      );
      if (ok != true) return;

      final msg = noteCtrl.text.trim();
      final hadNote = r.adminMessage != null && r.adminMessage!.trim().isNotEmpty;
      final String? adminMsgParam;
      if (msg.isEmpty) {
        adminMsgParam = hadNote ? '' : null;
      } else if (msg == (r.adminMessage ?? '').trim()) {
        adminMsgParam = null;
      } else {
        adminMsgParam = msg;
      }
      final statusChanged = picked != r.status;
      if (!statusChanged && adminMsgParam == null) {
        Get.snackbar('', 'admin_no_changes'.tr);
        return;
      }
      processingId.value = r.id;
      await _firestore.adminPatchWithdrawalRequestRecord(
        requestId: r.id,
        status: picked,
        adminMessage: adminMsgParam,
      );
      Get.snackbar('', 'admin_withdrawal_status_updated'.tr);
    } catch (e) {
      final s = e.toString();
      if (s.contains('withdrawal_use_standard_actions_for_pending')) {
        Get.snackbar('error'.tr, 'admin_withdrawal_use_pending_actions'.tr);
      } else {
        Get.snackbar('error'.tr, e.toString());
      }
    } finally {
      processingId.value = null;
      noteCtrl.dispose();
    }
  }
}
