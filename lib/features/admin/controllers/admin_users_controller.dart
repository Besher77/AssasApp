import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

class AdminUsersController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final AuthService _auth = Get.find<AuthService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final users = <UserDocument>[].obs;
  final engineers = <UserDocument>[].obs;
  final isBroadcasting = false.obs;
  final pendingEngineerRegistrationsCount = 0.obs;
  /// Filters lists by name, phone, email, IBAN, or uid substring.
  final searchQuery = ''.obs;

  StreamSubscription<List<UserDocument>>? _subUsers;
  StreamSubscription<List<UserDocument>>? _subEngineers;
  StreamSubscription<int>? _pendingEngineerRegSub;

  @override
  void onClose() {
    _subUsers?.cancel();
    _subEngineers?.cancel();
    _pendingEngineerRegSub?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _pendingEngineerRegSub = _firestore.streamPendingEngineerRegistrationCount().listen(
      (n) => pendingEngineerRegistrationsCount.value = n,
    );
    _subUsers = _firestore.streamUsersByUserType('user').listen(
          (list) => users.value = list,
          onError: (e) => Get.snackbar('error'.tr, e.toString()),
        );
    _subEngineers = _firestore.streamUsersByUserType('engineer').listen(
          (list) => engineers.value = list,
          onError: (e) => Get.snackbar('error'.tr, e.toString()),
        );
  }

  static bool userMatchesSearch(UserDocument u, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final qIban = q.replaceAll(' ', '');
    if (u.name.toLowerCase().contains(q)) return true;
    if (u.phone.contains(q)) return true;
    if ((u.email ?? '').toLowerCase().contains(q)) return true;
    final iban = (u.payoutIban ?? '').toLowerCase().replaceAll(' ', '');
    if (qIban.isNotEmpty && iban.contains(qIban)) return true;
    if ((u.payoutAccountName ?? '').toLowerCase().contains(q)) return true;
    if (u.uid.toLowerCase().contains(q)) return true;
    return false;
  }

  List<UserDocument> get filteredUsers {
    final q = searchQuery.value;
    if (q.trim().isEmpty) return List<UserDocument>.of(users);
    return users.where((u) => userMatchesSearch(u, q)).toList();
  }

  List<UserDocument> get filteredEngineers {
    final q = searchQuery.value;
    if (q.trim().isEmpty) return List<UserDocument>.of(engineers);
    return engineers.where((u) => userMatchesSearch(u, q)).toList();
  }

  bool _isSelf(String uid) => uid == _auth.currentUserId;

  Future<void> promptNotifyAllUsers() async {
    if (isBroadcasting.value) return;
    int count = 0;
    try {
      count = (await _firestore.getClientAndEngineerUserUids()).length;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return;
    }
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    try {
      final ok = await Get.dialog<bool>(
        AlertDialog(
          title: Text('admin_notify_all_users'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('admin_notify_all_confirm'.trParams({'count': '$count'})),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'admin_announcement_title'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'admin_announcement_body'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
            FilledButton(onPressed: () => Get.back(result: true), child: Text('send'.tr)),
          ],
        ),
      );
      if (ok != true) return;
      final t = titleCtrl.text.trim();
      final b = bodyCtrl.text.trim();
      if (t.isEmpty || b.isEmpty) {
        Get.snackbar('error'.tr, 'admin_announcement_validation'.tr);
        return;
      }
      isBroadcasting.value = true;
      final n = await _notif.sendAdminAnnouncementToAllUsers(title: t, body: b);
      Get.snackbar('', 'admin_notify_all_done'.trParams({'count': '$n'}));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isBroadcasting.value = false;
      titleCtrl.dispose();
      bodyCtrl.dispose();
    }
  }

  Future<void> toggleBlocked(UserDocument u) async {
    if (u.userType == 'admin' || _isSelf(u.uid)) {
      Get.snackbar('error'.tr, 'admin_cannot_restrict_self'.tr);
      return;
    }
    final newBlocked = !u.blocked;
    try {
      await _firestore.adminSetUserAccessRestriction(
        targetUid: u.uid,
        blocked: newBlocked,
        suspendedUntil: newBlocked ? null : u.suspendedUntil,
        blockedReason: u.blockedReason,
      );
      Get.snackbar('', newBlocked ? 'admin_user_blocked'.tr : 'admin_user_unblocked'.tr);
      unawaited(_notif.notifyAdminUserBlockedChanged(userId: u.uid, blocked: newBlocked));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> pickSuspendUntil(UserDocument u) async {
    if (u.userType == 'admin' || _isSelf(u.uid)) {
      Get.snackbar('error'.tr, 'admin_cannot_restrict_self'.tr);
      return;
    }
    final now = DateTime.now();
    final ctx = Get.context;
    if (ctx == null) return;
    final d = await showDatePicker(
      context: ctx,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (d == null) return;
    final end = DateTime(d.year, d.month, d.day, 23, 59, 59);
    try {
      await _firestore.adminSetUserAccessRestriction(
        targetUid: u.uid,
        blocked: u.blocked,
        suspendedUntil: end,
        blockedReason: u.blockedReason,
      );
      Get.snackbar('', 'admin_suspension_updated'.tr);
      unawaited(_notif.notifyAdminUserSuspensionChanged(userId: u.uid, suspendedUntil: end));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> clearSuspension(UserDocument u) async {
    if (u.userType == 'admin' || _isSelf(u.uid)) return;
    try {
      await _firestore.adminSetUserAccessRestriction(
        targetUid: u.uid,
        blocked: u.blocked,
        suspendedUntil: null,
        blockedReason: u.blockedReason,
      );
      Get.snackbar('', 'admin_suspension_cleared'.tr);
      unawaited(_notif.notifyAdminUserSuspensionChanged(userId: u.uid, suspendedUntil: null));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }
}
