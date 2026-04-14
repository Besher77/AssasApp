import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/otp_controller.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'otp_title'.tr,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'otp_subtitle'.trParams({'phone': controller.phone}),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              AsasOtpInput(
                onCompleted: controller.verifyOtp,
              ),
              const SizedBox(height: 32),
              Obx(
                () => controller.isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(color: AppColors.primaryAccent),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Obx(
                () => TextButton(
                  onPressed: controller.canResend.value ? controller.resendOtp : null,
                  child: Text(
                    controller.canResend.value ? 'resend_otp'.tr : 'resend_otp_wait'.tr,
                    style: TextStyle(
                      color: controller.canResend.value
                          ? AppColors.primaryAccent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
