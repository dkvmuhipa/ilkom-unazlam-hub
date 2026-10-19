import 'package:flutter/material.dart';

import '../../../core/services/course_schedule_service.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import 'lecturer_reminder_modal.dart';

class CourseTimelineCard extends StatelessWidget {
  final Course course;
  final bool isLast;
  final VoidCallback? onTap;

  const CourseTimelineCard({
    super.key,
    required this.course,
    this.isLast = false,
    this.onTap,
  });

  Color _getCourseAccentColor(String courseName) {
    final colors = [
      const Color(0xFF6D28D9), // Royal Blue
      const Color(0xFF0284C7), // Sky Blue
      const Color(0xFF0D9488), // Teal
      const Color(0xFFD97706), // Amber
      const Color(0xFF7C3AED), // Violet
      const Color(0xFF2563EB), // Indigo Blue
      const Color(0xFF059669), // Emerald
    ];
    return colors[courseName.hashCode.abs() % colors.length];
  }

  bool _isCourseOngoing(Course c) {
    if (c.isCancelledToday) return false;
    final now = DateTime.now();
    final today = CourseScheduleService.getDayName(now);
    if (today.toLowerCase() != c.hari.trim().toLowerCase()) return false;
    try {
      final startParts = c.effectiveJamMulai.split(':');
      final endParts = c.effectiveJamSelesai.split(':');
      final startDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      final endDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
      return now.isAfter(startDt) && now.isBefore(endDt);
    } catch (_) {
      return false;
    }
  }

  bool _isCourseFinished(Course c) {
    if (c.isCancelledToday) return false;
    final now = DateTime.now();
    final today = CourseScheduleService.getDayName(now);
    if (today.toLowerCase() != c.hari.trim().toLowerCase()) return false;
    try {
      final endParts = c.effectiveJamSelesai.split(':');
      final endDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
      return now.isAfter(endDt);
    } catch (_) {
      return false;
    }
  }

  int _calculateDurationMinutes(Course c) {
    try {
      final s = c.effectiveJamMulai.split(':');
      final e = c.effectiveJamSelesai.split(':');
      final startMin = int.parse(s[0]) * 60 + int.parse(s[1]);
      final endMin = int.parse(e[0]) * 60 + int.parse(e[1]);
      return endMin - startMin;
    } catch (_) {
      return 100;
    }
  }

  Widget _buildModeBadge(Course c) {
    final r = c.ruangan.toLowerCase();
    final link = c.linkVirtual ?? '';
    final isOnline = link.isNotEmpty ||
        r.contains('zoom') ||
        r.contains('online') ||
        r.contains('meet') ||
        r.contains('virtual');
    final isHybrid = r.contains('hybrid');
    final isLab = r.contains('lab');

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (isOnline) {
      bgColor = const Color(0xFFF5F3FF);
      textColor = const Color(0xFF2563EB);
      icon = Icons.videocam_rounded;
      label = 'Online (Virtual)';
    } else if (isHybrid) {
      bgColor = const Color(0xFFF3E8FF);
      textColor = const Color(0xFF7C3AED);
      icon = Icons.sensors_rounded;
      label = 'Hybrid';
    } else if (isLab) {
      bgColor = const Color(0xFFEEF2FF);
      textColor = const Color(0xFF4F46E5);
      icon = Icons.computer_rounded;
      label = 'Praktikum Lab';
    } else {
      bgColor = const Color(0xFFECFDF5);
      textColor = const Color(0xFF059669);
      icon = Icons.business_rounded;
      label = 'Tatap Muka';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerAvatar(String name, Color color) {
    final clean = name
        .replaceAll(RegExp(r'(Dr\.|M\.I\.Kom|S\.Sos|Prof\.|H\.|Hj\.)'), '')
        .trim();
    final initials = clean.isNotEmpty
        ? clean
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'DS';
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _openWhatsAppDosen(BuildContext context, Course c) {
    LecturerReminderModal.show(
      context,
      course: c,
      senderName: 'Ketua Kelas',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = course;
    final accentColor = _getCourseAccentColor(c.nama);
    final isOngoing = _isCourseOngoing(c);
    final isFinished = _isCourseFinished(c);
    final durationMin = _calculateDurationMinutes(c);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Time Column
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.isCancelledToday ? '-' : c.effectiveJamMulai,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: c.isCancelledToday
                        ? const Color(0xFFEF4444)
                        : (isOngoing
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0F172A)),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.isCancelledToday ? 'Batal' : c.effectiveJamSelesai,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: c.isCancelledToday
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                  ),
                ),
                if (c.hasActiveOverride && c.jamMulai != c.effectiveJamMulai) ...[
                  const SizedBox(height: 1),
                  Text(
                    c.jamMulai,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${durationMin}m',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Node & Line
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? const Color(0xFF10B981)
                      : (isFinished ? const Color(0xFF94A3B8) : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOngoing
                        ? Colors.white
                        : (isFinished ? const Color(0xFF94A3B8) : accentColor),
                    width: isOngoing ? 2 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOngoing
                              ? const Color(0xFF10B981)
                              : accentColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: isFinished
                    ? const Icon(
                        Icons.check,
                        size: 9,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Right Card
          Expanded(
            child: ScaleButton(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOngoing
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                    width: isOngoing ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOngoing
                          ? const Color(0xFF10B981).withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isOngoing
                              ? const Color(0xFF10B981)
                              : accentColor,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges Row
                        Row(
                          children: [
                            _buildModeBadge(c),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${c.sks} SKS',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            if (c.hasActiveOverride) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: c.isCancelledToday
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: c.isCancelledToday
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFFFDE68A),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  c.override!.statusBadgeLabel,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: c.isCancelledToday
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (isOngoing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Color(0xFF16A34A),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Berlangsung',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isFinished)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Selesai',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          c.nama,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Room location
                        Row(
                          children: [
                            Icon(
                              c.isOnlineOverride
                                  ? Icons.videocam_rounded
                                  : Icons.location_on_outlined,
                              size: 13,
                              color: c.isOnlineOverride
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.isCancelledToday
                                    ? 'Kelas ditiadakan / libur'
                                    : (c.effectiveRuangan.isNotEmpty
                                        ? c.effectiveRuangan
                                        : 'Ruang A2'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.isCancelledToday
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF334155),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (c.hasActiveOverride &&
                            c.override!.alasan != null &&
                            c.override!.alasan!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan: ${c.override!.alasan}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 8),

                        // Lecturer & WA Shortcut
                        Row(
                          children: [
                            _buildLecturerAvatar(c.dosen, accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.dosen,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.dosen.trim().isNotEmpty)
                              ScaleButton(
                                onTap: () => _openWhatsAppDosen(context, c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_rounded,
                                        size: 11,
                                        color: Color(0xFF059669),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'WA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
