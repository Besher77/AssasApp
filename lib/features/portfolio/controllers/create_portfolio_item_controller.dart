import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/portfolio_item.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import 'portfolio_controller.dart';

class CreatePortfolioItemController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final StorageService _storage = Get.find<StorageService>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final selectedProjectTypeId = ''.obs;
  final executionDate = Rxn<DateTime>();
  final imagePaths = <String>[].obs;
  final _imageFiles = <File>[];
  final isLoading = false.obs;

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.onClose();
  }

  String? validateRequired(String? value, String key) {
    if (value == null || value.trim().isEmpty) return key.tr;
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
    if (index < _imageFiles.length) _imageFiles.removeAt(index);
    imagePaths.removeAt(index);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: executionDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) executionDate.value = picked;
  }

  Future<void> createItem() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final uid = _authService.currentUserId;
      if (uid == null) {
        Get.snackbar('error'.tr, 'error_user_not_found'.tr);
        return;
      }

      final item = PortfolioItem(
        id: '',
        engineerId: uid,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        imageUrls: [],
        projectType: selectedProjectTypeId.value.isEmpty ? null : selectedProjectTypeId.value,
        location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        executionDate: executionDate.value,
      );

      final itemId = await _firestore.createPortfolioItem(item);
      final imageUrls = <String>[];

      for (var i = 0; i < _imageFiles.length; i++) {
        try {
          final url = await _storage.uploadPortfolioImage(uid, itemId, i, _imageFiles[i]);
          if (url != null) imageUrls.add(url);
        } catch (e) {
          Get.snackbar('error'.tr, '${'upload_failed'.tr}: ${e.toString()}');
          isLoading.value = false;
          return;
        }
      }

      if (imageUrls.isNotEmpty) {
        await _firestore.updatePortfolioItemImages(itemId, imageUrls);
      }

      Get.snackbar('', 'portfolio_item_added'.tr);
      try {
        await Get.find<PortfolioController>().loadItems();
      } catch (_) {}
      Get.back();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
