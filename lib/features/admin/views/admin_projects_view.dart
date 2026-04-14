import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/project_options.dart';
import '../../../core/constants/saudi_cities.dart';
import '../../../core/models/project_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/admin_projects_controller.dart';

class AdminProjectsView extends GetView<AdminProjectsController> {
  const AdminProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'admin_projects_title'.tr,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryAccent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryAccent,
            tabs: [
              Tab(text: 'admin_projects_tab_all'.tr),
              Tab(text: 'admin_projects_tab_support'.tr),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Get.toNamed(AppRoutes.adminProjectEdit),
          backgroundColor: AppColors.primaryAccent,
          child: const Icon(Icons.add_rounded, color: Colors.black),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'admin_search_projects_hint'.tr,
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  Obx(() {
                    controller.searchQuery.value;
                    controller.projects.length;
                    controller.userNameById.length;
                    return _ProjectsListBody(
                      controller: controller,
                      list: controller.filteredProjects,
                      supportPrimaryAction: false,
                    );
                  }),
                  Obx(() {
                    controller.searchQuery.value;
                    controller.projects.length;
                    controller.userNameById.length;
                    return _ProjectsListBody(
                      controller: controller,
                      list: controller.filteredSupportProjects,
                      supportPrimaryAction: true,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsListBody extends StatelessWidget {
  const _ProjectsListBody({
    required this.controller,
    required this.list,
    required this.supportPrimaryAction,
  });

  final AdminProjectsController controller;
  final List<ProjectDocument> list;
  final bool supportPrimaryAction;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      final allEmpty = supportPrimaryAction
          ? controller.supportChatProjects.isEmpty
          : controller.projects.isEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            allEmpty
                ? (supportPrimaryAction ? 'admin_support_tab_empty'.tr : 'admin_no_projects'.tr)
                : 'admin_search_no_results'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = list[i];
        return Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              if (supportPrimaryAction) {
                Get.toNamed(AppRoutes.adminProjectSupportChat, arguments: p.id);
              } else {
                Get.toNamed(AppRoutes.adminProjectEdit, arguments: p.id);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.description.length > 80 ? '${p.description.substring(0, 80)}…' : p.description,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => Get.toNamed(AppRoutes.adminUserEdit, arguments: p.userId),
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(color: AppColors.primaryAccent, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: '${'admin_project_owner'.tr}: ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                TextSpan(
                                  text: controller.displayNameForUserId(p.userId),
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (p.acceptedEngineerId != null && p.acceptedEngineerId!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () =>
                                Get.toNamed(AppRoutes.adminUserEdit, arguments: p.acceptedEngineerId),
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(color: AppColors.primaryAccent, fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: '${'admin_accepted_engineer'.tr}: ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  TextSpan(
                                    text: controller.displayNameForUserId(p.acceptedEngineerId!),
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (p.invitedEngineerId != null && p.invitedEngineerId!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () =>
                                Get.toNamed(AppRoutes.adminUserEdit, arguments: p.invitedEngineerId),
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(color: AppColors.primaryAccent, fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: '${'admin_invited_engineer'.tr}: ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  TextSpan(
                                    text: controller.displayNameForUserId(p.invitedEngineerId!),
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              p.city.isNotEmpty ? getCityNameById(p.city) : '—',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                getProjectStatusNameById(p.status),
                                style: TextStyle(color: AppColors.primaryAccent, fontSize: 11),
                              ),
                            ),
                            if (!p.listed) ...[
                              const SizedBox(width: 8),
                              Text(
                                'admin_project_unlisted'.tr,
                                style: TextStyle(color: Colors.orange.shade700, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (supportPrimaryAction)
                        IconButton(
                          tooltip: 'admin_open_support_chat'.tr,
                          icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryAccent),
                          onPressed: () => Get.toNamed(AppRoutes.adminProjectSupportChat, arguments: p.id),
                        ),
                      IconButton(
                        tooltip: 'admin_project_edit'.tr,
                        icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                        onPressed: () => Get.toNamed(AppRoutes.adminProjectEdit, arguments: p.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
