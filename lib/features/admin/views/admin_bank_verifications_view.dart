import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/firestore_service.dart'
    show PayoutVerificationStatus, UserDocument;
import '../../../core/theme/app_colors.dart';
import '../controllers/admin_bank_verifications_controller.dart';

class AdminBankVerificationsView extends GetView<AdminBankVerificationsController> {
  const AdminBankVerificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'admin_menu_bank_verifications'.tr,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('admin_bank_tab_pending'.tr),
                      selected: controller.tabIndex.value == 0,
                      onSelected: (_) => controller.tabIndex.value = 0,
                      selectedColor: AppColors.primaryAccent.withValues(alpha: 0.35),
                      labelStyle: TextStyle(
                        color: controller.tabIndex.value == 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('admin_bank_tab_history'.tr),
                      selected: controller.tabIndex.value == 1,
                      onSelected: (_) => controller.tabIndex.value = 1,
                      selectedColor: AppColors.primaryAccent.withValues(alpha: 0.35),
                      labelStyle: TextStyle(
                        color: controller.tabIndex.value == 1
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'admin_search_bank_hint'.tr,
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              controller.tabIndex.value;
              controller.searchQuery.value;
              final list = controller.tabIndex.value == 0
                  ? controller.filteredPending
                  : controller.filteredHistory;
              final baseEmpty = controller.tabIndex.value == 0
                  ? controller.engineersPending.isEmpty
                  : controller.engineersHistory.isEmpty;
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      baseEmpty
                          ? (controller.tabIndex.value == 0
                              ? 'admin_bank_verifications_empty'.tr
                              : 'admin_bank_history_empty'.tr)
                          : 'admin_search_no_results'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4),
                    ),
                  ),
                );
              }
              final isHistory = controller.tabIndex.value == 1;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final u = list[i];
                  final busy = controller.processingUid.value == u.uid;
                  return _BankVerificationCard(
                    u: u,
                    busy: busy,
                    isHistory: isHistory,
                    statusLabel: controller.payoutStatusLabel(u),
                    onOpenUser: () => controller.openUser(u.uid),
                    onApprove: () => controller.approve(u),
                    onReject: () => controller.reject(u),
                    bankLine: (label, value) => _line(label, value),
                    bankLabel: controller.bankLabel(u.payoutBankId),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankVerificationCard extends StatelessWidget {
  const _BankVerificationCard({
    required this.u,
    required this.busy,
    required this.isHistory,
    required this.statusLabel,
    required this.onOpenUser,
    required this.onApprove,
    required this.onReject,
    required this.bankLine,
    required this.bankLabel,
  });

  final UserDocument u;
  final bool busy;
  final bool isHistory;
  final String statusLabel;
  final VoidCallback onOpenUser;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final Widget Function(String label, String value) bankLine;
  final String bankLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onOpenUser,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                          child: Text(
                            u.name.isNotEmpty ? u.name.substring(0, 1).toUpperCase() : '?',
                            style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.name,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                u.phone,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: AppColors.primaryAccent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    bankLine('payout_bank'.tr, bankLabel),
                    bankLine('payout_account_name'.tr, u.payoutAccountName ?? '—'),
                    bankLine('payout_iban'.tr, u.payoutIban ?? '—'),
                    if (isHistory &&
                        u.payoutAdminMessage != null &&
                        u.payoutAdminMessage!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      bankLine('payout_admin_message'.tr, u.payoutAdminMessage!.trim()),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: !isHistory
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busy ? null : onReject,
                            child: Text('payout_status_rejected'.tr),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: busy ? null : onApprove,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              foregroundColor: Colors.black,
                            ),
                            child: busy
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : Text('admin_bank_action_approve'.tr),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (u.payoutStatus == PayoutVerificationStatus.approved)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy ? null : onReject,
                              child: Text('admin_bank_change_to_rejected'.tr),
                            ),
                          ),
                        if (u.payoutStatus == PayoutVerificationStatus.rejected)
                          Expanded(
                            child: FilledButton(
                              onPressed: busy ? null : onApprove,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryAccent,
                                foregroundColor: Colors.black,
                              ),
                              child: busy
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : Text('admin_bank_change_to_approved'.tr),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
