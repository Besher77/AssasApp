import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moyasar/moyasar.dart';

/// Saved card (token only - no full number, PCI compliant)
class SavedCardDocument {
  SavedCardDocument({
    required this.id,
    required this.userId,
    required this.token,
    required this.lastFour,
    required this.brand,
    required this.name,
    this.month,
    this.year,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String token;
  final String lastFour;
  final String brand;
  final String name;
  final String? month;
  final String? year;
  final DateTime? createdAt;

  CardCompany get cardCompany {
    switch (brand.toLowerCase()) {
      case 'visa': return CardCompany.visa;
      case 'mastercard':
      case 'master': return CardCompany.master;
      case 'mada': return CardCompany.mada;
      case 'amex': return CardCompany.amex;
      default: return CardCompany.visa;
    }
  }

  factory SavedCardDocument.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SavedCardDocument(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      token: d['token'] as String? ?? '',
      lastFour: d['lastFour'] as String? ?? '',
      brand: d['brand'] as String? ?? 'visa',
      name: d['name'] as String? ?? '',
      month: d['month'] as String?,
      year: d['year'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'token': token,
    'lastFour': lastFour,
    'brand': brand,
    'name': name,
    if (month != null) 'month': month,
    if (year != null) 'year': year,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
