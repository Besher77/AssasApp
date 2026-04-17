import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart' show getCityNameById;
import '../../../core/models/message_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/presence_text.dart';
import '../controllers/chat_controller.dart';
import 'chat_image_preview.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

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
        title: Obx(() {
          final u = controller.otherUser.value;
          final presence = u != null
              ? presenceSubtitle(isOnline: u.isOnline, lastSeen: u.lastSeen)
              : '';
          final otherId = controller.otherUserId;
          final canOpenEngineerProfile =
              controller.otherPartyIsEngineer &&
                  otherId != null &&
                  otherId.isNotEmpty;

          Widget titleContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      controller.otherUserName ?? 'chat'.tr,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canOpenEngineerProfile) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
              if (presence.isNotEmpty)
                Text(
                  presence,
                  style: TextStyle(
                    color: u?.isOnline == true
                        ? Colors.greenAccent.shade200
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          );

          if (!canOpenEngineerProfile) return titleContent;

          return Tooltip(
            message: 'engineer_profile'.tr,
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.engineerProfile, arguments: otherId),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: titleContent,
              ),
            ),
          );
        }),
      ),
      body: Column(
        children: [
          if (controller.project != null) _ProjectSummaryCard(project: controller.project!),
          const _ChatOffPlatformDisclaimer(),
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'no_messages'.tr,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, i) {
                  final msg = controller.messages[i];
                  final allImages = controller.messages
                      .where((m) => m.type == MessageType.image && m.imageUrls.isNotEmpty)
                      .expand((m) => m.imageUrls)
                      .toList();
                  return _MessageBubble(
                    key: ValueKey(msg.id),
                    message: msg,
                    isMe: controller.isMe(msg.senderId),
                    showAdminBadge: msg.adminSupport || msg.adminSender,
                    allChatImages: allImages,
                    chatController: controller,
                    onImageTap: (url) {
                      final idx = allImages.indexOf(url);
                      if (idx >= 0 && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatImagePreview(
                              images: allImages,
                              initialIndex: idx,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            }),
          ),
          Obx(() {
            final open = controller.canSendMessages.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!open)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.12),
                      border: Border(top: BorderSide(color: AppColors.glassBorder)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'chat_read_only_hint'.tr,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border(top: BorderSide(color: AppColors.glassBorder)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: !open || controller.sendingImage.value ? null : controller.sendImage,
                        icon: Obx(() => controller.sendingImage.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.image_outlined,
                                color: open ? AppColors.textPrimary : AppColors.textSecondary,
                              )),
                      ),
                      IconButton(
                        onPressed: !open || controller.sendingFile.value ? null : controller.sendFile,
                        icon: Obx(() => controller.sendingFile.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.attach_file,
                                color: open ? AppColors.textPrimary : AppColors.textSecondary,
                              )),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          enabled: open,
                          style: TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: open ? 'type_message'.tr : 'chat_read_only_hint'.tr,
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.primaryBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) {
                            if (open) controller.sendMessage();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: open ? controller.sendMessage : null,
                        icon: const Icon(Icons.send, color: Colors.black),
                        style: IconButton.styleFrom(
                          backgroundColor: open ? AppColors.primaryAccent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ChatOffPlatformDisclaimer extends StatelessWidget {
  const _ChatOffPlatformDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.09),
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.policy_outlined, size: 22, color: Colors.amber.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'chat_off_platform_disclaimer'.tr,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSummaryCard extends StatelessWidget {
  const _ProjectSummaryCard({required this.project});

  final ProjectDocument project;

  @override
  Widget build(BuildContext context) {
    final imageUrl = project.imageUrls.isNotEmpty ? project.imageUrls.first : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed('/project-detail', arguments: project),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.primaryBackground,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getProjectTypeNameById(project.projectType),
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.landArea} ${'land_area_unit'.tr}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (project.city.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            getCityNameById(project.city),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.primaryAccent.withValues(alpha: 0.15),
      child: Icon(Icons.folder_outlined, color: AppColors.primaryAccent, size: 28),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAdminBadge,
    required this.allChatImages,
    required this.chatController,
    required this.onImageTap,
  });

  final MessageDocument message;
  final bool isMe;
  final bool showAdminBadge;
  final List<String> allChatImages;
  final ChatController chatController;
  final void Function(String url) onImageTap;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusIcon() {
    if (!isMe) return const SizedBox.shrink();
    switch (message.status) {
      case MessageStatus.sent:
        return Icon(Icons.done, size: 14, color: AppColors.textSecondary);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: AppColors.textSecondary);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryAccent.withValues(alpha: 0.3)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAdminBadge)
              Padding(
                padding: EdgeInsets.only(bottom: 6, left: isMe ? 0 : 0),
                child: Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'admin_message_badge'.tr,
                      style: TextStyle(
                        color: Colors.deepPurple.shade200,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            if (message.type == MessageType.image && message.imageUrls.isNotEmpty)
              GestureDetector(
                onTap: () => onImageTap(message.imageUrls.first),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrls.first,
                    fit: BoxFit.cover,
                    width: 200,
                    height: 200,
                    placeholder: (context, url) => const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              )
            else if (message.type == MessageType.audio)
              Text(
                'audio_unavailable'.tr,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (message.type == MessageType.file && message.fileUrl != null)
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(message.fileUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file, color: AppColors.primaryAccent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message.fileName ?? 'file',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (message.editedAt != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    'message_edited_label'.tr,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
