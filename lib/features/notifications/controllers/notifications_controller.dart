import 'package:get/get.dart';

import '../../../core/models/notification_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class NotificationsController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final notifications = <NotificationDocument>[].obs;
  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    final uid = _auth.currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      notifications.value = await _firestore.getUserNotifications(uid);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(NotificationDocument n) async {
    if (n.read) return;
    try {
      await _firestore.markNotificationRead(n.id);
      final i = notifications.indexWhere((x) => x.id == n.id);
      if (i >= 0) {
        notifications[i] = NotificationDocument(
          id: n.id,
          userId: n.userId,
          title: n.title,
          body: n.body,
          type: n.type,
          data: n.data,
          read: true,
          createdAt: n.createdAt,
        );
      }
    } catch (_) {}
  }

  void onNotificationTap(NotificationDocument n) {
    markAsRead(n);
    final data = n.data;
    if (data != null) {
      final projectId = data['projectId'] as String?;
      if (projectId != null && projectId.isNotEmpty) {
        Get.toNamed('/project-detail', arguments: projectId);
      }
    }
  }
}
