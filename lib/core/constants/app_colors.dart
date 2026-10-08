import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Vibrant Royal Purple (Matches UI Mockup)
  static const Color primary = Color(0xFF5B3DE8);
  static const Color primaryDark = Color(0xFF4330B8);
  static const Color primaryLight = Color(0xFF826EF4);
  static const Color primaryContainer = Color(0xFFEDE8FF);
  static const Color primarySoft = Color(0xFFF1EDFF);

  static const Color secondary = Color(0xFFF0A52B);
  static const Color secondaryDark = Color(0xFFAD6509);
  static const Color secondarySoft = Color(0xFFFFF1D6);
  static const Color tertiary = Color(0xFF159D9A);
  static const Color tertiaryDark = Color(0xFF087477);
  static const Color tertiarySoft = Color(0xFFE1F6F3);
  static const Color coral = Color(0xFFE96C78);
  static const Color coralSoft = Color(0xFFFFECEE);
  static const Color sky = Color(0xFF3989D8);
  static const Color skySoft = Color(0xFFE8F3FF);

  // Modern Neutral Surfaces (Warm, Premium & Airy)
  static const Color background = Color(0xFFF8F7FC);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Status Colors (Vibrant yet Refined)
  static const Color success = Color(0xFF0B966B);
  static const Color successSoft = Color(0xFFE6F8F0);

  static const Color warning = Color(0xFFCA7900);
  static const Color warningSoft = Color(0xFFFFF4D9);

  static const Color error = Color(0xFFD94255);
  static const Color errorSoft = Color(0xFFFFECEF);

  static const Color info = Color(0xFF2878C7);
  static const Color infoSoft = Color(0xFFE8F3FF);

  // Modern Typography (High Contrast & Clear)
  static const Color textMain = Color(0xFF20212B);
  static const Color textSub = Color(0xFF656777);
  static const Color textMuted = Color(0xFF9293A1);
  static const Color textLight = Color(0xFF9293A1);

  // Subtle Borders & Shadows
  static const Color border = Color(0xFFE6E1EF);
  static const Color borderLight = Color(0xFFF0EDF5);

  // Modern Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF20212B).withValues(alpha: 0.045),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF20212B).withValues(alpha: 0.02),
      blurRadius: 5,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF20212B).withValues(alpha: 0.045),
      blurRadius: 18,
      offset: const Offset(0, 5),
    ),
  ];
}
