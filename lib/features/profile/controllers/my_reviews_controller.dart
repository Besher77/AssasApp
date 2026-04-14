import 'package:get/get.dart';

import '../../../core/models/review_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

class MyReviewsController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final reviews = <ReviewDocument>[].obs;
  final averageRating = 0.0.obs;
  final isLoading = true.obs;
  String _engineerName = '';
  bool _hasLoadedOnce = false;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    final uid = _auth.currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    if (!_hasLoadedOnce) isLoading.value = true;
    try {
      final user = await _firestore.getUser(uid);
      _engineerName = user?.name ?? '';
      reviews.value = await _firestore.getEngineerReviews(uid);
      averageRating.value = await _firestore.getEngineerAverageRating(uid);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
      _hasLoadedOnce = true;
    }
  }

  Future<void> answerReview(String reviewId, String answer) async {
    if (answer.trim().isEmpty) return;
    final uid = _auth.currentUserId;
    if (uid == null) return;
    try {
      await _firestore.updateReviewAnswer(reviewId, answer.trim());
      final idx = reviews.indexWhere((r) => r.id == reviewId);
      if (idx >= 0) {
        final r = reviews[idx];
        try {
          await _notif.notifyReviewAnswered(
            reviewerUserId: r.reviewerId,
            engineerName: _engineerName.isNotEmpty ? _engineerName : 'engineer'.tr,
            reviewId: reviewId,
            projectId: r.projectId ?? '',
            engineerId: uid,
          );
        } catch (_) {}
        reviews[idx] = ReviewDocument(
          id: reviews[idx].id,
          engineerId: reviews[idx].engineerId,
          reviewerId: reviews[idx].reviewerId,
          rating: reviews[idx].rating,
          comment: reviews[idx].comment,
          projectId: reviews[idx].projectId,
          reviewerName: reviews[idx].reviewerName,
          createdAt: reviews[idx].createdAt,
          engineerAnswer: answer.trim(),
          answeredAt: DateTime.now(),
        );
        reviews.refresh();
      }
      Get.snackbar('', 'answer_saved'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }
}
