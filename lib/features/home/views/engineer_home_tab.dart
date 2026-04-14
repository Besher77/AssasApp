import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/project_options.dart';
import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart';
import '../../../core/models/project_document.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../projects/controllers/browse_projects_controller.dart';

class EngineerHomeTab extends GetView<BrowseProjectsController> {
  const EngineerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchBar(controller: controller),
        _FilterSection(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const _ProjectsShimmer();
            }
            if (controller.filteredProjects.isEmpty) {
              return _EmptyProjects();
            }
            return _ProjectsList(
              projects: controller.filteredProjects.toList(),
              getCustomerName: (id) => controller.getCustomerName(id),
            );
          }),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final BrowseProjectsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: TextField(
        onChanged: controller.setSearch,
        decoration: InputDecoration(
          hintText: 'search_projects_placeholder'.tr,
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.controller});

  final BrowseProjectsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                Text(
                  'filter'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (controller.hasActiveFilters)
                  TextButton.icon(
                    onPressed: controller.clearFilters,
                    icon: Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryAccent),
                    label: Text('clear_filters'.tr, style: TextStyle(color: AppColors.primaryAccent, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'project_type'.tr,
                    value: controller.selectedProjectType.value.isEmpty
                        ? 'all'.tr
                        : getProjectTypeNameById(controller.selectedProjectType.value),
                    onTap: () => _showProjectTypeSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'city'.tr,
                    value: controller.selectedCity.value.isEmpty
                        ? 'all'.tr
                        : getCityNameById(controller.selectedCity.value),
                    onTap: () => _showCitySheet(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'price_range'.tr,
                    value: _priceRangeLabel,
                    onTap: () => _showPriceRangeSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'date_range'.tr,
                    value: _dateRangeLabel,
                    onTap: () => _showDateRangeSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'sort_by'.tr,
                    value: controller.sortNewestFirst.value ? 'newest_first'.tr : 'oldest_first'.tr,
                    onTap: () => _showSortSheet(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _dateRangeLabel {
    final from = controller.dateFrom.value;
    final to = controller.dateTo.value;
    if (from == null && to == null) return 'all'.tr;
    if (from == null) return '${'all'.tr} - ${_fmtDate(to!)}';
    if (to == null) return '${_fmtDate(from)}+';
    return '${_fmtDate(from)} - ${_fmtDate(to)}';
  }

  String _fmtDate(DateTime d) => '${d.year}/${d.month}/${d.day}';

  String get _priceRangeLabel {
    final min = controller.selectedBudgetMin.value;
    final max = controller.selectedBudgetMax.value;
    if (min.isEmpty && max.isEmpty) return 'all'.tr;
    if (min.isEmpty) return '${'all'.tr} - ${getBudgetOptionNameById(max)}';
    if (max.isEmpty) return '${getBudgetOptionNameById(min)}+';
    return '${getBudgetOptionNameById(min)} - ${getBudgetOptionNameById(max)}';
  }

  void _showProjectTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'project_type'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            ListTile(
              title: Text('all'.tr, style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.setProjectTypeFilter(null);
                Navigator.pop(ctx);
              },
            ),
            ...projectTypes.map(
              (t) => ListTile(
                title: Text(t.name, style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  controller.setProjectTypeFilter(t.id);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'city'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      title: Text('all'.tr, style: TextStyle(color: AppColors.textPrimary)),
                      onTap: () {
                        controller.setCityFilter(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...saudiCities.map(
                      (c) => ListTile(
                        title: Text(c.name, style: TextStyle(color: AppColors.textPrimary)),
                        onTap: () {
                          controller.setCityFilter(c.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceRangeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'price_range'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      title: Text('all'.tr, style: TextStyle(color: AppColors.textPrimary)),
                      onTap: () {
                        controller.setBudgetMinFilter(null);
                        controller.setBudgetMaxFilter(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'min_budget'.tr,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    ...budgetOptions.map(
                      (b) => ListTile(
                        title: Text(b.name, style: TextStyle(color: AppColors.textPrimary)),
                        onTap: () {
                          controller.setBudgetMinFilter(b.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'max_budget'.tr,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    ...budgetOptions.map(
                      (b) => ListTile(
                        title: Text(b.name, style: TextStyle(color: AppColors.textPrimary)),
                        onTap: () {
                          controller.setBudgetMaxFilter(b.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateRangeSheet(BuildContext context) {
    DateTime? from = controller.dateFrom.value;
    DateTime? to = controller.dateTo.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'date_range'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('all'.tr, style: TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      controller.setDateFrom(null);
                      controller.setDateTo(null);
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    title: Text('from_date'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  ListTile(
                    title: Text(from != null ? _fmtDate(from!) : 'select'.tr, style: TextStyle(color: AppColors.textPrimary)),
                    trailing: Icon(Icons.calendar_today, size: 20, color: AppColors.primaryAccent),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: from ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        from = picked;
                        controller.setDateFrom(picked);
                        setModalState(() {});
                      }
                    },
                  ),
                  ListTile(
                    title: Text('to_date'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  ListTile(
                    title: Text(to != null ? _fmtDate(to!) : 'select'.tr, style: TextStyle(color: AppColors.textPrimary)),
                    trailing: Icon(Icons.calendar_today, size: 20, color: AppColors.primaryAccent),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: to ?? from ?? DateTime.now(),
                        firstDate: from ?? DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        to = picked;
                        controller.setDateTo(picked);
                        setModalState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('apply'.tr),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'sort_by'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            ListTile(
              leading: Icon(Icons.new_releases_rounded, color: AppColors.primaryAccent),
              title: Text('newest_first'.tr, style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.setSortNewestFirst(true);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.history_rounded, color: AppColors.primaryAccent),
              title: Text('oldest_first'.tr, style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.setSortNewestFirst(false);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 18, color: AppColors.primaryAccent),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primaryAccent),
          ],
        ),
      ),
    );
  }
}

class _ProjectsShimmer extends StatelessWidget {
  const _ProjectsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBackground,
      highlightColor: AppColors.glassBorder,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ShimmerCard(),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'no_projects_match'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'try_different_filters'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsList extends StatelessWidget {
  const _ProjectsList({
    required this.projects,
    required this.getCustomerName,
  });

  final List<ProjectDocument> projects;
  final String? Function(String) getCustomerName;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Get.find<BrowseProjectsController>().loadProjects();
      },
      color: AppColors.primaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final p = projects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ProjectCard(
              project: p,
              customerName: getCustomerName(p.userId),
            ),
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, this.customerName});

  final ProjectDocument project;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    final imageUrl = project.imageUrls.isNotEmpty ? project.imageUrls.first : null;
    return AsasCard(
      padding: EdgeInsets.zero,
      onTap: () => Get.toNamed('/project-detail', arguments: project),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 110,
                    height: 110,
                    color: AppColors.primaryBackground,
                    child: Icon(Icons.image_not_supported, color: AppColors.textSecondary, size: 32),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customerName != null && customerName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        customerName!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getProjectTypeNameById(project.projectType),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${project.landArea} ${'land_area_unit'.tr}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (project.budget != null && project.budget!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(
                          getBudgetOptionNameById(project.budget!),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project.city.isNotEmpty ? getCityNameById(project.city) : '-',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
