import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

class AdminUserEditController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final AuthService _auth = Get.find<AuthService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final uidController = TextEditingController();
  final membershipController = TextEditingController();
  final experienceController = TextEditingController();
  final specializationController = TextEditingController();
  final bioController = TextEditingController();
  final blockedReasonController = TextEditingController();
  final engineerRegNoteController = TextEditingController();

  final userTypeStr = 'user'.obs;
  /// [EngineerRegistrationStatus] when type is engineer (admin can set active / pending / rejected).
  final engineerRegStr = EngineerRegistrationStatus.active.obs;
  final blocked = false.obs;
  final suspendedUntil = Rxn<DateTime>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isSendingAnnouncement = false.obs;

  UserDocument? _loaded;

  /// Non-null when editing an existing profile.
  String? get editingUid {
    final a = Get.arguments;
    if (a is String && a.isNotEmpty) return a;
    return null;
  }

  bool get isCreate => editingUid == null;

  bool get isSelf => editingUid != null && editingUid == _auth.currentUserId;

  @override
  void onInit() {
    super.onInit();
    final uid = editingUid;
    if (uid != null) {
      uidController.text = uid;
      loadUser();
    } else {
      engineerRegStr.value = EngineerRegistrationStatus.active;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    uidController.dispose();
    membershipController.dispose();
    experienceController.dispose();
    specializationController.dispose();
    bioController.dispose();
    blockedReasonController.dispose();
    engineerRegNoteController.dispose();
    super.onClose();
  }

  Future<void> loadUser() async {
    final uid = editingUid;
    if (uid == null) return;
    isLoading.value = true;
    try {
      final doc = await _firestore.getUser(uid);
      _loaded = doc;
      if (doc == null) {
        Get.snackbar('error'.tr, 'admin_user_not_found'.tr);
        Get.back();
        return;
      }
      if (doc.userType == 'admin') {
        Get.snackbar('error'.tr, 'admin_cannot_edit_admin_profile'.tr);
        Get.back();
        return;
      }
      nameController.text = doc.name;
      phoneController.text = doc.phone.replaceFirst(RegExp(r'^966'), '');
      emailController.text = doc.email ?? '';
      cityController.text = doc.city;
      userTypeStr.value = doc.userType == 'engineer' ? 'engineer' : 'user';
      if (doc.userType == 'engineer') {
        engineerRegStr.value = doc.engineerRegistrationStatus?.isNotEmpty == true
            ? doc.engineerRegistrationStatus!
            : EngineerRegistrationStatus.active;
        engineerRegNoteController.text = doc.engineerRegistrationNote ?? '';
      } else {
        engineerRegStr.value = EngineerRegistrationStatus.active;
        engineerRegNoteController.clear();
      }
      membershipController.text = doc.membershipNumber ?? '';
      experienceController.text = doc.yearsExperience ?? '';
      specializationController.text = doc.specialization ?? '';
      bioController.text = doc.bio ?? '';
      blocked.value = doc.blocked;
      suspendedUntil.value = doc.suspendedUntil;
      blockedReasonController.text = doc.blockedReason ?? '';
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  String? validateUidField(String? v) {
    if (!isCreate) return null;
    if (v == null || v.trim().isEmpty) return 'admin_uid_required'.tr;
    if (v.trim().length < 10) return 'admin_uid_invalid'.tr;
    return null;
  }

  String? validateNameField(String? v) {
    if (v == null || v.trim().isEmpty) return 'name_required'.tr;
    return null;
  }

  String? validatePhoneField(String? v) {
    if (v == null || v.trim().isEmpty) return 'login_phone_required'.tr;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9 || !digits.startsWith('5')) return 'phone_saudi_invalid'.tr;
    return null;
  }

  String? validateCityField(String? v) {
    if (v == null || v.trim().isEmpty) return 'city_required'.tr;
    return null;
  }

  String _targetUid() {
    if (editingUid != null) return editingUid!;
    return uidController.text.trim();
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    final uid = _targetUid();
    if (isCreate && validateUidField(uidController.text) != null) return;

    isSaving.value = true;
    try {
      final prev = _loaded ?? await _firestore.getUser(uid);
      final fullPhone = '966${phoneController.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '')}';
      final type = userTypeStr.value;
      final isEng = type == 'engineer';

      final doc = UserDocument(
        uid: uid,
        phone: fullPhone,
        name: nameController.text.trim(),
        city: cityController.text.trim(),
        userType: type,
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        photoUrl: prev?.photoUrl,
        bio: isEng && bioController.text.trim().isNotEmpty ? bioController.text.trim() : null,
        membershipNumber: isEng && membershipController.text.trim().isNotEmpty ? membershipController.text.trim() : null,
        yearsExperience: isEng && experienceController.text.trim().isNotEmpty ? experienceController.text.trim() : null,
        specialization: isEng && specializationController.text.trim().isNotEmpty ? specializationController.text.trim() : null,
        fcmToken: prev?.fcmToken,
        createdAt: prev?.createdAt,
        isOnline: prev?.isOnline ?? false,
        lastSeen: prev?.lastSeen,
        payoutBankId: prev?.payoutBankId,
        payoutAccountName: prev?.payoutAccountName,
        payoutIban: prev?.payoutIban,
        payoutStatus: prev?.payoutStatus,
        payoutAdminMessage: prev?.payoutAdminMessage,
        payoutSubmittedAt: prev?.payoutSubmittedAt,
        blocked: blocked.value,
        suspendedUntil: suspendedUntil.value,
        blockedReason: blockedReasonController.text.trim().isEmpty ? null : blockedReasonController.text.trim(),
        engineerRegistrationStatus: isEng ? engineerRegStr.value : null,
        engineerRegistrationNote:
            isEng && engineerRegNoteController.text.trim().isNotEmpty ? engineerRegNoteController.text.trim() : null,
      );

      await _firestore.adminMergeUserProfile(doc);
      if (isEng && engineerRegNoteController.text.trim().isEmpty) {
        await _firestore.adminClearEngineerRegistrationNote(uid);
      }
      if (!isEng) {
        await _firestore.adminClearEngineerOnlyFields(uid);
      }
      _loaded = doc;
      if (!isSelf) {
        unawaited(_notif.notifyAdminUserProfileUpdated(userId: uid));
      }
      Get.snackbar('', 'profile_saved'.tr);
      if (isCreate) Get.back();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> pickSuspensionEnd() async {
    if (isSelf) {
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
    suspendedUntil.value = DateTime(d.year, d.month, d.day, 23, 59, 59);
    if (!isCreate) await _pushRestrictionToServer();
  }

  Future<void> clearSuspension() async {
    if (isSelf) return;
    suspendedUntil.value = null;
    if (!isCreate) await _pushRestrictionToServer();
  }

  Future<void> _pushRestrictionToServer() async {
    final uid = _targetUid();
    if (uid.isEmpty || isSelf) return;
    try {
      await _firestore.adminSetUserAccessRestriction(
        targetUid: uid,
        blocked: blocked.value,
        suspendedUntil: suspendedUntil.value,
        blockedReason: blockedReasonController.text.trim().isEmpty ? null : blockedReasonController.text.trim(),
      );
      Get.snackbar('', 'admin_suspension_updated'.tr);
      await _refreshRestrictionFromServer(uid);
      unawaited(_notif.notifyAdminUserSuspensionChanged(userId: uid, suspendedUntil: suspendedUntil.value));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> _refreshRestrictionFromServer(String uid) async {
    final fresh = await _firestore.getUser(uid);
    if (fresh == null) return;
    _loaded = fresh;
    blocked.value = fresh.blocked;
    suspendedUntil.value = fresh.suspendedUntil;
    blockedReasonController.text = fresh.blockedReason ?? '';
  }

  Future<void> applyQuickBlock({required bool value}) async {
    if (isSelf) {
      Get.snackbar('error'.tr, 'admin_cannot_restrict_self'.tr);
      return;
    }
    final uid = _targetUid();
    if (uid.isEmpty) return;
    final prevBlocked = blocked.value;
    blocked.value = value;
    if (value) suspendedUntil.value = null;
    try {
      await _firestore.adminSetUserAccessRestriction(
        targetUid: uid,
        blocked: value,
        suspendedUntil: value ? null : suspendedUntil.value,
        blockedReason: blockedReasonController.text.trim().isEmpty ? null : blockedReasonController.text.trim(),
      );
      Get.snackbar('', value ? 'admin_user_blocked'.tr : 'admin_user_unblocked'.tr);
      await _refreshRestrictionFromServer(uid);
      unawaited(_notif.notifyAdminUserBlockedChanged(userId: uid, blocked: value));
    } catch (e) {
      blocked.value = prevBlocked;
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> promptSendAnnouncement() async {
    if (isCreate || editingUid == null) return;
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    try {
      final ok = await Get.dialog<bool>(
        AlertDialog(
          title: Text('admin_send_notification'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
      isSendingAnnouncement.value = true;
      await _notif.sendAdminAnnouncementToUser(userId: editingUid!, title: t, body: b);
      Get.snackbar('', 'admin_notify_user_done'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSendingAnnouncement.value = false;
      titleCtrl.dispose();
      bodyCtrl.dispose();
    }
  }

  Future<void> deleteUser() async {
    if (isCreate) return;
    if (isSelf) {
      Get.snackbar('error'.tr, 'admin_cannot_delete_self'.tr);
      return;
    }
    final uid = editingUid!;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('admin_delete_user_title'.tr),
        content: Text('admin_delete_user_body'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      unawaited(_notif.notifyAdminUserProfileRemoved(userId: uid));
      await _firestore.adminDeleteUserDocument(uid);
      Get.snackbar('', 'admin_user_deleted'.tr);
      Get.back();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  void setUserType(String type) {
    if (type != 'user' && type != 'engineer') return;
    final was = userTypeStr.value;
    userTypeStr.value = type;
    if (type == 'engineer' && was != 'engineer') {
      engineerRegStr.value = EngineerRegistrationStatus.active;
    }
  }
}
