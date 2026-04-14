import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/admin_wallets_controller.dart';

class AdminWalletsView extends GetView<AdminWalletsController> {
  const AdminWalletsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'admin_wallets_title'.tr,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.promptEnsureWallet,
        backgroundColor: AppColors.primaryAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: Text('admin_wallets_ensure'.tr, style: const TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'admin_wallets_search_hint'.tr,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryAccent),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Obx(
              () => Row(
                children: [
                  _FilterChip(
                    label: 'admin_wallets_filter_all'.tr,
                    selected: controller.userTypeFilter.value.isEmpty,
                    onTap: () => controller.userTypeFilter.value = '',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'admin_wallets_filter_user'.tr,
                    selected: controller.userTypeFilter.value == 'user',
                    onTap: () => controller.userTypeFilter.value = 'user',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'admin_wallets_filter_engineer'.tr,
                    selected: controller.userTypeFilter.value == 'engineer',
                    onTap: () => controller.userTypeFilter.value = 'engineer',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
              }
              final list = controller.filteredRows;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'admin_wallets_empty'.tr,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final row = list[i];
                  final w = row.wallet;
                  final u = row.user;
                  final name = u?.name ?? '—';
                  final busy = controller.busyUserId.value == w.userId;
                  return Card(
                    color: AppColors.cardBackground,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppColors.glassBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (u != null)
                                      Text(
                                        u.phone,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    Text(
                                      '${'admin_wallets_uid'.tr}: ${w.userId}',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${w.balance.toStringAsFixed(2)} ${'currency_sar'.tr}',
                                    style: TextStyle(
                                      color: AppColors.primaryAccent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                  if (u == null)
                                    Text(
                                      'admin_wallets_no_user_profile'.tr,
                                      style: TextStyle(color: Colors.orange.shade300, fontSize: 11),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (busy)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        controller.promptAmount(userId: w.userId, credit: true),
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                    label: Text('admin_wallets_add'.tr),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        controller.promptAmount(userId: w.userId, credit: false),
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                                    label: Text('admin_wallets_take'.tr),
                                  ),
                                  if (w.balance == 0)
                                    TextButton(
                                      onPressed: () async {
                                        final ok = await Get.dialog<bool>(
                                          AlertDialog(
                                            title: Text('admin_wallets_delete_empty_title'.tr),
                                            content: Text('admin_wallets_delete_empty_body'.tr),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Get.back(result: false),
                                                child: Text('cancel'.tr),
                                              ),
                                              TextButton(
                                                onPressed: () => Get.back(result: true),
                                                child: Text('delete'.tr,
                                                    style: const TextStyle(color: Colors.redAccent)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) await controller.deleteEmptyWallet(w.userId);
                                      },
                                      child: Text(
                                        'admin_wallets_delete_empty'.tr,
                                        style: const TextStyle(color: Colors.redAccent),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryAccent.withValues(alpha: 0.2) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryAccent : AppColors.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primaryAccent : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
