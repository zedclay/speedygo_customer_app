import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF0A4096);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2F59AF);
  static const onPrimaryContainer = Color(0xFFC7D5FF);
  static const secondary = Color(0xFF4658AC);
  static const tertiary = Color(0xFF3C4B00);
  static const tertiaryFixed = Color(0xFFD3EE78);
  static const tertiaryContainer = Color(0xFF516400);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFFC7E16D);
  static const surface = Color(0xFFF9F9FF);
  static const onSurface = Color(0xFF121B2E);
  static const onSurfaceVariant = Color(0xFF434652);
  static const outline = Color(0xFF747783);
  static const outlineVariant = Color(0xFFC3C6D4);
  static const error = Color(0xFFBA1A1A);
  static const inverseSurface = Color(0xFF273044);
  static const inverseOnSurface = Color(0xFFEDF0FF);
  static const surfaceContainer = Color(0xFFE9EDFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F3FF);
  static const surfaceContainerHigh = Color(0xFFE1E8FF);
  static const tertiaryFixedDim = Color(0xFFB7D15F);
  static const brandGreen = Color(0xFFBBD562);
  static const onBackground = Color(0xFF121B2E);
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Inter';
  static const splashDeep = Color(0xFF162B7F);
  static const splashMid = Color(0xFF2F59AF);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        error: AppColors.error,
        onError: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: base.textTheme
          .apply(
            fontFamily: fontFamily,
            fontFamilyFallback: const <String>[
              'Geeza Pro',
              'Noto Naskh Arabic',
              'Noto Sans Arabic',
              'SF Arabic',
              'Noto Emoji',
              'Noto Color Emoji',
              'Apple Color Emoji',
              'Segoe UI Emoji',
            ],
            bodyColor: AppColors.onSurface,
            displayColor: AppColors.onSurface,
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 48 / 40,
              letterSpacing: -0.8,
              color: AppColors.onSurface,
            ),
            headlineLarge: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 40 / 32,
              letterSpacing: -0.32,
              color: AppColors.onSurface,
            ),
            headlineSmall: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 32 / 24,
              color: AppColors.onSurface,
            ),
            titleLarge: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: AppColors.onSurface,
            ),
            titleMedium: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 24 / 16,
              color: AppColors.onSurface,
            ),
            bodyLarge: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: AppColors.onSurface,
            ),
            bodyMedium: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              color: AppColors.onSurface,
            ),
            labelLarge: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              letterSpacing: 0.1,
              color: AppColors.onSurface,
            ),
            labelMedium: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              letterSpacing: 0.5,
              color: AppColors.onSurface,
            ),
            labelSmall: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 16 / 11,
              color: AppColors.onSurface,
            ),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}
