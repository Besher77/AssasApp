import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/settings_service.dart';

/// Dark theme colors
class DarkThemeColors {
  static const primaryBackground = Color(0xFF0B0F2A);
  static const cardBackground = Color(0xFF12173A);
  static const primaryAccent = Color(0xFFD4AF37);
  static const secondaryAccent = Color(0xFFF5C96A);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A4C3);
  static const glassBackground = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
}

/// Light theme colors
class LightThemeColors {
  static const primaryBackground = Color(0xFFF5F5F7);
  static const cardBackground = Color(0xFFFFFFFF);
  static const primaryAccent = Color(0xFFB8860B);
  static const secondaryAccent = Color(0xFFD4AF37);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const glassBackground = Color(0x1A000000);
  static const glassBorder = Color(0x22000000);
}

bool _getIsDark() {
  try {
    return Get.find<SettingsService>().isDarkMode;
  } catch (_) {
    return true;
  }
}

/// App color palette - theme-aware
class AppColors {
  AppColors._();

  static Color get primaryBackground =>
      _getIsDark() ? DarkThemeColors.primaryBackground : LightThemeColors.primaryBackground;

  static Color get cardBackground =>
      _getIsDark() ? DarkThemeColors.cardBackground : LightThemeColors.cardBackground;

  static Color get primaryAccent =>
      _getIsDark() ? DarkThemeColors.primaryAccent : LightThemeColors.primaryAccent;

  static Color get secondaryAccent =>
      _getIsDark() ? DarkThemeColors.secondaryAccent : LightThemeColors.secondaryAccent;

  static Color get textPrimary =>
      _getIsDark() ? DarkThemeColors.textPrimary : LightThemeColors.textPrimary;

  static Color get textSecondary =>
      _getIsDark() ? DarkThemeColors.textSecondary : LightThemeColors.textSecondary;

  static Color get glassBackground =>
      _getIsDark() ? DarkThemeColors.glassBackground : LightThemeColors.glassBackground;

  static Color get glassBorder =>
      _getIsDark() ? DarkThemeColors.glassBorder : LightThemeColors.glassBorder;

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [DarkThemeColors.primaryAccent, DarkThemeColors.secondaryAccent],
  );

  /// Soft shadow for elevated cards (theme-aware).
  static List<BoxShadow> get cardDropShadow => [
        BoxShadow(
          color: _getIsDark()
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF1A1A2E).withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: _getIsDark()
              ? Colors.black.withValues(alpha: 0.18)
              : const Color(0xFFB8860B).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Subtle overlay for tinted surfaces (search fields, chips).
  static Color get surfaceTint => _getIsDark()
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0xFFB8860B).withValues(alpha: 0.06);
}
