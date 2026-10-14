import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../core/widgets/universal_search_modal.dart';
import '../../../models/models.dart';

class HomeHeaderBar extends StatelessWidget {
  final StudentProfile student;
  final bool isDark;
  final int unreadNotificationCount;
  final ValueChanged<int> onNavigateTab;
  final VoidCallback? onOpenDrawer;
  final Animation<double> livePulseAnimation;

  const HomeHeaderBar({
    super.key,
    required this.student,
    required this.isDark,
    required this.unreadNotificationCount,
    required this.onNavigateTab,
    this.onOpenDrawer,
    required this.livePulseAnimation,
  });

  Map<String, dynamic> _getTimeContext() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return {
        'greeting': 'Selamat Pagi',
        'subtitle': 'Awali perkuliahan hari ini dengan semangat',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFF59E0B),
      };
    } else if (hour >= 11 && hour < 15) {
      return {
        'greeting': 'Selamat Siang',
        'subtitle': 'Tetap produktif dan jaga stamina belajarmu',
        'icon': Icons.light_mode_rounded,
        'color': const Color(0xFFF97316),
      };
    } else if (hour >= 15 && hour < 18) {
      return {
        'greeting': 'Selamat Sore',
        'subtitle': 'Periksa tugas dan persiapan kuliah esok hari',
        'icon': Icons.wb_twilight_rounded,
        'color': const Color(0xFF8B5CF6),
      };
    } else {
      return {
        'greeting': 'Selamat Malam',
        'subtitle': 'Istirahat cukup untuk kesiapan hari esok',
        'icon': Icons.nightlight_round,
        'color': const Color(0xFF38BDF8),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeCtx = _getTimeContext();
    final firstName = student.nama.trim().split(' ').first;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    final textMain = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E1C2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2C3D) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Bar: Greeting & Actions (Notification & Avatar)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Greeting and Date Context
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live indicator + date
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: livePulseAnimation,
                        builder: (context, child) => Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: livePulseAnimation.value),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: livePulseAnimation.value * 0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        timeCtx['icon'] as IconData,
                        size: 13,
                        color: timeCtx['color'] as Color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dateStr.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Greeting Name
                  Text(
                    '${timeCtx['greeting']}, $firstName 👋',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Subtitle & Room
                  Row(
                    children: [
                      Text(
                        'Ilmu Komunikasi • Ruang A2',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textSub,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Smt ${student.semester}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right: Notification Bell Button
            ScaleButton(
              scaleDown: 0.92,
              onTap: () => onNavigateTab(17), // Tab Notifikasi
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      unreadNotificationCount > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: unreadNotificationCount > 0
                          ? const Color(0xFFF59E0B)
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      size: 22,
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              unreadNotificationCount > 9 ? '9+' : '$unreadNotificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Right: Student Avatar
            ScaleButton(
              scaleDown: 0.92,
              onTap: () {
                if (onOpenDrawer != null) {
                  onOpenDrawer!();
                } else {
                  onNavigateTab(16); // Profil
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  student.nama.isNotEmpty ? student.nama[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Command Search Bar
        ScaleButton(
          scaleDown: 0.98,
          onTap: () => UniversalSearchModal.show(context, onNavigateTab: onNavigateTab),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cari jadwal kuliah, dosen, tugas, atau warta...',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF26223D) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3B3358) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Cari',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
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
