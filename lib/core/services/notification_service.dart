import 'package:get/get.dart';

import 'firestore_service.dart';
import '../models/notification_document.dart';
import '../models/project_document.dart';

/// Creates in-app notifications. For push (FCM), deploy Cloud Functions.
class NotificationService extends GetxService {
  final FirestoreService _firestore = Get.find<FirestoreService>();

  /// Notify project owner when engineer sends offer
  Future<void> notifyOfferReceived({
    required String clientUserId,
    required String engineerName,
    required String projectId,
    String? offerId,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: clientUserId,
      title: 'offer_received_title'.tr,
      body: 'offer_received_body'.trParams({'name': engineerName}),
      type: 'offer_received',
      data: {'projectId': projectId, 'offerId': offerId ?? ''},
    ));
  }

  /// Notify engineer when offer is accepted
  Future<void> notifyOfferAccepted({
    required String engineerUserId,
    required String projectId,
    String? offerId,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: engineerUserId,
      title: 'offer_accepted_title'.tr,
      body: 'offer_accepted_body'.tr,
      type: 'offer_accepted',
      data: {'projectId': projectId, 'offerId': offerId ?? ''},
    ));
  }

  /// Notify client when engineer delivers project
  Future<void> notifyProjectDelivered({
    required String clientUserId,
    required String projectId,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: clientUserId,
      title: 'project_delivered_title'.tr,
      body: 'project_delivered_body'.tr,
      type: 'project_delivered',
      data: {'projectId': projectId},
    ));
  }

  /// Notify engineer when offer is rejected
  Future<void> notifyOfferRejected({
    required String engineerUserId,
    required String projectId,
    String? offerId,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: engineerUserId,
      title: 'offer_rejected_title'.tr,
      body: 'offer_rejected_body'.tr,
      type: 'offer_rejected',
      data: {'projectId': projectId, 'offerId': offerId ?? ''},
    ));
  }

  /// User wallet deposit — triggers FCM via Firestore `notifications` onCreate.
  Future<void> notifyWalletDeposit({
    required String userId,
    required double amount,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: userId,
      title: 'notif_wallet_deposit_title'.tr,
      body: 'notif_wallet_deposit_body'.trParams({'amount': amount.toStringAsFixed(2)}),
      type: 'wallet_deposit',
      data: {'amount': amount.toStringAsFixed(2)},
    ));
  }

  /// Admin added balance to user wallet (in-app + FCM).
  Future<void> notifyAdminWalletCredit({
    required String userId,
    required double amount,
    String? note,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: userId,
      title: 'notif_admin_wallet_credit_title'.tr,
      body: 'notif_admin_wallet_credit_body'.trParams({'amount': amount.toStringAsFixed(2)}),
      type: 'admin_wallet_credit',
      data: {
        'amount': amount.toStringAsFixed(2),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    ));
  }

  /// Admin removed balance from user wallet (in-app + FCM).
  Future<void> notifyAdminWalletDebit({
    required String userId,
    required double amount,
    String? note,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: userId,
      title: 'notif_admin_wallet_debit_title'.tr,
      body: 'notif_admin_wallet_debit_body'.trParams({'amount': amount.toStringAsFixed(2)}),
      type: 'admin_wallet_debit',
      data: {
        'amount': amount.toStringAsFixed(2),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    ));
  }

  /// Engineer withdrawal request submitted.
  Future<void> notifyWithdrawalSubmitted({
    required String userId,
    required double amount,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: userId,
      title: 'notif_withdrawal_submitted_title'.tr,
      body: 'notif_withdrawal_submitted_body'.trParams({'amount': amount.toStringAsFixed(2)}),
      type: 'withdrawal_submitted',
      data: {'amount': amount.toStringAsFixed(2)},
    ));
  }

  /// Engineer notified when a client submits a review.
  Future<void> notifyReviewReceived({
    required String engineerUserId,
    required String reviewerName,
    required String projectId,
    required String reviewId,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: engineerUserId,
      title: 'notif_review_received_title'.tr,
      body: 'notif_review_received_body'.trParams({'name': reviewerName}),
      type: 'review_received',
      data: {
        'projectId': projectId,
        'reviewId': reviewId,
        'engineerId': engineerUserId,
      },
    ));
  }

  /// Recipients to notify when an admin changes a project.
  static Set<String> projectChangeRecipients(ProjectDocument p) {
    final s = <String>{p.userId};
    final acc = p.acceptedEngineerId;
    if (acc != null && acc.isNotEmpty) s.add(acc);
    final inv = p.invitedEngineerId;
    if (inv != null && inv.isNotEmpty) s.add(inv);
    return s;
  }

  /// Admin updated a user profile — notify that user (in-app + FCM via Cloud Function).
  Future<void> notifyAdminUserProfileUpdated({required String userId}) async {
    try {
      await _firestore.createNotification(NotificationDocument(
        id: '',
        userId: userId,
        title: 'notif_admin_user_updated_title'.tr,
        body: 'notif_admin_user_updated_body'.tr,
        type: 'admin_user_updated',
        data: const {},
      ));
    } catch (_) {}
  }

  /// Admin blocked or unblocked the account.
  Future<void> notifyAdminUserBlockedChanged({required String userId, required bool blocked}) async {
    try {
      await _firestore.createNotification(NotificationDocument(
        id: '',
        userId: userId,
        title: blocked ? 'notif_admin_user_blocked_title'.tr : 'notif_admin_user_unblocked_title'.tr,
        body: blocked ? 'notif_admin_user_blocked_body'.tr : 'notif_admin_user_unblocked_body'.tr,
        type: blocked ? 'admin_user_blocked' : 'admin_user_unblocked',
        data: const {},
      ));
    } catch (_) {}
  }

  /// Admin set or cleared suspension window.
  Future<void> notifyAdminUserSuspensionChanged({
    required String userId,
    required DateTime? suspendedUntil,
  }) async {
    try {
      final active = suspendedUntil != null && suspendedUntil.isAfter(DateTime.now());
      await _firestore.createNotification(NotificationDocument(
        id: '',
        userId: userId,
        title: active ? 'notif_admin_user_suspended_title'.tr : 'notif_admin_suspension_cleared_title'.tr,
        body: active
            ? 'notif_admin_user_suspended_body'.trParams({
                'date':
                    '${suspendedUntil.year}-${suspendedUntil.month.toString().padLeft(2, '0')}-${suspendedUntil.day.toString().padLeft(2, '0')}',
              })
            : 'notif_admin_suspension_cleared_body'.tr,
        type: active ? 'admin_user_suspended' : 'admin_suspension_cleared',
        data: const {},
      ));
    } catch (_) {}
  }

  /// Before Firestore user doc is removed — last in-app notice.
  Future<void> notifyAdminUserProfileRemoved({required String userId}) async {
    try {
      await _firestore.createNotification(NotificationDocument(
        id: '',
        userId: userId,
        title: 'notif_admin_user_removed_title'.tr,
        body: 'notif_admin_user_removed_body'.tr,
        type: 'admin_user_removed',
        data: const {},
      ));
    } catch (_) {}
  }

  /// Admin updated a project — notify owner and linked engineers.
  Future<void> notifyAdminProjectUpdated({
    required ProjectDocument project,
  }) async {
    for (final uid in projectChangeRecipients(project)) {
      try {
        await _firestore.createNotification(NotificationDocument(
          id: '',
          userId: uid,
          title: 'notif_admin_project_updated_title'.tr,
          body: 'notif_admin_project_updated_body'.tr,
          type: 'admin_project_updated',
          data: {'projectId': project.id},
        ));
      } catch (_) {}
    }
  }

  /// Admin deleted a project — notify stakeholders (project id only for reference).
  Future<void> notifyAdminProjectDeleted({
    required String projectId,
    required Set<String> recipientUserIds,
  }) async {
    for (final uid in recipientUserIds) {
      try {
        await _firestore.createNotification(NotificationDocument(
          id: '',
          userId: uid,
          title: 'notif_admin_project_deleted_title'.tr,
          body: 'notif_admin_project_deleted_body'.tr,
          type: 'admin_project_deleted',
          data: {'projectId': projectId},
        ));
      } catch (_) {}
    }
  }

  /// Admin created a project on behalf of a client.
  Future<void> notifyAdminProjectCreated({
    required String userId,
    required String projectId,
  }) async {
    try {
      await _firestore.createNotification(NotificationDocument(
        id: '',
        userId: userId,
        title: 'notif_admin_project_created_title'.tr,
        body: 'notif_admin_project_created_body'.tr,
        type: 'admin_project_created',
        data: {'projectId': projectId},
      ));
    } catch (_) {}
  }

  /// Client notified when engineer replies to their review.
  Future<void> notifyReviewAnswered({
    required String reviewerUserId,
    required String engineerName,
    required String reviewId,
    required String projectId,
    required String engineerId,
  }) async {
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: reviewerUserId,
      title: 'notif_review_answer_title'.tr,
      body: 'notif_review_answer_body'.trParams({'name': engineerName}),
      type: 'review_answered',
      data: {
        'projectId': projectId,
        'reviewId': reviewId,
        'engineerId': engineerId,
      },
    ));
  }

  /// Push + in-app when admin marks a withdrawal as transferred to the engineer’s bank.
  Future<void> notifyWithdrawalTransferred({
    required String userId,
    required double amount,
    required String withdrawalRequestId,
  }) async {
    try {
      await _firestore.createNotification(NotificationDocument(
        id: '',
        userId: userId,
        title: 'notif_withdrawal_transferred_title'.tr,
        body: 'notif_withdrawal_transferred_body'.trParams({'amount': amount.toStringAsFixed(2)}),
        type: 'withdrawal_transferred',
        data: {
          'amount': amount.toStringAsFixed(2),
          'withdrawalRequestId': withdrawalRequestId,
        },
      ));
    } catch (_) {}
  }

  /// Client and accepted engineer notified when admin posts in the shared project chat.
  Future<void> notifyProjectAdminChatMessage({
    required String projectId,
    required String clientUserId,
    required String engineerUserId,
  }) async {
    final ids = <String>{clientUserId, engineerUserId}..removeWhere((e) => e.isEmpty);
    try {
      for (final uid in ids) {
        await _firestore.createNotification(NotificationDocument(
          id: '',
          userId: uid,
          title: 'notif_admin_support_title'.tr,
          body: 'notif_admin_support_body'.tr,
          type: 'admin_support_message',
          data: {'projectId': projectId},
        ));
      }
    } catch (_) {}
  }

  /// Admin-composed message to one user (in-app + FCM via `sendNotificationFcm`).
  Future<void> sendAdminAnnouncementToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    if (userId.isEmpty || title.isEmpty || body.isEmpty) return;
    await _firestore.createNotification(NotificationDocument(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: 'admin_announcement',
      data: const {},
    ));
  }

  /// Admin broadcast to every client + engineer account (not admins).
  Future<int> sendAdminAnnouncementToAllUsers({
    required String title,
    required String body,
  }) async {
    if (title.isEmpty || body.isEmpty) return 0;
    final ids = await _firestore.getClientAndEngineerUserUids();
    return _firestore.adminBroadcastNotifications(userIds: ids, title: title, body: body);
  }
}
