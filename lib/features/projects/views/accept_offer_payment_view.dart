import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/accept_offer_payment_controller.dart';

class AcceptOfferPaymentView extends GetView<AcceptOfferPaymentController> {
  const AcceptOfferPaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'pay_to_accept'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'pay_before_accept'.tr,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (_) {
                  final hasOfferAmount = controller.offer?.parsedAmount != null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'amount'.tr,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasOfferAmount)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            controller.formatAmount(controller.offer!.parsedAmount!),
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        AsasTextField(
                          controller: controller.amountController,
                          hintText: 'enter_amount'.tr,
                          keyboardType: TextInputType.number,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'payment_method'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _PaymentOptionCard(
                  icon: Icons.account_balance_wallet,
                  title: 'pay_from_wallet'.tr,
                  subtitle: '${'wallet_balance'.tr}: ${controller.formatAmount(controller.walletBalance.value)}',
                  enabled: controller.canPayFromWallet,
                  onTap: controller.canPayFromWallet
                      ? () async {
                          await controller.payFromWallet();
                          // On success, controller calls Get.back(result: true) in _acceptOffer
                        }
                      : null,
                  isLoading: controller.isPaying.value,
                ),
              ),
              const SizedBox(height: 12),
              _PaymentOptionCard(
                icon: Icons.credit_card,
                title: 'pay_with_card'.tr,
                subtitle: 'pay_with_card_subtitle'.tr,
                enabled: (controller.amount ?? 0) > 0,
                onTap: () => controller.payWithCard(),
              ),
              if (!controller.canPayFromWallet && (controller.amount ?? 0) > 0) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Get.toNamed('/wallet'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: AppColors.primaryAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'charge_wallet_first'.tr,
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled ? AppColors.primaryAccent.withValues(alpha: 0.5) : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (enabled ? AppColors.primaryAccent : AppColors.textSecondary).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.primaryAccent : AppColors.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryAccent,
                  ),
                )
              else if (enabled)
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryAccent),
            ],
          ),
        ),
      ),
    );
  }
}
