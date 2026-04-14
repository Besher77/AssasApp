import 'package:get/get.dart';

import '../../../core/models/offer_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import 'browse_projects_controller.dart';

class ProjectDetailController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final project = Rxn<ProjectDocument>();
  final offers = <OfferDocument>[].obs;
  final acceptedOffer = Rxn<OfferDocument>();
  final offerCount = 0.obs;
  final isLoading = true.obs;
  final isOwner = false.obs;
  final hasOffered = false.obs;
  final isEngineer = false.obs;
  final hasReviewed = false.obs;
  final cancelRequest = Rxn<Map<String, dynamic>>();
  final isConfirmingReceipt = false.obs;
  /// Engineer tried to open a project the owner hid from browse.
  final unlistedAccessDenied = false.obs;

  String? get currentUserId => _auth.currentUserId;

  /// Owner can hide or show project in engineer browse (only before an engineer is assigned).
  bool get canToggleBrowseListing {
    final p = project.value;
    if (p == null || !isOwner.value) return false;
    if (p.status != 'new') return false;
    final acc = p.acceptedEngineerId;
    if (acc != null && acc.isNotEmpty) return false;
    return true;
  }

  bool get canCancelProject {
    final p = project.value;
    if (p == null) return false;
    return (p.status == 'in_progress' || p.status == 'delivered') &&
        p.paidAmount != null &&
        p.paidAmount! > 0;
  }

  bool get isOtherPartyInCancelRequest {
    final req = cancelRequest.value;
    if (req == null) return false;
    final initiatorId = req['initiatorId'] as String?;
    return initiatorId != null && initiatorId != currentUserId;
  }

  Future<void> load(String projectId) async {
    isLoading.value = true;
    unlistedAccessDenied.value = false;
    try {
      final p = await _firestore.getProject(projectId);
      project.value = p;
      if (p == null) {
        isLoading.value = false;
        return;
      }
      isOwner.value = currentUserId == p.userId;
      if (_auth.currentUser != null) {
        final user = await _firestore.getUser(currentUserId!);
        isEngineer.value = user?.userType == 'engineer';
      }

      if (!isOwner.value) {
        final uid = currentUserId;
        final acceptedByMe =
            uid != null && p.acceptedEngineerId != null && p.acceptedEngineerId == uid;
        if (!p.listed && !acceptedByMe) {
          unlistedAccessDenied.value = true;
          project.value = null;
          Get.snackbar('error'.tr, 'project_hidden_from_engineers'.tr);
          return;
        }
      }

      if (isOwner.value) {
        offers.value = await _firestore.getProjectOffers(projectId);
        acceptedOffer.value = await _firestore.getAcceptedOfferForProject(projectId);
        if (acceptedOffer.value != null && currentUserId != null) {
          hasReviewed.value = await _firestore.hasUserReviewedEngineerForProject(
            currentUserId!,
            acceptedOffer.value!.engineerId,
            projectId,
          );
        }
      } else if (isEngineer.value) {
        hasOffered.value = await _firestore.hasEngineerOffered(projectId, currentUserId!);
        if (p.acceptedEngineerId == currentUserId) {
          acceptedOffer.value = await _firestore.getAcceptedOfferForProject(projectId);
        }
      }
      offerCount.value = await _firestore.getProjectOfferCount(projectId);
      cancelRequest.value = await _firestore.getProjectCancelRequest(projectId);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String? get remainingTimeText {
    final p = project.value;
    if (p == null || p.expectedCompletionAt == null) return null;
    final now = DateTime.now();
    final end = p.expectedCompletionAt!;
    if (end.isBefore(now)) return 'overdue'.tr;
    final diff = end.difference(now);
    if (diff.inDays > 0) return 'days_remaining'.trParams({'count': '${diff.inDays}'});
    if (diff.inHours > 0) return 'hours_remaining'.trParams({'count': '${diff.inHours}'});
    return 'less_than_hour'.tr;
  }

  Future<void> markProjectDelivered() async {
    final p = project.value;
    if (p == null) return;
    try {
      await _firestore.markProjectDelivered(p.id);
      await _notif.notifyProjectDelivered(clientUserId: p.userId, projectId: p.id);
      project.value = ProjectDocument(
        id: p.id,
        userId: p.userId,
        projectType: p.projectType,
        landArea: p.landArea,
        city: p.city,
        description: p.description,
        imageUrls: p.imageUrls,
        fileAttachments: p.fileAttachments,
        status: 'delivered',
        budget: p.budget,
        deliveryDuration: p.deliveryDuration,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        paidAmount: p.paidAmount,
        acceptedEngineerId: p.acceptedEngineerId,
        acceptedOfferId: p.acceptedOfferId,
        invitedEngineerId: p.invitedEngineerId,
        expectedCompletionAt: p.expectedCompletionAt,
        deliveredAt: DateTime.now(),
        listed: p.listed,
      );
      Get.snackbar('success'.tr, 'project_delivered'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> confirmProjectReceipt() async {
    final p = project.value;
    if (p == null || currentUserId == null) return;
    isConfirmingReceipt.value = true;
    try {
      final confId = await _firestore.confirmProjectReceipt(p.id, currentUserId!);
      final completed = await _firestore.waitForProjectConfirmation(confId);
      if (completed) {
        project.value = ProjectDocument(
          id: p.id,
          userId: p.userId,
          projectType: p.projectType,
          landArea: p.landArea,
          city: p.city,
          description: p.description,
          imageUrls: p.imageUrls,
          fileAttachments: p.fileAttachments,
          status: 'completed',
          budget: p.budget,
          deliveryDuration: p.deliveryDuration,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
          paidAmount: p.paidAmount,
          acceptedEngineerId: p.acceptedEngineerId,
          acceptedOfferId: p.acceptedOfferId,
          invitedEngineerId: p.invitedEngineerId,
          expectedCompletionAt: p.expectedCompletionAt,
          deliveredAt: p.deliveredAt,
          listed: p.listed,
        );
        Get.snackbar('success'.tr, 'project_received'.tr);
      } else {
        Get.snackbar('error'.tr, 'payment_processing_timeout'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isConfirmingReceipt.value = false;
    }
  }

  Future<void> acceptOffer(OfferDocument offer) async {
    try {
      await _firestore.updateOfferStatus(offer.id, 'accepted');
      await _firestore.updateProjectStatus(offer.projectId, 'in_progress');
      await _notif.notifyOfferAccepted(
        engineerUserId: offer.engineerId,
        projectId: offer.projectId,
        offerId: offer.id,
      );
      offers.removeWhere((o) => o.id == offer.id);
      acceptedOffer.value = offer;
      offerCount.value = offers.where((o) => o.status == 'pending').length;
      project.value = project.value != null
          ? ProjectDocument(
              id: project.value!.id,
              userId: project.value!.userId,
              projectType: project.value!.projectType,
              landArea: project.value!.landArea,
              city: project.value!.city,
              description: project.value!.description,
              imageUrls: project.value!.imageUrls,
              fileAttachments: project.value!.fileAttachments,
              status: 'in_progress',
              budget: project.value!.budget,
              deliveryDuration: project.value!.deliveryDuration,
              createdAt: project.value!.createdAt,
              updatedAt: project.value!.updatedAt,
              paidAmount: project.value!.paidAmount,
              acceptedEngineerId: offer.engineerId,
              acceptedOfferId: offer.id,
              invitedEngineerId: project.value!.invitedEngineerId,
              expectedCompletionAt: project.value!.expectedCompletionAt,
              deliveredAt: project.value!.deliveredAt,
              listed: project.value!.listed,
            )
          : null;
      Get.snackbar('success'.tr, 'offer_accepted'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> rejectOffer(OfferDocument offer) async {
    try {
      await _firestore.updateOfferStatus(offer.id, 'rejected');
      await _notif.notifyOfferRejected(
        engineerUserId: offer.engineerId,
        projectId: offer.projectId,
        offerId: offer.id,
      );
      offers.removeWhere((o) => o.id == offer.id);
      offerCount.value = offers.where((o) => o.status == 'pending').length;
      Get.snackbar('success'.tr, 'offer_rejected'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> requestCancelProject(String causeId, {String? causeText}) async {
    final p = project.value;
    if (p == null || currentUserId == null) return;
    try {
      await _firestore.createProjectCancelRequest(
        projectId: p.id,
        initiatorId: currentUserId!,
        causeId: causeId,
        causeText: causeText,
      );
      cancelRequest.value = await _firestore.getProjectCancelRequest(p.id);
      Get.snackbar('success'.tr, 'cancel_request_sent'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> respondToCancelRequest(String causeId, {String? causeText}) async {
    final req = cancelRequest.value;
    if (req == null || currentUserId == null) return;
    final reqId = req['id'] as String?;
    if (reqId == null) return;
    try {
      await _firestore.respondToCancelRequest(
        requestId: reqId,
        causeId: causeId,
        causeText: causeText,
      );
      cancelRequest.value = null;
      Get.snackbar('success'.tr, 'project_cancelled'.tr);
      await load(project.value!.id);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> updateBrowseListing(bool listed) async {
    final p = project.value;
    if (p == null || !canToggleBrowseListing) return;
    try {
      await _firestore.updateProjectListed(p.id, listed);
      project.value = ProjectDocument(
        id: p.id,
        userId: p.userId,
        projectType: p.projectType,
        landArea: p.landArea,
        city: p.city,
        description: p.description,
        imageUrls: p.imageUrls,
        fileAttachments: p.fileAttachments,
        status: p.status,
        budget: p.budget,
        deliveryDuration: p.deliveryDuration,
        createdAt: p.createdAt,
        updatedAt: DateTime.now(),
        paidAmount: p.paidAmount,
        acceptedEngineerId: p.acceptedEngineerId,
        acceptedOfferId: p.acceptedOfferId,
        invitedEngineerId: p.invitedEngineerId,
        expectedCompletionAt: p.expectedCompletionAt,
        deliveredAt: p.deliveredAt,
        listed: listed,
      );
      Get.snackbar(
        'success'.tr,
        listed ? 'project_now_visible_to_engineers'.tr : 'project_now_hidden_from_engineers'.tr,
      );
      if (Get.isRegistered<BrowseProjectsController>()) {
        await Get.find<BrowseProjectsController>().loadProjects();
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<Map<String, dynamic>?> getChatArgs() async {
    final p = project.value;
    final acc = acceptedOffer.value;
    if (p == null || acc == null || currentUserId == null) return null;
    if (isOwner.value) {
      return {
        'project': p,
        'otherUserId': acc.engineerId,
        'otherUserName': acc.engineerName ?? 'engineer'.tr,
      };
    }
    if (isEngineer.value && p.acceptedEngineerId == currentUserId) {
      final owner = await _firestore.getUser(p.userId);
      return {
        'project': p,
        'otherUserId': p.userId,
        'otherUserName': owner?.name ?? 'client'.tr,
      };
    }
    return null;
  }

  @override
  Future<void> refresh() async {
    final p = project.value;
    if (p != null) await load(p.id);
  }
}
