import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/add_review_controller.dart';

class AddReviewView extends GetView<AddReviewController> {
  const AddReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'add_review'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ratings'.tr,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        onPressed: () => controller.rating.value = i + 1,
                        icon: Icon(
                          i < controller.rating.value ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.primaryAccent,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                AsasTextField(
                  controller: controller.commentController,
                  hintText: 'review_comment'.tr,
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                Obx(
                  () => AsasButton(
                    label: 'submit_review'.tr,
                    onPressed: controller.submit,
                    isLoading: controller.isSubmitting.value,
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
