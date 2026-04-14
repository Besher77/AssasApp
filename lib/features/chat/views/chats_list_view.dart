import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/project_types.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/chats_list_controller.dart';

class ChatsListView extends GetView<ChatsListController> {
  const ChatsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'chats'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }
        if (controller.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'no_chats'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_chats_subtitle'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          color: AppColors.primaryAccent,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.items.length,
            itemBuilder: (context, index) {
              final item = controller.items[index];
              return _ChatTile(item: item, controller: controller);
            },
          ),
        );
      }),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.item, required this.controller});

  final ChatListItem item;
  final ChatsListController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.getLastMessagePreview(item.lastMessage);
    return InkWell(
      onTap: () => _openChat(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                  backgroundImage: item.otherUserPhotoUrl != null && item.otherUserPhotoUrl!.isNotEmpty
                      ? NetworkImage(item.otherUserPhotoUrl!)
                      : null,
                  child: item.otherUserPhotoUrl == null || item.otherUserPhotoUrl!.isEmpty
                      ? Text(
                          item.otherUserName.isNotEmpty ? item.otherUserName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (item.unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.otherUserName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: item.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.lastMessage?.createdAt != null)
                        Text(
                          _formatTime(item.lastMessage!.createdAt!),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getProjectTypeNameById(item.project.projectType),
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: item.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (dt.year == now.year) {
      return '${dt.day}/${dt.month}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _openChat() {
    Get.toNamed('/chat', arguments: {
      'project': item.project,
      'otherUserId': item.otherUserId,
      'otherUserName': item.otherUserName,
    });
  }
}
