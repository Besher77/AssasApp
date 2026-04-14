import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/project_options.dart' show getProjectStatusNameById;
import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart' show getCityNameById;
import '../../../core/models/project_document.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/my_projects_controller.dart';

class MyProjectsView extends GetView<MyProjectsController> {
  const MyProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectsTabBar(controller: controller),
        Expanded(
          child: Obx(
            () {
              if (controller.isLoading.value) {
                return const _ProjectsShimmer();
              }
              final list = controller.displayedProjects;
              if (list.isEmpty) {
                return _EmptyProjects(emptyMessage: _getEmptyMessage(controller));
              }
              return _ProjectsList(projects: list);
            },
          ),
        ),
      ],
    );
  }

  String _getEmptyMessage(MyProjectsController c) {
    switch (c.selectedTabIndex.value) {
      case 1:
        return 'no_projects_in_progress'.tr;
      case 2:
        return 'no_projects_complete'.tr;
      default:
        return 'no_projects'.tr;
    }
  }
}

class _ProjectsTabBar extends StatelessWidget {
  const _ProjectsTabBar({required this.controller});

  final MyProjectsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Obx(
        () => Row(
          children: [
            _TabChip(
              label: 'tab_projects_all'.tr,
              isSelected: controller.selectedTabIndex.value == 0,
              onTap: () => controller.selectTab(0),
            ),
            _TabChip(
              label: 'tab_in_progress'.tr,
              isSelected: controller.selectedTabIndex.value == 1,
              onTap: () => controller.selectTab(1),
            ),
            _TabChip(
              label: 'tab_complete'.tr,
              isSelected: controller.selectedTabIndex.value == 2,
              onTap: () => controller.selectTab(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.primaryAccent, width: 1) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
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
        padding: const EdgeInsets.all(24),
        itemCount: 6,
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
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 14,
                    width: 80,
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
  const _EmptyProjects({required this.emptyMessage});

  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'no_projects_subtitle'.tr,
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
  const _ProjectsList({required this.projects});

  final List<ProjectDocument> projects;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final c = Get.find<MyProjectsController>();
        await c.loadProjects();
      },
      color: AppColors.primaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final p = projects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ProjectCard(project: p),
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final ProjectDocument project;

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
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 120,
                    height: 120,
                    color: AppColors.primaryBackground,
                    child: Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          getProjectTypeNameById(project.projectType),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (!project.listed && project.status == 'new')
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Text(
                              'project_hidden_badge'.tr,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          getProjectStatusNameById(project.status),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.landArea} ${'land_area_unit'.tr}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.city.isNotEmpty ? getCityNameById(project.city) : '-',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
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
