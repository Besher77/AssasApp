import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction types
enum TransactionType {
  deposit,      // شحن - user adds money
  withdraw,     // سحب - user withdraws
  paymentOut,   // دفع - client pays for project
  paymentIn,    // استلام - engineer receives payment
  refund,       // استرداد
}

/// Transaction status
enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class TransactionDocument {
  TransactionDocument({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.status = 'pending',
    this.currency = 'SAR',
    this.description,
    this.referenceId,
    this.referenceType,
    this.relatedUserId,
    this.metadata,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String type; // deposit, withdraw, payment_out, payment_in, refund
  final double amount;
  final String status; // pending, completed, failed, cancelled
  final String currency;
  final String? description;
  final String? referenceId;
  final String? referenceType;
  final String? relatedUserId;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get isCredit =>
      type == 'deposit' ||
      type == 'admin_credit' ||
      type == 'payment_in' ||
      type == 'refund';
  bool get isDebit =>
      type == 'withdraw' || type == 'payment_out' || type == 'admin_debit';

  factory TransactionDocument.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TransactionDocument(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      type: d['type'] as String? ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      status: d['status'] as String? ?? 'pending',
      currency: d['currency'] as String? ?? 'SAR',
      description: d['description'] as String?,
      referenceId: d['referenceId'] as String?,
      referenceType: d['referenceType'] as String?,
      relatedUserId: d['relatedUserId'] as String?,
      metadata: d['metadata'] as Map<String, dynamic>?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'status': status,
      'currency': currency,
      'description': description,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'relatedUserId': relatedUserId,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  static String typeToString(TransactionType t) {
    switch (t) {
      case TransactionType.deposit:
        return 'deposit';
      case TransactionType.withdraw:
        return 'withdraw';
      case TransactionType.paymentOut:
        return 'payment_out';
      case TransactionType.paymentIn:
        return 'payment_in';
      case TransactionType.refund:
        return 'refund';
    }
  }

  static String statusToString(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.cancelled:
        return 'cancelled';
    }
  }
}
