import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routing/auth_navigation.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';

/// Shown when an engineer is [pending] or [rejected] until admin sets [active].
class EngineerRegistrationGateView extends StatelessWidget {
  const EngineerRegistrationGateView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final rejected = args['rejected'] == true;
    final note = args['note'] as String?;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                rejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                size: 72,
                color: rejected ? Colors.red.shade300 : AppColors.primaryAccent,
              ),
              const SizedBox(height: 24),
              Text(
                rejected ? 'engineer_reg_rejected_title'.tr : 'engineer_reg_pending_title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                rejected ? 'engineer_reg_rejected_body'.tr : 'engineer_reg_pending_body'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.45),
              ),
              if (rejected && note != null && note.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(
                    note.trim(),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () async => navigateToRoleHome(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('engineer_reg_check_again'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await Get.find<AuthService>().logout();
                  Get.offAllNamed(AppRoutes.login);
                },
                child: Text('logout'.tr, style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
