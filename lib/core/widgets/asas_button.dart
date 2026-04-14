import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Reusable luxury gold gradient button
class AsasButton extends StatelessWidget {
  const AsasButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          child: Container(
            decoration: BoxDecoration(
              gradient: isOutlined
                  ? null
                  : (isEnabled ? AppColors.goldGradient : null),
              color: isOutlined ? Colors.transparent : null,
              border: isOutlined
                  ? Border.all(color: AppColors.primaryAccent)
                  : null,
              borderRadius:
                  BorderRadius.circular(AppConstants.buttonRadius),
              boxShadow: isEnabled && !isOutlined
                  ? [
                      BoxShadow(
                        color: AppColors.primaryAccent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          icon!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
