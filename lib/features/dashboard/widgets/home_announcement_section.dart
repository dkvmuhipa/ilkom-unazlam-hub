import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import '../../announcements/announcements_screen.dart';
import '../../announcements/widgets/announcement_helper.dart';

class HomeAnnouncementSection extends StatelessWidget {
  final Announcement? announcement;
  final bool isDark;
  final ValueChanged<int> onNavigateTab;
  final VoidCallback onRefresh;

  const HomeAnnouncementSection({
    super.key,
    required this.announcement,
    required this.isDark,
    required this.onNavigateTab,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (announcement == null) return const SizedBox.shrink();

    final item = announcement!;
    final style = AnnouncementHelper.getCategoryStyle(item.kategori);
    final friendlyDate = AnnouncementHelper.formatFriendlyDate(item.createdAt);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'WARTA & PENGUMUMAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF94A3B8),
              ),
            ),
            ScaleButton(
              scaleDown: 0.95,
              onTap: () => onNavigateTab(7), // Tab Warta & Pengumuman
              child: const Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Announcement Banner Card
        ScaleButton(
          scaleDown: 0.97,
          onTap: () {
            AnnouncementsScreen.showAnnouncementDetail(
              context,
              item,
              onChanged: onRefresh,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.isPinned
                    ? const Color(0xFFFCA5A5)
                    : borderColor,
                width: item.isPinned ? 1.2 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: style.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    style.icon,
                    size: 22,
                    color: style.primaryColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta Badge Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: style.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              style.label,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: style.primaryColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (item.isPinned) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '• Disematkan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            friendlyDate,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: textSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textMain,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Excerpt
                      Text(
                        item.isi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSub,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
