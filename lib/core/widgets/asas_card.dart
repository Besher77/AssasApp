import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Reusable card with soft shadow and rounded corners
class AsasCard extends StatelessWidget {
  const AsasCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? AppConstants.cardRadius;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.65),
          width: 1,
        ),
        boxShadow: AppColors.cardDropShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          splashColor: AppColors.primaryAccent.withValues(alpha: 0.12),
          highlightColor: AppColors.primaryAccent.withValues(alpha: 0.06),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
