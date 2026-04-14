import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/moyasar_config.dart';
import '../../../core/models/transaction_document.dart';
import '../../../core/models/wallet_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

class WalletController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final wallet = Rxn<WalletDocument>();
  final transactions = <TransactionDocument>[].obs;
  final withdrawalRequests = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isWithdrawing = false.obs;
  final isEngineer = false.obs;

  /// Verified IBAN (admin approved) — required before withdrawal request.
  final payoutReadyForWithdraw = false.obs;

  final depositAmountController = TextEditingController();
  final withdrawAmountController = TextEditingController();

  StreamSubscription<List<Map<String, dynamic>>>? _withdrawalSub;
  StreamSubscription<UserDocument?>? _userSub;

  /// Amount must be **strictly greater** than this (SAR), e.g. 100.01+.
  static double get minWithdrawExclusiveSar => FirestoreService.withdrawalMinExclusiveSar;

  void _applyUserPayoutState(UserDocument? u) {
    if (u == null) {
      isEngineer.value = false;
      payoutReadyForWithdraw.value = false;
      return;
    }
    isEngineer.value = u.userType == 'engineer';
    final ibanOk = u.payoutIban != null && u.payoutIban!.trim().isNotEmpty;
    payoutReadyForWithdraw.value = u.userType == 'engineer' &&
        u.payoutStatus == PayoutVerificationStatus.approved &&
        ibanOk;
  }

  @override
  void onClose() {
    _withdrawalSub?.cancel();
    _userSub?.cancel();
    depositAmountController.dispose();
    withdrawAmountController.dispose();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    final uid = _auth.currentUserId;
    if (uid != null) {
      _withdrawalSub = _firestore.streamWithdrawalRequests(uid).listen((list) {
        withdrawalRequests.value = list;
      });
      _userSub = _firestore.streamUser(uid).listen(_applyUserPayoutState);
    }
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
      final user = await _firestore.getUser(uid);
      _applyUserPayoutState(user);

      wallet.value = await _firestore.getOrCreateWallet(uid);
      transactions.value = await _firestore.getUserTransactions(uid);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Top-up wallet only after successful Moyasar card payment (see [WalletDepositPaymentController]).
  Future<void> startCardDeposit() async {
    final amount =
        double.tryParse(depositAmountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      Get.snackbar('error'.tr, 'invalid_amount'.tr);
      return;
    }
    if (amount < 1) {
      Get.snackbar('error'.tr, 'deposit_min_amount_sar'.tr);
      return;
    }
    if (_auth.currentUserId == null) return;
    if (!MoyasarConfig.isConfigured) {
      Get.snackbar('error'.tr, 'moyasar_not_configured'.tr);
      return;
    }

    final amt = amount;
    depositAmountController.clear();
    if (Get.isBottomSheetOpen ?? false) Get.back();
    await Get.toNamed(
      AppRoutes.cardPayment,
      arguments: {'mode': 'wallet', 'amount': amt},
    );
    await load();
  }

  Future<void> withdraw() async {
    if (!isEngineer.value) {
      Get.snackbar('error'.tr, 'withdraw_engineers_only'.tr);
      return;
    }
    if (!payoutReadyForWithdraw.value) {
      Get.snackbar('error'.tr, 'withdraw_iban_not_ready'.tr);
      return;
    }
    final amount =
        double.tryParse(withdrawAmountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      Get.snackbar('error'.tr, 'invalid_amount'.tr);
      return;
    }
    if (amount <= minWithdrawExclusiveSar) {
      Get.snackbar('error'.tr, 'withdraw_amount_gt_100'.tr);
      return;
    }
    final uid = _auth.currentUserId;
    if (uid == null) return;

    final w = wallet.value;
    if (w == null || w.balance < amount) {
      Get.snackbar('error'.tr, 'insufficient_balance'.tr);
      return;
    }

    isWithdrawing.value = true;
    try {
      await _firestore.createWithdrawalRequest(
        uid,
        amount,
        description: 'withdraw_description'.tr,
      );
      withdrawAmountController.clear();
      await load();
      try {
        await _notif.notifyWithdrawalSubmitted(userId: uid, amount: amount);
      } catch (_) {}
      Get.snackbar('success'.tr, 'withdraw_success'.tr);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('withdraw_engineers_only')) {
        Get.snackbar('error'.tr, 'withdraw_engineers_only'.tr);
      } else if (msg.contains('withdraw_iban_not_approved')) {
        Get.snackbar('error'.tr, 'withdraw_iban_not_ready'.tr);
      } else if (msg.contains('withdraw_min_amount')) {
        Get.snackbar('error'.tr, 'withdraw_amount_gt_100'.tr);
      } else if (msg.contains('insufficient_balance')) {
        Get.snackbar('error'.tr, 'insufficient_balance'.tr);
      } else {
        Get.snackbar('error'.tr, e.toString());
      }
    } finally {
      isWithdrawing.value = false;
    }
  }

  String formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} ${'currency_sar'.tr}';
  }

  String withdrawalStatusLabel(String? status) {
    switch (status) {
      case 'transferred':
        return 'withdrawal_status_transferred'.tr;
      case 'rejected':
        return 'withdrawal_status_rejected'.tr;
      case 'pending':
        return 'withdrawal_status_pending'.tr;
      default:
        return status ?? '';
    }
  }

  String getTransactionTypeLabel(String type) {
    switch (type) {
      case 'deposit':
        return 'transaction_deposit'.tr;
      case 'withdraw':
        return 'transaction_withdraw'.tr;
      case 'payment_out':
        return 'transaction_payment_out'.tr;
      case 'payment_in':
        return 'transaction_payment_in'.tr;
      case 'refund':
        return 'transaction_refund'.tr;
      case 'admin_credit':
        return 'transaction_admin_credit'.tr;
      case 'admin_debit':
        return 'transaction_admin_debit'.tr;
      default:
        return type;
    }
  }

  String transactionSubtitle(TransactionDocument tx) {
    if (tx.type == 'withdraw' && tx.status == 'pending') {
      return 'transaction_withdraw_pending'.tr;
    }
    return tx.description ?? '';
  }
}
