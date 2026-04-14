import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/project_types.dart';
import '../../../core/models/portfolio_item.dart';
import '../../../core/theme/app_colors.dart';

class PortfolioItemDetailView extends StatelessWidget {
  const PortfolioItemDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final item = Get.arguments is PortfolioItem ? Get.arguments as PortfolioItem : null;
    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Text('item_not_found'.tr, style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primaryBackground,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrls.isEmpty
                  ? Container(
                      color: AppColors.cardBackground,
                      child: Center(
                        child: Icon(Icons.image_not_supported_rounded, size: 80, color: AppColors.textSecondary),
                      ),
                    )
                  : PageView.builder(
                      itemCount: item.imageUrls.length,
                      itemBuilder: (_, i) => Image.network(item.imageUrls[i], fit: BoxFit.cover),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (item.projectType != null) ...[
                    const SizedBox(height: 8),
                    _InfoChip(
                      icon: Icons.category_outlined,
                      label: getProjectTypeNameById(item.projectType!),
                    ),
                  ],
                  if (item.executionDate != null) ...[
                    const SizedBox(height: 8),
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: '${item.executionDate!.year}-${item.executionDate!.month.toString().padLeft(2, '0')}-${item.executionDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ],
                  if (item.location != null && item.location!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoChip(icon: Icons.location_on_outlined, label: item.location!),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryAccent),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
