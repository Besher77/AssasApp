import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/views/profile_view.dart';
import '../../projects/controllers/my_projects_controller.dart';
import '../../projects/views/my_projects_view.dart';
import 'engineer_home_tab.dart';
import 'user_home_tab.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AsasAppBar(
        showLogo: true,
        actions: [
          _ChatButton(),
          const SizedBox(width: 8),
          _NotificationButton(),
          const SizedBox(width: 12),
          _ProfileAvatar(),
        ],
      ),
      body: Obx(() => _buildPage(controller.currentIndex.value)),
      bottomNavigationBar: Obx(
        () => AsasBottomBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.setIndex,
          isEngineer: controller.isEngineer.value,
        ),
      ),
      floatingActionButton: Obx(() => controller.showCreateButton
          ? FloatingActionButton(
              onPressed: controller.onCreateProject,
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.primaryBackground,
              child: const Icon(Icons.add_rounded, size: 32),
            )
          : const SizedBox.shrink()),
    );
  }

  Widget _buildPage(int index) {
    if (controller.isEngineer.value) {
      switch (index) {
        case 0:
          return const EngineerHomeTab();
        case 1:
          return const _MyProjectsTab();
        case 2:
          return const _ProfileTab();
        default:
          return const EngineerHomeTab();
      }
    }
    switch (index) {
      case 0:
        return const UserHomeTab();
      case 1:
        return const _MyProjectsTab();
      case 2:
        return const _ProfileTab();
      default:
        return const UserHomeTab();
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final photoUrl = controller.userPhotoUrl.value;
      return GestureDetector(
        onTap: () async {
          await Get.toNamed('/profile');
          controller.loadUserType();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl.isNotEmpty
                ? (photoUrl.startsWith('http')
                    ? Image.network(photoUrl, fit: BoxFit.cover)
                    : Image.file(File(photoUrl), fit: BoxFit.cover))
                : Container(
                    color: AppColors.cardBackground,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryAccent,
                      size: 26,
                    ),
                  ),
          ),
        ),
      );
    });
  }
}

class _ChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final count = controller.unreadChatCount.value;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => Get.toNamed('/chats'),
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
          if (count > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final count = controller.unreadNotificationCount.value;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => Get.toNamed('/notifications'),
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
          if (count > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _MyProjectsTab extends StatelessWidget {
  const _MyProjectsTab();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MyProjectsController>()) {
      Get.put<MyProjectsController>(MyProjectsController());
    }
    return const MyProjectsView();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileView(showBackButton: false, isEmbedded: true);
  }
}

