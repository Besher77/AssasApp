import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/withdrawal_request_row.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/admin_withdrawals_controller.dart';

class AdminWithdrawalsView extends GetView<AdminWithdrawalsController> {
  const AdminWithdrawalsView({super.key});

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
          'admin_menu_withdrawals'.tr,
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
                      label: Text('admin_withdrawals_tab_pending'.tr),
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
                      label: Text('admin_withdrawals_tab_history'.tr),
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
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('admin_withdrawals_tab_all'.tr),
                      selected: controller.tabIndex.value == 2,
                      onSelected: (_) => controller.tabIndex.value = 2,
                      selectedColor: AppColors.primaryAccent.withValues(alpha: 0.35),
                      labelStyle: TextStyle(
                        color: controller.tabIndex.value == 2
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'admin_search_withdrawals_hint'.tr,
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
              final tab = controller.tabIndex.value;
              final list = controller.filteredRowsForTab(tab);
              final baseEmpty = switch (tab) {
                0 => controller.requests.where((r) => r.isPending).isEmpty,
                1 => controller.requests.where((r) => !r.isPending).isEmpty,
                _ => controller.requests.isEmpty,
              };
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    baseEmpty
                        ? switch (tab) {
                            0 => 'admin_withdrawals_empty_pending'.tr,
                            1 => 'admin_withdrawals_empty_history'.tr,
                            _ => 'admin_withdrawals_empty_all'.tr,
                          }
                        : 'admin_search_no_results'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = list[i];
                  final busy = controller.processingId.value == r.id;
                  return _WithdrawalCard(
                    row: r,
                    busy: busy,
                    onOpenUserDetails: () => controller.openWithdrawalUserDetails(r),
                    onTransfer: r.isPending ? () => controller.markTransferred(r) : null,
                    onReject: r.isPending ? () => controller.markRejected(r) : null,
                    onChangeStatus:
                        !r.isPending ? () => controller.changeWithdrawalStatus(r) : null,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({
    required this.row,
    required this.busy,
    required this.onOpenUserDetails,
    this.onTransfer,
    this.onReject,
    this.onChangeStatus,
  });

  final WithdrawalRequestRow row;
  final bool busy;
  final VoidCallback onOpenUserDetails;
  final VoidCallback? onTransfer;
  final VoidCallback? onReject;
  final VoidCallback? onChangeStatus;

  String _statusLabel() {
    switch (row.status) {
      case 'transferred':
        return 'withdrawal_status_transferred'.tr;
      case 'rejected':
        return 'withdrawal_status_rejected'.tr;
      default:
        return 'withdrawal_status_pending'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpenUserDetails,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Obx(() {
                        final c = Get.find<AdminWithdrawalsController>();
                        final label = c.displayNameForWithdrawalUser(row.userId);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: AppColors.primaryAccent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primaryAccent,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.account_balance_outlined,
                                  size: 18,
                                  color: AppColors.primaryAccent.withValues(alpha: 0.85),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'admin_withdrawal_tap_for_iban'.tr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(color: AppColors.primaryAccent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${row.amount.toStringAsFixed(2)} ${row.currency}',
              style: TextStyle(color: AppColors.primaryAccent, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (row.adminMessage != null && row.adminMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${'withdrawal_admin_reason'.tr}: ${row.adminMessage}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            if (onTransfer != null && onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      child: Text('withdrawal_status_rejected'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onTransfer,
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
                          : Text('admin_withdrawal_action_transfer'.tr),
                    ),
                  ),
                ],
              ),
            ],
            if (onChangeStatus != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: busy ? null : onChangeStatus,
                  icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryAccent),
                  label: Text('admin_change_status'.tr),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
