import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/saudi_banks.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/firestore_service.dart'
    show FirestoreService, PayoutVerificationStatus, UserDocument;
import 'admin_users_controller.dart';

class AdminBankVerificationsController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final engineersPending = <UserDocument>[].obs;
  final engineersHistory = <UserDocument>[].obs;
  /// 0 = pending review, 1 = history (approved / rejected)
  final tabIndex = 0.obs;
  final processingUid = RxnString();
  final searchQuery = ''.obs;

  StreamSubscription<List<UserDocument>>? _subPending;
  StreamSubscription<List<UserDocument>>? _subHistory;

  @override
  void onClose() {
    _subPending?.cancel();
    _subHistory?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _subPending = _firestore.streamEngineersPendingPayoutVerification().listen(
      (list) => engineersPending.value = list,
      onError: (e) => Get.snackbar('error'.tr, e.toString()),
    );
    _subHistory = _firestore.streamEngineersPayoutVerificationHistory().listen(
      (list) => engineersHistory.value = list,
      onError: (e) => Get.snackbar('error'.tr, e.toString()),
    );
  }

  void openUser(String uid) {
    Get.toNamed(AppRoutes.adminUserEdit, arguments: uid);
  }

  Future<void> approve(UserDocument u) async {
    if (processingUid.value != null) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('admin_bank_approve_title'.tr),
        content: Text('admin_bank_approve_body'.trParams({'name': u.name})),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Get.back(result: true), child: Text('confirm'.tr)),
        ],
      ),
    );
    if (ok != true) return;
    processingUid.value = u.uid;
    try {
      await _firestore.adminSetPayoutVerification(engineerUid: u.uid, approved: true);
      Get.snackbar('', 'admin_bank_approved'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      processingUid.value = null;
    }
  }

  Future<void> reject(UserDocument u) async {
    if (processingUid.value != null) return;
    final noteCtrl = TextEditingController();
    try {
      final ok = await Get.dialog<bool>(
        AlertDialog(
          title: Text('admin_bank_reject_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('admin_bank_reject_hint'.tr),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'payout_admin_message'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
            FilledButton(onPressed: () => Get.back(result: true), child: Text('payout_status_rejected'.tr)),
          ],
        ),
      );
      if (ok != true) return;
      processingUid.value = u.uid;
      await _firestore.adminSetPayoutVerification(
        engineerUid: u.uid,
        approved: false,
        adminMessage: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      Get.snackbar('', 'admin_bank_rejected'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      processingUid.value = null;
      noteCtrl.dispose();
    }
  }

  String bankLabel(String? bankId) => bankNameById(bankId) ?? (bankId ?? '—');

  static bool userMatchesSearch(UserDocument u, String query) {
    return AdminUsersController.userMatchesSearch(u, query);
  }

  List<UserDocument> get filteredPending {
    final q = searchQuery.value;
    if (q.trim().isEmpty) return List<UserDocument>.of(engineersPending);
    return engineersPending.where((u) => userMatchesSearch(u, q)).toList();
  }

  List<UserDocument> get filteredHistory {
    final q = searchQuery.value;
    if (q.trim().isEmpty) return List<UserDocument>.of(engineersHistory);
    return engineersHistory.where((u) => userMatchesSearch(u, q)).toList();
  }

  String payoutStatusLabel(UserDocument u) {
    switch (u.payoutStatus) {
      case PayoutVerificationStatus.approved:
        return 'payout_status_approved'.tr;
      case PayoutVerificationStatus.rejected:
        return 'payout_status_rejected'.tr;
      case PayoutVerificationStatus.pending:
        return 'payout_status_pending'.tr;
      default:
        return 'payout_status_none'.tr;
    }
  }
}
