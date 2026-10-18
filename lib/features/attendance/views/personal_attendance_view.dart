import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import '../models/attendance_models.dart';
import '../widgets/course_detail_modal.dart';

/// Ultra-modern personal attendance view featuring an animated radial gauge with 75% UAS
/// safety marker, interactive 4-stat metric cards, alpa battery meter, and course breakdown.
class PersonalAttendanceView extends StatelessWidget {
  final bool isDark;
  final int totalSessions;
  final int hadirCount;
  final int izinCount;
  final int sakitCount;
  final int alpaCount;
  final double attendanceRatio;
  final int attendancePercent;
  final bool isSafeZone;
  final String studentName;
  final String studentNim;
  final List<AttendanceHistoryItem> history;
  final List<Course> courses;
  final VoidCallback onShowScanQr;
  final void Function(
    BuildContext context, {
    String? preselectedCourse,
    int? preselectedPertemuan,
  })
  onShowAbsenceRequest;
  final VoidCallback? onConfirmResetPersonalAttendance;

  const PersonalAttendanceView({
    super.key,
    required this.isDark,
    required this.totalSessions,
    required this.hadirCount,
    required this.izinCount,
    required this.sakitCount,
    required this.alpaCount,
    required this.attendanceRatio,
    required this.attendancePercent,
    required this.isSafeZone,
    required this.studentName,
    required this.studentNim,
    required this.history,
    this.courses = const [],
    required this.onShowScanQr,
    required this.onShowAbsenceRequest,
    this.onConfirmResetPersonalAttendance,
  });

  @override
  Widget build(BuildContext context) {
    const maxAlpaAllowed = 4;
    final remainingAlpa = (maxAlpaAllowed - alpaCount).clamp(0, maxAlpaAllowed);

    final atRiskCourses = courses.where((course) {
      final logs = history
          .where((h) => h.courseName.toLowerCase() == course.nama.toLowerCase())
          .toList();
      if (logs.isEmpty) return false;
      final hadir = logs.where((h) => h.status == 'Hadir').length;
      final pct = (hadir / logs.length) * 100;
      final alpaInCourse = logs.where((h) => h.status == 'Alpa').length;
      return pct < 75 || alpaInCourse >= 3;
    }).toList();

    final bool hasAcademicRisk =
        atRiskCourses.isNotEmpty || alpaCount >= 3 || remainingAlpa <= 1;

    return Column(
      children: [
        // 1. Quick Presensi & Izin Actions Banner
        FadeSlideEntrance(
          delay: const Duration(milliseconds: 60),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 540;
                final intro = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presensi Kuliah Mandiri',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pindai QR, masukkan PIN, atau ajukan izin',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final actions = _buildQuickAttendanceActions(
                  context,
                  isCompact,
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [intro, const SizedBox(height: 14), actions],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: intro),
                    const SizedBox(width: 14),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),

        // EARLY WARNING CARD JIKA ADA RISIKO UAS
        if (hasAcademicRisk)
          FadeSlideEntrance(
            delay: const Duration(milliseconds: 100),
            child: _buildAcademicWarningCard(
              context: context,
              atRiskCourses: atRiskCourses,
              remainingAlpa: remainingAlpa,
              isDark: isDark,
            ),
          ),

        // 2. HERO ATTENDANCE RADIAL GAUGE CARD (With 75% UAS Threshold Marker)
        FadeSlideEntrance(
          delay: const Duration(milliseconds: 140),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2E2E3E)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Kehadiran Semester',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Semester Ganjil 2026/2027 • Standar UAS 75%',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Safe Zone Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: totalSessions == 0
                            ? (isDark
                                  ? const Color(0xFF2E2E3E)
                                  : const Color(0xFFF1F5F9))
                            : (isSafeZone
                                  ? (isDark
                                        ? const Color(0xFF064E3B)
                                        : const Color(0xFFDCFCE7))
                                  : (isDark
                                        ? const Color(0xFF7F1D1D)
                                        : const Color(0xFFFEE2E2))),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: totalSessions == 0
                              ? (isDark
                                    ? const Color(0xFF3E3E4E)
                                    : const Color(0xFFE2E8F0))
                              : (isSafeZone
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFCA5A5)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            totalSessions == 0
                                ? Icons.schedule_rounded
                                : (isSafeZone
                                      ? Icons.verified_rounded
                                      : Icons.warning_amber_rounded),
                            size: 13,
                            color: totalSessions == 0
                                ? (isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B))
                                : (isSafeZone
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            totalSessions == 0
                                ? 'Belum Ada Sesi'
                                : (isSafeZone
                                      ? 'Syarat UAS Aman'
                                      : 'Batas Kritis (<75%)'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: totalSessions == 0
                                  ? (isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B))
                                  : (isSafeZone
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Radial Gauge with 75% Safety Line Marker
                SizedBox(
                  width: 145,
                  height: 145,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(145, 145),
                        painter: _AttendanceRadialGaugePainter(
                          progress: totalSessions > 0 ? attendanceRatio : 0.0,
                          isDark: isDark,
                          isSafeZone: isSafeZone,
                          totalSessions: totalSessions,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            totalSessions > 0 ? '$attendancePercent%' : '0%',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            totalSessions > 0
                                ? '$hadirCount/$totalSessions Sesi'
                                : 'Kehadiran',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4 Interactive Metric Cards: Hadir, Izin, Sakit, Alpa
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        count: '$hadirCount',
                        label: 'Hadir',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        count: '$izinCount',
                        label: 'Izin',
                        icon: Icons.assignment_turned_in_rounded,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        count: '$sakitCount',
                        label: 'Sakit',
                        icon: Icons.medical_services_rounded,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        count: '$alpaCount',
                        label: 'Alpa',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Visual Alpa Tolerance Battery Meter
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252538)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3E3E4E)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.battery_charging_full_rounded,
                            size: 15,
                            color: remainingAlpa <= 1
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF1E40AF),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toleransi Alpa (maks. 4 sesi)',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Sisa $remainingAlpa kali',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: remainingAlpa <= 1
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 4 Quota blocks
                      Row(
                        children: List.generate(4, (i) {
                          final isAlpaUsed = i < alpaCount;
                          return Expanded(
                            child: Container(
                              height: 6,
                              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                              decoration: BoxDecoration(
                                color: isAlpaUsed
                                    ? const Color(0xFFEF4444)
                                    : (isDark
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF34D399)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 3. COURSE ATTENDANCE BREAKDOWN (Per Mata Kuliah)
        FadeSlideEntrance(
          delay: const Duration(milliseconds: 180),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kehadiran Per Mata Kuliah',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${courses.length} Mata Kuliah',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2E2E3E)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 36,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada mata kuliah yang terjadwal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...courses.map((course) {
            // Check personal logs for this course
            final courseLogs = history
                .where(
                  (h) =>
                      h.courseName.toLowerCase() == course.nama.toLowerCase(),
                )
                .toList();
            final courseHadir = courseLogs
                .where((h) => h.status == 'Hadir')
                .length;
            final int coursePct = courseLogs.isNotEmpty
                ? ((courseHadir / courseLogs.length) * 100).round()
                : 100;
            final String badgeText = courseLogs.isNotEmpty
                ? '$coursePct% Hadir ($courseHadir/${courseLogs.length})'
                : 'Belum Ada Sesi';

            return ScaleButton(
              onTap: () => CourseDetailModal.show(
                context,
                course: course,
                isDark: isDark,
                history: history,
                onShowAbsenceRequest: onShowAbsenceRequest,
              ),
              scaleDown: 0.98,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E2E3E)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFF1E40AF),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.nama,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${course.kode} • ${course.sks} SKS • ${course.dosen}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: courseLogs.isNotEmpty
                                ? (coursePct >= 75
                                      ? (isDark
                                            ? const Color(0xFF064E3B)
                                            : const Color(0xFFECFDF5))
                                      : (isDark
                                            ? const Color(0xFF7F1D1D)
                                            : const Color(0xFFFEF2F2)))
                                : (isDark
                                      ? const Color(0xFF2E2E3E)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: courseLogs.isNotEmpty
                                  ? (coursePct >= 75
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444))
                                  : (isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pertemuan Indicator Matrix (P1 - P16)
                    Row(
                      children: List.generate(16, (i) {
                        final pNum = i + 1;
                        final isRecorded = pNum <= courseLogs.length;
                        final bool isHadir =
                            isRecorded &&
                            courseLogs[courseLogs.length - pNum].status ==
                                'Hadir';

                        Color dotColor = isDark
                            ? const Color(0xFF2E2E3E)
                            : const Color(0xFFE2E8F0);
                        if (isRecorded) {
                          dotColor = isHadir
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444);
                        }

                        return Expanded(
                          child: Container(
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: dotColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),

        // 4. RIWAYAT PRESENSI PRIBADI REAL-TIME
        FadeSlideEntrance(
          delay: const Duration(milliseconds: 220),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Presensi Pribadi',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (history.isNotEmpty &&
                      onConfirmResetPersonalAttendance != null) ...[
                    TextButton.icon(
                      onPressed: onConfirmResetPersonalAttendance,
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        size: 15,
                        color: Color(0xFFEF4444),
                      ),
                      label: const Text(
                        'Kosongkan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${history.length} Log Masuk',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (history.isEmpty)
          FadeSlideEntrance(
            delay: const Duration(milliseconds: 240),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E2E3E)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      size: 32,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Belum Ada Riwayat Presensi Pribadi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Presensi kuliah Anda melalui pemindaian QR Code atau lembar absensi kelas akan tercatat aman di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...history.map((h) => _buildHistoryTile(h, isDark)),
      ],
    );
  }

  Widget _buildQuickAttendanceActions(BuildContext context, bool compact) {
    return Row(
      children: [
        if (compact) ...[
          Expanded(child: _buildScanAction(compact: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildAbsenceAction(context, compact: true)),
        ] else ...[
          _buildScanAction(compact: false),
          const SizedBox(width: 6),
          _buildAbsenceAction(context, compact: false),
        ],
      ],
    );
  }

  Widget _buildScanAction({required bool compact}) => ScaleButton(
    onTap: onShowScanQr,
    scaleDown: 0.92,
    child: Container(
      width: compact ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 14,
            color: Color(0xFF1E40AF),
          ),
          SizedBox(width: 5),
          Text(
            'Presensi',
            style: TextStyle(
              color: Color(0xFF1E40AF),
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAbsenceAction(BuildContext context, {required bool compact}) =>
      ScaleButton(
        onTap: () => onShowAbsenceRequest(context),
        scaleDown: 0.92,
        child: Container(
          width: compact ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 10,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 13,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'Izin/Sakit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMetricCard({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicWarningCard({
    required BuildContext context,
    required List<Course> atRiskCourses,
    required int remainingAlpa,
    required bool isDark,
  }) {
    final hasSpecificCourseRisk = atRiskCourses.isNotEmpty;
    final courseNames = atRiskCourses.map((c) => c.nama).join(', ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERINGATAN DINI KELAYAKAN UAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasSpecificCourseRisk
                          ? 'Kehadiran pada mata kuliah "$courseNames" berada di bawah standar 75% atau mendekati batas alpa.'
                          : 'Toleransi ketidakhadiran tersisa $remainingAlpa kali sesi kuliah sebelum kehilangan hak mengikuti UAS.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF7F1D1D),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E0C0C) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Sesuai panduan akademik UNAZLAM, batas minimum kehadiran UAS adalah 75% (maks 4 kali alpa).',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onShowAbsenceRequest(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Ajukan Izin',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(AttendanceHistoryItem item, bool isDark) {
    final isHadir = item.status == 'Hadir';
    final isIzin = item.status == 'Izin';
    final isSakit = item.status == 'Sakit';

    Color statusColor = const Color(0xFFEF4444);
    Color statusBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);

    if (isHadir) {
      statusColor = const Color(0xFF10B981);
      statusBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
    } else if (isIzin) {
      statusColor = const Color(0xFFF59E0B);
      statusBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
    } else if (isSakit) {
      statusColor = const Color(0xFF3B82F6);
      statusBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.date,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.pertemuanKe != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2E2E3E)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'P${item.pertemuanKe}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Keterangan: ${item.catatan}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the attendance radial donut gauge with a 75% threshold tick marker
class _AttendanceRadialGaugePainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final bool isSafeZone;
  final int totalSessions;

  _AttendanceRadialGaugePainter({
    required this.progress,
    required this.isDark,
    required this.isSafeZone,
    required this.totalSessions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 11.0;

    // 1. Background Track
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc
    final activeColor = totalSessions == 0
        ? const Color(0xFF94A3B8)
        : (isSafeZone ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    final progressPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // 3. Draw 75% Threshold Marker (UAS Safety Line)
    // 75% point is at 270 degrees from top (-pi/2 + 2*pi*0.75 = pi)
    const thresholdAngle = startAngle + (2 * math.pi * 0.75);
    final markerInner = Offset(
      center.dx + (radius - strokeWidth / 2 - 3) * math.cos(thresholdAngle),
      center.dy + (radius - strokeWidth / 2 - 3) * math.sin(thresholdAngle),
    );
    final markerOuter = Offset(
      center.dx + (radius + strokeWidth / 2 + 4) * math.cos(thresholdAngle),
      center.dy + (radius + strokeWidth / 2 + 4) * math.sin(thresholdAngle),
    );

    final markerPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(markerInner, markerOuter, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _AttendanceRadialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isSafeZone != isSafeZone ||
        oldDelegate.totalSessions != totalSessions;
  }
}
