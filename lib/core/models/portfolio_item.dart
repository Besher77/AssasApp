import 'package:cloud_firestore/cloud_firestore.dart';

/// Engineer portfolio item - work gallery entry
class PortfolioItem {
  PortfolioItem({
    required this.id,
    required this.engineerId,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.fileUrls = const [],
    this.executionDate,
    this.projectType,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String engineerId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final List<String> fileUrls;
  final DateTime? executionDate;
  final String? projectType;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PortfolioItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imgUrls = data['imageUrls'];
    final fUrls = data['fileUrls'];
    return PortfolioItem(
      id: doc.id,
      engineerId: data['engineerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrls: imgUrls is List ? imgUrls.map((e) => e.toString()).toList() : [],
      fileUrls: fUrls is List ? fUrls.map((e) => e.toString()).toList() : [],
      executionDate: (data['executionDate'] as Timestamp?)?.toDate(),
      projectType: data['projectType'] as String?,
      location: data['location'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final now = FieldValue.serverTimestamp();
    return {
      'engineerId': engineerId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'fileUrls': fileUrls,
      'executionDate': executionDate != null ? Timestamp.fromDate(executionDate!) : null,
      'projectType': projectType,
      'location': location,
      'updatedAt': now,
      if (createdAt == null) 'createdAt': now,
    };
  }
}
