import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/project_options.dart' show getProjectStatusNameById;
import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart' show getCityNameById;
import '../../../core/models/project_document.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/invite_engineer_project_controller.dart';

class InviteEngineerProjectView extends GetView<InviteEngineerProjectController> {
  const InviteEngineerProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        foregroundColor: AppColors.textPrimary,
        title: Text('invite_engineer_pick_project_title'.tr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'invite_engineer_pick_project_subtitle'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final attaching = controller.attachingId.value;
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primaryAccent),
                );
              }
              final list = controller.projects;
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded,
                            size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'invite_engineer_no_eligible_projects'.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primaryAccent,
                onRefresh: controller.load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final p = list[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InviteProjectTile(
                        project: p,
                        isBusy: attaching == p.id,
                        onInvite: () => controller.confirmAndAttach(p),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AsasButton(
                label: 'invite_engineer_create_new_project'.tr,
                onPressed: controller.openCreateNewProject,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteProjectTile extends StatelessWidget {
  const _InviteProjectTile({
    required this.project,
    required this.isBusy,
    required this.onInvite,
  });

  final ProjectDocument project;
  final bool isBusy;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final imageUrl = project.imageUrls.isNotEmpty ? project.imageUrls.first : null;
    return AsasCard(
      padding: EdgeInsets.zero,
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
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: AppColors.primaryBackground,
                    child: Icon(Icons.image_not_supported,
                        color: AppColors.textSecondary),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getProjectTypeNameById(project.projectType),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getProjectStatusNameById(project.status),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.city.isNotEmpty ? getCityNameById(project.city) : '-',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: isBusy
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryAccent,
                            ),
                          )
                        : TextButton(
                            onPressed: onInvite,
                            child: Text('invite_to_private_project'.tr),
                          ),
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
