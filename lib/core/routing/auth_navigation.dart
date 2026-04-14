import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Sends the signed-in user to [AppRoutes.adminHome] or [AppRoutes.home] from Firestore [userType].
Future<void> navigateToRoleHome() async {
  final auth = Get.find<AuthService>();
  final uid = auth.currentUserId;
  if (uid == null) {
    Get.offAllNamed(AppRoutes.login);
    return;
  }
  try {
    final user = await Get.find<FirestoreService>().getUser(uid);
    if (user?.userType == 'admin') {
      Get.offAllNamed(AppRoutes.adminHome);
      return;
    }
    if (user != null && user.isAccessRestricted) {
      await auth.logout();
      Get.snackbar('error'.tr, 'account_restricted'.tr);
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    if (user != null &&
        user.userType == 'engineer' &&
        !user.isEngineerRegistrationApproved) {
      Get.offAllNamed(
        AppRoutes.engineerRegistrationGate,
        arguments: {
          'rejected': user.isEngineerRegistrationRejected,
          'note': user.engineerRegistrationNote,
        },
      );
      return;
    }
  } catch (_) {
    // Fall through to app home if profile fetch fails.
  }
  Get.offAllNamed(AppRoutes.home);
}
