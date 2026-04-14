import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/admin_dashboard_stats.dart';
import '../models/message_document.dart' show MessageDocument, MessageStatus, MessageType;
import '../models/notification_document.dart' show NotificationDocument;
import '../models/saved_card_document.dart' show SavedCardDocument;
import '../models/offer_document.dart' show OfferDocument;
import '../models/portfolio_item.dart' show PortfolioItem;
import '../models/project_document.dart' show ProjectDocument;
import '../models/review_document.dart' show ReviewDocument;
import '../models/transaction_document.dart' show TransactionDocument;
import '../models/withdrawal_request_row.dart' show WithdrawalRequestRow;
import '../models/wallet_document.dart' show WalletDocument;

/// Thrown when [FirestoreService.clientInviteEngineerToExistingProject] cannot proceed.
class ClientInviteProjectException implements Exception {
  const ClientInviteProjectException(this.code);
  /// `forbidden` | `not_eligible`
  final String code;
}

/// Engineer project statistics for profile display
class EngineerProjectStats {
  const EngineerProjectStats({
    required this.inProgress,
    required this.completed,
    required this.completedOnTimePercent,
    required this.cancelledPercent,
  });
  final int inProgress;
  final int completed;
  final double completedOnTimePercent;
  final double cancelledPercent;
}

/// Firestore paths
class FirestorePaths {
  FirestorePaths._();
  static const users = 'users';
  static String userDoc(String uid) => '$users/$uid';

  static const projects = 'projects';
  static String projectDoc(String id) => '$projects/$id';

  static const portfolioItems = 'portfolio_items';
  static String portfolioItemDoc(String id) => '$portfolioItems/$id';

  static const offers = 'offers';
  static String offerDoc(String id) => '$offers/$id';

  static const notifications = 'notifications';
  static String notificationDoc(String id) => '$notifications/$id';

  static const reviews = 'reviews';
  static String reviewDoc(String id) => '$reviews/$id';

  static const wallets = 'wallets';
  static String walletDoc(String userId) => '$wallets/$userId';

  static const transactions = 'transactions';
  static String transactionDoc(String id) => '$transactions/$id';

  static const paymentRequests = 'payment_requests';
  static String paymentRequestDoc(String id) => '$paymentRequests/$id';

  static const withdrawalRequests = 'withdrawal_requests';
  static String withdrawalRequestDoc(String id) => '$withdrawalRequests/$id';

  static const projectConfirmations = 'project_confirmations';
  static String projectConfirmationDoc(String id) => '$projectConfirmations/$id';

  static const projectCancelRequests = 'project_cancel_requests';
  static String projectCancelRequestDoc(String id) => '$projectCancelRequests/$id';

  static const messages = 'messages';
  static String messageDoc(String id) => '$messages/$id';

  static const cardPaymentConfirmations = 'card_payment_confirmations';
  static String cardPaymentConfirmationDoc(String id) => '$cardPaymentConfirmations/$id';

  static const savedCards = 'saved_cards';
  static String userSavedCards(String userId) => '$savedCards/$userId/cards';
}

/// Payout / IBAN verification (engineers). Admin sets [approved] / [rejected] in Firestore.
abstract class PayoutVerificationStatus {
  static const none = 'none';
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
}

/// Engineer account visibility (admin). New self-registrations start [pending].
abstract class EngineerRegistrationStatus {
  static const pending = 'pending';
  static const active = 'active';
  static const rejected = 'rejected';
}

/// User document model for Firestore
class UserDocument {
  UserDocument({
    required this.uid,
    required this.phone,
    required this.name,
    required this.city,
    required this.userType,
    this.email,
    this.photoUrl,
    this.bio,
    this.membershipNumber,
    this.yearsExperience,
    this.specialization,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.isOnline = false,
    this.lastSeen,
    this.payoutBankId,
    this.payoutAccountName,
    this.payoutIban,
    this.payoutStatus,
    this.payoutAdminMessage,
    this.payoutSubmittedAt,
    this.blocked = false,
    this.suspendedUntil,
    this.blockedReason,
    this.engineerRegistrationStatus,
    this.engineerRegistrationNote,
  });

  final String uid;
  final String phone;
  final String name;
  final String city;
  final String userType;
  final String? email;
  final String? photoUrl;
  final String? bio;
  final String? membershipNumber;
  final String? yearsExperience;
  final String? specialization;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// Presence: user has app in foreground (best-effort).
  final bool isOnline;
  final DateTime? lastSeen;

  /// Engineer payout: bank id from [saudiBanks] list.
  final String? payoutBankId;
  final String? payoutAccountName;
  /// Normalized IBAN (no spaces), e.g. SA...
  final String? payoutIban;
  /// [PayoutVerificationStatus] or null/none.
  final String? payoutStatus;
  /// Admin rejection reason (or notes).
  final String? payoutAdminMessage;
  final DateTime? payoutSubmittedAt;

  /// Permanent block (admin). User cannot sign in / use the app until cleared.
  final bool blocked;

  /// Temporary suspension end time (admin). Access denied while [DateTime.now] is before this.
  final DateTime? suspendedUntil;

  /// Optional note shown to admin / logged for block or suspension.
  final String? blockedReason;

  /// [EngineerRegistrationStatus] for [userType] == `engineer`. Null/empty = legacy (treated as active).
  final String? engineerRegistrationStatus;

  /// Admin rejection note when [engineerRegistrationStatus] == [EngineerRegistrationStatus.rejected].
  final String? engineerRegistrationNote;

  /// User cannot use the app (blocked or still within suspension window).
  bool get isAccessRestricted {
    if (blocked) return true;
    final until = suspendedUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  /// Engineers may use engineer features only when active (or legacy doc without status).
  bool get isEngineerRegistrationApproved {
    if (userType != 'engineer') return true;
    final s = engineerRegistrationStatus;
    if (s == null || s.isEmpty) return true;
    return s == EngineerRegistrationStatus.active;
  }

  bool get isEngineerRegistrationRejected =>
      userType == 'engineer' && engineerRegistrationStatus == EngineerRegistrationStatus.rejected;

  /// Listed in client “browse engineers” when approved (or legacy).
  bool get isVisibleAsEngineerInBrowse {
    if (userType != 'engineer') return false;
    final s = engineerRegistrationStatus;
    if (s == null || s.isEmpty) return true;
    return s == EngineerRegistrationStatus.active;
  }

  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDocument(
      uid: doc.id,
      phone: data['phone'] as String? ?? '',
      name: data['name'] as String? ?? '',
      city: data['city'] as String? ?? '',
      userType: data['userType'] as String? ?? 'user',
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      membershipNumber: data['membershipNumber'] as String?,
      yearsExperience: data['yearsExperience'] as String?,
      specialization: data['specialization'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      payoutBankId: data['payoutBankId'] as String?,
      payoutAccountName: data['payoutAccountName'] as String?,
      payoutIban: data['payoutIban'] as String?,
      payoutStatus: data['payoutStatus'] as String?,
      payoutAdminMessage: data['payoutAdminMessage'] as String?,
      payoutSubmittedAt: (data['payoutSubmittedAt'] as Timestamp?)?.toDate(),
      blocked: data['blocked'] as bool? ?? false,
      suspendedUntil: (data['suspendedUntil'] as Timestamp?)?.toDate(),
      blockedReason: data['blockedReason'] as String?,
      engineerRegistrationStatus: data['engineerRegistrationStatus'] as String?,
      engineerRegistrationNote: data['engineerRegistrationNote'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final now = FieldValue.serverTimestamp();
    final map = <String, dynamic>{
      'uid': uid,
      'phone': phone,
      'name': name,
      'city': city,
      'userType': userType,
      'updatedAt': now,
      if (createdAt == null) 'createdAt': now,
    };

    // With SetOptions(merge: true), encoding `null` as a field value removes that key in Firestore.
    // Only write optional fields when we have a value, or use FieldValue.delete() to clear purposely.

    if (email != null && email!.isNotEmpty) {
      map['email'] = email;
    } else {
      map['email'] = FieldValue.delete();
    }

    // photoUrl: null means "do not change" (e.g. admin save before prev loaded); empty = remove photo
    if (photoUrl != null) {
      map['photoUrl'] = photoUrl!.isEmpty ? FieldValue.delete() : photoUrl;
    }

    void putOptionalClearableString(String key, String? value) {
      if (value == null || value.isEmpty) {
        map[key] = FieldValue.delete();
      } else {
        map[key] = value;
      }
    }

    putOptionalClearableString('bio', bio);
    putOptionalClearableString('membershipNumber', membershipNumber);
    putOptionalClearableString('yearsExperience', yearsExperience);
    putOptionalClearableString('specialization', specialization);

    if (fcmToken != null && fcmToken!.isNotEmpty) {
      map['fcmToken'] = fcmToken;
    }

    if (payoutBankId != null) map['payoutBankId'] = payoutBankId;
    if (payoutAccountName != null) map['payoutAccountName'] = payoutAccountName;
    if (payoutIban != null) map['payoutIban'] = payoutIban;
    if (payoutStatus != null) map['payoutStatus'] = payoutStatus;
    if (payoutAdminMessage != null) map['payoutAdminMessage'] = payoutAdminMessage;
    if (payoutSubmittedAt != null) map['payoutSubmittedAt'] = Timestamp.fromDate(payoutSubmittedAt!);
    map['blocked'] = blocked;
    if (suspendedUntil != null) {
      map['suspendedUntil'] = Timestamp.fromDate(suspendedUntil!);
    }
    if (blockedReason != null) map['blockedReason'] = blockedReason;
    if (engineerRegistrationStatus != null) {
      map['engineerRegistrationStatus'] = engineerRegistrationStatus;
    }
    if (engineerRegistrationNote != null) {
      map['engineerRegistrationNote'] = engineerRegistrationNote;
    }
    return map;
  }
}

/// Firestore service for user data
class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrUpdateUser(UserDocument user) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(user.uid)).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserDocument?> getUser(String uid) async {
    try {
      final doc = await _firestore.doc(FirestorePaths.userDoc(uid)).get();
      if (doc.exists) {
        return UserDocument.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Real-time user doc (for presence: isOnline, lastSeen).
  Stream<UserDocument?> streamUser(String uid) {
    return _firestore.doc(FirestorePaths.userDoc(uid)).snapshots().map(
          (s) => s.exists ? UserDocument.fromFirestore(s) : null,
        );
  }

  /// Update online / last seen (merge; does not overwrite profile fields).
  Future<void> updateUserPresence(String uid, {required bool isOnline}) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).set(
        {
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('updateUserPresence: $e');
    }
  }

  /// Engineer submits / updates bank details for payouts. Sets status to [pending] for admin review.
  Future<void> submitEngineerPayoutDetails({
    required String uid,
    required String bankId,
    required String accountName,
    required String iban,
  }) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).set(
        {
          'payoutBankId': bankId,
          'payoutAccountName': accountName,
          'payoutIban': iban,
          'payoutStatus': PayoutVerificationStatus.pending,
          'payoutSubmittedAt': FieldValue.serverTimestamp(),
          'payoutAdminMessage': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: live list of users with [userType] (`user` or `engineer`).
  Stream<List<UserDocument>> streamUsersByUserType(String userType) {
    return _firestore
        .collection(FirestorePaths.users)
        .where('userType', isEqualTo: userType)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(UserDocument.fromFirestore).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// UIDs with role `user` or `engineer` (excludes `admin`). For broadcast announcements.
  Future<List<String>> getClientAndEngineerUserUids() async {
    try {
      final usersSnap =
          await _firestore.collection(FirestorePaths.users).where('userType', isEqualTo: 'user').get();
      final engSnap =
          await _firestore.collection(FirestorePaths.users).where('userType', isEqualTo: 'engineer').get();
      final set = <String>{};
      for (final d in usersSnap.docs) {
        set.add(d.id);
      }
      for (final d in engSnap.docs) {
        set.add(d.id);
      }
      return set.toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: same notification content for many users (batched writes). Returns number of docs written.
  Future<int> adminBroadcastNotifications({
    required List<String> userIds,
    required String title,
    required String body,
  }) async {
    final ids = userIds.where((u) => u.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return 0;
    const chunk = 450;
    var total = 0;
    for (var i = 0; i < ids.length; i += chunk) {
      final end = i + chunk < ids.length ? i + chunk : ids.length;
      final slice = ids.sublist(i, end);
      final batch = _firestore.batch();
      for (final uid in slice) {
        final ref = _firestore.collection(FirestorePaths.notifications).doc();
        batch.set(ref, {
          'userId': uid,
          'title': title,
          'body': body,
          'type': 'admin_announcement',
          'data': <String, dynamic>{},
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        total++;
      }
      await batch.commit();
    }
    return total;
  }

  /// Admin: create or update a user profile (document id must match Firebase Auth uid when they log in).
  Future<void> adminMergeUserProfile(UserDocument user) async {
    await _firestore.doc(FirestorePaths.userDoc(user.uid)).set(
          user.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Admin: block, suspend until a date, and optional reason (merge).
  Future<void> adminSetUserAccessRestriction({
    required String targetUid,
    required bool blocked,
    DateTime? suspendedUntil,
    String? blockedReason,
  }) async {
    final data = <String, dynamic>{
      'blocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (suspendedUntil != null) {
      data['suspendedUntil'] = Timestamp.fromDate(suspendedUntil);
    } else {
      data['suspendedUntil'] = FieldValue.delete();
    }
    if (blockedReason != null && blockedReason.trim().isNotEmpty) {
      data['blockedReason'] = blockedReason.trim();
    } else {
      data['blockedReason'] = FieldValue.delete();
    }
    await _firestore.doc(FirestorePaths.userDoc(targetUid)).set(
          data,
          SetOptions(merge: true),
        );
  }

  /// Admin: remove user document only (Auth account remains).
  Future<void> adminDeleteUserDocument(String targetUid) async {
    await _firestore.doc(FirestorePaths.userDoc(targetUid)).delete();
  }

  /// Admin: strip engineer-only profile fields (e.g. after changing user type to client).
  Future<void> adminClearEngineerOnlyFields(String targetUid) async {
    await _firestore.doc(FirestorePaths.userDoc(targetUid)).set(
      {
        'membershipNumber': FieldValue.delete(),
        'yearsExperience': FieldValue.delete(),
        'specialization': FieldValue.delete(),
        'bio': FieldValue.delete(),
        'engineerRegistrationStatus': FieldValue.delete(),
        'engineerRegistrationNote': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Admin: remove optional rejection note from engineer profile.
  Future<void> adminClearEngineerRegistrationNote(String targetUid) async {
    await _firestore.doc(FirestorePaths.userDoc(targetUid)).set(
      {
        'engineerRegistrationNote': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Client profile: remove engineer registration fields when user becomes a client.
  Future<void> clearUserEngineerRegistrationFields(String uid) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set(
      {
        'engineerRegistrationStatus': FieldValue.delete(),
        'engineerRegistrationNote': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Get engineers for browse
  Future<List<UserDocument>> getEngineers() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .where('userType', isEqualTo: 'engineer')
          .get();
      return snapshot.docs.map((d) => UserDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get engineer min offer price (starting from) - from their offers
  Future<double?> getEngineerMinOfferPrice(String engineerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.offers)
          .where('engineerId', isEqualTo: engineerId)
          .limit(50)
          .get();
      double? minPrice;
      for (final doc in snapshot.docs) {
        final offer = OfferDocument.fromFirestore(doc);
        final amt = offer.parsedAmount;
        if (amt != null && (minPrice == null || amt < minPrice)) {
          minPrice = amt;
        }
      }
      return minPrice;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateFcmToken(String uid, String? token) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new project (optionally with invitedEngineerId for private invitations)
  Future<String> createProject(ProjectDocument project) async {
    try {
      final ref = _firestore.collection(FirestorePaths.projects).doc();
      final doc = ProjectDocument(
        id: ref.id,
        userId: project.userId,
        projectType: project.projectType,
        landArea: project.landArea,
        city: project.city,
        description: project.description,
        imageUrls: project.imageUrls,
        status: project.status,
        budget: project.budget,
        deliveryDuration: project.deliveryDuration,
        invitedEngineerId: project.invitedEngineerId,
        listed: project.listed,
      );
      await ref.set(doc.toFirestore());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update project image URLs
  Future<void> updateProjectImages(String projectId, List<String> imageUrls) async {
    try {
      await _firestore.doc(FirestorePaths.projectDoc(projectId)).update({
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update project file attachments
  Future<void> updateProjectFiles(String projectId, List<Map<String, dynamic>> fileAttachments) async {
    try {
      await _firestore.doc(FirestorePaths.projectDoc(projectId)).update({
        'fileAttachments': fileAttachments,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get projects where engineer was invited (private invitation, not yet accepted)
  Future<List<ProjectDocument>> getEngineerInvitedProjects(String engineerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.projects)
          .where('invitedEngineerId', isEqualTo: engineerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((d) => ProjectDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get projects where engineer has accepted offer (engineer's worked-on projects)
  Future<List<ProjectDocument>> getEngineerProjects(String engineerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.projects)
          .where('acceptedEngineerId', isEqualTo: engineerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((d) => ProjectDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Engineer project stats: in progress, completed, on-time %, cancelled %
  Future<EngineerProjectStats> getEngineerProjectStats(String engineerId) async {
    try {
      final projects = await getEngineerProjects(engineerId);
      var inProgress = 0;
      var completed = 0;
      var completedOnTime = 0;
      var cancelled = 0;
      for (final p in projects) {
        if (p.status == 'in_progress' || p.status == 'delivered') {
          inProgress++;
        } else if (p.status == 'completed') {
          completed++;
          if (p.expectedCompletionAt != null &&
              p.deliveredAt != null &&
              !p.deliveredAt!.isAfter(p.expectedCompletionAt!)) {
            completedOnTime++;
          }
        } else if (p.status == 'cancelled') {
          cancelled++;
        }
      }
      final total = completed + cancelled;
      final onTimePercent = completed > 0 ? (completedOnTime / completed) * 100 : 0.0;
      final cancelledPercent = total > 0 ? (cancelled / total) * 100 : 0.0;
      return EngineerProjectStats(
        inProgress: inProgress,
        completed: completed,
        completedOnTimePercent: onTimePercent,
        cancelledPercent: cancelledPercent,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get project where client has chat with this engineer (invited or accepted)
  Future<ProjectDocument?> getChatProjectWithEngineer(
      String clientUserId, String engineerId) async {
    try {
      final projects = await getUserProjects(clientUserId);
      for (final p in projects) {
        if (p.acceptedEngineerId == engineerId || p.invitedEngineerId == engineerId) {
          return p;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static const _activeChatStatuses = ['new', 'in_progress', 'delivered'];

  /// Get projects where user has active chat (accepted offer, or invited - client or engineer).
  /// Excludes cancelled and completed projects - chat is closed for those.
  Future<List<ProjectDocument>> getChatProjects(String userId) async {
    try {
      final clientProjects = await getUserProjects(userId);
      final engineerProjects = await getEngineerProjects(userId);
      final engineerInvitedProjects = await getEngineerInvitedProjects(userId);
      final chatProjects = clientProjects
          .where((p) =>
              (p.acceptedEngineerId != null || p.invitedEngineerId != null) &&
              _activeChatStatuses.contains(p.status))
          .toList();
      final seen = chatProjects.map((p) => p.id).toSet();
      for (final p in engineerProjects) {
        if (!seen.contains(p.id) && _activeChatStatuses.contains(p.status)) {
          chatProjects.add(p);
        }
      }
      for (final p in engineerInvitedProjects) {
        if (!p.listed) continue;
        if (!seen.contains(p.id) && _activeChatStatuses.contains(p.status)) {
          chatProjects.add(p);
        }
      }
      chatProjects.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return chatProjects;
    } catch (_) {
      return [];
    }
  }

  /// Whether [viewerId] may send messages and should see this project's chats in active lists.
  /// Matches [getChatProjects]: active status (new / in_progress / delivered), not completed/cancelled;
  /// owner needs an engineer (invited or accepted); invited engineer only if [ProjectDocument.listed].
  bool isProjectChatOpenForUser(ProjectDocument p, String viewerId) {
    if (!_activeChatStatuses.contains(p.status)) return false;

    final isOwner = p.userId == viewerId;
    final isAcceptedEng =
        p.acceptedEngineerId != null && p.acceptedEngineerId!.isNotEmpty && p.acceptedEngineerId == viewerId;
    final isInvitedEng =
        p.invitedEngineerId != null && p.invitedEngineerId!.isNotEmpty && p.invitedEngineerId == viewerId;

    if (isOwner) {
      final hasEngineer = (p.acceptedEngineerId != null && p.acceptedEngineerId!.isNotEmpty) ||
          (p.invitedEngineerId != null && p.invitedEngineerId!.isNotEmpty);
      return hasEngineer;
    }
    if (isAcceptedEng) return true;
    if (isInvitedEng) return p.listed;
    return false;
  }

  /// Real-time project doc (for chat gate when status/listing changes).
  Stream<ProjectDocument?> streamProjectDocument(String projectId) {
    return _firestore.doc(FirestorePaths.projectDoc(projectId)).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ProjectDocument.fromFirestore(snap);
    });
  }

  /// Get last message for a project
  Future<MessageDocument?> getLastMessage(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.messages)
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .limit(40)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return MessageDocument.fromFirestore(snapshot.docs.first);
    } catch (_) {
      return null;
    }
  }

  /// Get unread count for a project (messages for this user). Zero if chat is closed for this user.
  Future<int> getProjectUnreadCount(String projectId, String userId) async {
    try {
      final project = await getProject(projectId);
      if (project == null || !isProjectChatOpenForUser(project, userId)) return 0;
      final snapshot = await _firestore
          .collection(FirestorePaths.messages)
          .where('projectId', isEqualTo: projectId)
          .where('receiverId', isEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Get projects for a user (their own - as client)
  Future<List<ProjectDocument>> getUserProjects(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.projects)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((d) => ProjectDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Client-owned projects that can receive a private invite to [forEngineerId].
  Future<List<ProjectDocument>> getUserProjectsEligibleForPrivateInvite(
    String clientUserId, {
    required String forEngineerId,
  }) async {
    final all = await getUserProjects(clientUserId);
    return all.where((p) => p.isEligibleForPrivateInviteToEngineer(forEngineerId)).toList();
  }

  /// Set [invitedEngineerId] on an existing project (owner only). Does not send notifications.
  Future<void> clientInviteEngineerToExistingProject({
    required String clientUserId,
    required String projectId,
    required String engineerId,
  }) async {
    final p = await getProject(projectId);
    if (p == null || p.userId != clientUserId) {
      throw const ClientInviteProjectException('forbidden');
    }
    if (!p.isEligibleForPrivateInviteToEngineer(engineerId)) {
      throw const ClientInviteProjectException('not_eligible');
    }
    await _firestore.doc(FirestorePaths.projectDoc(projectId)).update({
      'invitedEngineerId': engineerId,
      'listed': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: stream projects (newest activity first, client-side sort).
  Stream<List<ProjectDocument>> streamProjectsForAdmin({int limit = 200}) {
    return _firestore
        .collection(FirestorePaths.projects)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ProjectDocument.fromFirestore).toList();
      list.sort((a, b) {
        final tb = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final ta = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// Admin: merge-write full project document (document id must match [project.id]).
  Future<void> adminMergeProject(ProjectDocument project) async {
    await _firestore.doc(FirestorePaths.projectDoc(project.id)).set(
          project.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Admin: create project for a client ([template.id] ignored; new id generated).
  Future<String> adminCreateProject(ProjectDocument template) async {
    final ref = _firestore.collection(FirestorePaths.projects).doc();
    final doc = ProjectDocument(
      id: ref.id,
      userId: template.userId,
      projectType: template.projectType,
      landArea: template.landArea,
      city: template.city,
      description: template.description,
      imageUrls: template.imageUrls,
      fileAttachments: template.fileAttachments,
      status: template.status,
      budget: template.budget,
      deliveryDuration: template.deliveryDuration,
      paidAmount: template.paidAmount,
      acceptedEngineerId: template.acceptedEngineerId,
      acceptedOfferId: template.acceptedOfferId,
      invitedEngineerId: template.invitedEngineerId,
      expectedCompletionAt: template.expectedCompletionAt,
      deliveredAt: template.deliveredAt,
      listed: template.listed,
    );
    await ref.set(doc.toFirestore());
    return ref.id;
  }

  /// Admin: delete project document.
  Future<void> adminDeleteProject(String projectId) async {
    await _firestore.doc(FirestorePaths.projectDoc(projectId)).delete();
  }

  /// Get all projects (for Engineer browse) - optionally filter client-side
  Future<List<ProjectDocument>> getAllProjects({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.projects)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => ProjectDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update project status
  Future<void> updateProjectStatus(String projectId, String status) async {
    try {
      await _firestore.doc(FirestorePaths.projectDoc(projectId)).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Show or hide project from engineer browse (owner only; [listed] true = visible).
  Future<void> updateProjectListed(String projectId, bool listed) async {
    try {
      await _firestore.doc(FirestorePaths.projectDoc(projectId)).update({
        'listed': listed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get accepted offer for a project (if any)
  Future<OfferDocument?> getAcceptedOfferForProject(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.offers)
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return OfferDocument.fromFirestore(snapshot.docs.first);
    } catch (e) {
      rethrow;
    }
  }

  /// Get completed project IDs where client worked with this engineer
  Future<List<String>> getCompletedProjectIdsWithEngineer(
      String clientUserId, String engineerId) async {
    try {
      final offersSnap = await _firestore
          .collection(FirestorePaths.offers)
          .where('engineerId', isEqualTo: engineerId)
          .where('status', isEqualTo: 'accepted')
          .get();
      final projectIds = <String>[];
      for (final doc in offersSnap.docs) {
        final offer = OfferDocument.fromFirestore(doc);
        final project = await getProject(offer.projectId);
        if (project != null &&
            project.userId == clientUserId &&
            project.status == 'completed') {
          projectIds.add(project.id);
        }
      }
      return projectIds;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user already reviewed this engineer for this project
  Future<bool> hasUserReviewedEngineerForProject(
      String reviewerId, String engineerId, String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.reviews)
          .where('engineerId', isEqualTo: engineerId)
          .where('reviewerId', isEqualTo: reviewerId)
          .where('projectId', isEqualTo: projectId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }

  /// Get project by id
  Future<ProjectDocument?> getProject(String projectId) async {
    try {
      final doc = await _firestore.doc(FirestorePaths.projectDoc(projectId)).get();
      if (doc.exists) return ProjectDocument.fromFirestore(doc);
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Create offer (engineer submits bid)
  Future<String> createOffer(OfferDocument offer) async {
    try {
      final ref = _firestore.collection(FirestorePaths.offers).doc();
      final doc = OfferDocument(
        id: ref.id,
        projectId: offer.projectId,
        engineerId: offer.engineerId,
        message: offer.message,
        proposedPrice: offer.proposedPrice,
        proposedDuration: offer.proposedDuration,
        imageUrls: offer.imageUrls,
        fileAttachments: offer.fileAttachments,
        status: 'pending',
        engineerName: offer.engineerName,
        engineerPhotoUrl: offer.engineerPhotoUrl,
      );
      await ref.set(doc.toFirestore());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get offers for a project (for client)
  Future<List<OfferDocument>> getProjectOffers(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.offers)
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((d) => OfferDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get offer count for a project
  Future<int> getProjectOfferCount(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.offers)
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if engineer already submitted offer for project
  Future<bool> hasEngineerOffered(String projectId, String engineerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.offers)
          .where('projectId', isEqualTo: projectId)
          .where('engineerId', isEqualTo: engineerId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }

  /// Update offer status (accept/reject)
  Future<void> updateOfferStatus(String offerId, String status) async {
    try {
      await _firestore.doc(FirestorePaths.offerDoc(offerId)).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get offer by id
  Future<OfferDocument?> getOffer(String offerId) async {
    try {
      final doc = await _firestore.doc(FirestorePaths.offerDoc(offerId)).get();
      if (doc.exists) return OfferDocument.fromFirestore(doc);
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Create notification
  Future<String> createNotification(NotificationDocument notification) async {
    try {
      final ref = _firestore.collection(FirestorePaths.notifications).doc();
      final doc = NotificationDocument(
        id: ref.id,
        userId: notification.userId,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        data: notification.data,
        read: false,
      );
      await ref.set(doc.toFirestore());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user notifications
  Future<List<NotificationDocument>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.notifications)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => NotificationDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread notification count for user
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.notifications)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream unread notification count for user (real-time updates)
  Stream<int> streamUnreadNotificationCount(String userId) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _firestore.doc(FirestorePaths.notificationDoc(notificationId)).update({'read': true});
    } catch (e) {
      rethrow;
    }
  }

  /// Create review
  Future<String> createReview(ReviewDocument review) async {
    try {
      final ref = _firestore.collection(FirestorePaths.reviews).doc();
      final doc = ReviewDocument(
        id: ref.id,
        engineerId: review.engineerId,
        reviewerId: review.reviewerId,
        rating: review.rating,
        comment: review.comment,
        projectId: review.projectId,
        reviewerName: review.reviewerName,
      );
      await ref.set(doc.toFirestore());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update engineer's answer to a review (engineer only)
  Future<void> updateReviewAnswer(String reviewId, String answer) async {
    await _firestore.collection(FirestorePaths.reviews).doc(reviewId).update({
      'engineerAnswer': answer,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get engineer reviews
  Future<List<ReviewDocument>> getEngineerReviews(String engineerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.reviews)
          .where('engineerId', isEqualTo: engineerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((d) => ReviewDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get engineer average rating
  Future<double> getEngineerAverageRating(String engineerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.reviews)
          .where('engineerId', isEqualTo: engineerId)
          .get();
      if (snapshot.docs.isEmpty) return 0;
      final sum = snapshot.docs.fold<int>(
        0,
        (s, d) => s + ((d.data()['rating'] as int?) ?? 0),
      );
      return sum / snapshot.docs.length;
    } catch (e) {
      rethrow;
    }
  }

  /// Create portfolio item
  Future<String> createPortfolioItem(PortfolioItem item) async {
    try {
      final ref = _firestore.collection(FirestorePaths.portfolioItems).doc();
      final doc = PortfolioItem(
        id: ref.id,
        engineerId: item.engineerId,
        title: item.title,
        description: item.description,
        imageUrls: item.imageUrls,
        fileUrls: item.fileUrls,
        executionDate: item.executionDate,
        projectType: item.projectType,
        location: item.location,
      );
      await ref.set(doc.toFirestore());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update portfolio item images
  Future<void> updatePortfolioItemImages(String itemId, List<String> imageUrls) async {
    try {
      await _firestore.doc(FirestorePaths.portfolioItemDoc(itemId)).update({
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get engineer portfolio items
  Future<List<PortfolioItem>> getEngineerPortfolio(String engineerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.portfolioItems)
          .where('engineerId', isEqualTo: engineerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((d) => PortfolioItem.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get portfolio item by id (for public view)
  Future<PortfolioItem?> getPortfolioItem(String itemId) async {
    try {
      final doc = await _firestore.doc(FirestorePaths.portfolioItemDoc(itemId)).get();
      if (doc.exists) return PortfolioItem.fromFirestore(doc);
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Wallet ─────────────────────────────────────────────────────────────

  /// Get or create wallet for user
  Future<WalletDocument> getOrCreateWallet(String userId) async {
    try {
      final ref = _firestore.doc(FirestorePaths.walletDoc(userId));
      final doc = await ref.get();
      if (doc.exists) {
        return WalletDocument.fromFirestore(doc);
      }
      final wallet = WalletDocument(id: userId, userId: userId);
      await ref.set(wallet.toFirestore());
      return wallet;
    } catch (e) {
      rethrow;
    }
  }

  /// Get wallet
  Future<WalletDocument?> getWallet(String userId) async {
    try {
      final doc = await _firestore.doc(FirestorePaths.walletDoc(userId)).get();
      if (doc.exists) return WalletDocument.fromFirestore(doc);
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: live list of all wallet documents.
  Stream<List<WalletDocument>> streamAllWallets() {
    return _firestore.collection(FirestorePaths.wallets).snapshots().map(
          (snap) => snap.docs.map(WalletDocument.fromFirestore).toList(),
        );
  }

  /// Deposit - add balance atomically
  Future<String> deposit(
    String userId,
    double amount, {
    String? description,
    Map<String, dynamic>? metadata,
    String transactionType = 'deposit',
  }) async {
    try {
      return await _firestore.runTransaction<String>((tx) async {
        final walletRef = _firestore.doc(FirestorePaths.walletDoc(userId));
        final walletSnap = await tx.get(walletRef);
        final currentBalance = walletSnap.exists
            ? (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        final newBalance = currentBalance + amount;

        if (!walletSnap.exists) {
          tx.set(walletRef, {
            'userId': userId,
            'balance': newBalance,
            'currency': 'SAR',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(walletRef, {
            'balance': newBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final txRef = _firestore.collection(FirestorePaths.transactions).doc();
        final txData = <String, dynamic>{
          'userId': userId,
          'type': transactionType,
          'amount': amount,
          'status': 'completed',
          'currency': 'SAR',
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        };
        if (description != null && description.isNotEmpty) {
          txData['description'] = description;
        }
        if (metadata != null && metadata.isNotEmpty) {
          txData['metadata'] = metadata;
        }
        tx.set(txRef, txData);
        return txRef.id;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Admin panel: add balance and log as [admin_credit].
  Future<String> adminCreditWallet(
    String userId,
    double amount, {
    String? note,
    String? adminUserId,
  }) async {
    if (amount <= 0) throw Exception('invalid_amount');
    final metadata = <String, dynamic>{
      if (adminUserId != null && adminUserId.isNotEmpty) 'adminUserId': adminUserId,
    };
    return deposit(
      userId,
      amount,
      description: note,
      metadata: metadata.isEmpty ? null : metadata,
      transactionType: 'admin_credit',
    );
  }

  /// Admin panel: remove balance and log as [admin_debit]. Fails if insufficient funds or no wallet.
  Future<String> adminDebitWallet(
    String userId,
    double amount, {
    String? note,
    String? adminUserId,
  }) async {
    if (amount <= 0) throw Exception('invalid_amount');
    try {
      return await _firestore.runTransaction<String>((tx) async {
        final walletRef = _firestore.doc(FirestorePaths.walletDoc(userId));
        final walletSnap = await tx.get(walletRef);
        if (!walletSnap.exists) {
          throw Exception('wallet_not_found');
        }
        final currentBalance =
            (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        if (currentBalance < amount) {
          throw Exception('insufficient_balance');
        }
        final newBalance = currentBalance - amount;
        tx.update(walletRef, {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final txRef = _firestore.collection(FirestorePaths.transactions).doc();
        final metadata = <String, dynamic>{
          if (adminUserId != null && adminUserId.isNotEmpty) 'adminUserId': adminUserId,
        };
        final txData = <String, dynamic>{
          'userId': userId,
          'type': 'admin_debit',
          'amount': amount,
          'status': 'completed',
          'currency': 'SAR',
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        };
        if (note != null && note.isNotEmpty) {
          txData['description'] = note;
        }
        if (metadata.isNotEmpty) {
          txData['metadata'] = metadata;
        }
        tx.set(txRef, txData);
        return txRef.id;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: remove wallet document only when balance is exactly zero.
  Future<void> adminDeleteEmptyWallet(String userId) async {
    await _firestore.runTransaction((tx) async {
      final walletRef = _firestore.doc(FirestorePaths.walletDoc(userId));
      final walletSnap = await tx.get(walletRef);
      if (!walletSnap.exists) return;
      final currentBalance =
          (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      if (currentBalance != 0) {
        throw Exception('wallet_not_empty');
      }
      tx.delete(walletRef);
    });
  }

  /// Withdrawal amount must be **strictly greater** than this value (SAR).
  static const double withdrawalMinExclusiveSar = 100.0;

  /// Engineer withdrawal: reserves balance, creates admin review doc + pending transaction.
  /// Admin sets `withdrawal_requests.status` to `transferred` or `rejected` (+ optional `adminMessage`).
  Future<String> createWithdrawalRequest(
    String userId,
    double amount, {
    String? bankAccount,
    String? description,
  }) async {
    try {
      final profile = await getUser(userId);
      if (profile == null || profile.userType != 'engineer') {
        throw Exception('withdraw_engineers_only');
      }
      final ibanOk = profile.payoutIban != null && profile.payoutIban!.trim().isNotEmpty;
      if (profile.payoutStatus != PayoutVerificationStatus.approved || !ibanOk) {
        throw Exception('withdraw_iban_not_approved');
      }
      if (amount <= withdrawalMinExclusiveSar) {
        throw Exception('withdraw_min_amount');
      }

      final wrRef = _firestore.collection(FirestorePaths.withdrawalRequests).doc();
      final wrId = wrRef.id;
      final txnRef = _firestore.collection(FirestorePaths.transactions).doc();
      final txnId = txnRef.id;

      return await _firestore.runTransaction<String>((tx) async {
        final walletRef = _firestore.doc(FirestorePaths.walletDoc(userId));
        final walletSnap = await tx.get(walletRef);
        final currentBalance = walletSnap.exists
            ? (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0
            : 0.0;

        if (currentBalance < amount) {
          throw Exception('insufficient_balance');
        }

        if (!walletSnap.exists) {
          throw Exception('insufficient_balance');
        }

        tx.update(walletRef, {
          'balance': currentBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(txnRef, {
          'userId': userId,
          'type': 'withdraw',
          'amount': amount,
          'status': 'pending',
          'currency': 'SAR',
          'description': description,
          'referenceId': wrId,
          'referenceType': 'withdrawal_request',
          'metadata': bankAccount != null && bankAccount.isNotEmpty
              ? {'bankNote': bankAccount}
              : null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(wrRef, {
          'userId': userId,
          'amount': amount,
          'currency': 'SAR',
          'status': 'pending',
          'bankAccount': bankAccount,
          'linkedTransactionId': txnId,
          'adminMessage': null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return wrId;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Stream engineer withdrawal requests (for status: pending / transferred / rejected).
  Stream<List<Map<String, dynamic>>> streamWithdrawalRequests(String userId) {
    return _firestore
        .collection(FirestorePaths.withdrawalRequests)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              return <String, dynamic>{...m, 'id': d.id};
            }).toList());
  }

  // --- Admin: withdrawals & engineer bank (IBAN) verification ---
  /// Admin: all withdrawal requests (newest first).
  Stream<List<WithdrawalRequestRow>> streamWithdrawalRequestsForAdmin({int limit = 100}) {
    return _firestore
        .collection(FirestorePaths.withdrawalRequests)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(WithdrawalRequestRow.fromFirestore).toList());
  }

  /// Admin badge: count of requests still `pending`.
  Stream<int> streamPendingWithdrawalRequestCount() {
    return _firestore
        .collection(FirestorePaths.withdrawalRequests)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Engineers waiting for bank / IBAN verification.
  Stream<List<UserDocument>> streamEngineersPendingPayoutVerification() {
    return _firestore
        .collection(FirestorePaths.users)
        .where('userType', isEqualTo: 'engineer')
        .where('payoutStatus', isEqualTo: PayoutVerificationStatus.pending)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(UserDocument.fromFirestore).toList();
      list.sort((a, b) => (b.payoutSubmittedAt ?? b.createdAt ?? DateTime(0))
          .compareTo(a.payoutSubmittedAt ?? a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Stream<int> streamPendingPayoutVerificationCount() {
    return _firestore
        .collection(FirestorePaths.users)
        .where('userType', isEqualTo: 'engineer')
        .where('payoutStatus', isEqualTo: PayoutVerificationStatus.pending)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Engineers with [engineerRegistrationStatus] == pending (awaiting admin activation).
  Stream<int> streamPendingEngineerRegistrationCount() {
    return _firestore
        .collection(FirestorePaths.users)
        .where('userType', isEqualTo: 'engineer')
        .where('engineerRegistrationStatus', isEqualTo: EngineerRegistrationStatus.pending)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Engineers with payout already [approved] or [rejected] (newest activity first, client-sorted).
  Stream<List<UserDocument>> streamEngineersPayoutVerificationHistory({int limit = 120}) {
    return _firestore
        .collection(FirestorePaths.users)
        .where('userType', isEqualTo: 'engineer')
        .where('payoutStatus', whereIn: [
          PayoutVerificationStatus.approved,
          PayoutVerificationStatus.rejected,
        ])
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(UserDocument.fromFirestore).toList();
      list.sort((a, b) {
        final tb = b.updatedAt ?? b.payoutSubmittedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final ta = a.updatedAt ?? a.payoutSubmittedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// Admin approves or rejects engineer payout bank details.
  Future<void> adminSetPayoutVerification({
    required String engineerUid,
    required bool approved,
    String? adminMessage,
  }) async {
    try {
      final updates = <String, dynamic>{
        'payoutStatus': approved ? PayoutVerificationStatus.approved : PayoutVerificationStatus.rejected,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (adminMessage != null && adminMessage.trim().isNotEmpty) {
        updates['payoutAdminMessage'] = adminMessage.trim();
      } else if (approved) {
        updates['payoutAdminMessage'] = FieldValue.delete();
      }
      await _firestore.doc(FirestorePaths.userDoc(engineerUid)).set(updates, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Admin marks withdrawal as bank-transferred or rejects (reject triggers Cloud Function refund).
  Future<void> adminSetWithdrawalOutcome({
    required String requestId,
    required bool markTransferred,
    String? adminMessage,
  }) async {
    final wrRef = _firestore.doc(FirestorePaths.withdrawalRequestDoc(requestId));
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(wrRef);
        if (!snap.exists) {
          throw Exception('withdrawal_not_found');
        }
        final m = snap.data()!;
        if (m['status'] != 'pending') {
          throw Exception('withdrawal_already_processed');
        }
        final linkedId = m['linkedTransactionId'] as String?;
        final newStatus = markTransferred ? 'transferred' : 'rejected';
        tx.update(wrRef, {
          'status': newStatus,
          'adminMessage': adminMessage,
          'updatedAt': FieldValue.serverTimestamp(),
          'processedAt': FieldValue.serverTimestamp(),
        });
        if (markTransferred && linkedId != null && linkedId.isNotEmpty) {
          final tRef = _firestore.doc(FirestorePaths.transactionDoc(linkedId));
          final tSnap = await tx.get(tRef);
          if (tSnap.exists) {
            final td = tSnap.data()!;
            if (td['type'] == 'withdraw' && td['status'] == 'pending') {
              tx.update(tRef, {
                'status': 'completed',
                'completedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Admin-only: correct **already processed** withdrawal records (does not adjust wallet).
  /// Use normal approve/reject flows while status is `pending`.
  /// [status]: `transferred` or `rejected`, or null to leave unchanged.
  /// [adminMessage]: null = leave note as-is; empty string = remove note; else set text.
  Future<void> adminPatchWithdrawalRequestRecord({
    required String requestId,
    String? status,
    String? adminMessage,
  }) async {
    final ref = _firestore.doc(FirestorePaths.withdrawalRequestDoc(requestId));
    final snap = await ref.get();
    if (!snap.exists) throw Exception('withdrawal_not_found');
    final cur = (snap.data()?['status'] as String?) ?? '';
    if (cur == 'pending') {
      throw Exception('withdrawal_use_standard_actions_for_pending');
    }
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status != null) {
      if (status != 'transferred' && status != 'rejected') {
        throw ArgumentError.value(status, 'status', 'must be transferred or rejected');
      }
      updates['status'] = status;
    }
    if (adminMessage != null) {
      updates['adminMessage'] =
          adminMessage.isEmpty ? FieldValue.delete() : adminMessage.trim();
    }
    if (updates.length == 1) return;
    await ref.update(updates);
  }

  /// Create payment request - Cloud Function will process the transfer to escrow
  Future<String> createPaymentRequest({
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? projectId,
    String? offerId,
    int? deliveryDurationDays,
  }) async {
    try {
      final ref = _firestore.collection(FirestorePaths.paymentRequests).doc();
      await ref.set({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'projectId': projectId,
        'offerId': offerId,
        'deliveryDurationDays': deliveryDurationDays ?? 30,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark project as delivered (engineer)
  Future<void> markProjectDelivered(String projectId) async {
    try {
      await _firestore.doc(FirestorePaths.projectDoc(projectId)).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Create project cancel request - initiator must provide cause
  Future<String> createProjectCancelRequest({
    required String projectId,
    required String initiatorId,
    required String causeId,
    String? causeText,
  }) async {
    try {
      final ref = _firestore.collection(FirestorePaths.projectCancelRequests).doc();
      await ref.set({
        'projectId': projectId,
        'initiatorId': initiatorId,
        'initiatorCauseId': causeId,
        'initiatorCauseText': causeText,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get active cancel request for project
  Future<Map<String, dynamic>?> getProjectCancelRequest(String projectId) async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.projectCancelRequests)
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first.data();
      d['id'] = snap.docs.first.id;
      return d;
    } catch (e) {
      rethrow;
    }
  }

  /// Respond to cancel request - other party adds their cause and agrees
  Future<void> respondToCancelRequest({
    required String requestId,
    required String causeId,
    String? causeText,
  }) async {
    try {
      await _firestore.doc(FirestorePaths.projectCancelRequestDoc(requestId)).update({
        'otherPartyCauseId': causeId,
        'otherPartyCauseText': causeText,
        'status': 'both_agreed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Create project confirmation (user confirms receipt) - triggers escrow release
  Future<String> confirmProjectReceipt(String projectId, String userId) async {
    try {
      final ref = _firestore.collection(FirestorePaths.projectConfirmations).doc();
      await ref.set({
        'projectId': projectId,
        'userId': userId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get project messages (chat)
  Future<List<MessageDocument>> getProjectMessages(String projectId, {int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.messages)
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => MessageDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Send chat message (text, image, or file)
  Future<String> sendMessage(
    String projectId,
    String senderId, {
    String text = '',
    String? receiverId,
    MessageType type = MessageType.text,
    List<String> imageUrls = const [],
    String? fileUrl,
    String? fileName,
    bool adminSupport = false,
    bool adminSender = false,
  }) async {
    try {
      final ref = _firestore.collection(FirestorePaths.messages).doc();
      await ref.set(MessageDocument(
        id: ref.id,
        projectId: projectId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        imageUrls: imageUrls,
        fileUrl: fileUrl,
        fileName: fileName,
        status: MessageStatus.sent,
        adminSupport: adminSupport,
        adminSender: adminSender,
      ).toFirestore());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProjectMessageText(String messageId, String newText) async {
    await _firestore.collection(FirestorePaths.messages).doc(messageId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProjectMessage(String messageId) async {
    await _firestore.collection(FirestorePaths.messages).doc(messageId).delete();
  }

  /// Mark incoming messages as delivered (recipient has synced chat; sender sees ✓✓).
  Future<void> markMessagesAsDelivered(String projectId, String recipientId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.messages)
          .where('projectId', isEqualTo: projectId)
          .where('receiverId', isEqualTo: recipientId)
          .where('status', isEqualTo: 'sent')
          .get();
      final batch = _firestore.batch();
      var n = 0;
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'delivered'});
        n++;
      }
      if (n > 0) await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark messages as read (recipient views chat). Updates both `sent` and `delivered`.
  Future<void> markMessagesAsRead(String projectId, String recipientId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.messages)
          .where('projectId', isEqualTo: projectId)
          .where('receiverId', isEqualTo: recipientId)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();
      final batch = _firestore.batch();
      var n = 0;
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'read'});
        n++;
      }
      if (n > 0) await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream unread message count for user (real-time). Excludes messages for closed/inactive projects.
  Stream<int> streamUnreadMessageCount(String userId) {
    return _firestore
        .collection(FirestorePaths.messages)
        .where('receiverId', isEqualTo: userId)
        .where('status', whereIn: ['sent', 'delivered'])
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return 0;
      final projectIds = snapshot.docs
          .map((d) => d.data()['projectId'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (projectIds.isEmpty) return 0;
      final projectById = <String, ProjectDocument>{};
      for (final id in projectIds) {
        final doc = await _firestore.doc(FirestorePaths.projectDoc(id)).get();
        if (doc.exists) {
          projectById[id] = ProjectDocument.fromFirestore(doc);
        }
      }
      var n = 0;
      for (final d in snapshot.docs) {
        final pid = d.data()['projectId'] as String?;
        if (pid == null || pid.isEmpty) continue;
        final p = projectById[pid];
        if (p == null || !isProjectChatOpenForUser(p, userId)) continue;
        n++;
      }
      return n;
    });
  }

  /// Stream project messages for real-time chat
  Stream<List<MessageDocument>> streamProjectMessages(String projectId) {
    return _firestore
        .collection(FirestorePaths.messages)
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageDocument.fromFirestore(d)).toList());
  }

  /// Wait for project confirmation to complete
  Future<bool> waitForProjectConfirmation(String confId, {int maxAttempts = 30}) async {
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final doc = await _firestore.doc(FirestorePaths.projectConfirmationDoc(confId)).get();
      if (!doc.exists) return false;
      final status = doc.data()?['status'] as String?;
      if (status == 'completed') return true;
      if (status == 'failed') return false;
    }
    return false;
  }

  /// Wait for payment request to complete (stream listener - reacts immediately when CF updates)
  Future<bool> waitForPaymentCompletion(String requestId, {Duration timeout = const Duration(seconds: 45)}) async {
    final ref = _firestore.doc(FirestorePaths.paymentRequestDoc(requestId));
    final completer = Completer<bool>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
    Timer? timeoutTimer;

    void cleanup() {
      sub?.cancel();
      timeoutTimer?.cancel();
    }

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete(false);
      }
    });

    sub = ref.snapshots().listen((doc) {
      if (completer.isCompleted) return;
      if (!doc.exists) {
        cleanup();
        completer.complete(false);
        return;
      }
      final status = doc.data()?['status'] as String?;
      if (status == 'completed') {
        cleanup();
        completer.complete(true);
      } else if (status == 'failed') {
        cleanup();
        completer.complete(false);
      }
    }, onError: (e) {
      if (!completer.isCompleted) {
        cleanup();
        completer.completeError(e);
      }
    });

    try {
      return await completer.future;
    } finally {
      cleanup();
    }
  }

  /// Get error message from failed payment request (call after waitForPaymentCompletion returns false)
  Future<String?> getPaymentRequestError(String requestId) async {
    final doc = await _firestore.doc(FirestorePaths.paymentRequestDoc(requestId)).get();
    if (!doc.exists) return null;
    final status = doc.data()?['status'] as String?;
    if (status != 'failed') return null;
    return doc.data()?['error'] as String?;
  }

  /// Wallet top-up via Moyasar card — processed by [processCardPaymentConfirmation] (wallet_topup).
  Future<String> createWalletTopupConfirmation({
    required String moyasarPaymentId,
    required String userId,
    required double amount,
  }) async {
    return createCardPaymentConfirmation(
      moyasarPaymentId: moyasarPaymentId,
      fromUserId: userId,
      toUserId: userId,
      amount: amount,
      projectId: 'wallet_topup',
      offerId: 'wallet_topup',
      deliveryDurationDays: 0,
    );
  }

  /// Create add-card-only confirmation - 1 SAR charge, CF deposits to user wallet
  Future<String> createAddCardConfirmation({
    required String moyasarPaymentId,
    required String userId,
    required double amount,
  }) async {
    try {
      final ref = _firestore.collection(FirestorePaths.cardPaymentConfirmations).doc();
      await ref.set({
        'moyasarPaymentId': moyasarPaymentId,
        'fromUserId': userId,
        'toUserId': userId,
        'amount': amount,
        'projectId': 'add_card',
        'offerId': 'add_card',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Create card payment confirmation - Cloud Function verifies with Moyasar and updates project
  Future<String> createCardPaymentConfirmation({
    required String moyasarPaymentId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String projectId,
    required String offerId,
    int? deliveryDurationDays,
  }) async {
    try {
      final ref = _firestore.collection(FirestorePaths.cardPaymentConfirmations).doc();
      await ref.set({
        'moyasarPaymentId': moyasarPaymentId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'projectId': projectId,
        'offerId': offerId,
        'deliveryDurationDays': deliveryDurationDays ?? 30,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's saved cards
  Future<List<SavedCardDocument>> getSavedCards(String userId) async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.savedCards)
          .doc(userId)
          .collection('cards')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => SavedCardDocument.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Save a card (token) for user
  Future<String> saveCard(
    String userId, {
    required String token,
    required String lastFour,
    required String brand,
    required String name,
    String? month,
    String? year,
  }) async {
    try {
      final ref = _firestore
          .collection(FirestorePaths.savedCards)
          .doc(userId)
          .collection('cards')
          .doc();
      final card = SavedCardDocument(
        id: ref.id,
        userId: userId,
        token: token,
        lastFour: lastFour,
        brand: brand,
        name: name,
        month: month,
        year: year,
      );
      await ref.set(card.toFirestore());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete saved card
  Future<void> deleteSavedCard(String userId, String cardId) async {
    await _firestore
        .collection(FirestorePaths.savedCards)
        .doc(userId)
        .collection('cards')
        .doc(cardId)
        .delete();
  }

  /// Wait for card payment confirmation to complete (stream listener)
  Future<bool> waitForCardPaymentCompletion(String confId,
      {Duration timeout = const Duration(seconds: 45)}) async {
    final ref = _firestore.doc(FirestorePaths.cardPaymentConfirmationDoc(confId));
    final completer = Completer<bool>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
    Timer? timeoutTimer;

    void cleanup() {
      sub?.cancel();
      timeoutTimer?.cancel();
    }

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete(false);
      }
    });

    sub = ref.snapshots().listen((doc) {
      if (completer.isCompleted) return;
      if (!doc.exists) {
        cleanup();
        completer.complete(false);
        return;
      }
      final status = doc.data()?['status'] as String?;
      if (status == 'completed') {
        cleanup();
        completer.complete(true);
      } else if (status == 'failed') {
        cleanup();
        completer.complete(false);
      }
    }, onError: (e) {
      if (!completer.isCompleted) {
        cleanup();
        completer.completeError(e);
      }
    });

    try {
      return await completer.future;
    } finally {
      cleanup();
    }
  }

  /// Transfer payment from client to engineer (project payment) - client-side only for wallet deduction
  /// Use createPaymentRequest + Cloud Function for full transfer
  Future<String> transferPayment({
    required String clientUserId,
    required String engineerUserId,
    required double amount,
    String? projectId,
    String? offerId,
  }) async {
    try {
      return await _firestore.runTransaction<String>((tx) async {
        final clientWalletRef = _firestore.doc(FirestorePaths.walletDoc(clientUserId));
        final engineerWalletRef = _firestore.doc(FirestorePaths.walletDoc(engineerUserId));

        final clientSnap = await tx.get(clientWalletRef);
        final clientBalance = clientSnap.exists
            ? (clientSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0
            : 0.0;

        if (clientBalance < amount) {
          throw Exception('insufficient_balance');
        }

        final engineerSnap = await tx.get(engineerWalletRef);
        final engineerBalance = engineerSnap.exists
            ? (engineerSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0
            : 0.0;

        if (!clientSnap.exists) {
          tx.set(clientWalletRef, {
            'userId': clientUserId,
            'balance': 0,
            'currency': 'SAR',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        tx.update(clientWalletRef, {
          'balance': clientBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!engineerSnap.exists) {
          tx.set(engineerWalletRef, {
            'userId': engineerUserId,
            'balance': amount,
            'currency': 'SAR',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(engineerWalletRef, {
            'balance': engineerBalance + amount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final txRef = _firestore.collection(FirestorePaths.transactions).doc();
        tx.set(txRef, {
          'userId': clientUserId,
          'type': 'payment_out',
          'amount': amount,
          'status': 'completed',
          'currency': 'SAR',
          'description': 'Project payment',
          'referenceId': projectId,
          'referenceType': 'project',
          'relatedUserId': engineerUserId,
          'metadata': {'offerId': offerId},
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        final txRef2 = _firestore.collection(FirestorePaths.transactions).doc();
        tx.set(txRef2, {
          'userId': engineerUserId,
          'type': 'payment_in',
          'amount': amount,
          'status': 'completed',
          'currency': 'SAR',
          'description': 'Payment received for project',
          'referenceId': projectId,
          'referenceType': 'project',
          'relatedUserId': clientUserId,
          'metadata': {'offerId': offerId},
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        return txRef.id;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get user transactions
  Future<List<TransactionDocument>> getUserTransactions(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.transactions)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((d) => TransactionDocument.fromFirestore(d))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Admin home: user/project counts and estimated platform revenue (10% of completed `paidAmount`).
  Future<AdminDashboardStats> fetchAdminDashboardStats() async {
    final usersCol = _firestore.collection(FirestorePaths.users);
    final projectsCol = _firestore.collection(FirestorePaths.projects);

    Future<int> readCount(Query<Map<String, dynamic>> q) async {
      final snap = await q.count().get();
      return snap.count ?? 0;
    }

    final counts = await Future.wait([
      readCount(usersCol.where('userType', isEqualTo: 'user')),
      readCount(usersCol.where('userType', isEqualTo: 'engineer')),
      readCount(usersCol.where('userType', isEqualTo: 'admin')),
      readCount(projectsCol),
      readCount(projectsCol.where('status', isEqualTo: 'new')),
      readCount(projectsCol.where('status', isEqualTo: 'in_progress')),
      readCount(projectsCol.where('status', isEqualTo: 'delivered')),
      readCount(projectsCol.where('status', isEqualTo: 'completed')),
      readCount(projectsCol.where('status', isEqualTo: 'cancelled')),
    ]);

    var completedPaid = 0.0;
    try {
      final done = await projectsCol.where('status', isEqualTo: 'completed').get();
      for (final d in done.docs) {
        final n = (d.data()['paidAmount'] as num?)?.toDouble();
        if (n != null && n > 0) completedPaid += n;
      }
    } catch (_) {}

    final fee = completedPaid * AdminDashboardStats.platformFeeRate;

    return AdminDashboardStats(
      clientsCount: counts[0],
      engineersCount: counts[1],
      adminsCount: counts[2],
      projectsTotal: counts[3],
      projectsNew: counts[4],
      projectsInProgress: counts[5],
      projectsDelivered: counts[6],
      projectsCompleted: counts[7],
      projectsCancelled: counts[8],
      completedProjectsPaidTotalSar: completedPaid,
      estimatedPlatformFeesSar: fee,
    );
  }
}
