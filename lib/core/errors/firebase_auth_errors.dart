import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Maps Firebase Auth errors to user-friendly localized messages
class FirebaseAuthErrors {
  FirebaseAuthErrors._();

  static String getMessage(dynamic error, [String fallback = 'error_unknown']) {
    if (error is FirebaseAuthException) {
      return _getAuthMessage(error.code);
    }
    if (error is FirebaseException) {
      return _getFirebaseMessage(error.code);
    }
    return fallback.tr;
  }

  static String _getAuthMessage(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'error_otp_invalid'.tr;
      case 'invalid-verification-id':
        return 'error_otp_expired'.tr;
      case 'session-expired':
        return 'error_session_expired'.tr;
      case 'too-many-requests':
        return 'error_too_many_requests'.tr;
      case 'quota-exceeded':
        return 'error_quota_exceeded'.tr;
      case 'invalid-phone-number':
        return 'error_invalid_phone'.tr;
      case 'missing-phone-number':
        return 'error_phone_required'.tr;
      case 'captcha-check-failed':
        return 'error_captcha_failed'.tr;
      case 'network-request-failed':
        return 'error_network'.tr;
      case 'user-disabled':
        return 'error_account_disabled'.tr;
      case 'operation-not-allowed':
        return 'error_operation_not_allowed'.tr;
      case 'account-exists-with-different-credential':
        return 'error_account_exists_different'.tr;
      case 'invalid-credential':
        return 'error_invalid_credential'.tr;
      case 'user-not-found':
        return 'error_user_not_found'.tr;
      case 'wrong-password':
        return 'error_wrong_password'.tr;
      case 'email-already-in-use':
        return 'error_email_in_use'.tr;
      case 'credential-already-in-use':
        return 'error_credential_in_use'.tr;
      case 'requires-recent-login':
        return 'error_requires_recent_login'.tr;
      case 'popup-closed-by-user':
      case 'popup-cancelled-by-user':
        return 'error_sign_in_cancelled'.tr;
      case 'sign-in-failed':
        return 'error_sign_in_failed'.tr;
      case 'internal-error':
        return 'error_internal'.tr;
      default:
        return 'error_unknown'.tr;
    }
  }

  static String _getFirebaseMessage(String? code) {
    final c = code ?? '';
    if (c.contains('permission-denied')) return 'error_permission_denied'.tr;
    if (c.contains('unavailable')) return 'error_service_unavailable'.tr;
    return 'error_unknown'.tr;
  }
}
