import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/my_reviews_controller.dart';
import '../widgets/engineer_review_tile.dart';

class MyReviewsView extends GetView<MyReviewsController> {
  const MyReviewsView({super.key});

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
        title: Text('my_reviews'.tr, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        return RefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: controller.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Obx(() {
                    final avg = controller.averageRating.value;
                    final n = controller.reviews.length;
                    if (n == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: AppColors.primaryAccent, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            avg.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($n)',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              Obx(() {
                if (controller.reviews.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_outline_rounded, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'no_ratings'.tr,
                              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = controller.reviews[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < controller.reviews.length - 1 ? 12 : 0),
                          child: EngineerReviewTile(
                            review: r,
                            showReplyAction: true,
                            onAnswer: (answer) => controller.answerReview(r.id, answer),
                          ),
                        );
                      },
                      childCount: controller.reviews.length,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}
