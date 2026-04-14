import 'package:get/get.dart';

/// Engineer specialization with Arabic and English names
class EngineerSpecialization {
  const EngineerSpecialization({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });
  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

/// All engineer specializations
const List<EngineerSpecialization> engineerSpecializations = [
  EngineerSpecialization(id: 'civil', nameAr: 'هندسة مدنية', nameEn: 'Civil Engineering'),
  EngineerSpecialization(id: 'architectural', nameAr: 'هندسة معمارية', nameEn: 'Architectural Engineering'),
  EngineerSpecialization(id: 'mechanical', nameAr: 'هندسة ميكانيكية', nameEn: 'Mechanical Engineering'),
  EngineerSpecialization(id: 'electrical', nameAr: 'هندسة كهربائية', nameEn: 'Electrical Engineering'),
  EngineerSpecialization(id: 'chemical', nameAr: 'هندسة كيميائية', nameEn: 'Chemical Engineering'),
  EngineerSpecialization(id: 'industrial', nameAr: 'هندسة صناعية', nameEn: 'Industrial Engineering'),
  EngineerSpecialization(id: 'structural', nameAr: 'هندسة إنشائية', nameEn: 'Structural Engineering'),
  EngineerSpecialization(id: 'environmental', nameAr: 'هندسة بيئية', nameEn: 'Environmental Engineering'),
  EngineerSpecialization(id: 'petroleum', nameAr: 'هندسة بترول', nameEn: 'Petroleum Engineering'),
  EngineerSpecialization(id: 'computer', nameAr: 'هندسة حاسوب', nameEn: 'Computer Engineering'),
  EngineerSpecialization(id: 'electronics', nameAr: 'هندسة إلكترونيات', nameEn: 'Electronics Engineering'),
  EngineerSpecialization(id: 'construction', nameAr: 'هندسة إنشاءات', nameEn: 'Construction Engineering'),
  EngineerSpecialization(id: 'surveying', nameAr: 'هندسة مساحة', nameEn: 'Surveying Engineering'),
  EngineerSpecialization(id: 'mep', nameAr: 'هندسة ميكانيكية وكهربائية', nameEn: 'MEP Engineering'),
  EngineerSpecialization(id: 'interior', nameAr: 'تصميم داخلي', nameEn: 'Interior Design'),
  EngineerSpecialization(id: 'urban', nameAr: 'تخطيط حضري', nameEn: 'Urban Planning'),
  EngineerSpecialization(id: 'other', nameAr: 'أخرى', nameEn: 'Other'),
];

String getSpecializationNameById(String id) {
  try {
    return engineerSpecializations.firstWhere((s) => s.id == id).name;
  } catch (_) {
    return id;
  }
}

/// Resolve stored value (id, nameAr, or nameEn) to specialization id for dropdown
String? getSpecializationIdByValue(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final found = engineerSpecializations.firstWhere(
      (s) => s.id == value || s.nameAr == value || s.nameEn == value,
    );
    return found.id;
  } catch (_) {
    return null;
  }
}
