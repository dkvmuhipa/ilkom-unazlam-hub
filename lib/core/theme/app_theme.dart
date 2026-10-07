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

  static ThemeData get darkTheme {
    const textThemeDark = TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w800),
      displayMedium: TextStyle(fontFamily: fontFamily, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w800),
      displaySmall: TextStyle(fontFamily: fontFamily, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: fontFamily, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        color: Color(0xFFF3F4F6),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(fontFamily: fontFamily, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        color: Color(0xFFF3F4F6),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        color: Color(0xFFF3F4F6),
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(fontFamily: fontFamily, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: fontFamily, color: Color(0xFFE5E7EB), fontSize: 14),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        color: Color(0xFFE5E7EB),
        fontSize: 13,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        color: Color(0xFF9CA3AF),
        fontSize: 11,
      ),
      labelLarge: TextStyle(fontFamily: fontFamily, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontFamily: fontFamily, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontFamily: fontFamily, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: const Color(0xFF0F0C1B), // Deep OLED Charcoal
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF755BF7),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF261D4C),
        onPrimaryContainer: Color(0xFFD6CEFE),
        secondary: Color(0xFFFBBF24),
        onSecondary: Colors.black,
        surface: Color(0xFF181428),
        onSurface: Color(0xFFF3F4F6),
      ),
      textTheme: textThemeDark,
      primaryTextTheme: textThemeDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF3F4F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Color(0xFFF3F4F6),
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF181428),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D2644), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF755BF7),
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
          foregroundColor: const Color(0xFFD6CEFE),
          side: const BorderSide(color: Color(0xFF382F57), width: 1.2),
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
        backgroundColor: const Color(0xFF181428),
        elevation: 0,
        indicatorColor: const Color(0xFF261D4C),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD6CEFE),
            );
          }
          return const TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFD6CEFE), size: 22);
          }
          return const IconThemeData(color: Color(0xFF6B7280), size: 22);
        }),
      ),
    );
  }
}
