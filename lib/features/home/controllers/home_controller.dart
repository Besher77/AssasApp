import 'dart:async';

import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final currentIndex = 0.obs;
  final isEngineer = false.obs;
  final userPhotoUrl = Rxn<String>();
  final unreadNotificationCount = 0.obs;
  final unreadChatCount = 0.obs;

  StreamSubscription<int>? _unreadNotifSub;
  StreamSubscription<int>? _unreadChatSub;

  @override
  void onInit() {
    super.onInit();
    loadUserType();
    _listenUnreadCounts();
  }

  @override
  void onClose() {
    _unreadNotifSub?.cancel();
    _unreadChatSub?.cancel();
    super.onClose();
  }

  void _listenUnreadCounts() {
    final uid = _authService.currentUserId;
    if (uid == null) return;
    _unreadNotifSub?.cancel();
    _unreadNotifSub = _firestore.streamUnreadNotificationCount(uid).listen(
      (count) => unreadNotificationCount.value = count,
      onError: (_) {},
    );
    _unreadChatSub?.cancel();
    _unreadChatSub = _firestore.streamUnreadMessageCount(uid).listen(
      (count) => unreadChatCount.value = count,
      onError: (_) {},
    );
  }

  Future<void> loadUserType() async {
    try {
      final uid = _authService.currentUserId;
      if (uid == null) return;

      final userDoc = await _firestore.getUser(uid);
      if (userDoc != null) {
        if (userDoc.userType == 'admin') {
          Get.offAllNamed(AppRoutes.adminHome);
          return;
        }
        if (userDoc.isAccessRestricted) {
          await _authService.logout();
          Get.snackbar('error'.tr, 'account_restricted'.tr);
          Get.offAllNamed(AppRoutes.login);
          return;
        }
        if (userDoc.userType == 'engineer' && !userDoc.isEngineerRegistrationApproved) {
          Get.offAllNamed(
            AppRoutes.engineerRegistrationGate,
            arguments: {
              'rejected': userDoc.isEngineerRegistrationRejected,
              'note': userDoc.engineerRegistrationNote,
            },
          );
          return;
        }
        isEngineer.value = userDoc.userType == 'engineer';
        userPhotoUrl.value = userDoc.photoUrl ?? _authService.currentUser?.photoURL;
      } else {
        userPhotoUrl.value = _authService.currentUser?.photoURL;
      }
    } catch (_) {}
  }

  void setIndex(int index) {
    currentIndex.value = index;
  }

  void goToMyProjects() {
    currentIndex.value = isEngineer.value ? 1 : 1;
  }

  void onCreateProject() {
    Get.toNamed('/create-project');
  }

  bool get showCreateButton => !isEngineer.value;
}
