import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moyasar/moyasar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/moyasar_config.dart';
import '../../../core/constants/project_options.dart' show getDeliveryDurationDays;
import '../../../core/models/saved_card_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../wallet/controllers/wallet_deposit_payment_controller.dart';
import '../controllers/accept_offer_payment_controller.dart';

/// Card type from number - Visa, Mada, Mastercard, Amex
CardCompany _getCardCompany(String number) {
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return CardCompany.visa;
  if (digits.startsWith('34') || digits.startsWith('37')) return CardCompany.amex;
  if (digits.startsWith('4201') || digits.startsWith('5043') || digits.startsWith('5297') ||
      digits.startsWith('5859') || digits.startsWith('5889') || digits.startsWith('6051') ||
      digits.startsWith('50') || digits.startsWith('60')) return CardCompany.mada;
  if (digits.startsWith('51') || digits.startsWith('52') || digits.startsWith('53') ||
      digits.startsWith('54') || digits.startsWith('55')) return CardCompany.master;
  if (digits.length >= 4) {
    final n = int.tryParse(digits.substring(0, 4));
    if (n != null && n >= 2221 && n <= 2720) return CardCompany.master;
  }
  if (digits.startsWith('4')) return CardCompany.visa;
  if (digits.startsWith('5')) return CardCompany.master;
  return CardCompany.visa;
}

Widget _buildCardIcon(CardCompany company) {
  final (String label, Color color) = switch (company) {
    CardCompany.visa => ('VISA', Colors.blue),
    CardCompany.master => ('MC', Colors.orange),
    CardCompany.mada => ('Mada', Colors.green),
    CardCompany.amex => ('AMEX', Colors.blue.shade900),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

/// Formats card number with space every 4 digits
class _CardNumberInputFormatter extends TextInputFormatter {
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

/// Formats expiry as MM/YY - adds "/" after month (2 digits) so user can type year directly
class _ExpiryInputFormatter extends TextInputFormatter {
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

class CardPaymentView extends StatefulWidget {
  const CardPaymentView({super.key});

  @override
  State<CardPaymentView> createState() => _CardPaymentViewState();
}

class _CardPaymentViewState extends State<CardPaymentView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isSubmitting = false;
  bool _saveCard = false;
  SavedCardDocument? _selectedSavedCard;
  List<SavedCardDocument> _savedCards = [];

  bool get _walletMode => Get.isRegistered<WalletDepositPaymentController>();

  AcceptOfferPaymentController get _accept => Get.find<AcceptOfferPaymentController>();

  WalletDepositPaymentController get _walletDep => Get.find<WalletDepositPaymentController>();

  double? get _payAmt => _walletMode ? _walletDep.amount : _accept.amount;

  void _onMoyasarSuccess(String paymentId) {
    if (_walletMode) {
      _walletDep.onCardPaymentSuccess(paymentId);
    } else {
      _accept.onCardPaymentSuccess(paymentId);
    }
  }

  void _onSavedCardPaidByCloud() {
    if (_walletMode) {
      _walletDep.onPaymentAlreadyProcessedByCloud();
    } else {
      _accept.onPaymentAlreadyProcessedByCloud();
    }
  }

  String _formatAmount(double a) => _walletMode ? _walletDep.formatAmount(a) : _accept.formatAmount(a);

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    final uid = Get.find<AuthService>().currentUserId;
    if (uid == null) return;
    try {
      final cards = await Get.find<FirestoreService>().getSavedCards(uid);
      if (mounted) setState(() => _savedCards = cards);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amt = _payAmt ?? 0;
    if (amt <= 0) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: _buildAppBar(),
        body: Center(
          child: Text('invalid_amount'.tr, style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    if (!MoyasarConfig.isConfigured) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Text(
              'moyasar_not_configured'.tr,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (_walletMode ? _walletDep.isPaying.value : _accept.isPaying.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AmountCard(amount: amt, formatter: _formatAmount),
                  const SizedBox(height: 28),
                  if (_savedCards.isNotEmpty) ...[
                    Text(
                      'saved_cards'.tr,
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._savedCards.map((c) => _SavedCardTile(
                      card: c,
                      isSelected: _selectedSavedCard?.id == c.id,
                      onTap: () => setState(() {
                        _selectedSavedCard = _selectedSavedCard?.id == c.id ? null : c;
                      }),
                    )),
                    GestureDetector(
                      onTap: () => setState(() => _selectedSavedCard = null),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _selectedSavedCard == null
                              ? AppColors.primaryAccent.withValues(alpha: 0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedSavedCard == null
                                ? AppColors.primaryAccent
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, color: AppColors.primaryAccent),
                            const SizedBox(width: 12),
                            Text('add_new_card'.tr, style: TextStyle(color: AppColors.primaryAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedSavedCard != null) ...[
                    Text(
                      'enter_cvc_to_pay'.tr,
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AsasTextField(
                      controller: _cvcController,
                      label: 'cvc'.tr,
                      hintText: '123',
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) => _validateCvc(v),
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else ...[
                  Text(
                    'enter_card_details'.tr,
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AsasTextField(
                    controller: _nameController,
                    label: 'name_on_card'.tr,
                    hintText: 'John Doe',
                    textInputAction: TextInputAction.next,
                    validator: (v) => _validateName(v),
                  ),
                  const SizedBox(height: 20),
                  AsasTextField(
                    controller: _numberController,
                    label: 'card_number'.tr,
                    hintText: '4111 1111 1111 1111',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _validateCardNumber(v),
                    inputFormatters: [
                      _CardNumberInputFormatter(),
                      LengthLimitingTextInputFormatter(19 + 4),
                    ],
                    suffixIcon: _numberController.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 4
                        ? _buildCardIcon(_getCardCompany(_numberController.text))
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AsasTextField(
                          controller: _expiryController,
                          label: 'expiry'.tr,
                          hintText: 'MM/YY',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (v) => _validateExpiry(v),
                          inputFormatters: [
                            _ExpiryInputFormatter(),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AsasTextField(
                          controller: _cvcController,
                          label: 'cvc'.tr,
                          hintText: '123',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) => _validateCvc(v),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _saveCard,
                    onChanged: (v) => setState(() => _saveCard = v ?? false),
                    title: Text('save_card_for_future'.tr, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    activeColor: AppColors.primaryAccent,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submitPayment(amt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.primaryAccent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'pay_amount'.trParams({'amount': _formatAmount(amt)}),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'secure_payment'.tr,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: Text(
        _walletMode ? 'wallet_deposit_card_title'.tr : 'pay_with_card'.tr,
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'name_required'.tr;
    final parts = v.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return 'both_names_required'.tr;
    return null;
  }

  String? _validateCardNumber(String? v) {
    if (v == null || v.isEmpty) return 'card_number_required'.tr;
    final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return 'invalid_card_number'.tr;
    if (!_isValidLuhn(cleaned)) return 'invalid_card_number'.tr;
    return null;
  }

  String? _validateExpiry(String? v) {
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

  String? _validateCvc(String? v) {
    if (v == null || v.isEmpty) return 'cvc_required'.tr;
    if (v.length < 3 || v.length > 4) return 'invalid_cvc'.tr;
    return null;
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

  Future<void> _submitPayment(double amt) async {
    if (_selectedSavedCard != null) {
      final cvcErr = _validateCvc(_cvcController.text);
      if (cvcErr != null) {
        _showError(cvcErr);
        return;
      }
      await _payWithSavedCard(amt);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();

    final number = _numberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final expiryStr = _expiryController.text.replaceAll(RegExp(r'[^0-9/]'), '');
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
      name: _nameController.text.trim(),
      number: number,
      month: month,
      year: year,
      cvc: _cvcController.text.trim(),
    );

    setState(() => _isSubmitting = true);

    try {
      final amt = _payAmt ?? 0;
      final amountHalalas = (amt * 100).round();
      final uid = Get.find<AuthService>().currentUserId ?? '';
      final config = PaymentConfig(
        publishableApiKey: MoyasarConfig.publishableApiKey,
        amount: amountHalalas,
        description: _walletMode ? 'wallet_deposit_payment_desc'.tr : 'project_payment'.tr,
        metadata: _walletMode
            ? {
                'purpose': 'wallet_topup',
                'userId': uid,
              }
            : {
                'projectId': _accept.project?.id ?? '',
                'offerId': _accept.offer?.id ?? '',
              },
        creditCard: CreditCardConfig(saveCard: _saveCard, manual: false),
      );

      final source = CardPaymentRequestSource(
        creditCardData: cardData,
        tokenizeCard: _saveCard,
        manualPayment: false,
      );
      final request = PaymentRequest(config, source);

      final result = await Moyasar.pay(
        apiKey: config.publishableApiKey,
        paymentRequest: request,
      );

      if (result is PaymentResponse && result.status == PaymentStatus.initiated) {
        final transactionUrl = (result.source as CardPaymentResponseSource).transactionUrl;
        if (mounted) {
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
          _onPaymentResult(result);
        }
      } else {
        _onPaymentResult(result);
      }
    } catch (e) {
      _onPaymentResult(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onPaymentResult(dynamic result) {
    if (result is PaymentResponse) {
      switch (result.status) {
        case PaymentStatus.paid:
        case PaymentStatus.captured:
        case PaymentStatus.authorized:
          final id = result.id;
          if (id.isNotEmpty) {
            if (_saveCard && result.source is CardPaymentResponseSource) {
              final src = result.source as CardPaymentResponseSource;
              final token = src.token;
              if (token != null && token.isNotEmpty) {
                _saveCardToFirestore(src);
              }
            }
            _onMoyasarSuccess(id);
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

  Future<void> _saveCardToFirestore(CardPaymentResponseSource src) async {
    final uid = Get.find<AuthService>().currentUserId;
    if (uid == null) return;
    try {
      final lastFour = src.number.length >= 4 ? src.number.substring(src.number.length - 4) : '';
      if (lastFour.isEmpty) return;
      await Get.find<FirestoreService>().saveCard(
        uid,
        token: src.token ?? '',
        lastFour: lastFour,
        brand: src.company.name,
        name: src.name,
      );
      await _loadSavedCards();
    } catch (_) {}
  }

  Future<void> _payWithSavedCard(double amt) async {
    if (_selectedSavedCard == null) return;
    final auth = Get.find<AuthService>();
    final uid = auth.currentUserId ?? '';
    late final String projectId;
    late final String offerId;
    late final String toUserId;
    if (_walletMode) {
      if (uid.isEmpty) {
        _showError('payment_failed'.tr);
        return;
      }
      projectId = 'wallet_topup';
      offerId = 'wallet_topup';
      toUserId = uid;
    } else {
      projectId = _accept.project?.id ?? '';
      offerId = _accept.offer?.id ?? '';
      toUserId = _accept.offer?.engineerId ?? '';
      if (projectId.isEmpty || offerId.isEmpty || toUserId.isEmpty) {
        _showError('payment_failed'.tr);
        return;
      }
    }
    if (amt <= 0 || amt.isNaN) {
      _showError('invalid_amount'.tr);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final fc = FirebaseFunctions.instance;
      final callable = fc.httpsCallable('payWithSavedCard');
      final deliveryDays = _walletMode
          ? 0
          : (_accept.project?.deliveryDuration != null
              ? getDeliveryDurationDays(_accept.project!.deliveryDuration!)
              : 30);
      final res = await callable.call(<String, dynamic>{
        'token': _selectedSavedCard!.token,
        'amount': amt.toDouble(),
        'projectId': projectId,
        'offerId': offerId,
        'toUserId': toUserId,
        'deliveryDurationDays': deliveryDays,
      });
      final data = res.data as Map<String, dynamic>?;
      final transactionUrl = data?['transactionUrl'] as String?;
      final status = data?['status'] as String?;
      if (status == 'paid' || status == 'captured' || status == 'authorized') {
        // Cloud Function already updated project; just close and notify
        _onSavedCardPaidByCloud();
      } else if (transactionUrl != null && transactionUrl.isNotEmpty && mounted) {
        final paymentId = data?['paymentId'] as String? ?? '';
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _ThreeDSScreen(
              transactionUrl: transactionUrl,
              onDone: (s, msg) {
                if (s == PaymentStatus.paid.name || s == PaymentStatus.authorized.name) {
                  _onMoyasarSuccess(paymentId);
                } else {
                  _showError(msg);
                }
              },
            ),
          ),
        );
      } else {
        _showError('payment_failed'.tr);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({required this.card, required this.isSelected, required this.onTap});

  final SavedCardDocument card;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent.withValues(alpha: 0.2) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            _buildCardIcon(card.cardCompany),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•••• •••• •••• ${card.lastFour}',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  Text(card.name, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primaryAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIcon(CardCompany company) {
    final (String label, Color color) = switch (company) {
      CardCompany.visa => ('VISA', Colors.blue),
      CardCompany.master => ('MC', Colors.orange),
      CardCompany.mada => ('Mada', Colors.green),
      CardCompany.amex => ('AMEX', Colors.blue.shade900),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount, required this.formatter});

  final double amount;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.2),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'amount'.tr,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          Text(
            formatter(amount),
            style: TextStyle(
              color: AppColors.primaryAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
