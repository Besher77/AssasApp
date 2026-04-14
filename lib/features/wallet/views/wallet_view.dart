import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/transaction_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'wallet'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBalanceCard(context),
              const SizedBox(height: 24),
              _buildActions(context),
              Obx(() {
                if (!controller.isEngineer.value ||
                    controller.withdrawalRequests.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    const SizedBox(height: 28),
                    _buildWithdrawalRequests(context),
                  ],
                );
              }),
              const SizedBox(height: 32),
              _buildTransactionHistory(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final balance = controller.wallet.value?.balance ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.3),
            AppColors.primaryAccent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'wallet_balance'.tr,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.formatAmount(balance),
            style: TextStyle(
              color: AppColors.primaryAccent,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Obx(() {
      final eng = controller.isEngineer.value;
      return Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.add_circle_outline,
              label: 'deposit'.tr,
              onTap: () => _showDepositSheet(context),
            ),
          ),
          if (eng) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _ActionCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'withdraw'.tr,
                onTap: () => _showWithdrawSheet(context),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildWithdrawalRequests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.outgoing_mail, color: AppColors.primaryAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              'withdrawal_requests_title'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...controller.withdrawalRequests.map((r) {
          final amount = (r['amount'] as num?)?.toDouble() ?? 0;
          final status = r['status'] as String? ?? 'pending';
          final msg = r['adminMessage'] as String?;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.formatAmount(amount),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'transferred'
                            ? Colors.green.withValues(alpha: 0.2)
                            : status == 'rejected'
                                ? Colors.red.withValues(alpha: 0.15)
                                : AppColors.primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.withdrawalStatusLabel(status),
                        style: TextStyle(
                          color: status == 'transferred'
                              ? Colors.greenAccent.shade200
                              : status == 'rejected'
                                  ? Colors.red.shade300
                                  : AppColors.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (status == 'rejected' && msg != null && msg.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'withdrawal_admin_reason'.tr}: ${msg.trim()}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showDepositSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'deposit'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'deposit_pay_with_card_hint'.tr,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            AsasTextField(
              controller: controller.depositAmountController,
              hintText: 'amount'.tr,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            AsasButton(
              label: 'pay_with_card'.tr,
              onPressed: () => controller.startCardDeposit(),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Obx(
          () => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'withdraw'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'withdraw_requirements_intro'.tr,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 12),
                _WithdrawCheckRow(
                  ok: controller.payoutReadyForWithdraw.value,
                  labelOk: 'withdraw_check_iban_ok'.tr,
                  labelBad: 'withdraw_check_iban_bad'.tr,
                ),
                if (!controller.payoutReadyForWithdraw.value) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Get.toNamed(AppRoutes.engineerBankDetails);
                    },
                    icon: Icon(Icons.account_balance, color: AppColors.primaryAccent, size: 20),
                    label: Text(
                      'withdraw_open_bank_settings'.tr,
                      style: TextStyle(color: AppColors.primaryAccent),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'withdraw_amount_gt_100_hint'.tr,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                AsasTextField(
                  controller: controller.withdrawAmountController,
                  hintText: 'amount'.tr,
                  keyboardType: TextInputType.number,
                ),
                if (controller.payoutReadyForWithdraw.value) ...[
                  const SizedBox(height: 8),
                  Text(
                    'withdraw_uses_saved_iban'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                AsasButton(
                  label: 'withdraw'.tr,
                  onPressed: controller.payoutReadyForWithdraw.value
                      ? () async {
                          await controller.withdraw();
                          if (Get.isBottomSheetOpen ?? false) Get.back();
                        }
                      : null,
                  isLoading: controller.isWithdrawing.value,
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildTransactionHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: AppColors.primaryAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              'transaction_history'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: AppColors.textSecondary, size: 40),
                const SizedBox(width: 16),
                Text(
                  'no_transactions'.tr,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...controller.transactions.map((t) => _TransactionTile(tx: t)),
      ],
    );
  }
}

class _WithdrawCheckRow extends StatelessWidget {
  const _WithdrawCheckRow({
    required this.ok,
    required this.labelOk,
    required this.labelBad,
  });

  final bool ok;
  final String labelOk;
  final String labelBad;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.highlight_off,
          size: 22,
          color: ok ? Colors.greenAccent.shade200 : Colors.orange.shade300,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            ok ? labelOk : labelBad,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryAccent, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final TransactionDocument tx;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();
    final isCredit = tx.isCredit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.getTransactionTypeLabel(tx.type),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (controller.transactionSubtitle(tx).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    controller.transactionSubtitle(tx),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${controller.formatAmount(tx.amount)}',
            style: TextStyle(
              color: isCredit ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
