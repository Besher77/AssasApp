import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type: text, image, file, or audio
enum MessageType { text, image, file, audio }

/// Delivery status: sent, delivered, read
enum MessageStatus { sent, delivered, read }

/// Chat message between client and engineer
class MessageDocument {
  MessageDocument({
    required this.id,
    required this.projectId,
    required this.senderId,
    this.receiverId,
    this.text = '',
    this.type = MessageType.text,
    this.imageUrls = const [],
    this.fileUrl,
    this.fileName,
    this.status = MessageStatus.sent,
    this.createdAt,
    this.editedAt,
    this.adminSupport = false,
    this.adminSender = false,
  });

  final String id;
  final String projectId;
  final String senderId;
  final String? receiverId;
  final String text;
  final MessageType type;
  final List<String> imageUrls;
  final String? fileUrl;
  final String? fileName;
  final MessageStatus status;
  final DateTime? createdAt;
  final DateTime? editedAt;
  /// Legacy: separate admin↔engineer flag (older messages). Shown in unified chat.
  final bool adminSupport;
  /// Sent by an admin in the shared project thread (visible to client + engineer).
  final bool adminSender;

  factory MessageDocument.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final typeStr = d['type'] as String? ?? 'text';
    final statusStr = d['status'] as String? ?? 'sent';
    final urls = d['imageUrls'];
    return MessageDocument(
      id: doc.id,
      projectId: d['projectId'] as String? ?? '',
      senderId: d['senderId'] as String? ?? '',
      receiverId: d['receiverId'] as String?,
      text: d['text'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MessageType.text,
      ),
      imageUrls: urls is List
          ? (urls).map((e) => e.toString()).toList()
          : const [],
      fileUrl: d['fileUrl'] as String?,
      fileName: d['fileName'] as String?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      editedAt: (d['editedAt'] as Timestamp?)?.toDate(),
      adminSupport: d['adminSupport'] as bool? ?? false,
      adminSender: d['adminSender'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'senderId': senderId,
      if (receiverId != null) 'receiverId': receiverId,
      'text': text,
      'type': type.name,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      'status': status.name,
      if (adminSupport) 'adminSupport': true,
      if (adminSender) 'adminSender': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
