import 'package:cloud_firestore/cloud_firestore.dart';

/// Review/Rating for engineer
class ReviewDocument {
  ReviewDocument({
    required this.id,
    required this.engineerId,
    required this.reviewerId,
    required this.rating,
    this.comment,
    this.projectId,
    this.reviewerName,
    this.createdAt,
    this.engineerAnswer,
    this.answeredAt,
  });

  final String id;
  final String engineerId;
  final String reviewerId;
  final int rating; // 1-5
  final String? comment;
  final String? projectId;
  final String? reviewerName;
  final DateTime? createdAt;
  final String? engineerAnswer;
  final DateTime? answeredAt;

  factory ReviewDocument.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewDocument(
      id: doc.id,
      engineerId: d['engineerId'] as String? ?? '',
      reviewerId: d['reviewerId'] as String? ?? '',
      rating: d['rating'] as int? ?? 0,
      comment: d['comment'] as String?,
      projectId: d['projectId'] as String?,
      reviewerName: d['reviewerName'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      engineerAnswer: d['engineerAnswer'] as String?,
      answeredAt: (d['answeredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'engineerId': engineerId,
      'reviewerId': reviewerId,
      'rating': rating,
      'comment': comment,
      'projectId': projectId,
      'reviewerName': reviewerName,
      'createdAt': FieldValue.serverTimestamp(),
      if (engineerAnswer != null) 'engineerAnswer': engineerAnswer,
      if (answeredAt != null) 'answeredAt': FieldValue.serverTimestamp(),
    };
  }
}
