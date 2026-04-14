import 'package:cloud_firestore/cloud_firestore.dart';

/// User wallet - one per user
class WalletDocument {
  WalletDocument({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.currency = 'SAR',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WalletDocument.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WalletDocument(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      balance: (d['balance'] as num?)?.toDouble() ?? 0.0,
      currency: d['currency'] as String? ?? 'SAR',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final now = FieldValue.serverTimestamp();
    return {
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'updatedAt': now,
      if (createdAt == null) 'createdAt': now,
    };
  }
}
