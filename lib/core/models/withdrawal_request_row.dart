import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin / engineer view of a row in `withdrawal_requests`.
class WithdrawalRequestRow {
  WithdrawalRequestRow({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    this.linkedTransactionId,
    this.bankAccount,
    this.adminMessage,
    this.refundApplied,
    this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String? linkedTransactionId;
  final String? bankAccount;
  final String? adminMessage;
  final bool? refundApplied;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  factory WithdrawalRequestRow.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return WithdrawalRequestRow(
      id: doc.id,
      userId: m['userId'] as String? ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      currency: m['currency'] as String? ?? 'SAR',
      status: m['status'] as String? ?? 'pending',
      linkedTransactionId: m['linkedTransactionId'] as String?,
      bankAccount: m['bankAccount'] as String?,
      adminMessage: m['adminMessage'] as String?,
      refundApplied: m['refundApplied'] as bool?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
