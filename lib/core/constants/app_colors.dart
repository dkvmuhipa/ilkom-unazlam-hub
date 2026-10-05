import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Vibrant Royal Purple (Matches UI Mockup)
  static const Color primary = Color(0xFF5B3DE8); // Vibrant Royal Purple
  static const Color primaryDark = Color(0xFF4527A0); // Deep Violet
  static const Color primaryLight = Color(0xFF755BF7); // Lighter Purple for Gradients
  static const Color primaryContainer = Color(0xFFF3F0FF); // Soft Violet Container
  static const Color primarySoft = Color(0xFFF3F0FF); // Alias for soft violet container

  static const Color secondary = Color(0xFFFFA000); // Warm Amber Gold
  static const Color secondaryDark = Color(0xFFD97706);
  static const Color secondarySoft = Color(0xFFFEF3C7); // Soft Amber Container

  // Modern Neutral Surfaces (Warm, Premium & Airy)
  static const Color background = Color(0xFFF8F9FD); // Clean Off-White
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Status Colors (Vibrant yet Refined)
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEF2F2);
  
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  // Modern Typography (High Contrast & Clear)
  static const Color textMain = Color(0xFF191424);
  static const Color textSub = Color(0xFF5B5469);
  static const Color textMuted = Color(0xFF8C849B);
  static const Color textLight = Color(0xFF8C849B);

  // Subtle Borders & Shadows
  static const Color border = Color(0xFFE9E4F0);
  static const Color borderLight = Color(0xFFF2EEF7);

  // Modern Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF2B0948).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF2B0948).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1E0633).withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}
