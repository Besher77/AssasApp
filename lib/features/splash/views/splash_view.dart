import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBackground,
              AppColors.primaryBackground,
              AppColors.cardBackground,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: _AnimatedSplashContent(),
        ),
      ),
    );
  }
}

class _AnimatedSplashContent extends StatefulWidget {
  @override
  State<_AnimatedSplashContent> createState() => _AnimatedSplashContentState();
}

class _AnimatedSplashContentState extends State<_AnimatedSplashContent>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _shimmerController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _shimmerController]),
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Logo with scale and fade
            Transform.scale(
              scale: _logoScale.value,
              child: Opacity(
                opacity: _logoOpacity.value,
                child: _LogoWithShimmer(
                  shimmerValue: _shimmerController.value,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // App name with fade
            Opacity(
              opacity: _titleOpacity.value,
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.goldGradient.createShader(bounds),
                child: Text(
                  'أساس',
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: _titleOpacity.value,
              child: Text(
                'app_name'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  letterSpacing: 2,
                ),
              ),
            ),
            const Spacer(flex: 2),
            // Loading indicator
            Opacity(
              opacity: _titleOpacity.value,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryAccent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        );
      },
    );
  }
}

class _LogoWithShimmer extends StatelessWidget {
  const _LogoWithShimmer({required this.shimmerValue});

  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // App logo image
            Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, _error, _stackTrace) => _FallbackLogo(),
            ),
            // Subtle shimmer overlay
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment(-1.5 + shimmerValue * 2, 0),
                    end: Alignment(-0.5 + shimmerValue * 2, 0),
                    colors: [
                      Colors.transparent,
                      AppColors.glassBackground,
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcOver,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBackground,
      child: Icon(
        Icons.apartment,
        size: 72,
        color: AppColors.primaryAccent,
      ),
    );
  }
}
