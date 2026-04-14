import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
/// Landing page that fetches project/offer and navigates to chat.
/// Used when opening chat from FCM notification (we only have projectId).
class ChatLandingView extends StatefulWidget {
  const ChatLandingView({super.key, required this.projectId});

  final String projectId;

  @override
  State<ChatLandingView> createState() => _ChatLandingViewState();
}

class _ChatLandingViewState extends State<ChatLandingView> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    if (widget.projectId.isEmpty) {
      if (mounted) Get.back();
      return;
    }
    try {
      final firestore = Get.find<FirestoreService>();
      final auth = Get.find<AuthService>();
      final project = await firestore.getProject(widget.projectId);
      if (project == null || !mounted) return;

      final uid = auth.currentUserId;
      if (uid == null) {
        if (mounted) Get.back();
        return;
      }

      if (!firestore.isProjectChatOpenForUser(project, uid)) {
        if (mounted) {
          Get.back();
          Get.snackbar('info'.tr, 'chat_not_available'.tr);
        }
        return;
      }

      String? otherUserId;
      String? otherUserName;

      if (project.userId == uid) {
        final offer = await firestore.getAcceptedOfferForProject(widget.projectId);
        otherUserId = offer?.engineerId ?? project.invitedEngineerId;
        if (offer != null) {
          otherUserName = offer.engineerName;
        } else if (otherUserId != null) {
          final eng = await firestore.getUser(otherUserId);
          otherUserName = eng?.name;
        }
      } else if (project.acceptedEngineerId == uid || project.invitedEngineerId == uid) {
        otherUserId = project.userId;
        final owner = await firestore.getUser(project.userId);
        otherUserName = owner?.name;
      }

      if (otherUserId == null) return;

      if (!mounted) return;
      Get.offNamed('/chat', arguments: {
        'project': project,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName ?? 'chat'.tr,
      });
    } catch (e) {
      if (mounted) {
        Get.back();
        Get.snackbar('error'.tr, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryAccent),
            const SizedBox(height: 24),
            Text(
              'loading_chat'.tr,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
