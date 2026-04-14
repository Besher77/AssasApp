import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/review_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

class AddReviewController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final formKey = GlobalKey<FormState>();
  final commentController = TextEditingController();
  final rating = 5.obs;
  final isSubmitting = false.obs;

  String engineerId = '';
  String? projectId;

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (engineerId.isEmpty || !(formKey.currentState?.validate() ?? false)) return;
    final uid = _auth.currentUserId;
    if (uid == null) return;

    if (projectId == null || projectId!.isEmpty) {
      Get.snackbar('error'.tr, 'review_only_after_completion'.tr);
      return;
    }

    final project = await _firestore.getProject(projectId!);
    if (project == null || project.status != 'completed') {
      Get.snackbar('error'.tr, 'review_only_after_completion'.tr);
      return;
    }
    if (project.userId != uid) {
      Get.snackbar('error'.tr, 'error_permission_denied'.tr);
      return;
    }

    final acceptedOffer = await _firestore.getAcceptedOfferForProject(projectId!);
    if (acceptedOffer == null || acceptedOffer.engineerId != engineerId) {
      Get.snackbar('error'.tr, 'review_only_after_completion'.tr);
      return;
    }

    final alreadyReviewed = await _firestore.hasUserReviewedEngineerForProject(
        uid, engineerId, projectId!);
    if (alreadyReviewed) {
      Get.snackbar('error'.tr, 'already_reviewed'.tr);
      return;
    }

    isSubmitting.value = true;
    try {
      final user = await _firestore.getUser(uid);
      final review = ReviewDocument(
        id: '',
        engineerId: engineerId,
        reviewerId: uid,
        rating: rating.value,
        comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
        projectId: projectId,
        reviewerName: user?.name,
      );
      final reviewId = await _firestore.createReview(review);
      try {
        await _notif.notifyReviewReceived(
          engineerUserId: engineerId,
          reviewerName: user?.name ?? 'user'.tr,
          projectId: projectId!,
          reviewId: reviewId,
        );
      } catch (_) {}
      Get.back(result: true);
      Get.snackbar('success'.tr, 'review_sent'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
