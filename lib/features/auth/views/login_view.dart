import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton.icon(
                  onPressed: () {
                    final isAr = Get.locale?.languageCode == 'ar';
                    Get.updateLocale(Locale(isAr ? 'en' : 'ar'));
                  },
                  icon: Icon(Icons.language, color: AppColors.textSecondary, size: 20),
                  label: Text(
                    Get.locale?.languageCode == 'ar' ? 'EN' : 'ع',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      const AsasLogo(size: 100),
                      const SizedBox(height: 32),
                      Text(
                        'welcome'.tr,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'fill_required_fields'.tr,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      AsasPhoneField(
                        controller: controller.phoneController,
                        hintText: 'phone_number'.tr,
                        validator: validateSaudiPhone,
                        onSubmitted: (_) => controller.sendOtpAndNavigate(),
                      ),
                      const SizedBox(height: 32),
                      Obx(
                        () => AsasButton(
                          label: 'send_otp'.tr,
                          onPressed: controller.sendOtpAndNavigate,
                          isLoading: controller.isLoading.value,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Get.toNamed('/signup'),
                        child: Text(
                          'no_account_signup'.tr,
                          style: TextStyle(color: AppColors.primaryAccent),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or'.tr,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(child: _divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SocialButton(
                        label: 'login_with_google'.tr,
                        icon: Icons.g_mobiledata,
                        onPressed: controller.loginWithGoogle,
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        label: 'login_with_apple'.tr,
                        icon: Icons.apple,
                        onPressed: controller.loginWithApple,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'terms_disclaimer'.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: AppColors.glassBorder,
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AsasButton(
      label: label,
      icon: Icon(icon, color: AppColors.textPrimary, size: 24),
      onPressed: onPressed,
      isOutlined: true,
    );
  }
}
