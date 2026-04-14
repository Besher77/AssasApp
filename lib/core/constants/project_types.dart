import 'package:get/get.dart';

/// Project type (نوع المشروع)
class ProjectType {
  const ProjectType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });
  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

/// Project types: villa, floor, apartment, commercial, etc.
const List<ProjectType> projectTypes = [
  ProjectType(id: 'villa', nameAr: 'فيلا', nameEn: 'Villa'),
  ProjectType(id: 'floor', nameAr: 'دور', nameEn: 'Floor'),
  ProjectType(id: 'apartment', nameAr: 'شقة', nameEn: 'Apartment'),
  ProjectType(id: 'commercial', nameAr: 'محل تجاري', nameEn: 'Commercial Shop'),
  ProjectType(id: 'building', nameAr: 'مبنى', nameEn: 'Building'),
  ProjectType(id: 'land', nameAr: 'أرض', nameEn: 'Land'),
  ProjectType(id: 'office', nameAr: 'مكتب', nameEn: 'Office'),
  ProjectType(id: 'warehouse', nameAr: 'مستودع', nameEn: 'Warehouse'),
  ProjectType(id: 'other', nameAr: 'أخرى', nameEn: 'Other'),
];

String getProjectTypeNameById(String id) {
  try {
    return projectTypes.firstWhere((t) => t.id == id).name;
  } catch (_) {
    return id;
  }
}
