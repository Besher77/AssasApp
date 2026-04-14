import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification
class NotificationDocument {
  NotificationDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String? type; // offer_received, offer_accepted, offer_rejected
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime? createdAt;

  factory NotificationDocument.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationDocument(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: d['type'] as String?,
      data: d['data'] as Map<String, dynamic>?,
      read: d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
