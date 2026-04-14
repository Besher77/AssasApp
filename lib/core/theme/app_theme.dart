import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData _darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DarkThemeColors.primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: DarkThemeColors.primaryAccent,
        secondary: DarkThemeColors.secondaryAccent,
        surface: DarkThemeColors.cardBackground,
        error: Colors.redAccent,
        onPrimary: DarkThemeColors.textPrimary,
        onSecondary: DarkThemeColors.textPrimary,
        onSurface: DarkThemeColors.textPrimary,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkThemeColors.primaryAccent,
          foregroundColor: DarkThemeColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkThemeColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkThemeColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkThemeColors.primaryAccent, width: 2),
        ),
        hintStyle: const TextStyle(color: DarkThemeColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: DarkThemeColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          color: DarkThemeColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: base.textTheme.displayMedium?.copyWith(
          color: DarkThemeColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: DarkThemeColors.textPrimary,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: DarkThemeColors.textSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme => _darkTheme();

  static ThemeData _lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: LightThemeColors.primaryBackground,
      colorScheme: const ColorScheme.light(
        primary: LightThemeColors.primaryAccent,
        secondary: LightThemeColors.secondaryAccent,
        surface: LightThemeColors.cardBackground,
        error: Colors.redAccent,
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onSurface: LightThemeColors.textPrimary,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightThemeColors.primaryAccent,
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightThemeColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LightThemeColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LightThemeColors.primaryAccent, width: 2),
        ),
        hintStyle: const TextStyle(color: LightThemeColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: LightThemeColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          color: LightThemeColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: base.textTheme.displayMedium?.copyWith(
          color: LightThemeColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: LightThemeColors.textPrimary,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: LightThemeColors.textSecondary,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _lightTheme();
}
