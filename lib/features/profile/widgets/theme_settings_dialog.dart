import 'package:flutter/material.dart';
import '../../../core/theme/theme_notifier.dart';

class ThemeSettingsDialog {
  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentMode = ThemeScope.notifier.themeMode;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                const Icon(Icons.palette_outlined, color: Color(0xFF6D28D9), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Tema Tampilan',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOptionTile(
                  title: 'Mode Terang (Light)',
                  subtitle: 'Palet cerah bersih untuk siang hari',
                  icon: Icons.light_mode_rounded,
                  iconColor: const Color(0xFFD97706),
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () {
                    ThemeScope.notifier.setThemeMode(ThemeMode.light);
                    Navigator.pop(dialogCtx);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  title: 'Mode Gelap (Dark)',
                  subtitle: 'OLED Charcoal ramah mata',
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () {
                    ThemeScope.notifier.setThemeMode(ThemeMode.dark);
                    Navigator.pop(dialogCtx);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  title: 'Ikuti Sistem HP',
                  subtitle: 'Otomatis mengikuti setelan perangkat',
                  icon: Icons.phone_android_rounded,
                  iconColor: const Color(0xFF10B981),
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () {
                    ThemeScope.notifier.setThemeMode(ThemeMode.system);
                    Navigator.pop(dialogCtx);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6D28D9).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF28283E) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6D28D9) : (isDark ? const Color(0xFF38384E) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF6D28D9), size: 18),
          ],
        ),
      ),
    );
  }
}
