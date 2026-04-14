import 'dart:async';

import 'package:get/get.dart';

import '../../../core/models/portfolio_item.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/review_document.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

class EngineerProfileController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  String engineerId = '';
  final engineerName = ''.obs;
  final engineerPhotoUrl = Rxn<String>();
  final engineerCity = ''.obs;
  final engineerBio = ''.obs;
  final engineerSpecialization = ''.obs;
  final engineerYearsExperience = ''.obs;
  final engineerMembership = ''.obs;
  final selectedTabIndex = 0.obs;
  final portfolioItems = <PortfolioItem>[].obs;
  final reviews = <ReviewDocument>[].obs;
  final averageRating = 0.0.obs;
  final isLoading = true.obs;
  final canReview = false.obs;
  final reviewableProjectId = Rxn<String>();

  // Engineer project stats
  final projectsInProgress = 0.obs;
  final projectsCompleted = 0.obs;
  final completedOnTimePercent = 0.0.obs;
  final cancelledPercent = 0.0.obs;

  /// Real-time presence for engineer preview (viewers only).
  final engineerIsOnline = false.obs;
  final engineerLastSeen = Rxn<DateTime>();

  StreamSubscription<UserDocument?>? _engineerPresenceSub;

  @override
  void onClose() {
    _engineerPresenceSub?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  void _listenEngineerPresence() {
    _engineerPresenceSub?.cancel();
    if (engineerId.isEmpty) return;
    _engineerPresenceSub = _firestore.streamUser(engineerId).listen((u) {
      if (u == null) return;
      engineerIsOnline.value = u.isOnline;
      engineerLastSeen.value = u.lastSeen;
    });
  }

  Future<void> load() async {
    if (engineerId.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final user = await _firestore.getUser(engineerId);
      if (user != null) {
        engineerName.value = user.name;
        engineerPhotoUrl.value = user.photoUrl;
        engineerCity.value = user.city;
        engineerBio.value = user.bio ?? '';
        engineerSpecialization.value = user.specialization ?? '';
        engineerYearsExperience.value = user.yearsExperience ?? '';
        engineerMembership.value = user.membershipNumber ?? '';
        engineerIsOnline.value = user.isOnline;
        engineerLastSeen.value = user.lastSeen;
      }
      _listenEngineerPresence();
      portfolioItems.value = await _firestore.getEngineerPortfolio(engineerId);
      reviews.value = await _firestore.getEngineerReviews(engineerId);
      averageRating.value = await _firestore.getEngineerAverageRating(engineerId);

      final stats = await _firestore.getEngineerProjectStats(engineerId);
      projectsInProgress.value = stats.inProgress;
      projectsCompleted.value = stats.completed;
      completedOnTimePercent.value = stats.completedOnTimePercent;
      cancelledPercent.value = stats.cancelledPercent;

      final uid = _auth.currentUserId;
      if (uid != null && uid != engineerId) {
        final currentUser = await _firestore.getUser(uid);
        isClient.value = currentUser?.userType == 'user';
        final project = await _firestore.getChatProjectWithEngineer(uid, engineerId);
        chatProjectId.value = project?.id;
        final projectIds = await _firestore.getCompletedProjectIdsWithEngineer(uid, engineerId);
        for (final pid in projectIds) {
          final alreadyReviewed = await _firestore.hasUserReviewedEngineerForProject(uid, engineerId, pid);
          if (!alreadyReviewed) {
            canReview.value = true;
            reviewableProjectId.value = pid;
            break;
          }
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool get isOwnProfile => _auth.currentUserId == engineerId;

  final isClient = false.obs;
  final chatProjectId = Rxn<String>();

  Future<void> openChatOrInvite() async {
    final uid = _auth.currentUserId;
    if (uid == null || uid == engineerId) return;
    final project = await _firestore.getChatProjectWithEngineer(uid, engineerId);
    if (project != null) {
      Get.toNamed('/chat-project', arguments: project.id);
    } else {
      _navigateToInviteProject();
    }
  }

  void inviteToPrivateProject() {
    _navigateToInviteProject();
  }

  void _navigateToInviteProject() {
    Get.toNamed(AppRoutes.inviteEngineerChooseProject, arguments: {
      'engineerId': engineerId,
      'engineerName': engineerName.value,
    });
  }

  Future<void> answerReview(String reviewId, String answer) async {
    if (answer.trim().isEmpty) return;
    try {
      await _firestore.updateReviewAnswer(reviewId, answer.trim());
      final idx = reviews.indexWhere((r) => r.id == reviewId);
      if (idx >= 0) {
        final r = reviews[idx];
        try {
          await _notif.notifyReviewAnswered(
            reviewerUserId: r.reviewerId,
            engineerName:
                engineerName.value.isNotEmpty ? engineerName.value : 'engineer'.tr,
            reviewId: reviewId,
            projectId: r.projectId ?? '',
            engineerId: engineerId,
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
