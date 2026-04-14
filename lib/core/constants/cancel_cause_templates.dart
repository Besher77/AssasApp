import 'package:get/get.dart';

/// Cancel cause template - predefined reasons for project cancellation
class CancelCauseTemplate {
  const CancelCauseTemplate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

/// Predefined cancel cause templates
const List<CancelCauseTemplate> cancelCauseTemplates = [
  CancelCauseTemplate(
    id: 'change_of_plans',
    nameAr: 'تغيير في الخطط',
    nameEn: 'Change of plans',
  ),
  CancelCauseTemplate(
    id: 'budget_constraints',
    nameAr: 'قيود مالية',
    nameEn: 'Budget constraints',
  ),
  CancelCauseTemplate(
    id: 'timeline_issues',
    nameAr: 'مشاكل في الجدول الزمني',
    nameEn: 'Timeline issues',
  ),
  CancelCauseTemplate(
    id: 'scope_mismatch',
    nameAr: 'عدم تطابق التوقعات',
    nameEn: 'Scope mismatch',
  ),
  CancelCauseTemplate(
    id: 'found_another',
    nameAr: 'اختيار خيار آخر',
    nameEn: 'Found another option',
  ),
  CancelCauseTemplate(
    id: 'communication_issues',
    nameAr: 'مشاكل في التواصل',
    nameEn: 'Communication issues',
  ),
  CancelCauseTemplate(
    id: 'other',
    nameAr: 'أخرى',
    nameEn: 'Other',
  ),
];

String getCancelCauseNameById(String id) {
  try {
    return cancelCauseTemplates.firstWhere((c) => c.id == id).name;
  } catch (_) {
    return id;
  }
}
