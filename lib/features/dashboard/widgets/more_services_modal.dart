import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class MoreServicesModal {
  static void show(
    BuildContext context, {
    required bool isDark,
    required StudentProfile student,
    required void Function(int) onNavigateTab,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MoreServicesSheetContent(
        isDark: isDark,
        student: student,
        onNavigateTab: onNavigateTab,
      ),
    );
  }
}

class _MoreServicesSheetContent extends StatefulWidget {
  final bool isDark;
  final StudentProfile student;
  final void Function(int) onNavigateTab;

  const _MoreServicesSheetContent({
    required this.isDark,
    required this.student,
    required this.onNavigateTab,
  });

  @override
  State<_MoreServicesSheetContent> createState() => _MoreServicesSheetContentState();
}

class _MoreServicesSheetContentState extends State<_MoreServicesSheetContent> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sheetBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    final allItems = [
      _ServiceModalData(
        icon: Icons.calendar_month_rounded,
        label: 'Jadwal Kuliah',
        color: AppColors.primary,
        bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        tabIndex: 1,
      ),
      _ServiceModalData(
        icon: Icons.groups_rounded,
        label: 'Teman Kelas',
        color: AppColors.amber,
        bgColor: isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB),
        tabIndex: 3,
      ),
      _ServiceModalData(
        icon: Icons.payments_rounded,
        label: 'Kas Kelas',
        color: const Color(0xFF0D9488),
        bgColor: isDark ? const Color(0xFF163230) : const Color(0xFFF0FDFA),
        tabIndex: 8,
      ),
      _ServiceModalData(
        icon: Icons.co_present_rounded,
        label: 'Presensi',
        color: const Color(0xFF10B981),
        bgColor: isDark ? const Color(0xFF152F24) : const Color(0xFFECFDF5),
        tabIndex: 5,
      ),
      _ServiceModalData(
        icon: Icons.school_rounded,
        label: 'KHS Nilai',
        color: const Color(0xFF7C3AED),
        bgColor: isDark ? const Color(0xFF2B2144) : AppColors.primarySoft,
        tabIndex: 15,
      ),
      _ServiceModalData(
        icon: Icons.menu_book_rounded,
        label: 'Materi Kuliah',
        color: AppColors.cyan,
        bgColor: isDark ? const Color(0xFF162D3D) : const Color(0xFFE0F2FE),
        tabIndex: 10,
      ),
      _ServiceModalData(
        icon: Icons.mark_email_read_rounded,
        label: 'Surat Izin',
        color: AppColors.amber,
        bgColor: isDark ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB),
        tabIndex: 13,
      ),
      _ServiceModalData(
        icon: Icons.history_rounded,
        label: 'Audit Log',
        color: const Color(0xFF6366F1),
        bgColor: isDark ? const Color(0xFF232244) : const Color(0xFFEEF2FF),
        tabIndex: 14,
      ),
      _ServiceModalData(
        icon: Icons.person_outline_rounded,
        label: 'Profil Saya',
        color: AppColors.primary,
        bgColor: isDark ? const Color(0xFF262244) : const Color(0xFFEDE9FE),
        tabIndex: 4,
      ),
      if (widget.student.isKetuaKelas || widget.student.isAdmin)
        _ServiceModalData(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Panel Komti',
          color: const Color(0xFFEA580C),
          bgColor: isDark ? const Color(0xFF381D26) : const Color(0xFFFFF7ED),
          tabIndex: 7,
        ),
    ];

    final filteredItems = _searchQuery.trim().isEmpty
        ? allItems
        : allItems
            .where((item) => item.label.toLowerCase().contains(_searchQuery.toLowerCase().trim()))
            .toList();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
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
                      color: textSub,
                    ),
                  ),
                ],
              ),
              ScaleButton(
                scaleDown: 0.9,
                onTap: () => Navigator.pop(context),
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
          const SizedBox(height: 14),

          // Search Bar Filter
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161524) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: textSub),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari layanan atau menu...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _searchQuery = ''),
                    child: Icon(Icons.clear_rounded, size: 16, color: textSub),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (filteredItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Layanan "$_searchQuery" tidak ditemukan',
                  style: TextStyle(fontSize: 12.5, color: textSub, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: filteredItems
                  .map((item) => _buildModalMenuItem(
                        context,
                        icon: item.icon,
                        label: item.label,
                        color: item.color,
                        bgColor: item.bgColor,
                        textColor: textMain,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onNavigateTab(item.tabIndex);
                        },
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildModalMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 76,
      child: ScaleButton(
        scaleDown: 0.92,
        onTap: onTap,
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

class _ServiceModalData {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final int tabIndex;

  _ServiceModalData({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.tabIndex,
  });
}
