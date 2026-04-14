import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/routing/auth_navigation.dart';
import '../../../core/services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;

  String get fullPhone {
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    return '966$digits';
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> sendOtpAndNavigate() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final verificationId = await _authService.sendOtp(fullPhone);
      Get.toNamed('/otp', arguments: {
        'phone': fullPhone,
        'verificationId': verificationId,
      });
    } on AuthException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    try {
      final result = await _authService.loginWithGoogle();
      if (result.isNewUser) {
        Get.offAllNamed('/complete-profile', arguments: {
          'name': result.name,
          'email': result.email,
        });
      } else {
        await navigateToRoleHome();
      }
    } on AuthException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithApple() async {
    isLoading.value = true;
    try {
      final result = await _authService.loginWithApple();
      if (result.isNewUser) {
        Get.offAllNamed('/complete-profile', arguments: {
          'name': result.name,
          'email': result.email,
        });
      } else {
        await navigateToRoleHome();
      }
    } on AuthException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
