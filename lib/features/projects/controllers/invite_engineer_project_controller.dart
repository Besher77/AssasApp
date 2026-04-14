import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/notification_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import 'my_projects_controller.dart';

class InviteEngineerProjectController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final AuthService _auth = Get.find<AuthService>();

  String engineerId = '';
  String engineerName = '';

  final projects = <ProjectDocument>[].obs;
  final isLoading = true.obs;
  final attachingId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    engineerId = args?['engineerId'] as String? ?? '';
    engineerName = args?['engineerName'] as String? ?? '';
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    final uid = _auth.currentUserId;
    if (uid == null || engineerId.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final list = await _firestore.getUserProjectsEligibleForPrivateInvite(
        uid,
        forEngineerId: engineerId,
      );
      projects.value = list;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void openCreateNewProject() {
    Get.toNamed(AppRoutes.createProject, arguments: {
      'invitedEngineerId': engineerId,
      'invitedEngineerName': engineerName,
    });
  }

  Future<void> confirmAndAttach(ProjectDocument project) async {
    final displayName =
        engineerName.isNotEmpty ? engineerName : 'engineer'.tr;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'invite_engineer_confirm_invite_title'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'invite_engineer_confirm_invite_body'.trParams({'name': displayName}),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('invite_to_private_project'.tr),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _attachInvite(project);
  }

  Future<void> _attachInvite(ProjectDocument project) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    attachingId.value = project.id;
    try {
      await _firestore.clientInviteEngineerToExistingProject(
        clientUserId: uid,
        projectId: project.id,
        engineerId: engineerId,
      );
      final clientName = _auth.currentUser?.displayName ?? 'client'.tr;
      await _firestore.createNotification(
        NotificationDocument(
          id: '',
          userId: engineerId,
          title: 'project_invitation_title'.tr,
          body: 'project_invitation_body'.trParams({'name': clientName}),
          type: 'project_invitation',
          data: {'projectId': project.id},
        ),
      );
      if (Get.isRegistered<MyProjectsController>()) {
        await Get.find<MyProjectsController>().loadProjects();
      }
      Get.back();
      Get.snackbar('', 'invite_engineer_invitation_sent_existing'.tr);
    } on ClientInviteProjectException catch (e) {
      final msg = e.code == 'forbidden'
          ? 'invite_project_forbidden'.tr
          : 'invite_project_not_eligible'.tr;
      Get.snackbar('error'.tr, msg);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      attachingId.value = null;
    }
  }
}
