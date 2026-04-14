import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Golden building logo for أساس app
class AsasLogo extends StatelessWidget {
  const AsasLogo({
    super.key,
    this.size = 80,
    this.showTitle = true,
  });

  final double size;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: _BuildingLogoPainter(),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
            child: Text(
              'أساس',
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for building/architecture logo
class _BuildingLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryAccent
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Roof peak (triangle)
    final roofPath = Path()
      ..moveTo(w * 0.5, h * 0.15)
      ..lineTo(w * 0.85, h * 0.45)
      ..lineTo(w * 0.15, h * 0.45)
      ..close();
    canvas.drawPath(roofPath, paint);

    // Building body (rectangle with windows)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.45, w * 0.6, h * 0.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, paint);

    // Window accents (lighter)
    final windowPaint = Paint()
      ..color = AppColors.secondaryAccent
      ..style = PaintingStyle.fill;

    // Three windows
    for (var i = 0; i < 3; i++) {
      final left = w * 0.3 + (i * w * 0.2);
      final top = h * 0.55 + (i % 2) * h * 0.15;
      canvas.drawRect(
        Rect.fromLTWH(left, top, w * 0.1, h * 0.1),
        windowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
