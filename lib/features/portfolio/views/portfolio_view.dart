import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/project_types.dart';
import '../../../core/models/portfolio_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/portfolio_controller.dart';

class PortfolioView extends GetView<PortfolioController> {
  const PortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'portfolio'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.primaryAccent),
            onPressed: () => Get.toNamed('/create-portfolio-item'),
          ),
        ],
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const _PortfolioShimmer();
          }
          if (controller.items.isEmpty) {
            return _EmptyPortfolio();
          }
          return _PortfolioList(items: controller.items.toList());
        },
      ),
    );
  }
}

class _PortfolioShimmer extends StatelessWidget {
  const _PortfolioShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBackground,
      highlightColor: AppColors.glassBorder,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 4,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 24),
            Text(
              'no_portfolio_items'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'no_portfolio_subtitle'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AsasButton(
              label: 'add_portfolio_item'.tr,
              onPressed: () => Get.toNamed('/create-portfolio-item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioList extends StatelessWidget {
  const _PortfolioList({required this.items});

  final List<PortfolioItem> items;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => await Get.find<PortfolioController>().loadItems(),
      color: AppColors.primaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PortfolioCard(item: item),
          );
        },
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;
    return AsasCard(
      padding: EdgeInsets.zero,
      onTap: () => Get.toNamed('/portfolio-item-detail', arguments: item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 120,
                    height: 120,
                    color: AppColors.primaryBackground,
                    child: Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (item.projectType != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      getProjectTypeNameById(item.projectType!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  if (item.executionDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.executionDate!.year}-${item.executionDate!.month.toString().padLeft(2, '0')}-${item.executionDate!.day.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
