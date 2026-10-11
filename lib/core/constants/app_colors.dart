import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Royal Navy Blue (#1E40AF / #2563EB)
  static const Color primary = Color(0xFF1E40AF); // Royal Navy Blue 800
  static const Color primaryLight = Color(0xFF2563EB); // Royal Blue 600
  static const Color primaryDark = Color(0xFF172554); // Navy 950
  static const Color primaryContainer = Color(0xFFDBEAFE); // Blue 100
  static const Color primarySoft = Color(0xFFEFF6FF); // Blue 50
  static const Color primaryBorder = Color(0xFFBFDBFE); // Blue 200

  // Secondary Accents & Vibrant SaaS Tones
  static const Color secondary = Color(0xFFF59E0B); // Amber 500
  static const Color secondaryDark = Color(0xFFB45309);
  static const Color secondarySoft = Color(0xFFFFFBEB); // Amber 50
  static const Color secondaryBorder = Color(0xFFFDE68A); // Amber 200

  static const Color tertiary = Color(0xFF0D9488); // Teal 600
  static const Color tertiaryDark = Color(0xFF0F766E);
  static const Color tertiarySoft = Color(0xFFCCFBF1); // Teal 100
  static const Color tertiaryBorder = Color(0xFF99F6E4); // Teal 200

  static const Color coral = Color(0xFFF43F5E); // Rose 500
  static const Color coralSoft = Color(0xFFFFE4E6); // Rose 100
  static const Color sky = Color(0xFF0284C7); // Sky 600
  static const Color skySoft = Color(0xFFE0F2FE); // Sky 100

  // Extended Modern Clean Vibrant SaaS Palette
  static const Color violet = Color(0xFF7C3AED); // Violet 600
  static const Color violetLight = Color(0xFF8B5CF6);
  static const Color violetSoft = Color(0xFFF5F3FF); // Violet 50
  static const Color violetBorder = Color(0xFFDDD6FE); // Violet 200
  static const Color violetText = Color(0xFF6D28D9); // Violet 700

  static const Color cyan = Color(0xFF0891B2); // Cyan 600
  static const Color cyanLight = Color(0xFF06B6D4);
  static const Color cyanSoft = Color(0xFFECFEFF); // Cyan 50
  static const Color cyanBorder = Color(0xFFA5F3FC); // Cyan 200
  static const Color cyanText = Color(0xFF0E7490); // Cyan 700

  static const Color indigo = Color(0xFF4F46E5); // Indigo 600
  static const Color indigoLight = Color(0xFF6366F1);
  static const Color indigoSoft = Color(0xFFEEF2FF); // Indigo 50
  static const Color indigoBorder = Color(0xFFC7D2FE); // Indigo 200
  static const Color indigoText = Color(0xFF3730A3); // Indigo 700

  static const Color fuchsia = Color(0xFFC026D3); // Fuchsia 600
  static const Color fuchsiaLight = Color(0xFFD946EF);
  static const Color fuchsiaSoft = Color(0xFFFDF4FF); // Fuchsia 50
  static const Color fuchsiaBorder = Color(0xFFF5D0FE); // Fuchsia 200
  static const Color fuchsiaText = Color(0xFF86198F); // Fuchsia 700

  // Direct Vibrant SaaS Brand Palette
  static const Color emerald = Color(0xFF10B981); // Emerald 500
  static const Color amber = Color(0xFFF59E0B); // Amber 500
  static const Color rose = Color(0xFFE11D48); // Rose 600
  static const Color teal = Color(0xFF0D9488); // Teal 600
  static const Color slate = Color(0xFF64748B); // Slate 500

  // Clean Slate Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Soft Pill Status Badges (Emerald, Amber, Rose, Navy with dark bold text)
  static const Color emeraldSoft = Color(0xFFD1FAE5); // Emerald 100
  static const Color emeraldText = Color(0xFF065F46); // Emerald 800
  static const Color emeraldBorder = Color(0xFFA7F3D0); // Emerald 200
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successSoft = Color(0xFFECFDF5); // Emerald 50

  static const Color amberSoft = Color(0xFFFEF3C7); // Amber 100
  static const Color amberText = Color(0xFF92400E); // Amber 800
  static const Color amberBorder = Color(0xFFFDE68A); // Amber 200
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color roseSoft = Color(0xFFFFE4E6); // Rose 100
  static const Color roseText = Color(0xFF9F1239); // Rose 800
  static const Color roseBorder = Color(0xFFFECDD3); // Rose 200
  static const Color error = Color(0xFFE11D48); // Rose 600
  static const Color errorSoft = Color(0xFFFFF1F2); // Rose 50

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

  // Modern Vibrant Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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

  // Subtle Colorful Glow Shadow for vibrant icons & chips
  static List<BoxShadow> coloredGlow(Color color, {double opacity = 0.18, double blur = 8}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      offset: const Offset(0, 3),
    ),
  ];
}
