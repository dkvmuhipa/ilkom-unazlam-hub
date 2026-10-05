import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
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
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.poppins(color: AppColors.textMain, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.poppins(color: AppColors.textMain, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.poppins(color: AppColors.textMain, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.poppins(color: AppColors.textMain, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.poppins(
          color: AppColors.textMain,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.poppins(color: AppColors.textMain, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.poppins(
          color: AppColors.textMain,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.poppins(
          color: AppColors.textMain,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.poppins(color: AppColors.textMain, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: AppColors.textMain, fontSize: 14),
        bodyMedium: GoogleFonts.poppins(
          color: AppColors.textMain,
          fontSize: 13,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          color: AppColors.textSub,
          fontSize: 11,
        ),
        labelLarge: GoogleFonts.poppins(color: AppColors.textMain, fontWeight: FontWeight.w700),
        labelMedium: GoogleFonts.poppins(color: AppColors.textSub, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.poppins(color: AppColors.textSub, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
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
          textStyle: GoogleFonts.poppins(
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
          textStyle: GoogleFonts.poppins(
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
            return GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.poppins(
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
