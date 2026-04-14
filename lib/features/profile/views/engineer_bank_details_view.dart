import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/engineer_bank_details_controller.dart';

class EngineerBankDetailsView extends GetView<EngineerBankDetailsController> {
  const EngineerBankDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('engineer_bank_details'.tr, style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() => _StatusBanner(
                      status: controller.payoutStatus.value,
                      adminMessage: controller.payoutAdminMessage.value,
                    )),
                const SizedBox(height: 20),
                Text(
                  'engineer_bank_details_subtitle'.tr,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AsasBankDropdown(
                    value: controller.selectedBankId.value.isEmpty ? null : controller.selectedBankId.value,
                    onChanged: (v) => controller.selectedBankId.value = v ?? '',
                    validator: controller.validateBank,
                  ),
                ),
                const SizedBox(height: 20),
                AsasTextField(
                  controller: controller.accountNameController,
                  hintText: 'payout_account_name'.tr,
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  validator: controller.validateAccountName,
                ),
                const SizedBox(height: 20),
                AsasTextField(
                  controller: controller.ibanController,
                  hintText: 'payout_iban'.tr,
                  prefixIcon: Icon(Icons.numbers_rounded, color: AppColors.textSecondary),
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z\s]')),
                  ],
                  validator: controller.validateIban,
                ),
                const SizedBox(height: 8),
                Text(
                  'payout_iban_hint'.tr,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 32),
                Obx(
                  () => AsasButton(
                    label: 'save'.tr,
                    isLoading: controller.isSaving.value,
                    onPressed: controller.isSaving.value ? null : controller.save,
                  ),
                ),
                const SizedBox(height: 24),
                _AdminNote(),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({this.status, this.adminMessage});

  final String? status;
  final String? adminMessage;

  @override
  Widget build(BuildContext context) {
    final s = status ?? PayoutVerificationStatus.none;
    Color bg;
    Color fg;
    String label;
    switch (s) {
      case PayoutVerificationStatus.approved:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.greenAccent.shade200;
        label = 'payout_status_approved'.tr;
        break;
      case PayoutVerificationStatus.rejected:
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red.shade300;
        label = 'payout_status_rejected'.tr;
        break;
      case PayoutVerificationStatus.pending:
        bg = AppColors.primaryAccent.withValues(alpha: 0.15);
        fg = AppColors.primaryAccent;
        label = 'payout_status_pending'.tr;
        break;
      default:
        bg = AppColors.cardBackground;
        fg = AppColors.textSecondary;
        label = 'payout_status_none'.tr;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s == PayoutVerificationStatus.approved
                    ? Icons.check_circle_outline
                    : s == PayoutVerificationStatus.rejected
                        ? Icons.cancel_outlined
                        : s == PayoutVerificationStatus.pending
                            ? Icons.hourglass_top_rounded
                            : Icons.info_outline,
                color: fg,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          if (s == PayoutVerificationStatus.rejected &&
              adminMessage != null &&
              adminMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'payout_admin_message'.tr,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              adminMessage!.trim(),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.admin_panel_settings_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'payout_admin_note'.tr,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
