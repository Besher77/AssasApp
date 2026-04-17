import 'package:cloud_firestore/cloud_firestore.dart';

/// File attachment for offer
class OfferFileAttachment {
  const OfferFileAttachment({required this.url, required this.name});
  final String url;
  final String name;

  factory OfferFileAttachment.fromMap(Map<String, dynamic> m) =>
      OfferFileAttachment(url: m['url'] as String? ?? '', name: m['name'] as String? ?? '');

  Map<String, dynamic> toMap() => {'url': url, 'name': name};
}

/// Offer/Bid from engineer on a project
class OfferDocument {
  OfferDocument({
    required this.id,
    required this.projectId,
    required this.engineerId,
    required this.message,
    this.proposedPrice,
    this.proposedDuration,
    this.imageUrls = const [],
    this.fileAttachments = const [],
    this.status = 'pending',
    this.engineerName,
    this.engineerPhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String engineerId;
  final String message;
  final String? proposedPrice;
  final String? proposedDuration;
  final List<String> imageUrls;
  final List<OfferFileAttachment> fileAttachments;
  final String status; // pending, accepted, rejected
  final String? engineerName;
  final String? engineerPhotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OfferDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urls = data['imageUrls'];
    final files = data['fileAttachments'];
    return OfferDocument(
      id: doc.id,
      projectId: data['projectId'] as String? ?? '',
      engineerId: data['engineerId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      proposedPrice: data['proposedPrice'] as String?,
      proposedDuration: data['proposedDuration'] as String?,
      imageUrls: urls is List ? urls.map((e) => e.toString()).toList() : [],
      fileAttachments: files is List
          ? files
              .map((e) => e is Map ? OfferFileAttachment.fromMap(Map<String, dynamic>.from(e)) : null)
              .whereType<OfferFileAttachment>()
              .where((a) => a.url.isNotEmpty)
              .toList()
          : [],
      status: data['status'] as String? ?? 'pending',
      engineerName: data['engineerName'] as String?,
      engineerPhotoUrl: data['engineerPhotoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Parse proposedPrice to amount (handles "5000", "5,000", "10000-20000" -> first number)
  double? get parsedAmount {
    final s = proposedPrice?.replaceAll(',', '').trim();
    if (s == null || s.isEmpty) return null;
    final match = RegExp(r'[\d.]+').firstMatch(s);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  Map<String, dynamic> toFirestore() {
    final now = FieldValue.serverTimestamp();
    return {
      'projectId': projectId,
      'engineerId': engineerId,
      'message': message,
      'proposedPrice': proposedPrice,
      'proposedDuration': proposedDuration,
      'imageUrls': imageUrls,
      'fileAttachments': fileAttachments.map((f) => f.toMap()).toList(),
      'status': status,
      'engineerName': engineerName,
      'engineerPhotoUrl': engineerPhotoUrl,
      'updatedAt': now,
      if (createdAt == null) 'createdAt': now,
    };
  }
}
