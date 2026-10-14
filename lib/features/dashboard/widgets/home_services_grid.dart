import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import 'more_services_modal.dart';

class HomeServicesGrid extends StatelessWidget {
  final StudentProfile student;
  final bool isDark;
  final ValueChanged<int> onNavigateTab;

  const HomeServicesGrid({
    super.key,
    required this.student,
    required this.isDark,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    final services = [
      _ServiceItemData(
        title: 'Jadwal',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF2563EB), // Blue 600
        bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        tabIndex: 4,
      ),
      _ServiceItemData(
        title: 'Presensi',
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xFF0284C7), // Sky 600
        bgColor: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
        tabIndex: 5,
      ),
      _ServiceItemData(
        title: 'Tugas',
        icon: Icons.assignment_rounded,
        color: const Color(0xFFE11D48), // Rose 600
        bgColor: isDark ? const Color(0xFF4C0519) : const Color(0xFFFFE4E6),
        tabIndex: 3,
      ),
      _ServiceItemData(
        title: 'Kas Kelas',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF0D9488), // Teal 600
        bgColor: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
        tabIndex: 8,
      ),
      _ServiceItemData(
        title: 'Warta',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFD97706), // Amber 600
        bgColor: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
        tabIndex: 7,
      ),
      _ServiceItemData(
        title: 'Kelompok',
        icon: Icons.groups_rounded,
        color: const Color(0xFF7C3AED), // Violet 600
        bgColor: isDark ? const Color(0xFF2E1065) : const Color(0xFFF5F3FF),
        tabIndex: 9,
      ),
      _ServiceItemData(
        title: 'Direktori',
        icon: Icons.badge_rounded,
        color: const Color(0xFF059669), // Emerald 600
        bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
        tabIndex: 12,
      ),
      _ServiceItemData(
        title: 'Lainnya',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF64748B), // Slate 500
        bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        isMore: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Text(
          'LAYANAN UTAMA KAMPUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),

        // Grid 4 Kolom x 2 Baris
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final item = services[index];
            return ScaleButton(
              scaleDown: 0.90,
              onTap: () {
                HapticFeedback.selectionClick();
                if (item.isMore) {
                  MoreServicesModal.show(
                    context,
                    isDark: isDark,
                    student: student,
                    onNavigateTab: onNavigateTab,
                  );
                } else {
                  onNavigateTab(item.tabIndex);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: isDark ? 0.2 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item.icon,
                      size: 24,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceItemData {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int tabIndex;
  final bool isMore;

  const _ServiceItemData({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.tabIndex = 0,
    this.isMore = false,
  });
}
