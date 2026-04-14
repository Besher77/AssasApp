import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/project_options.dart' show getDeliveryDurationDays;
import '../../../core/routes/app_routes.dart';
import '../../../core/models/offer_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

class AcceptOfferPaymentController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final amountController = TextEditingController();
  final isPaying = false.obs;
  final walletBalance = 0.0.obs;

  OfferDocument? offer;
  ProjectDocument? project;

  @override
  void onReady() {
    super.onReady();
    loadWallet();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  double? get amount {
    final parsed = offer?.parsedAmount;
    if (parsed != null && parsed > 0) return parsed;
    return double.tryParse(amountController.text.replaceAll(',', '.'));
  }

  bool get canPayFromWallet => walletBalance.value >= (amount ?? 0) && (amount ?? 0) > 0;

  Future<void> loadWallet() async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    try {
      final wallet = await _firestore.getOrCreateWallet(uid);
      walletBalance.value = wallet.balance;
    } catch (_) {}
  }

  Future<bool> payFromWallet() async {
    final amt = amount;
    if (amt == null || amt <= 0) {
      Get.snackbar('error'.tr, 'invalid_amount'.tr);
      return false;
    }
    if (offer == null || project == null) return false;
    final uid = _auth.currentUserId;
    if (uid == null) return false;

    if (walletBalance.value < amt) {
      Get.snackbar('error'.tr, 'insufficient_balance'.tr);
      return false;
    }

    isPaying.value = true;
    try {
      final days = project!.deliveryDuration != null && project!.deliveryDuration!.isNotEmpty
          ? getDeliveryDurationDays(project!.deliveryDuration!)
          : 30;
      final requestId = await _firestore.createPaymentRequest(
        fromUserId: uid,
        toUserId: offer!.engineerId,
        amount: amt,
        projectId: project!.id,
        offerId: offer!.id,
        deliveryDurationDays: days,
      );
      final completed = await _firestore.waitForPaymentCompletion(requestId);
      if (completed) {
        _acceptOffer();
        return true;
      }
      final err = await _firestore.getPaymentRequestError(requestId);
      final msg = err == 'insufficient_balance'
          ? 'insufficient_balance'.tr
          : (err != null && err.isNotEmpty ? err : 'payment_processing_timeout'.tr);
      Get.snackbar('error'.tr, msg);
      return false;
    } catch (e) {
      if (e.toString().contains('insufficient_balance')) {
        Get.snackbar('error'.tr, 'insufficient_balance'.tr);
      } else {
        Get.snackbar('error'.tr, e.toString());
      }
      return false;
    } finally {
      isPaying.value = false;
    }
  }

  Future<void> payWithCard() async {
    final amt = amount;
    if (amt == null || amt <= 0) {
      Get.snackbar('error'.tr, 'invalid_amount'.tr);
      return;
    }
    if (offer == null || project == null) return;
    Get.toNamed(AppRoutes.cardPayment);
  }

  Future<void> onCardPaymentSuccess(String moyasarPaymentId) async {
    if (offer == null || project == null) return;
    final uid = _auth.currentUserId;
    if (uid == null) return;
    final amt = amount ?? 0;
    if (amt <= 0) return;

    isPaying.value = true;
    try {
      final days = project!.deliveryDuration != null && project!.deliveryDuration!.isNotEmpty
          ? getDeliveryDurationDays(project!.deliveryDuration!)
          : 30;
      final confId = await _firestore.createCardPaymentConfirmation(
        moyasarPaymentId: moyasarPaymentId,
        fromUserId: uid,
        toUserId: offer!.engineerId,
        amount: amt,
        projectId: project!.id,
        offerId: offer!.id,
        deliveryDurationDays: days,
      );
      final completed = await _firestore.waitForCardPaymentCompletion(confId);
      if (completed) {
        _acceptOffer();
      } else {
        Get.snackbar('error'.tr, 'payment_processing_timeout'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isPaying.value = false;
    }
  }

  /// Called when payWithSavedCard Cloud Function already updated the project (status=paid)
  void onPaymentAlreadyProcessedByCloud() {
    _acceptOffer();
  }

  void _acceptOffer() {
    if (offer == null) return;
    _notif.notifyOfferAccepted(
      engineerUserId: offer!.engineerId,
      projectId: offer!.projectId,
      offerId: offer!.id,
    );
    Get.back(result: true);
    Get.snackbar('success'.tr, 'offer_accepted'.tr);
  }

  String formatAmount(double a) => '${a.toStringAsFixed(2)} ${'currency_sar'.tr}';
}
