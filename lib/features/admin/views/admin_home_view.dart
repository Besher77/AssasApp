import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/admin_home_controller.dart';

class AdminHomeView extends GetView<AdminHomeController> {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'admin_panel'.tr,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: controller.logout,
            tooltip: 'logout'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        return RefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: controller.refreshDashboardStats,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
            Obx(() {
              final name = controller.adminName.value;
              if (name.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${'welcome'.tr}, $name',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            _AdminDashboardOverview(controller: controller),
            Obx(() {
              return _AdminStatusCardsRow(
                engineerCount: controller.pendingEngineerRegistrationsCount.value,
                withdrawalsCount: controller.pendingWithdrawalsCount.value,
                bankCount: controller.pendingBankVerificationsCount.value,
              );
            }),
            Obx(
              () => _AdminMenuCard(
                icon: Icons.people_outline_rounded,
                title: 'admin_menu_users'.tr,
                subtitle: 'admin_menu_users_sub'.tr,
                badgeCount: controller.pendingEngineerRegistrationsCount.value,
                onTap: () => Get.toNamed(AppRoutes.adminUsers),
              ),
            ),
            const SizedBox(height: 12),
            _AdminMenuCard(
              icon: Icons.folder_special_outlined,
              title: 'admin_menu_projects'.tr,
              subtitle: 'admin_menu_projects_sub'.tr,
              onTap: () => Get.toNamed(AppRoutes.adminProjects),
            ),
            const SizedBox(height: 12),
            Obx(
              () => _AdminMenuCard(
                icon: Icons.payments_outlined,
                title: 'admin_menu_withdrawals'.tr,
                subtitle: 'admin_menu_withdrawals_sub'.tr,
                badgeCount: controller.pendingWithdrawalsCount.value,
                onTap: () => Get.toNamed(AppRoutes.adminWithdrawals),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => _AdminMenuCard(
                icon: Icons.account_balance_outlined,
                title: 'admin_menu_bank_verifications'.tr,
                subtitle: 'admin_menu_bank_verifications_sub'.tr,
                badgeCount: controller.pendingBankVerificationsCount.value,
                onTap: () => Get.toNamed(AppRoutes.adminBankVerifications),
              ),
            ),
            const SizedBox(height: 12),
            _AdminMenuCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'admin_menu_wallets'.tr,
              subtitle: 'admin_menu_wallets_sub'.tr,
              onTap: () => Get.toNamed(AppRoutes.adminWallets),
            ),
          ],
          ),
        );
      }),
    );
  }
}

class _AdminDashboardOverview extends StatelessWidget {
  const _AdminDashboardOverview({required this.controller});

  final AdminHomeController controller;

  static String _fmtSar(double v) {
    final decimals = v == v.roundToDouble() ? 0 : 2;
    final s = v.toStringAsFixed(decimals);
    return '$s ${'currency_sar'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.dashboardStatsLoading.value;
      final stats = controller.dashboardStats.value;

      if (loading && stats == null) {
        return _AdminStatsPanel(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    'admin_stats_loading'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (stats == null) {
        return _AdminStatsPanel(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'admin_stats_unavailable'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return _AdminStatsPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryAccent.withValues(alpha: 0.2),
                        AppColors.secondaryAccent.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(Icons.insights_rounded, color: AppColors.primaryAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'admin_stats_section'.tr,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _StatsGroupHeader(
              icon: Icons.people_alt_outlined,
              title: 'admin_stats_group_users'.tr,
            ),
            _StatsMetricRow(
              left: _StatsMetricCell(
                icon: Icons.person_outline_rounded,
                label: 'admin_stats_clients'.tr,
                value: '${stats.clientsCount}',
              ),
              right: _StatsMetricCell(
                icon: Icons.engineering_outlined,
                label: 'admin_stats_engineers'.tr,
                value: '${stats.engineersCount}',
              ),
            ),
            _StatsMetricRow(
              left: _StatsMetricCell(
                icon: Icons.admin_panel_settings_outlined,
                label: 'admin_stats_admins'.tr,
                value: '${stats.adminsCount}',
              ),
              right: _StatsMetricCell(
                icon: Icons.groups_outlined,
                label: 'admin_stats_users_total'.tr,
                value: '${stats.totalUserAccounts}',
              ),
            ),
            const SizedBox(height: 6),
            _StatsGroupHeader(
              icon: Icons.folder_special_outlined,
              title: 'admin_stats_group_projects'.tr,
            ),
            _StatsMetricRow(
              left: _StatsMetricCell(
                icon: Icons.folder_open_rounded,
                label: 'admin_stats_projects_total'.tr,
                value: '${stats.projectsTotal}',
              ),
              right: _StatsMetricCell(
                icon: Icons.fiber_new_rounded,
                label: 'admin_stats_projects_new'.tr,
                value: '${stats.projectsNew}',
              ),
            ),
            _StatsMetricRow(
              left: _StatsMetricCell(
                icon: Icons.bolt_rounded,
                label: 'admin_stats_projects_active'.tr,
                value: '${stats.projectsActive}',
              ),
              right: _StatsMetricCell(
                icon: Icons.autorenew_rounded,
                label: 'admin_stats_projects_in_progress'.tr,
                value: '${stats.projectsInProgress}',
              ),
            ),
            _StatsMetricRow(
              left: _StatsMetricCell(
                icon: Icons.local_shipping_outlined,
                label: 'admin_stats_projects_delivered'.tr,
                value: '${stats.projectsDelivered}',
              ),
              right: _StatsMetricCell(
                icon: Icons.check_circle_outline_rounded,
                label: 'admin_stats_projects_completed'.tr,
                value: '${stats.projectsCompleted}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StatsMetricCell(
                icon: Icons.cancel_outlined,
                label: 'admin_stats_projects_cancelled'.tr,
                value: '${stats.projectsCancelled}',
                wide: true,
              ),
            ),
            const SizedBox(height: 6),
            _StatsGroupHeader(
              icon: Icons.payments_outlined,
              title: 'admin_stats_group_revenue'.tr,
            ),
            _StatsRevenueCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'admin_stats_completed_volume'.tr,
              amount: _fmtSar(stats.completedProjectsPaidTotalSar),
            ),
            const SizedBox(height: 10),
            _StatsRevenueCard(
              icon: Icons.percent_rounded,
              title: 'admin_stats_platform_fees'.tr,
              amount: _fmtSar(stats.estimatedPlatformFeesSar),
              hint: 'admin_stats_platform_fees_hint'.tr,
            ),
          ],
        ),
      );
    });
  }
}

class _AdminStatsPanel extends StatelessWidget {
  const _AdminStatsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.045),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatsGroupHeader extends StatelessWidget {
  const _StatsGroupHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: AppColors.goldGradient,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsMetricRow extends StatelessWidget {
  const _StatsMetricRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }
}

class _StatsMetricCell extends StatelessWidget {
  const _StatsMetricCell({
    required this.icon,
    required this.label,
    required this.value,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryAccent;
    final inner = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            if (wide) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!wide) ...[
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (wide) ...[
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: inner,
    );
  }
}

class _StatsRevenueCard extends StatelessWidget {
  const _StatsRevenueCard({
    required this.icon,
    required this.title,
    required this.amount,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String amount;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.cardBackground,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    hint!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatusCardsRow extends StatelessWidget {
  const _AdminStatusCardsRow({
    required this.engineerCount,
    required this.withdrawalsCount,
    required this.bankCount,
  });

  final int engineerCount;
  final int withdrawalsCount;
  final int bankCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _AdminStatusCard(
              icon: Icons.engineering_outlined,
              label: 'admin_quick_engineers'.tr,
              count: engineerCount,
              onTap: () => Get.toNamed(AppRoutes.adminUsers, arguments: {'tab': 'engineers'}),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AdminStatusCard(
              icon: Icons.payments_outlined,
              label: 'admin_quick_withdrawals'.tr,
              count: withdrawalsCount,
              onTap: () => Get.toNamed(AppRoutes.adminWithdrawals),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AdminStatusCard(
              icon: Icons.account_balance_outlined,
              label: 'admin_quick_bank'.tr,
              count: bankCount,
              onTap: () => Get.toNamed(AppRoutes.adminBankVerifications),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatusCard extends StatelessWidget {
  const _AdminStatusCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  bool get _hasAttention => count > 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _hasAttention ? AppColors.goldGradient : null,
            color: _hasAttention ? null : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasAttention
                  ? AppColors.primaryAccent.withValues(alpha: 0.5)
                  : AppColors.glassBorder,
              width: _hasAttention ? 1.5 : 1,
            ),
            boxShadow: _hasAttention
                ? [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: _hasAttention ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    color: _hasAttention ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hasAttention
                        ? AppColors.textPrimary.withValues(alpha: 0.9)
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  bool get _hasAttention => badgeCount > 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _hasAttention ? AppColors.primaryAccent.withValues(alpha: 0.06) : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasAttention
                  ? AppColors.primaryAccent.withValues(alpha: 0.55)
                  : AppColors.glassBorder,
              width: _hasAttention ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primaryAccent, size: 26),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade700,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryBackground, width: 2),
                        ),
                        constraints: const BoxConstraints(minWidth: 20),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
