import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

/// Normalizes IBAN: uppercase, no spaces.
String normalizeIbanInput(String raw) {
  return raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
}

/// Saudi IBAN: SA + 22 alphanumeric (typically digits) = 24 characters.
bool isValidSaudiIban(String normalized) {
  return RegExp(r'^SA[0-9A-Z]{22}$').hasMatch(normalized);
}

class EngineerBankDetailsController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final formKey = GlobalKey<FormState>();
  final accountNameController = TextEditingController();
  final ibanController = TextEditingController();

  final selectedBankId = ''.obs;
  final payoutStatus = Rxn<String>();
  final payoutAdminMessage = Rxn<String>();
  final isSaving = false.obs;
  final isLoading = true.obs;

  StreamSubscription<UserDocument?>? _userSub;
  bool _hydrated = false;

  @override
  void onInit() {
    super.onInit();
    final uid = _auth.currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    _userSub = _firestore.streamUser(uid).listen((u) {
      if (u == null) {
        isLoading.value = false;
        return;
      }
      payoutStatus.value = u.payoutStatus;
      payoutAdminMessage.value = u.payoutAdminMessage;
      if (!_hydrated) {
        _hydrated = true;
        selectedBankId.value = u.payoutBankId ?? '';
        accountNameController.text = u.payoutAccountName ?? '';
        ibanController.text = u.payoutIban ?? '';
      }
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _userSub?.cancel();
    accountNameController.dispose();
    ibanController.dispose();
    super.onClose();
  }

  String? validateBank(String? v) {
    if (v == null || v.isEmpty) return 'payout_bank_required'.tr;
    return null;
  }

  String? validateAccountName(String? v) {
    if (v == null || v.trim().isEmpty) return 'account_name_required'.tr;
    return null;
  }

  String? validateIban(String? v) {
    if (v == null || v.trim().isEmpty) return 'iban_required'.tr;
    final n = normalizeIbanInput(v);
    if (!isValidSaudiIban(n)) return 'iban_invalid_saudi'.tr;
    return null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final uid = _auth.currentUserId;
    if (uid == null) return;

    isSaving.value = true;
    try {
      await _firestore.submitEngineerPayoutDetails(
        uid: uid,
        bankId: selectedBankId.value,
        accountName: accountNameController.text.trim(),
        iban: normalizeIbanInput(ibanController.text),
      );
      Get.snackbar('', 'payout_submitted'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSaving.value = false;
    }
  }
}
