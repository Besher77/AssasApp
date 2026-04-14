import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/notification_document.dart';
import '../../../core/models/project_document.dart';
import 'my_projects_controller.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';

class CreateProjectController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final StorageService _storage = Get.find<StorageService>();

  String invitedEngineerId = '';
  String invitedEngineerName = '';

  final projectTypeId = ''.obs;
  final landAreaController = TextEditingController();
  final selectedCityId = ''.obs;
  final selectedBudgetId = ''.obs;
  final selectedDeliveryDurationId = ''.obs;
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final imagePaths = <String>[].obs;
  final _imageFiles = <File>[];
  final fileAttachments = <({File file, String name})>[].obs;
  final isLoading = false.obs;
  /// 0–1 while submitting; used with [submitPhaseKey] for UI progress.
  final submitProgress = 0.0.obs;
  /// i18n key for current step (see `create_project_step_*`).
  final submitPhaseKey = ''.obs;

  @override
  void onClose() {
    landAreaController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  String? validateRequired(String? value, String key) {
    if (value == null || value.trim().isEmpty) return key.tr;
    return null;
  }

  String? validateProjectType(String? value) {
    if (value == null || value.isEmpty) return 'project_type_required'.tr;
    return null;
  }

  String? validateCity(String? value) {
    if (value == null || value.isEmpty) return 'city_required'.tr;
    return null;
  }

  String? validateBudget(String? value) {
    if (value == null || value.isEmpty) return 'budget_required'.tr;
    return null;
  }

  String? validateDeliveryDuration(String? value) {
    if (value == null || value.isEmpty) return 'delivery_duration_required'.tr;
    return null;
  }

  Future<void> pickImages() async {
    try {
      final picker = ImagePicker();
      final xfiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xfiles.isNotEmpty) {
        for (final x in xfiles) {
          _imageFiles.add(File(x.path));
          imagePaths.add(x.path);
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  void removeImage(int index) {
    if (index < _imageFiles.length) {
      _imageFiles.removeAt(index);
    }
    imagePaths.removeAt(index);
  }

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        for (final f in result.files) {
          if (f.path != null) {
            fileAttachments.add((file: File(f.path!), name: f.name));
          }
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  void removeFile(int index) {
    fileAttachments.removeAt(index);
  }

  Future<void> createProject() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    submitProgress.value = 0.05;
    submitPhaseKey.value = 'create_project_step_saving';
    try {
      final uid = _authService.currentUserId;
      if (uid == null) {
        Get.snackbar('error'.tr, 'error_user_not_found'.tr);
        return;
      }

      final project = ProjectDocument(
        id: '',
        userId: uid,
        projectType: projectTypeId.value,
        landArea: landAreaController.text.trim(),
        city: selectedCityId.value,
        description: descriptionController.text.trim(),
        imageUrls: [],
        status: 'new',
        budget: selectedBudgetId.value.isEmpty ? null : selectedBudgetId.value,
        deliveryDuration: selectedDeliveryDurationId.value.isEmpty ? null : selectedDeliveryDurationId.value,
        invitedEngineerId: invitedEngineerId.isEmpty ? null : invitedEngineerId,
        listed: invitedEngineerId.isEmpty,
      );

      submitProgress.value = 0.12;
      final projectId = await _firestore.createProject(project);
      submitProgress.value = 0.22;

      if (invitedEngineerId.isNotEmpty) {
        submitPhaseKey.value = 'create_project_step_notifying';
        final clientName = _authService.currentUser?.displayName ?? 'client'.tr;
        await _firestore.createNotification(
          NotificationDocument(
            id: '',
            userId: invitedEngineerId,
            title: 'project_invitation_title'.tr,
            body: 'project_invitation_body'.trParams({'name': clientName}),
            type: 'project_invitation',
            data: {'projectId': projectId},
          ),
        );
      }
      submitProgress.value = 0.28;

      submitPhaseKey.value = 'create_project_step_images';
      final imageUrls = <String>[];
      final nImg = _imageFiles.length;
      for (var i = 0; i < nImg; i++) {
        try {
          final url = await _storage.uploadProjectImage(projectId, i, _imageFiles[i]);
          if (url != null) imageUrls.add(url);
          submitProgress.value = 0.28 + (i + 1) / (nImg > 0 ? nImg : 1) * 0.32;
        } catch (e) {
          Get.snackbar('error'.tr, '${'upload_failed'.tr}: ${e.toString()}');
          return;
        }
      }
      if (nImg == 0) submitProgress.value = 0.6;

      if (imageUrls.isNotEmpty) {
        await _firestore.updateProjectImages(projectId, imageUrls);
      }
      submitProgress.value = 0.62;

      submitPhaseKey.value = 'create_project_step_files';
      final attachments = <Map<String, dynamic>>[];
      final nFiles = fileAttachments.length;
      for (var i = 0; i < nFiles; i++) {
        final f = fileAttachments[i];
        try {
          final url = await _storage.uploadProjectFile(projectId, f.name, f.file);
          if (url != null) attachments.add({'url': url, 'name': f.name});
          submitProgress.value = 0.62 + (i + 1) / (nFiles > 0 ? nFiles : 1) * 0.28;
        } catch (e) {
          Get.snackbar('error'.tr, '${'upload_failed'.tr}: ${e.toString()}');
          return;
        }
      }
      if (nFiles == 0) submitProgress.value = 0.92;

      if (attachments.isNotEmpty) {
        await _firestore.updateProjectFiles(projectId, attachments);
      }

      submitProgress.value = 1.0;
      submitPhaseKey.value = 'create_project_step_done';

      if (Get.isRegistered<MyProjectsController>()) {
        await Get.find<MyProjectsController>().loadProjects();
      }

      final successMsg =
          invitedEngineerId.isNotEmpty ? 'project_invitation_sent'.tr : 'project_created'.tr;
      Get.back();
      Future.microtask(() {
        Get.snackbar('success'.tr, successMsg, snackPosition: SnackPosition.BOTTOM);
      });
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
      submitProgress.value = 0;
      submitPhaseKey.value = '';
    }
  }
}
