import 'package:get/get.dart';

import '../../../core/constants/project_options.dart';
import '../../../core/constants/project_types.dart';
import '../../../core/models/project_document.dart';
import '../../../core/services/firestore_service.dart';

/// Controller for browsing all projects (Engineer home)
class BrowseProjectsController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final allProjects = <ProjectDocument>[].obs;
  final filteredProjects = <ProjectDocument>[].obs;
  final isLoading = true.obs;

  /// userId -> userName for project owners
  final userNames = <String, String>{};

  final searchQuery = ''.obs;
  final selectedProjectType = ''.obs;
  final selectedCity = ''.obs;
  final selectedBudgetMin = ''.obs;
  final selectedBudgetMax = ''.obs;
  final dateFrom = Rxn<DateTime>();
  final dateTo = Rxn<DateTime>();
  /// true = newest first, false = oldest first
  final sortNewestFirst = true.obs;

  /// Exclude completed, cancelled, and taken (in_progress, delivered) projects
  static const _excludedStatuses = ['completed', 'in_progress', 'delivered', 'cancelled'];

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects() async {
    isLoading.value = true;
    try {
      final raw = await _firestore.getAllProjects();
      final filtered = raw
          .where((p) =>
              p.listed &&
              !_excludedStatuses.contains(p.status) &&
              p.acceptedEngineerId == null)
          .toList();
      allProjects.value = filtered;

      final uids = filtered.map((p) => p.userId).where((id) => id.isNotEmpty).toSet();
      for (final uid in uids) {
        if (!userNames.containsKey(uid)) {
          final user = await _firestore.getUser(uid);
          if (user != null) userNames[uid] = user.name;
        }
      }

      _applyFilters();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      allProjects.value = [];
      filteredProjects.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  String? getCustomerName(String userId) => userNames[userId];

  void setSearch(String query) {
    searchQuery.value = query.trim().toLowerCase();
    _applyFilters();
  }

  void setProjectTypeFilter(String? id) {
    selectedProjectType.value = id ?? '';
    _applyFilters();
  }

  void setCityFilter(String? id) {
    selectedCity.value = id ?? '';
    _applyFilters();
  }

  void setBudgetMinFilter(String? id) {
    selectedBudgetMin.value = id ?? '';
    _applyFilters();
  }

  void setBudgetMaxFilter(String? id) {
    selectedBudgetMax.value = id ?? '';
    _applyFilters();
  }

  void setDateFrom(DateTime? d) {
    dateFrom.value = d;
    _applyFilters();
  }

  void setDateTo(DateTime? d) {
    dateTo.value = d;
    _applyFilters();
  }

  void setSortNewestFirst(bool newestFirst) {
    sortNewestFirst.value = newestFirst;
    _applyFilters();
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedProjectType.value = '';
    selectedCity.value = '';
    selectedBudgetMin.value = '';
    selectedBudgetMax.value = '';
    dateFrom.value = null;
    dateTo.value = null;
    sortNewestFirst.value = true;
    _applyFilters();
  }

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty ||
      selectedProjectType.value.isNotEmpty ||
      selectedCity.value.isNotEmpty ||
      selectedBudgetMin.value.isNotEmpty ||
      selectedBudgetMax.value.isNotEmpty ||
      dateFrom.value != null ||
      dateTo.value != null ||
      !sortNewestFirst.value;

  void _applyFilters() {
    var list = allProjects.toList();

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value;
      list = list.where((p) {
        final customerName = (userNames[p.userId] ?? '').toLowerCase();
        final projectTypeName = getProjectTypeNameById(p.projectType).toLowerCase();
        final desc = p.description.toLowerCase();
        final city = p.city.toLowerCase();
        return customerName.contains(q) ||
            projectTypeName.contains(q) ||
            desc.contains(q) ||
            city.contains(q);
      }).toList();
    }

    if (selectedProjectType.value.isNotEmpty) {
      list = list.where((p) => p.projectType == selectedProjectType.value).toList();
    }
    if (selectedCity.value.isNotEmpty) {
      list = list.where((p) => p.city == selectedCity.value).toList();
    }
    if (selectedBudgetMin.value.isNotEmpty) {
      final minVal = getBudgetMinAmount(selectedBudgetMin.value);
      list = list.where((p) {
        if (p.budget == null || p.budget!.isEmpty) return true;
        return getBudgetMinAmount(p.budget!) >= minVal;
      }).toList();
    }
    if (selectedBudgetMax.value.isNotEmpty) {
      final maxVal = getBudgetMaxAmount(selectedBudgetMax.value);
      list = list.where((p) {
        if (p.budget == null || p.budget!.isEmpty) return true;
        return getBudgetMaxAmount(p.budget!) <= maxVal;
      }).toList();
    }

    if (dateFrom.value != null) {
      final from = dateFrom.value!;
      list = list.where((p) {
        final d = p.createdAt;
        if (d == null) return true;
        return !d.isBefore(DateTime(from.year, from.month, from.day));
      }).toList();
    }
    if (dateTo.value != null) {
      final to = dateTo.value!;
      final toEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);
      list = list.where((p) {
        final d = p.createdAt;
        if (d == null) return true;
        return !d.isAfter(toEnd);
      }).toList();
    }

    list.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(0);
      final bDate = b.createdAt ?? DateTime(0);
      return sortNewestFirst.value
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });

    filteredProjects.value = list;
  }
}
