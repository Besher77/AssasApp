import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/engineer_specializations.dart';
import '../../../core/constants/saudi_cities.dart' show getCityNameById;
import '../../../core/models/portfolio_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/presence_text.dart';
import '../controllers/engineer_profile_controller.dart';
import '../widgets/engineer_review_tile.dart';

class EngineerProfileView extends GetView<EngineerProfileController> {
  const EngineerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        return Column(
          children: [
            _buildProfileHeader(context),
            _buildTabBar(context),
            Expanded(
              child: Obx(
                () => IndexedStack(
                  index: controller.selectedTabIndex.value,
                  sizing: StackFit.expand,
                  children: [
                    _HomeTab(controller: controller),
                    _PortfolioTab(controller: controller),
                    _ReviewsTab(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.15),
            AppColors.primaryBackground,
          ],
        ),
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Get.back(),
                ),
                const Spacer(),
              ],
            ),
            _ProfileAvatar(controller: controller),
            const SizedBox(height: 12),
            Text(
              controller.engineerName.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            if (!controller.isOwnProfile)
              Obx(() {
                final sub = presenceSubtitle(
                  isOnline: controller.engineerIsOnline.value,
                  lastSeen: controller.engineerLastSeen.value,
                );
                if (sub.isEmpty) return const SizedBox(height: 4);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    sub,
                    style: TextStyle(
                      color: controller.engineerIsOnline.value
                          ? Colors.greenAccent.shade200
                          : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
            if (controller.engineerCity.value.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    getCityNameById(controller.engineerCity.value),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _RatingBadge(controller: controller),
            Obx(() {
              if (controller.isOwnProfile || !controller.isClient.value) {
                return const SizedBox(height: 16);
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.openChatOrInvite,
                        icon: Icon(Icons.chat_bubble_outline_rounded,
                            size: 20, color: AppColors.primaryAccent),
                        label: Text(
                          'contact'.tr,
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.inviteToPrivateProject,
                        icon: Icon(Icons.add_circle_outline,
                            size: 20, color: AppColors.primaryBackground),
                        label: Text(
                          'invite_to_private_project'.tr,
                          style: TextStyle(
                            color: AppColors.primaryBackground,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            _TabItem(
              label: 'tab_home'.tr,
              icon: Icons.person_outline_rounded,
              isSelected: controller.selectedTabIndex.value == 0,
              onTap: () => controller.selectedTabIndex.value = 0,
            ),
            _TabItem(
              label: 'tab_portfolio'.tr,
              icon: Icons.workspace_premium_outlined,
              isSelected: controller.selectedTabIndex.value == 1,
              onTap: () => controller.selectedTabIndex.value = 1,
            ),
            _TabItem(
              label: 'tab_reviews'.tr,
              icon: Icons.star_outline_rounded,
              isSelected: controller.selectedTabIndex.value == 2,
              onTap: () => controller.selectedTabIndex.value = 2,
              badge: controller.reviews.length > 0 ? '${controller.reviews.length}' : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.controller});

  final EngineerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryAccent, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: controller.engineerPhotoUrl.value != null && controller.engineerPhotoUrl.value!.isNotEmpty
            ? Image.network(
                controller.engineerPhotoUrl.value!,
                fit: BoxFit.cover,
              )
            : Container(
                color: AppColors.cardBackground,
                alignment: Alignment.center,
                child: Text(
                  controller.engineerName.value.isNotEmpty
                      ? controller.engineerName.value[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.controller});

  final EngineerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: AppColors.primaryAccent, size: 20),
          const SizedBox(width: 6),
          Text(
            controller.averageRating.value.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${controller.reviews.length})',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.controller});

  final EngineerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProjectStats(context),
          const SizedBox(height: 20),
          _buildBioSection(context),
          const SizedBox(height: 20),
          _buildInfoCards(context),
        ],
      ),
    );
  }

  Widget _buildProjectStats(BuildContext context) {
    return Obx(() {
      final inProgress = controller.projectsInProgress.value;
      final completed = controller.projectsCompleted.value;
      final onTime = controller.completedOnTimePercent.value;
      final cancelled = controller.cancelledPercent.value;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.primaryAccent, size: 22),
                const SizedBox(width: 10),
                Text(
                  'engineer_project_stats'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'engineer_projects_in_progress'.tr,
                    value: '$inProgress',
                    icon: Icons.work_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItem(
                    label: 'engineer_projects_completed'.tr,
                    value: '$completed',
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'engineer_on_time_percent'.tr,
                    value: '${onTime.toStringAsFixed(0)}%',
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItem(
                    label: 'engineer_cancelled_percent'.tr,
                    value: '${cancelled.toStringAsFixed(0)}%',
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBioSection(BuildContext context) {
    if (controller.engineerBio.value.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'no_bio'.tr,
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, color: AppColors.primaryAccent, size: 22),
              const SizedBox(width: 10),
              Text(
                'engineer_bio'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            controller.engineerBio.value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.7,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    final hasSpecialization = controller.engineerSpecialization.value.isNotEmpty;
    final hasExperience = controller.engineerYearsExperience.value.isNotEmpty;
    final hasMembership = controller.engineerMembership.value.isNotEmpty;

    if (!hasSpecialization && !hasExperience && !hasMembership) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'engineer_info'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (hasSpecialization)
          _InfoCard(
            icon: Icons.engineering,
            label: 'engineer_specialization'.tr,
            value: _getSpecializationDisplay(controller.engineerSpecialization.value),
          ),
        if (hasExperience) ...[
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.calendar_today_outlined,
            label: 'engineer_experience'.tr,
            value: controller.engineerYearsExperience.value,
          ),
        ],
        if (hasMembership) ...[
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.badge_outlined,
            label: 'engineer_membership'.tr,
            value: controller.engineerMembership.value,
          ),
        ],
      ],
    );
  }

  String _getSpecializationDisplay(String spec) {
    if (spec.isEmpty) return '-';
    try {
      final found = engineerSpecializations.firstWhere(
        (s) => s.id == spec || s.name == spec || s.nameAr == spec || s.nameEn == spec,
      );
      return found.name;
    } catch (_) {
      return spec;
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab({required this.controller});

  final EngineerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: controller.portfolioItems.isEmpty
          ? _EmptyState(
              icon: Icons.workspace_premium_outlined,
              message: 'no_portfolio_items'.tr,
            )
          : Column(
              children: controller.portfolioItems
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PortfolioTile(item: item),
                      ))
                  .toList(),
            ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.controller});

  final EngineerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.canReview.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddReview(controller),
                  icon: Icon(Icons.add, size: 20, color: AppColors.primaryAccent),
                  label: Text('add_review'.tr, style: TextStyle(color: AppColors.primaryAccent)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          Obx(() {
            if (controller.reviews.isEmpty) {
              return _EmptyState(
                icon: Icons.star_outline_rounded,
                message: 'no_ratings'.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: controller.reviews
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EngineerReviewTile(
                          review: r,
                          showReplyAction: controller.isOwnProfile,
                          onAnswer: (answer) => controller.answerReview(r.id, answer),
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  void _openAddReview(EngineerProfileController c) {
    final projectId = c.reviewableProjectId.value;
    if (projectId == null || projectId.isEmpty) return;
    Get.toNamed('/add-review', arguments: {
      'engineerId': c.engineerId,
      'projectId': projectId,
    })?.then((_) => c.load());
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/portfolio-item-detail', arguments: item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.imageUrls.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(item.imageUrls.first, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
