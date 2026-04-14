import 'package:get/get.dart';

/// Saudi city with Arabic and English names
class SaudiCity {
  const SaudiCity({required this.id, required this.nameAr, required this.nameEn});
  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

/// All Saudi cities
const List<SaudiCity> saudiCities = [
  SaudiCity(id: 'riyadh', nameAr: 'الرياض', nameEn: 'Riyadh'),
  SaudiCity(id: 'jeddah', nameAr: 'جدة', nameEn: 'Jeddah'),
  SaudiCity(id: 'mecca', nameAr: 'مكة المكرمة', nameEn: 'Mecca'),
  SaudiCity(id: 'medina', nameAr: 'المدينة المنورة', nameEn: 'Medina'),
  SaudiCity(id: 'dammam', nameAr: 'الدمام', nameEn: 'Dammam'),
  SaudiCity(id: 'khobar', nameAr: 'الخبر', nameEn: 'Khobar'),
  SaudiCity(id: 'dhahran', nameAr: 'الظهران', nameEn: 'Dhahran'),
  SaudiCity(id: 'taif', nameAr: 'الطائف', nameEn: 'Taif'),
  SaudiCity(id: 'abha', nameAr: 'أبها', nameEn: 'Abha'),
  SaudiCity(id: 'tabuk', nameAr: 'تبوك', nameEn: 'Tabuk'),
  SaudiCity(id: 'jizan', nameAr: 'جيزان', nameEn: 'Jizan'),
  SaudiCity(id: 'najran', nameAr: 'نجران', nameEn: 'Najran'),
  SaudiCity(id: 'buraidah', nameAr: 'بريدة', nameEn: 'Buraidah'),
  SaudiCity(id: 'khamis_mushait', nameAr: 'خميس مشيط', nameEn: 'Khamis Mushait'),
  SaudiCity(id: 'hail', nameAr: 'حائل', nameEn: 'Hail'),
  SaudiCity(id: 'arar', nameAr: 'عرعر', nameEn: 'Arar'),
  SaudiCity(id: 'yanbu', nameAr: 'ينبع', nameEn: 'Yanbu'),
  SaudiCity(id: 'al_kharj', nameAr: 'الخرج', nameEn: 'Al Kharj'),
  SaudiCity(id: 'al_ahsa', nameAr: 'الأحساء', nameEn: 'Al Ahsa'),
  SaudiCity(id: 'al_baha', nameAr: 'الباحة', nameEn: 'Al Baha'),
  SaudiCity(id: 'sakaka', nameAr: 'سكاكا', nameEn: 'Sakaka'),
  SaudiCity(id: 'qatif', nameAr: 'القطيف', nameEn: 'Qatif'),
  SaudiCity(id: 'unayzah', nameAr: 'عنيزة', nameEn: 'Unaizah'),
  SaudiCity(id: 'al_majmaah', nameAr: 'المجمعة', nameEn: 'Al Majmaah'),
  SaudiCity(id: 'jubail', nameAr: 'الجبيل', nameEn: 'Jubail'),
  SaudiCity(id: 'ras_tanura', nameAr: 'راس تنورة', nameEn: 'Ras Tanura'),
  SaudiCity(id: 'dumat_al_jandal', nameAr: 'دومة الجندل', nameEn: 'Dumat Al Jandal'),
  SaudiCity(id: 'al_khafji', nameAr: 'الخفجي', nameEn: 'Al Khafji'),
  SaudiCity(id: 'tarout', nameAr: 'تاروت', nameEn: 'Tarout'),
  SaudiCity(id: 'jazan', nameAr: 'جازان', nameEn: 'Jazan'),
  SaudiCity(id: 'al_qunfudhah', nameAr: 'القنفذة', nameEn: 'Al Qunfudhah'),
  SaudiCity(id: 'al_mubarraz', nameAr: 'المبرز', nameEn: 'Al Mubarraz'),
  SaudiCity(id: 'al_hofuf', nameAr: 'الهفوف', nameEn: 'Al Hofuf'),
  SaudiCity(id: 'al_qurayyat', nameAr: 'القريات', nameEn: 'Al Qurayyat'),
  SaudiCity(id: 'al_wajh', nameAr: 'الوجه', nameEn: 'Al Wajh'),
  SaudiCity(id: 'dawadmi', nameAr: 'الدوادمي', nameEn: 'Dawadmi'),
  SaudiCity(id: 'dhurma', nameAr: 'ضرما', nameEn: 'Dhurma'),
  SaudiCity(id: 'afif', nameAr: 'عفيف', nameEn: 'Afif'),
  SaudiCity(id: 'al_badaya', nameAr: 'البدائع', nameEn: 'Al Badaya'),
  SaudiCity(id: 'al_bukayriyah', nameAr: 'البكيرية', nameEn: 'Al Bukayriyah'),
  SaudiCity(id: 'al_mithnab', nameAr: 'المذنب', nameEn: 'Al Mithnab'),
  SaudiCity(id: 'al_ras', nameAr: 'الرس', nameEn: 'Al Ras'),
  SaudiCity(id: 'al_zulfi', nameAr: 'الزلفي', nameEn: 'Al Zulfi'),
  SaudiCity(id: 'riyadh_al_khabra', nameAr: 'رياض الخبراء', nameEn: 'Riyadh Al Khabra'),
  SaudiCity(id: 'sharurah', nameAr: 'شرورة', nameEn: 'Sharurah'),
  SaudiCity(id: 'turaif', nameAr: 'طريف', nameEn: 'Turaif'),
  SaudiCity(id: 'wadi_ad_dawasir', nameAr: 'وادي الدواسر', nameEn: 'Wadi Ad Dawasir'),
];

/// Get city display name by id
String getCityNameById(String id) {
  try {
    return saudiCities.firstWhere((c) => c.id == id).name;
  } catch (_) {
    return id;
  }
}
