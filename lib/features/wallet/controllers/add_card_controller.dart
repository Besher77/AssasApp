import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moyasar/moyasar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/moyasar_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';

/// Controller for adding a new card (1 SAR verification charge, refunded to wallet)
class AddCardController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final isSubmitting = false.obs;
  final numberLength = 0.obs;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final numberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvcController = TextEditingController();

  static const double addCardAmount = 1.0;
  static final cardNumberFormatter = CardNumberInputFormatter();
  static final expiryFormatter = ExpiryInputFormatter();

  @override
  void onClose() {
    nameController.dispose();
    numberController.dispose();
    expiryController.dispose();
    cvcController.dispose();
    super.onClose();
  }

  String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'name_required'.tr;
    final parts = v.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return 'both_names_required'.tr;
    return null;
  }

  String? validateCardNumber(String? v) {
    if (v == null || v.isEmpty) return 'card_number_required'.tr;
    final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return 'invalid_card_number'.tr;
    if (!_isValidLuhn(cleaned)) return 'invalid_card_number'.tr;
    return null;
  }

  String? validateExpiry(String? v) {
    if (v == null || v.isEmpty) return 'expiry_required'.tr;
    final cleaned = v.replaceAll(RegExp(r'[^0-9/]'), '');
    int month;
    int year;
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/').map((e) => e.trim()).toList();
      if (parts.length != 2) return 'invalid_expiry'.tr;
      final m = int.tryParse(parts[0]);
      final y = int.tryParse(parts[1]);
      if (m == null || y == null) return 'invalid_expiry'.tr;
      month = m;
      year = y;
    } else if (cleaned.length >= 4) {
      month = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      year = int.tryParse(cleaned.substring(2, 4)) ?? 0;
    } else {
      return 'invalid_expiry'.tr;
    }
    if (month < 1 || month > 12) return 'invalid_expiry'.tr;
    final fullYear = year < 100 ? 2000 + year : year;
    final expiry = DateTime(fullYear, month);
    if (expiry.isBefore(DateTime.now())) return 'expired_card'.tr;
    return null;
  }

  String? validateCvc(String? v) {
    if (v == null || v.isEmpty) return 'cvc_required'.tr;
    if (v.length < 3 || v.length > 4) return 'invalid_cvc'.tr;
    return null;
  }

  void onNumberChanged(String value) {
    numberLength.value = value.replaceAll(RegExp(r'[^0-9]'), '').length;
  }

  bool _isValidLuhn(String s) {
    int sum = 0;
    for (var i = 0; i < s.length; i++) {
      int d = int.parse(s[s.length - 1 - i]);
      if (i % 2 == 1) d *= 2;
      sum += d > 9 ? d - 9 : d;
    }
    return sum % 10 == 0;
  }

  Future<void> submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    formKey.currentState!.save();
    FocusScope.of(context).unfocus();

    final uid = _auth.currentUserId;
    if (uid == null) {
      _showError('error'.tr);
      return;
    }

    final number = numberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final expiryStr = expiryController.text.replaceAll(RegExp(r'[^0-9/]'), '');
    String month = '';
    String year = '';
    if (expiryStr.contains('/')) {
      final parts = expiryStr.split('/').map((e) => e.trim()).toList();
      month = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '';
      year = parts.length > 1 ? parts[1].padLeft(2, '0') : '';
    } else if (expiryStr.length >= 4) {
      month = expiryStr.substring(0, 2).padLeft(2, '0');
      year = expiryStr.substring(2).padLeft(2, '0');
    }

    final cardData = CardFormModel(
      name: nameController.text.trim(),
      number: number,
      month: month,
      year: year,
      cvc: cvcController.text.trim(),
    );

    isSubmitting.value = true;

    try {
      final amountHalalas = (addCardAmount * 100).round();
      final config = PaymentConfig(
        publishableApiKey: MoyasarConfig.publishableApiKey,
        amount: amountHalalas,
        description: 'add_card_verification'.tr,
        metadata: {'addCardOnly': 'true', 'userId': uid},
        creditCard: CreditCardConfig(saveCard: true, manual: false),
      );

      final source = CardPaymentRequestSource(
        creditCardData: cardData,
        tokenizeCard: true,
        manualPayment: false,
      );
      final request = PaymentRequest(config, source);

      final result = await Moyasar.pay(
        apiKey: config.publishableApiKey,
        paymentRequest: request,
      );

      if (result is PaymentResponse && result.status == PaymentStatus.initiated) {
        final transactionUrl = (result.source as CardPaymentResponseSource).transactionUrl;
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _ThreeDSScreen(
              transactionUrl: transactionUrl,
              onDone: (status, message) {
                if (status == PaymentStatus.paid.name || status == PaymentStatus.authorized.name) {
                  result.status = PaymentStatus.paid;
                } else {
                  result.status = PaymentStatus.failed;
                  (result.source as CardPaymentResponseSource).message = message;
                }
              },
            ),
          ),
        );
        if (!context.mounted) return;
        await _onPaymentResult(result, uid);
      } else {
        await _onPaymentResult(result, uid);
      }
    } catch (e) {
      _onPaymentResult(e, uid);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _onPaymentResult(dynamic result, String uid) async {
    if (result is PaymentResponse) {
      switch (result.status) {
        case PaymentStatus.paid:
        case PaymentStatus.captured:
        case PaymentStatus.authorized:
          final id = result.id;
          if (id.isNotEmpty && result.source is CardPaymentResponseSource) {
            final src = result.source as CardPaymentResponseSource;
            final token = src.token;
            if (token != null && token.isNotEmpty) {
              await _saveCardAndConfirm(uid, id, src);
            }
            Get.snackbar('', 'card_added_success'.tr);
            Get.back();
          } else {
            _showError('payment_failed'.tr);
          }
          break;
        case PaymentStatus.failed:
          final msg = (result.source is CardPaymentResponseSource)
              ? (result.source as CardPaymentResponseSource).message
              : null;
          _showError(msg ?? 'payment_failed'.tr);
          break;
        case PaymentStatus.initiated:
          break;
      }
      return;
    }
    _showError(_getErrorMessage(result));
  }

  Future<void> _saveCardAndConfirm(String uid, String moyasarPaymentId, CardPaymentResponseSource src) async {
    final lastFour = src.number.length >= 4 ? src.number.substring(src.number.length - 4) : '';
    if (lastFour.isEmpty) return;
    await _firestore.saveCard(
      uid,
      token: src.token ?? '',
      lastFour: lastFour,
      brand: src.company.name,
      name: src.name,
    );
    await _firestore.createAddCardConfirmation(
      moyasarPaymentId: moyasarPaymentId,
      userId: uid,
      amount: addCardAmount,
    );
  }

  String _getErrorMessage(dynamic result) {
    try {
      if (result == null) return 'payment_failed'.tr;
      if (result is ValidationError) {
        final msg = result.message;
        if (msg.isNotEmpty) return msg;
        final errs = result.errors;
        if (errs != null && errs.isNotEmpty) {
          final parts = <String>[];
          for (final e in errs.entries) {
            final v = e.value;
            final s = v is List ? v.join(', ') : v.toString();
            if (s.isNotEmpty) parts.add('${e.key}: $s');
          }
          if (parts.isNotEmpty) return parts.join('\n');
        }
        return 'validation_failed'.tr;
      }
      if (result is PaymentCanceledError) return 'payment_cancelled'.tr;
      if (result is NetworkError || result is TimeoutError) return 'error_network'.tr;
      if (result is AuthError) return 'payment_auth_error'.tr;
      final str = result.toString();
      if (str.contains('message:')) {
        final match = RegExp(r'message:\s*([^\n]+)').firstMatch(str);
        if (match != null) return match.group(1)!.trim();
      }
      if (str.contains('canceled') || str.contains('cancelled')) return 'payment_cancelled'.tr;
      if (str.contains('network') || str.contains('Network')) return 'error_network'.tr;
      if (str.contains('Entity not activated') || str.contains('live account')) {
        return 'payment_live_not_activated'.tr;
      }
      if (str.startsWith('Instance of ')) return 'payment_failed'.tr;
      return str.length > 80 ? '${str.substring(0, 80)}...' : str;
    } catch (_) {
      return 'payment_failed'.tr;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.red.shade900,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}

/// Card number formatter
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 19) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Expiry formatter MM/YY
class ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) return oldValue;
    if (digits.isEmpty) return newValue;
    final formatted = digits.length <= 2
        ? (digits.length == 2 ? '$digits/' : digits)
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ThreeDSScreen extends StatefulWidget {
  const _ThreeDSScreen({required this.transactionUrl, required this.onDone});

  final String transactionUrl;
  final void Function(String status, String message) onDone;

  @override
  State<_ThreeDSScreen> createState() => _ThreeDSScreenState();
}

class _ThreeDSScreenState extends State<_ThreeDSScreen> {
  late final WebViewController _controller = WebViewController()
    ..loadRequest(Uri.parse(widget.transactionUrl))
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(onPageFinished: (url) {
      final uri = Uri.parse(url);
      final status = uri.queryParameters['status'] ?? '';
      final message = uri.queryParameters['message'] ?? '';
      if (status.isNotEmpty) {
        widget.onDone(status, message);
        if (mounted) Navigator.pop(context);
      }
    }));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('3ds_verification'.tr, style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
