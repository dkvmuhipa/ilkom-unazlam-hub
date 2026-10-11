import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static const String fontFamily = 'Poppins';

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 40,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 34,
            height: 1.16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          displaySmall: TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          headlineMedium: TextStyle(
            fontSize: 21,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontSize: 17,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontSize: 13,
            height: 1.55,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: TextStyle(
            fontSize: 12.5,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: TextStyle(
            fontSize: 11.5,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ).apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.textMain,
          displayColor: AppColors.textMain,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Color(0xFF392400),
        secondaryContainer: AppColors.secondarySoft,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.tertiarySoft,
        onTertiaryContainer: AppColors.tertiaryDark,
        surface: AppColors.surface,
        onSurface: AppColors.textMain,
        onSurfaceVariant: AppColors.textSub,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF8FAFC),
        surfaceContainer: Color(0xFFF1F5F9),
        surfaceContainerHigh: Color(0xFFE2E8F0),
        surfaceContainerHighest: Color(0xFFCBD5E1),
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorSoft,
        onErrorContainer: Color(0xFF991B1B),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textSub, size: 20),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        labelStyle: const TextStyle(color: AppColors.textSub, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSub,
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySoft,
        selectedColor: AppColors.primarySoft,
        disabledColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSub,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSub,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 4,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 20,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
        iconColor: AppColors.textSub,
        textColor: AppColors.textMain,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        hoverElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
            size: 20,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 20,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textMuted,
          size: 20,
        ),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        minWidth: 72,
        groupAlignment: -0.6,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  static ThemeData get darkTheme {
    const background = Color(0xFF0F172A); // Slate 900
    const surface = Color(0xFF1E293B); // Slate 800
    const surfaceVariant = Color(0xFF334155); // Slate 700
    const foreground = Color(0xFFF8FAFC); // Slate 50
    const muted = Color(0xFF94A3B8); // Slate 400
    const border = Color(0xFF334155); // Slate 700

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: foreground,
      displayColor: foreground,
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF818CF8),
        onPrimary: Color(0xFF0F172A),
        primaryContainer: Color(0xFF312E81),
        onPrimaryContainer: Color(0xFFE0E7FF),
        secondary: Color(0xFFFBBF24),
        onSecondary: Color(0xFF451A03),
        secondaryContainer: Color(0xFF78350F),
        onSecondaryContainer: Color(0xFFFEF3C7),
        tertiary: Color(0xFF2DD4BF),
        onTertiary: Color(0xFF042F2E),
        tertiaryContainer: Color(0xFF134E4A),
        onTertiaryContainer: Color(0xFFCCFBF1),
        surface: surface,
        onSurface: foreground,
        onSurfaceVariant: muted,
        surfaceContainerLowest: Color(0xFF0B1120),
        surfaceContainerLow: surface,
        surfaceContainer: surfaceVariant,
        surfaceContainerHigh: Color(0xFF475569),
        surfaceContainerHighest: Color(0xFF64748B),
        outline: border,
        outlineVariant: Color(0xFF475569),
        error: Color(0xFFF87171),
        onError: Color(0xFF450A0A),
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFEE2E2),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 60,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: foreground,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: muted, size: 20),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: muted, fontSize: 13.5),
        labelStyle: const TextStyle(color: muted, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF818CF8),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF818CF8),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC7D2FE),
          side: const BorderSide(color: border, width: 1),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 4,
        showDragHandle: true,
        dragHandleColor: border,
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 20,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF312E81),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        height: 68,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0xFF312E81),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIconTheme: const IconThemeData(color: Color(0xFFC7D2FE), size: 20),
        unselectedIconTheme: const IconThemeData(color: muted, size: 20),
        minWidth: 72,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: foreground,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF818CF8),
      ),
    );
  }
}
