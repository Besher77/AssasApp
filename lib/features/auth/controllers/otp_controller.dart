import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/models/user_type.dart';
import '../../../core/routing/auth_navigation.dart';
import '../../../core/services/auth_service.dart';

class OtpController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  String get phone => Get.arguments?['phone'] ?? '';
  String get verificationId =>
      _verificationId.value.isNotEmpty ? _verificationId.value : (Get.arguments?['verificationId'] ?? '');
  bool get isSignup => Get.arguments?['isSignup'] == true;

  final _verificationId = ''.obs;

  final isLoading = false.obs;
  final canResend = true.obs;
  int _resendCountdown = 60;

  @override
  void onInit() {
    super.onInit();
    _verificationId.value = Get.arguments?['verificationId'] ?? '';
    _startResendTimer();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _tryInstantAndroidVerification();
    });
  }

  /// Android SMS auto-retrieval: complete sign-in without typing the code.
  Future<void> _tryInstantAndroidVerification() async {
    final vid = verificationId;
    if (vid.isEmpty || isLoading.value) return;
    final cred = _authService.getPendingCredentialIfMatches(vid);
    if (cred == null) return;

    isLoading.value = true;
    try {
      bool success;
      if (isSignup) {
        final args = Get.arguments!;
        success = await _authService.verifyOtpAndSignupWithCredential(
          phone: phone,
          credential: cred,
          userType: args['userType'] as UserType,
          name: args['name'] as String,
          city: args['city'] as String,
          membershipNumber: args['membershipNumber'] as String?,
          yearsExperience: args['yearsExperience'] as String?,
          specialization: args['specialization'] as String?,
          bio: args['bio'] as String?,
        );
      } else {
        success = await _authService.verifyOtpWithCredential(phone, cred);
      }
      if (success) {
        _authService.clearPendingPhoneCredential();
        await navigateToRoleHome();
      } else {
        Get.snackbar('error'.tr, 'otp_invalid'.tr);
      }
    } on AuthException catch (e) {
      await _onAuthExceptionForOtp(e);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _onAuthExceptionForOtp(AuthException e) async {
    if (e.code == 'account_not_registered') {
      _authService.clearPendingPhoneCredential();
      Get.snackbar('error'.tr, e.message);
      await Get.offAllNamed('/signup', arguments: {'prefillPhone': phone});
      return;
    }
    Get.snackbar('error'.tr, e.message);
  }

  void _startResendTimer() {
    canResend.value = false;
    _resendCountdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _resendCountdown--;
      if (_resendCountdown <= 0) {
        canResend.value = true;
        return false;
      }
      return true;
    });
  }

  Future<void> verifyOtp(String code) async {
    if (code.length != 6) return;

    final vid = verificationId;
    if (vid.isEmpty) {
      Get.snackbar('error'.tr, 'error_otp_expired'.tr);
      return;
    }

    isLoading.value = true;
    try {
      bool success;
      if (isSignup) {
        success = await _authService.verifyOtpAndSignup(
          phone: phone,
          code: code,
          verificationId: vid,
          userType: Get.arguments!['userType'] as UserType,
          name: Get.arguments!['name'] as String,
          city: Get.arguments!['city'] as String,
          membershipNumber: Get.arguments?['membershipNumber'] as String?,
          yearsExperience: Get.arguments?['yearsExperience'] as String?,
          specialization: Get.arguments?['specialization'] as String?,
          bio: Get.arguments?['bio'] as String?,
        );
      } else {
        success = await _authService.verifyOtp(phone, code, vid);
      }
      if (success) {
        _authService.clearPendingPhoneCredential();
        await navigateToRoleHome();
      } else {
        Get.snackbar('error'.tr, 'otp_invalid'.tr);
      }
    } on AuthException catch (e) {
      await _onAuthExceptionForOtp(e);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value) return;

    isLoading.value = true;
    try {
      final newVerificationId = await _authService.sendOtp(phone);
      _verificationId.value = newVerificationId;
      _startResendTimer();
      Get.snackbar('', 'otp_resent'.tr);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _tryInstantAndroidVerification();
      });
    } on AuthException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
