import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - High-Contrast Electric Indigo / Royal Violet
  static const Color primary = Color(0xFF5B3DE8);
  static const Color primaryDark = Color(0xFF4328C7);
  static const Color primaryLight = Color(0xFF7C64F5);
  static const Color primaryContainer = Color(0xFFEEF0FF);
  static const Color primarySoft = Color(0xFFF4F3FF);

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

  // Modern Neutral Surfaces (Clean Tech Slate & Pure White)
  static const Color background = Color(0xFFF8FAFC); // Crisp Slate 50
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Status Colors (Vibrant yet Refined)
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF0284C7);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // Modern Typography (High Contrast Slate Hierarchy)
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textSub = Color(0xFF475467); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textLight = Color(0xFF94A3B8);

  // Hairline Precision Borders (SaaS Standard)
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100

  // Precision Clean Shadows (Multi-stop subtle drop)
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.035),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.015),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.035),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
