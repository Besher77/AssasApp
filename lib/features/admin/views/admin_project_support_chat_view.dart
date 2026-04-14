import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/saudi_cities.dart' show getCityNameById;
import '../../../core/models/message_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/views/chat_image_preview.dart';
import '../controllers/admin_project_support_chat_controller.dart';

class AdminProjectSupportChatView extends GetView<AdminProjectSupportChatController> {
  const AdminProjectSupportChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final eng = controller.engineerUser.value?.name ?? controller.engineerId ?? '';
          final cli = controller.clientUser.value?.name ?? controller.clientId ?? '';
          final sub = [cli, eng].where((s) => s.isNotEmpty).join(' · ');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'admin_support_chat_title'.tr,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
            ],
          );
        }),
        actions: [
          IconButton(
            tooltip: 'admin_project_edit'.tr,
            icon: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
              final id = controller.project?.id;
              if (id != null) Get.toNamed(AppRoutes.adminProjectEdit, arguments: id);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        final proj = controller.project;
        return Column(
          children: [
            if (proj != null) _ProjectStrip(project: proj),
            Expanded(
              child: Obx(() {
              final list = List<MessageDocument>.of(controller.messages);
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'admin_support_chat_empty'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                );
              }
              final allImages = list
                  .where((m) => m.type == MessageType.image && m.imageUrls.isNotEmpty)
                  .expand((m) => m.imageUrls)
                  .toList();
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final msg = list[i];
                  final fromAdmin = controller.isFromAdmin(msg);
                  return GestureDetector(
                    onLongPress: () => controller.onMessageLongPress(msg),
                    child: _SupportBubble(
                    message: msg,
                    alignRight: fromAdmin,
                    showAdminBadge: controller.showsAdminBadge(msg),
                    senderLabel: controller.senderLabel(msg),
                    onImageTap: (url) {
                      final idx = allImages.indexOf(url);
                      if (idx >= 0 && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatImagePreview(images: allImages, initialIndex: idx),
                          ),
                        );
                      }
                    },
                  ),
                  );
                },
              );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Obx(() {
                final open = controller.canSend;
                return Row(
                  children: [
                    IconButton(
                      onPressed: !open || controller.sendingImage.value ? null : controller.sendImage,
                      icon: controller.sendingImage.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.image_outlined, color: open ? AppColors.textPrimary : AppColors.textSecondary),
                    ),
                    IconButton(
                      onPressed: !open || controller.sendingFile.value ? null : controller.sendFile,
                      icon: controller.sendingFile.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.attach_file, color: open ? AppColors.textPrimary : AppColors.textSecondary),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller.messageController,
                        enabled: open,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: open ? 'type_message'.tr : 'admin_support_chat_not_available'.tr,
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.primaryBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

class _ProjectStrip extends StatelessWidget {
  const _ProjectStrip({required this.project});

  final ProjectDocument project;

  @override
  Widget build(BuildContext context) {
    final desc = project.description;
    final short = desc.length > 100 ? '${desc.substring(0, 100)}…' : desc;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            short,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          if (project.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              getCityNameById(project.city),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportBubble extends StatelessWidget {
  const _SupportBubble({
    required this.message,
    required this.alignRight,
    required this.showAdminBadge,
    this.senderLabel,
    required this.onImageTap,
  });

  final MessageDocument message;
  final bool alignRight;
  final bool showAdminBadge;
  final String? senderLabel;
  final void Function(String url) onImageTap;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderLabel != null && senderLabel!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 4, left: alignRight ? 0 : 2, right: alignRight ? 2 : 0),
                child: Text(
                  senderLabel!,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            if (showAdminBadge)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 2),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: alignRight
                    ? AppColors.primaryAccent.withValues(alpha: 0.28)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(alignRight ? 14 : 4),
                  bottomRight: Radius.circular(alignRight ? 4 : 14),
                ),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  else if (message.type == MessageType.file && message.fileUrl != null)
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(message.fileUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
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
                    )
                  else if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (message.editedAt != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'message_edited_label'.tr,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
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
