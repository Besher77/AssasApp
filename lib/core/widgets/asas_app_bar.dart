import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

class AsasAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AsasAppBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.actions,
    this.leading,
  });

  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (leading != null) leading!,
              const Spacer(),
              if (showLogo)
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.goldGradient.createShader(bounds),
                  child: Text(
                    'app_name'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (title != null)
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
