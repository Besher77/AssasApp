import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/review_document.dart';
import '../../../core/theme/app_colors.dart';

/// Review card with optional reply action for the engineer (own profile / my reviews).
class EngineerReviewTile extends StatelessWidget {
  const EngineerReviewTile({
    super.key,
    required this.review,
    this.showReplyAction = false,
    this.onAnswer,
  });

  final ReviewDocument review;
  final bool showReplyAction;
  final void Function(String)? onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              ...List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              if (review.reviewerName != null)
                Text(
                  review.reviewerName!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
            ),
          ],
          if (review.engineerAnswer != null && review.engineerAnswer!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 16, color: AppColors.primaryAccent),
                      const SizedBox(width: 6),
                      Text(
                        'engineer_answer'.tr,
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.engineerAnswer!,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          if (showReplyAction && (review.engineerAnswer == null || review.engineerAnswer!.isEmpty)) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showAnswerDialog(context),
              icon: Icon(Icons.reply_rounded, size: 18, color: AppColors.primaryAccent),
              label: Text('answer_review'.tr, style: TextStyle(color: AppColors.primaryAccent)),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnswerDialog(BuildContext context) {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('answer_review'.tr, style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: textController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'answer_review_hint'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.primaryBackground,
          ),
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final answer = textController.text.trim();
              Get.back();
              if (answer.isNotEmpty && onAnswer != null) onAnswer!(answer);
            },
            child: Text('save'.tr, style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }
}
