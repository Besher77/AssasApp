import 'package:get/get.dart';

/// Project status options
class ProjectStatus {
  const ProjectStatus({required this.id, required this.nameAr, required this.nameEn});
  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

const List<ProjectStatus> projectStatuses = [
  ProjectStatus(id: 'new', nameAr: 'جديد', nameEn: 'New'),
  ProjectStatus(id: 'in_progress', nameAr: 'قيد التنفيذ', nameEn: 'In Progress'),
  ProjectStatus(id: 'delivered', nameAr: 'تم التسليم', nameEn: 'Delivered'),
  ProjectStatus(id: 'completed', nameAr: 'مكتمل', nameEn: 'Completed'),
  ProjectStatus(id: 'cancelled', nameAr: 'ملغي', nameEn: 'Cancelled'),
];

/// Budget range options (SAR)
class BudgetOption {
  const BudgetOption({required this.id, required this.nameAr, required this.nameEn});
  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

const List<BudgetOption> budgetOptions = [
  BudgetOption(id: '500_1000', nameAr: '500 - 1,000 ر.س', nameEn: '500 - 1,000 SAR'),
  BudgetOption(id: '1000_2000', nameAr: '1,000 - 2,000 ر.س', nameEn: '1,000 - 2,000 SAR'),
  BudgetOption(id: '2000_5000', nameAr: '2,000 - 5,000 ر.س', nameEn: '2,000 - 5,000 SAR'),
  BudgetOption(id: '5000_10000', nameAr: '5,000 - 10,000 ر.س', nameEn: '5,000 - 10,000 SAR'),
  BudgetOption(id: '10000_20000', nameAr: '10,000 - 20,000 ر.س', nameEn: '10,000 - 20,000 SAR'),
  BudgetOption(id: '20000_50000', nameAr: '20,000 - 50,000 ر.س', nameEn: '20,000 - 50,000 SAR'),
  BudgetOption(id: '50000_100000', nameAr: '50,000 - 100,000 ر.س', nameEn: '50,000 - 100,000 SAR'),
  BudgetOption(id: '100000_plus', nameAr: 'أكثر من 100,000 ر.س', nameEn: '100,000+ SAR'),
];

/// Delivery duration options
class DeliveryDurationOption {
  const DeliveryDurationOption({required this.id, required this.nameAr, required this.nameEn});
  final String id;
  final String nameAr;
  final String nameEn;

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
}

const List<DeliveryDurationOption> deliveryDurationOptions = [
  DeliveryDurationOption(id: '1_week', nameAr: 'أسبوع واحد', nameEn: '1 week'),
  DeliveryDurationOption(id: '2_weeks', nameAr: 'أسبوعان', nameEn: '2 weeks'),
  DeliveryDurationOption(id: '1_month', nameAr: 'شهر واحد', nameEn: '1 month'),
  DeliveryDurationOption(id: '2_months', nameAr: 'شهران', nameEn: '2 months'),
  DeliveryDurationOption(id: '3_months', nameAr: '3 أشهر', nameEn: '3 months'),
  DeliveryDurationOption(id: '6_months', nameAr: '6 أشهر', nameEn: '6 months'),
  DeliveryDurationOption(id: '1_year', nameAr: 'سنة واحدة', nameEn: '1 year'),
  DeliveryDurationOption(id: 'flexible', nameAr: 'مرن', nameEn: 'Flexible'),
];

String getProjectStatusNameById(String id) {
  try {
    return projectStatuses.firstWhere((s) => s.id == id).name;
  } catch (_) {
    return id;
  }
}

String getBudgetOptionNameById(String id) {
  try {
    return budgetOptions.firstWhere((b) => b.id == id).name;
  } catch (_) {
    return id;
  }
}

/// Get minimum SAR amount from budget option ID (e.g. "500_1000" -> 500, "100000_plus" -> 100000)
double getBudgetMinAmount(String id) {
  if (id.isEmpty) return 0;
  if (id == '100000_plus') return 100000;
  final parts = id.split('_');
  if (parts.isNotEmpty) {
    final n = double.tryParse(parts[0]);
    if (n != null) return n;
  }
  return 0;
}

/// Get maximum SAR amount from budget option ID (e.g. "500_1000" -> 1000, "100000_plus" -> 1000000)
double getBudgetMaxAmount(String id) {
  if (id.isEmpty) return double.infinity;
  if (id == '100000_plus') return 1000000;
  final parts = id.split('_');
  if (parts.length >= 2) {
    final n = double.tryParse(parts[1]);
    if (n != null) return n;
  }
  return getBudgetMinAmount(id) + 50000;
}

String getDeliveryDurationNameById(String id) {
  try {
    return deliveryDurationOptions.firstWhere((d) => d.id == id).name;
  } catch (_) {
    return id;
  }
}

/// Get approximate days for delivery duration
int getDeliveryDurationDays(String id) {
  const daysMap = {
    '1_week': 7,
    '2_weeks': 14,
    '1_month': 30,
    '2_months': 60,
    '3_months': 90,
    '6_months': 180,
    '1_year': 365,
    'flexible': 365,
  };
  return daysMap[id] ?? 30;
}
