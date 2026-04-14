import 'package:get/get.dart';

/// Saudi local banks for engineer payout IBAN selection (display names).
class SaudiBank {
  const SaudiBank({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'en' ? nameEn : nameAr;
}

/// Stable ids stored in Firestore `payoutBankId`.
const List<SaudiBank> saudiBanks = [
  SaudiBank(id: 'alrajhi', nameAr: 'مصرف الراجحي', nameEn: 'Al Rajhi Bank'),
  SaudiBank(id: 'snb', nameAr: 'البنك الأهلي السعودي (SNB)', nameEn: 'Saudi National Bank (SNB)'),
  SaudiBank(id: 'riyad', nameAr: 'بنك الرياض', nameEn: 'Riyad Bank'),
  SaudiBank(id: 'alinma', nameAr: 'مصرف الإنماء', nameEn: 'Alinma Bank'),
  SaudiBank(id: 'bilad', nameAr: 'بنك البلاد', nameEn: 'Bank Albilad'),
  SaudiBank(id: 'sabb', nameAr: 'البنك السعودي البريطاني (SABB)', nameEn: 'SABB'),
  SaudiBank(id: 'saib', nameAr: 'البنك السعودي للاستثمار', nameEn: 'Saudi Investment Bank'),
  SaudiBank(id: 'bsf', nameAr: 'البنك السعودي الفرنسي', nameEn: 'Banque Saudi Fransi'),
  SaudiBank(id: 'jazira', nameAr: 'بنك الجزيرة', nameEn: 'Bank Aljazira'),
  SaudiBank(id: 'anb', nameAr: 'البنك العربي الوطني', nameEn: 'Arab National Bank'),
  SaudiBank(id: 'gib', nameAr: 'بنك الخليج الدولي', nameEn: 'Gulf International Bank Saudi Arabia'),
  SaudiBank(id: 'd360', nameAr: 'D360 Bank', nameEn: 'D360 Bank'),
  SaudiBank(id: 'stc_pay', nameAr: 'STC Pay', nameEn: 'STC Pay'),
  SaudiBank(id: 'urpay', nameAr: 'Urpay', nameEn: 'Urpay'),
  SaudiBank(id: 'other', nameAr: 'أخرى', nameEn: 'Other'),
];

String? bankNameById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final b in saudiBanks) {
    if (b.id == id) return b.name;
  }
  return id;
}
