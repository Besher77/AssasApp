import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/project_options.dart';
import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart';
import '../../../core/models/offer_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import 'admin_project_support_chat_controller.dart';

/// Linked user row for admin project detail (client / invited / accepted engineer).
class AdminProjectRelatedPerson {
  const AdminProjectRelatedPerson({
    required this.uid,
    required this.roleTrKey,
    this.displayName,
  });
  final String uid;
  final String roleTrKey;
  final String? displayName;
}

class AdminProjectEditController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final formKey = GlobalKey<FormState>();
  final userIdController = TextEditingController();
  final landAreaController = TextEditingController();
  final descriptionController = TextEditingController();
  final invitedEngineerIdController = TextEditingController();
  final acceptedEngineerIdController = TextEditingController();

  final projectTypeId = ''.obs;
  final selectedCityId = ''.obs;
  final selectedBudgetId = ''.obs;
  final selectedDeliveryId = ''.obs;
  final statusId = 'new'.obs;
  final listed = true.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final ownerDisplayName = ''.obs;

  final offers = <OfferDocument>[].obs;
  final relatedPeople = <AdminProjectRelatedPerson>[].obs;
  final acceptedOfferLine = RxnString();

  ProjectDocument? _loaded;

  String? get editingId {
    final a = Get.arguments;
    if (a is String && a.isNotEmpty) return a;
    return null;
  }

  bool get isCreate => editingId == null;

  bool get canOpenAdminSupportChat =>
      !isCreate &&
      _loaded != null &&
      AdminProjectSupportChatController.supportChatEligible(_loaded!);

  void openUserInAdmin(String uid) {
    if (uid.isEmpty) return;
    Get.toNamed(AppRoutes.adminUserEdit, arguments: uid);
  }

  @override
  void onInit() {
    super.onInit();
    if (editingId != null) {
      load();
    } else {
      ownerDisplayName.value = '';
      projectTypeId.value = projectTypes.isNotEmpty ? projectTypes.first.id : 'other';
      selectedCityId.value = saudiCities.isNotEmpty ? saudiCities.first.id : '';
      selectedBudgetId.value = budgetOptions.isNotEmpty ? budgetOptions.first.id : '';
      selectedDeliveryId.value =
          deliveryDurationOptions.isNotEmpty ? deliveryDurationOptions.last.id : 'flexible';
      statusId.value = 'new';
      listed.value = true;
    }
  }

  @override
  void onClose() {
    userIdController.dispose();
    landAreaController.dispose();
    descriptionController.dispose();
    invitedEngineerIdController.dispose();
    acceptedEngineerIdController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final id = editingId;
    if (id == null) return;
    isLoading.value = true;
    try {
      final p = await _firestore.getProject(id);
      _loaded = p;
      if (p == null) {
        Get.snackbar('error'.tr, 'admin_project_not_found'.tr);
        Get.back();
        return;
      }
      userIdController.text = p.userId;
      final ownerU = await _firestore.getUser(p.userId);
      ownerDisplayName.value = ownerU != null && ownerU.name.trim().isNotEmpty
          ? ownerU.name.trim()
          : 'admin_unknown_user'.tr;
      projectTypeId.value = p.projectType.isNotEmpty ? p.projectType : 'other';
      landAreaController.text = p.landArea;
      selectedCityId.value = p.city;
      descriptionController.text = p.description;
      selectedBudgetId.value = p.budget ?? '';
      selectedDeliveryId.value = p.deliveryDuration ?? 'flexible';
      statusId.value = p.status;
      listed.value = p.listed;
      invitedEngineerIdController.text = p.invitedEngineerId ?? '';
      acceptedEngineerIdController.text = p.acceptedEngineerId ?? '';

      final list = await _firestore.getProjectOffers(id);
      offers.assignAll(list);

      Future<AdminProjectRelatedPerson?> person(String? uid, String roleKey) async {
        if (uid == null || uid.isEmpty) return null;
        final u = await _firestore.getUser(uid);
        return AdminProjectRelatedPerson(uid: uid, roleTrKey: roleKey, displayName: u?.name);
      }

      final peopleParts = await Future.wait([
        person(p.userId, 'admin_related_owner'),
        person(p.invitedEngineerId, 'admin_related_invited'),
        person(p.acceptedEngineerId, 'admin_related_accepted'),
      ]);
      relatedPeople.assignAll(peopleParts.whereType<AdminProjectRelatedPerson>().toList());

      final aid = p.acceptedOfferId;
      if (aid != null && aid.isNotEmpty) {
        final off = await _firestore.getOffer(aid);
        if (off != null) {
          acceptedOfferLine.value =
              '$aid · ${off.engineerName ?? off.engineerId} · ${off.status}';
        } else {
          acceptedOfferLine.value = aid;
        }
      } else {
        acceptedOfferLine.value = null;
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  ProjectDocument _buildDoc(String id) {
    final prev = _loaded;
    final inv = invitedEngineerIdController.text.trim();
    final acc = acceptedEngineerIdController.text.trim();
    return ProjectDocument(
      id: id,
      userId: userIdController.text.trim(),
      projectType: projectTypeId.value,
      landArea: landAreaController.text.trim(),
      city: selectedCityId.value,
      description: descriptionController.text.trim(),
      imageUrls: prev?.imageUrls ?? const [],
      fileAttachments: prev?.fileAttachments ?? const [],
      status: statusId.value,
      budget: selectedBudgetId.value.isEmpty ? null : selectedBudgetId.value,
      deliveryDuration: selectedDeliveryId.value.isEmpty ? null : selectedDeliveryId.value,
      createdAt: prev?.createdAt,
      paidAmount: prev?.paidAmount,
      acceptedEngineerId: acc.isEmpty ? null : acc,
      acceptedOfferId: prev?.acceptedOfferId,
      invitedEngineerId: inv.isEmpty ? null : inv,
      expectedCompletionAt: prev?.expectedCompletionAt,
      deliveredAt: prev?.deliveredAt,
      listed: listed.value,
    );
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;
    try {
      if (isCreate) {
        final uid = userIdController.text.trim();
        if (uid.isEmpty) {
          Get.snackbar('error'.tr, 'admin_project_owner_required'.tr);
          return;
        }
        final template = _buildDoc('');
        final newId = await _firestore.adminCreateProject(template);
        await _notif.notifyAdminProjectCreated(userId: uid, projectId: newId);
        final inv = invitedEngineerIdController.text.trim();
        if (inv.isNotEmpty && inv != uid) {
          await _notif.notifyAdminProjectCreated(userId: inv, projectId: newId);
        }
        Get.snackbar('', 'profile_saved'.tr);
        Get.back();
        return;
      }

      final id = editingId!;
      final doc = _buildDoc(id);
      await _firestore.adminMergeProject(doc);
      final fresh = await _firestore.getProject(id);
      if (fresh != null) {
        await _notif.notifyAdminProjectUpdated(project: fresh);
      }
      Get.snackbar('', 'profile_saved'.tr);
      Get.back();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteProject() async {
    if (isCreate) return;
    final id = editingId!;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('admin_delete_project_title'.tr),
        content: Text('admin_delete_project_body'.tr),
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
      final prev = _loaded ?? await _firestore.getProject(id);
      final recipients =
          prev != null ? NotificationService.projectChangeRecipients(prev) : <String>{};
      await _notif.notifyAdminProjectDeleted(projectId: id, recipientUserIds: recipients);
      await _firestore.adminDeleteProject(id);
      Get.snackbar('', 'admin_project_deleted_snack'.tr);
      Get.back();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }
}
