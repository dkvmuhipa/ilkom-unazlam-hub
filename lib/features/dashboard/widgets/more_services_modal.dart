import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../models/models.dart';

class MoreServicesModal {
  static void show(
    BuildContext context, {
    required bool isDark,
    required StudentProfile student,
    required void Function(int) onNavigateTab,
  }) {
    final sheetBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direktori Layanan Portal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Akses cepat ke seluruh modul & fasilitas kelas',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF26223D) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: textMain),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                _buildModalMenuItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Jadwal Kuliah',
                  color: AppColors.primary,
                  bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(1); // Jadwal
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.groups_rounded,
                  label: 'Teman Kelas',
                  color: AppColors.amber,
                  bgColor: isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(3); // Direktori Kelas
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.payments_rounded,
                  label: 'Kas Kelas',
                  color: const Color(0xFF0D9488),
                  bgColor: isDark ? const Color(0xFF163230) : const Color(0xFFF0FDFA),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(8); // Kas
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.co_present_rounded,
                  label: 'Presensi',
                  color: const Color(0xFF10B981),
                  bgColor: isDark ? const Color(0xFF152F24) : const Color(0xFFECFDF5),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(5); // Presensi
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.school_rounded,
                  label: 'KHS Nilai',
                  color: const Color(0xFF7C3AED),
                  bgColor: isDark ? const Color(0xFF2B2144) : AppColors.primarySoft,
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(15); // KHS
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Materi Kuliah',
                  color: AppColors.cyan,
                  bgColor: isDark ? const Color(0xFF162D3D) : const Color(0xFFE0F2FE),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(10); // Materi
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.mark_email_read_rounded,
                  label: 'Surat Izin',
                  color: AppColors.amber,
                  bgColor: isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(13); // Izin
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.history_rounded,
                  label: 'Audit Log',
                  color: const Color(0xFF6366F1),
                  bgColor: isDark ? const Color(0xFF232244) : const Color(0xFFEEF2FF),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(14); // Audit Log
                  },
                ),
                _buildModalMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil Saya',
                  color: AppColors.primary,
                  bgColor: isDark ? const Color(0xFF262244) : const Color(0xFFEDE9FE),
                  textColor: textMain,
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavigateTab(4); // Profil
                  },
                ),
                if (student.isKetuaKelas || student.isAdmin)
                  _buildModalMenuItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Panel Komti',
                    color: const Color(0xFFEA580C),
                    bgColor: isDark ? const Color(0xFF381D26) : const Color(0xFFFFF7ED),
                    textColor: textMain,
                    onTap: () {
                      Navigator.pop(ctx);
                      onNavigateTab(7); // Pengumuman / Admin
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildModalMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorfulIconBox(
                icon: icon,
                color: color,
                size: 48,
                iconSize: 24,
                radius: 15,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
