import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Home filter categories (majors) - Design, Supervision, Property, Construction
class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.specializationIds,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  /// Specialization IDs that belong to this category
  final List<String> specializationIds;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

const List<HomeCategory> homeCategories = [
  HomeCategory(
    id: 'design',
    nameAr: 'تصميم',
    nameEn: 'Design',
    icon: Icons.architecture_rounded,
    color: Color(0xFF2E7D32),
    specializationIds: ['architectural', 'interior', 'urban'],
  ),
  HomeCategory(
    id: 'supervision',
    nameAr: 'استشارة',
    nameEn: 'Supervision',
    icon: Icons.engineering_rounded,
    color: Color(0xFFE65100),
    specializationIds: ['structural', 'civil', 'mep'],
  ),
  HomeCategory(
    id: 'property',
    nameAr: 'عقار',
    nameEn: 'Property',
    icon: Icons.home_rounded,
    color: Color(0xFF7B1FA2),
    specializationIds: ['surveying', 'urban'],
  ),
  HomeCategory(
    id: 'construction',
    nameAr: 'إنشاءات',
    nameEn: 'Construction',
    icon: Icons.apartment_rounded,
    color: Color(0xFF1976D2),
    specializationIds: ['construction', 'civil', 'structural'],
  ),
];

/// Major card for user home filter - one per engineer specialization
class HomeMajorCard {
  const HomeMajorCard({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

/// All majors (specializations) as filter cards for user home
const List<HomeMajorCard> homeMajorCards = [
  HomeMajorCard(id: 'civil', nameAr: 'مدني', nameEn: 'Civil', icon: Icons.engineering_rounded, color: Color(0xFF1976D2)),
  HomeMajorCard(id: 'architectural', nameAr: 'معماري', nameEn: 'Architectural', icon: Icons.architecture_rounded, color: Color(0xFF2E7D32)),
  HomeMajorCard(id: 'mechanical', nameAr: 'ميكانيكي', nameEn: 'Mechanical', icon: Icons.settings_rounded, color: Color(0xFFE65100)),
  HomeMajorCard(id: 'electrical', nameAr: 'كهربائي', nameEn: 'Electrical', icon: Icons.electrical_services_rounded, color: Color(0xFFF9A825)),
  HomeMajorCard(id: 'chemical', nameAr: 'كيميائي', nameEn: 'Chemical', icon: Icons.science_rounded, color: Color(0xFF7B1FA2)),
  HomeMajorCard(id: 'industrial', nameAr: 'صناعي', nameEn: 'Industrial', icon: Icons.factory_rounded, color: Color(0xFF455A64)),
  HomeMajorCard(id: 'structural', nameAr: 'إنشائي', nameEn: 'Structural', icon: Icons.dashboard_rounded, color: Color(0xFF5D4037)),
  HomeMajorCard(id: 'environmental', nameAr: 'بيئي', nameEn: 'Environmental', icon: Icons.eco_rounded, color: Color(0xFF388E3C)),
  HomeMajorCard(id: 'petroleum', nameAr: 'بترول', nameEn: 'Petroleum', icon: Icons.local_gas_station_rounded, color: Color(0xFF795548)),
  HomeMajorCard(id: 'computer', nameAr: 'حاسوب', nameEn: 'Computer', icon: Icons.computer_rounded, color: Color(0xFF0097A7)),
  HomeMajorCard(id: 'electronics', nameAr: 'إلكترونيات', nameEn: 'Electronics', icon: Icons.memory_rounded, color: Color(0xFF7E57C2)),
  HomeMajorCard(id: 'construction', nameAr: 'إنشاءات', nameEn: 'Construction', icon: Icons.apartment_rounded, color: Color(0xFF00695C)),
  HomeMajorCard(id: 'surveying', nameAr: 'مساحة', nameEn: 'Surveying', icon: Icons.straighten_rounded, color: Color(0xFF00838F)),
  HomeMajorCard(id: 'mep', nameAr: 'ميكانيكي وكهربائي', nameEn: 'MEP', icon: Icons.plumbing_rounded, color: Color(0xFFD84315)),
  HomeMajorCard(id: 'interior', nameAr: 'داخلي', nameEn: 'Interior', icon: Icons.design_services_rounded, color: Color(0xFFAD1457)),
  HomeMajorCard(id: 'urban', nameAr: 'تخطيط حضري', nameEn: 'Urban', icon: Icons.location_city_rounded, color: Color(0xFF4A148C)),
  HomeMajorCard(id: 'other', nameAr: 'أخرى', nameEn: 'Other', icon: Icons.more_horiz_rounded, color: Color(0xFF757575)),
];

String getHomeCategoryNameById(String id) {
  try {
    return homeCategories.firstWhere((c) => c.id == id).name;
  } catch (_) {
    return id;
  }
}
