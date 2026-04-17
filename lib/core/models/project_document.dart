import 'package:cloud_firestore/cloud_firestore.dart';

/// File attachment for project (PDF, DWG, etc.)
class ProjectFileAttachment {
  const ProjectFileAttachment({required this.url, required this.name});
  final String url;
  final String name;

  factory ProjectFileAttachment.fromMap(Map<String, dynamic> m) =>
      ProjectFileAttachment(url: m['url'] as String? ?? '', name: m['name'] as String? ?? '');

  Map<String, dynamic> toMap() => {'url': url, 'name': name};
}

/// Project document for Firestore
class ProjectDocument {
  ProjectDocument({
    required this.id,
    required this.userId,
    required this.projectType,
    required this.landArea,
    required this.city,
    required this.description,
    this.imageUrls = const [],
    this.fileAttachments = const [],
    this.status = 'new',
    this.budget,
    this.deliveryDuration,
    this.createdAt,
    this.updatedAt,
    this.paidAmount,
    this.acceptedEngineerId,
    this.acceptedOfferId,
    this.invitedEngineerId,
    this.expectedCompletionAt,
    this.deliveredAt,
    this.listed = true,
  });

  final String id;
  final String userId;
  final String projectType;
  final String landArea;
  final String city;
  final String description;
  final List<String> imageUrls;
  final List<ProjectFileAttachment> fileAttachments;
  final String status;
  final String? budget;
  final String? deliveryDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? paidAmount;
  final String? acceptedEngineerId;
  final String? acceptedOfferId;
  final String? invitedEngineerId;
  final DateTime? expectedCompletionAt;
  final DateTime? deliveredAt;
  /// When false, project is hidden from engineer browse / invites (owner only).
  final bool listed;

  bool get hasAcceptedEngineer =>
      acceptedEngineerId != null && acceptedEngineerId!.trim().isNotEmpty;

  /// Owner may attach or re-send a private invite to [engineerId] on this project.
  bool isEligibleForPrivateInviteToEngineer(String engineerId) {
    if (engineerId.isEmpty) return false;
    if (hasAcceptedEngineer) return false;
    if (status == 'cancelled' || status == 'completed' || status == 'delivered') {
      return false;
    }
    final inv = invitedEngineerId;
    if (inv != null && inv.isNotEmpty && inv != engineerId) return false;
    return true;
  }

  factory ProjectDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urls = data['imageUrls'];
    final files = data['fileAttachments'];
    return ProjectDocument(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      projectType: data['projectType'] as String? ?? '',
      landArea: data['landArea'] as String? ?? '',
      city: data['city'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrls: urls is List ? urls.map((e) => e.toString()).toList() : [],
      fileAttachments: files is List
          ? files
              .map((e) => e is Map ? ProjectFileAttachment.fromMap(Map<String, dynamic>.from(e)) : null)
              .whereType<ProjectFileAttachment>()
              .where((a) => a.url.isNotEmpty)
              .toList()
          : [],
      status: data['status'] as String? ?? 'new',
      budget: data['budget'] as String?,
      deliveryDuration: data['deliveryDuration'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      paidAmount: (data['paidAmount'] as num?)?.toDouble(),
      acceptedEngineerId: data['acceptedEngineerId'] as String?,
      acceptedOfferId: data['acceptedOfferId'] as String?,
      invitedEngineerId: data['invitedEngineerId'] as String?,
      expectedCompletionAt: (data['expectedCompletionAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      listed: data['listed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    final now = FieldValue.serverTimestamp();
    return {
      'userId': userId,
      'projectType': projectType,
      'landArea': landArea,
      'city': city,
      'description': description,
      'imageUrls': imageUrls,
      'fileAttachments': fileAttachments.map((f) => f.toMap()).toList(),
      'status': status,
      'budget': budget,
      'deliveryDuration': deliveryDuration,
      'paidAmount': paidAmount,
      'acceptedEngineerId': acceptedEngineerId,
      'acceptedOfferId': acceptedOfferId,
      'invitedEngineerId': invitedEngineerId,
      'expectedCompletionAt': expectedCompletionAt != null ? Timestamp.fromDate(expectedCompletionAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'listed': listed,
      'updatedAt': now,
      if (createdAt == null) 'createdAt': now,
    };
  }
}
