import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import 'wallet_controller.dart';

/// Card payment flow for wallet top-up (Moyasar). Used by [CardPaymentView] when opened from wallet.
class WalletDepositPaymentController extends GetxController {
  WalletDepositPaymentController({required this.depositAmount});

  final double depositAmount;

  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final isPaying = false.obs;

  double? get amount => depositAmount > 0 ? depositAmount : null;

  String formatAmount(double a) => '${a.toStringAsFixed(2)} ${'currency_sar'.tr}';

  Future<void> onCardPaymentSuccess(String moyasarPaymentId) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    final amt = amount;
    if (amt == null || amt <= 0) return;

    isPaying.value = true;
    try {
      final confId = await _firestore.createWalletTopupConfirmation(
        moyasarPaymentId: moyasarPaymentId,
        userId: uid,
        amount: amt,
      );
      final completed = await _firestore.waitForCardPaymentCompletion(confId);
      if (completed) {
        await _finishDepositSuccess(amt, uid);
      } else {
        Get.snackbar('error'.tr, 'payment_processing_timeout'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isPaying.value = false;
    }
  }

  /// Saved card path: Cloud Function credited wallet without confirmation doc.
  void onPaymentAlreadyProcessedByCloud() {
    final uid = _auth.currentUserId;
    final amt = amount;
    if (uid == null || amt == null) return;
    _finishDepositSuccess(amt, uid);
  }

  Future<void> _finishDepositSuccess(double amt, String uid) async {
    try {
      await _notif.notifyWalletDeposit(userId: uid, amount: amt);
    } catch (_) {}
    if (Get.isRegistered<WalletController>()) {
      await Get.find<WalletController>().load();
    }
    Get.snackbar('success'.tr, 'deposit_success'.tr);
    if (Get.currentRoute == AppRoutes.cardPayment) {
      Get.back();
    }
    Future.microtask(() {
      if (Get.isRegistered<WalletDepositPaymentController>()) {
        Get.delete<WalletDepositPaymentController>(force: true);
      }
    });
  }
}
