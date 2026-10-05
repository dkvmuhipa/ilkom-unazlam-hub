import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static const String fontFamily = 'Poppins';

  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontWeight: FontWeight.w800),
      displaySmall: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.textMain,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.textMain,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.textMain,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontSize: 14),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.textMain,
        fontSize: 13,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.textSub,
        fontSize: 11,
      ),
      labelLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textMain, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textSub, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontFamily: fontFamily, color: AppColors.textSub, fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textMain,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.primarySoft,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textLight, size: 22);
        }),
      ),
    );
  }
}
