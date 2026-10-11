import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Royal Navy Blue (#1E40AF / #2563EB)
  static const Color primary = Color(0xFF1E40AF); // Royal Navy Blue 800
  static const Color primaryLight = Color(0xFF2563EB); // Royal Blue 600
  static const Color primaryDark = Color(0xFF172554); // Navy 950
  static const Color primaryContainer = Color(0xFFDBEAFE); // Blue 100
  static const Color primarySoft = Color(0xFFEFF6FF); // Blue 50
  static const Color primaryBorder = Color(0xFFBFDBFE); // Blue 200

  // Secondary Accents
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFFB45309);
  static const Color secondarySoft = Color(0xFFFFFBEB);
  static const Color tertiary = Color(0xFF0D9488);
  static const Color tertiaryDark = Color(0xFF0F766E);
  static const Color tertiarySoft = Color(0xFFCCFBF1);
  static const Color coral = Color(0xFFF43F5E);
  static const Color coralSoft = Color(0xFFFFE4E6);
  static const Color sky = Color(0xFF0284C7);
  static const Color skySoft = Color(0xFFE0F2FE);

  // Clean Slate Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Soft Pill Status Badges (Emerald, Amber, Rose with dark bold text)
  static const Color emeraldSoft = Color(0xFFD1FAE5); // Emerald 100
  static const Color emeraldText = Color(0xFF065F46); // Emerald 800
  static const Color emeraldBorder = Color(0xFFA7F3D0); // Emerald 200
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);

  static const Color amberSoft = Color(0xFFFEF3C7); // Amber 100
  static const Color amberText = Color(0xFF92400E); // Amber 800
  static const Color amberBorder = Color(0xFFFDE68A); // Amber 200
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color roseSoft = Color(0xFFFFE4E6); // Rose 100
  static const Color roseText = Color(0xFF9F1239); // Rose 800
  static const Color roseBorder = Color(0xFFFECDD3); // Rose 200
  static const Color error = Color(0xFFE11D48); // Rose 600
  static const Color errorSoft = Color(0xFFFFE4E6);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  // Modern Typography (Slate Hierarchy)
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textSub = Color(0xFF475467); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400 (text-gray-400)
  static const Color textLight = Color(0xFF94A3B8);

  // Precision Hairline Borders
  static const Color border = Color(0xFFF1F5F9); // border-gray-100 / slate-100
  static const Color borderMedium = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF8FAFC); // Slate 50

  // Soft Shadows (shadow-sm)
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
