import 'dart:async';

import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/routing/auth_navigation.dart';
import '../../../core/services/auth_service.dart';

class SplashController extends GetxController {
  static const _splashDuration = Duration(milliseconds: 2500);

  @override
  void onReady() {
    super.onReady();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(_splashDuration);
    if (!Get.isRegistered<AuthService>()) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    final isLoggedIn = Get.find<AuthService>().currentUser != null;
    if (!isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    await navigateToRoleHome();
  }
}
