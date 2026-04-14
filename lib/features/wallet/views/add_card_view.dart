import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moyasar/moyasar.dart';

import '../../../core/config/moyasar_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/add_card_controller.dart';

CardCompany _getCardCompany(String number) {
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return CardCompany.visa;
  }
  if (digits.startsWith('34') || digits.startsWith('37')) {
    return CardCompany.amex;
  }
  if (digits.startsWith('4201') || digits.startsWith('5043') || digits.startsWith('5297') ||
      digits.startsWith('5859') || digits.startsWith('5889') || digits.startsWith('6051') ||
      digits.startsWith('50') || digits.startsWith('60')) {
    return CardCompany.mada;
  }
  if (digits.startsWith('51') || digits.startsWith('52') || digits.startsWith('53') ||
      digits.startsWith('54') || digits.startsWith('55')) {
    return CardCompany.master;
  }
  if (digits.length >= 4) {
    final n = int.tryParse(digits.substring(0, 4));
    if (n != null && n >= 2221 && n <= 2720) return CardCompany.master;
  }
  if (digits.startsWith('4')) {
    return CardCompany.visa;
  }
  if (digits.startsWith('5')) {
    return CardCompany.master;
  }
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

class AddCardView extends GetView<AddCardController> {
  const AddCardView({super.key});

  @override
  Widget build(BuildContext context) {
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
        if (controller.isSubmitting.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: controller.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AmountCard(amount: AddCardController.addCardAmount),
                  const SizedBox(height: 12),
                  Text(
                    'add_card_verification_info'.tr,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
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
                    controller: controller.nameController,
                    label: 'name_on_card'.tr,
                    hintText: 'John Doe',
                    textInputAction: TextInputAction.next,
                    validator: controller.validateName,
                  ),
                  const SizedBox(height: 20),
                  AsasTextField(
                    controller: controller.numberController,
                    label: 'card_number'.tr,
                    hintText: '4111 1111 1111 1111',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: controller.validateCardNumber,
                    inputFormatters: [
                      AddCardController.cardNumberFormatter,
                      LengthLimitingTextInputFormatter(19 + 4),
                    ],
                    suffixIcon: Obx(() {
                      if (controller.numberLength.value >= 4) {
                        return _buildCardIcon(_getCardCompany(controller.numberController.text));
                      }
                      return const SizedBox.shrink();
                    }),
                    onChanged: controller.onNumberChanged,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AsasTextField(
                          controller: controller.expiryController,
                          label: 'expiry'.tr,
                          hintText: 'MM/YY',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: controller.validateExpiry,
                          inputFormatters: [
                            AddCardController.expiryFormatter,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          onChanged: (_) {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AsasTextField(
                          controller: controller.cvcController,
                          label: 'cvc'.tr,
                          hintText: '123',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: controller.validateCvc,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => controller.submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_card, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'add_card_pay'.trParams({'amount': '1 SAR'}),
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
        icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'add_card'.tr,
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount});

  final double amount;

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
            'verification_charge'.tr,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          Text(
            '$amount SAR',
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
