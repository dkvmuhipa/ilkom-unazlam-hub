import 'package:flutter/material.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class ProfileAcademicSection extends StatelessWidget {
  final StudentProfile student;
  final bool isDark;
  final VoidCallback onEditPeminatan;
  final VoidCallback onEditAgama;

  const ProfileAcademicSection({
    super.key,
    required this.student,
    required this.isDark,
    required this.onEditPeminatan,
    required this.onEditAgama,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded, color: Color(0xFF6D28D9), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Informasi Akademik',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ScaleButton(
                onTap: onEditPeminatan,
                scaleDown: 0.94,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, color: Color(0xFF6D28D9), size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Peminatan',
                        style: TextStyle(
                          color: Color(0xFF6D28D9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildRow(
            icon: Icons.account_balance_rounded,
            label: 'Fakultas',
            value: 'Ilmu Sosial dan Ilmu Politik (FISIP)',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(height: 22, color: dividerColor),

          _buildRow(
            icon: Icons.menu_book_rounded,
            label: 'Program Studi',
            value: 'S1 Ilmu Komunikasi',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(height: 22, color: dividerColor),

          _buildRow(
            icon: Icons.stars_rounded,
            label: 'Konsentrasi / Peminatan',
            value: student.peminatan.isNotEmpty ? student.peminatan : 'Ilmu Komunikasi Terapan',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            highlightColor: const Color(0xFF6D28D9),
          ),
          Divider(height: 22, color: dividerColor),

          _buildRow(
            icon: Icons.auto_stories_rounded,
            label: 'Agama / Preferensi MK Agama',
            value: student.effectiveAgama,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            highlightColor: const Color(0xFF059669),
            trailing: ScaleButton(
              onTap: onEditAgama,
              scaleDown: 0.94,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: Color(0xFF059669), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Ubah',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 22, color: dividerColor),

          _buildRow(
            icon: Icons.groups_rounded,
            label: 'Angkatan & Jenjang',
            value: 'Angkatan 2026 • Sarjana Terakreditasi',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    bool isMonospace = false,
    bool isItalic = false,
    Color? highlightColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: highlightColor ?? textPrimary,
                  fontFamily: isMonospace ? 'monospace' : null,
                  fontStyle: isItalic ? FontStyle.italic : null,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
