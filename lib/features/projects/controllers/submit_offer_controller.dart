import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/platform_commission.dart';
import '../../../core/constants/project_options.dart';
import '../../../core/models/offer_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';

class SubmitOfferController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();
  final StorageService _storage = Get.find<StorageService>();

  final formKey = GlobalKey<FormState>();
  final messageController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();
  final isSubmitting = false.obs;
  /// Bumps when [priceController] changes so offer net preview rebuilds.
  final priceInputTick = 0.obs;

  final imageFiles = <File>[].obs;
  final fileAttachments = <({File file, String name})>[].obs;

  ProjectDocument? project;

  double get projectMinBudget =>
      project?.budget != null && project!.budget!.isNotEmpty
          ? getBudgetMinAmount(project!.budget!)
          : 0;

  String get projectDurationHint =>
      project?.deliveryDuration != null && project!.deliveryDuration!.isNotEmpty
          ? getDeliveryDurationNameById(project!.deliveryDuration!)
          : '';

  String get projectBudgetHint =>
      project?.budget != null && project!.budget!.isNotEmpty
          ? getBudgetOptionNameById(project!.budget!)
          : '';

  void _onPriceChanged() => priceInputTick.value++;

  /// Parsed offer amount from the price field, or null if invalid.
  double? get parsedOfferAmount {
    final s = priceController.text.replaceAll(',', '').trim();
    final match = RegExp(r'[\d.]+').firstMatch(s);
    if (match == null) return null;
    final amount = double.tryParse(match.group(0)!);
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  /// Estimated wallet credit after 10% platform fee (if client accepts this price as paid amount).
  double? get engineerEstimatedNet {
    final gross = parsedOfferAmount;
    if (gross == null) return null;
    return engineerNetAfterCommission(gross);
  }

  @override
  void onInit() {
    super.onInit();
    priceController.addListener(_onPriceChanged);
  }

  @override
  void onClose() {
    priceController.removeListener(_onPriceChanged);
    messageController.dispose();
    priceController.dispose();
    durationController.dispose();
    super.onClose();
  }

  String? validateMessage(String? v) =>
      (v == null || v.trim().isEmpty) ? 'offer_message_required'.tr : null;

  String? validatePrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'proposed_price_required'.tr;
    final s = v.replaceAll(',', '').trim();
    final match = RegExp(r'[\d.]+').firstMatch(s);
    if (match == null) return 'invalid_price'.tr;
    final amount = double.tryParse(match.group(0)!);
    if (amount == null || amount <= 0) return 'invalid_price'.tr;
    if (projectMinBudget > 0 && amount < projectMinBudget) {
      return 'price_min_hint'.trParams({'min': projectMinBudget.toStringAsFixed(0)});
    }
    return null;
  }

  String? validateDuration(String? v) =>
      (v == null || v.trim().isEmpty) ? 'proposed_duration_required'.tr : null;

  Future<void> pickImages() async {
    try {
      final picker = ImagePicker();
      final xfiles = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
      if (xfiles.isNotEmpty) {
        for (final x in xfiles) {
          imageFiles.add(File(x.path));
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
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

  void removeImage(int index) => imageFiles.removeAt(index);
  void removeFile(int index) => fileAttachments.removeAt(index);

  Future<void> submit() async {
    if (project == null || !(formKey.currentState?.validate() ?? false)) return;
    if (!project!.listed) {
      Get.snackbar('error'.tr, 'project_not_accepting_offers'.tr);
      return;
    }
    isSubmitting.value = true;
    try {
      final user = await _firestore.getUser(_auth.currentUserId!);
      if (user == null) throw Exception('error_user_not_found'.tr);

      final imageUrls = <String>[];
      for (var i = 0; i < imageFiles.length; i++) {
        final url = await _storage.uploadOfferImage(project!.id, i, imageFiles[i]);
        if (url != null) imageUrls.add(url);
      }

      final attachments = <OfferFileAttachment>[];
      for (final f in fileAttachments) {
        final url = await _storage.uploadOfferFile(project!.id, f.name, f.file);
        if (url != null) attachments.add(OfferFileAttachment(url: url, name: f.name));
      }

      final offer = OfferDocument(
        id: '',
        projectId: project!.id,
        engineerId: _auth.currentUserId!,
        message: messageController.text.trim(),
        proposedPrice: priceController.text.trim(),
        proposedDuration: durationController.text.trim(),
        imageUrls: imageUrls,
        fileAttachments: attachments,
        engineerName: user.name,
        engineerPhotoUrl: user.photoUrl,
      );
      final offerId = await _firestore.createOffer(offer);

      await _notif.notifyOfferReceived(
        clientUserId: project!.userId,
        engineerName: user.name,
        projectId: project!.id,
        offerId: offerId,
      );

      Get.back(result: true);
      Get.snackbar('success'.tr, 'offer_sent'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
