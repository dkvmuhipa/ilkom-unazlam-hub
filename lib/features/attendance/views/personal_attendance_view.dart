import 'package:flutter/material.dart';

import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';
import '../models/attendance_models.dart';
import '../widgets/course_detail_modal.dart';

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
  final void Function(BuildContext context, {String? preselectedCourse, int? preselectedPertemuan}) onShowAbsenceRequest;
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
      final logs = history.where((h) => h.courseName.toLowerCase() == course.nama.toLowerCase()).toList();
      if (logs.isEmpty) return false;
      final hadir = logs.where((h) => h.status == 'Hadir').length;
      final pct = (hadir / logs.length) * 100;
      final alpaInCourse = logs.where((h) => h.status == 'Alpa').length;
      return pct < 75 || alpaInCourse >= 3;
    }).toList();

    final bool hasAcademicRisk = atRiskCourses.isNotEmpty || alpaCount >= 3 || remainingAlpa <= 1;

    return Column(
      children: [
        // 1. Scan QR Quick Trigger Banner (Khusus Mahasiswa)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presensi Kuliah Mandiri',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pindai QR, masukkan PIN, atau ajukan izin/sakit',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleButton(
                    onTap: onShowScanQr,
                    scaleDown: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF1E40AF)),
                          SizedBox(width: 4),
                          Text(
                            'Presensi',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ScaleButton(
                    onTap: () => onShowAbsenceRequest(context),
                    scaleDown: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 13, color: Colors.white),
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
                  ),
                ],
              ),
            ],
          ),
        ),

        // EARLY WARNING CARD JIKA ADA RISIKO UAS
        if (hasAcademicRisk)
          _buildAcademicWarningCard(
            context: context,
            atRiskCourses: atRiskCourses,
            remainingAlpa: remainingAlpa,
            isDark: isDark,
          ),

        // 2. HERO ATTENDANCE CARD (Donut Progress + Safe Zone Status)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                          'Ringkasan Kehadiran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Semester Ganjil 2026/2027',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Safe Zone Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: totalSessions == 0
                          ? (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9))
                          : (isSafeZone
                              ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: totalSessions == 0
                            ? (isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0))
                            : (isSafeZone ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          totalSessions == 0
                              ? Icons.schedule_rounded
                              : (isSafeZone ? Icons.check_circle_rounded : Icons.warning_amber_rounded),
                          size: 13,
                          color: totalSessions == 0
                              ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                              : (isSafeZone ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          totalSessions == 0
                              ? 'Belum Ada Sesi'
                              : (isSafeZone ? 'Syarat Ujian Aman' : 'Batas Kritis (<75%)'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: totalSessions == 0
                                ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                                : (isSafeZone ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Circular Gauge Donut
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: totalSessions > 0 ? attendanceRatio : 0.0,
                        strokeWidth: 11,
                        backgroundColor: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFEFF6FF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalSessions == 0
                              ? const Color(0xFF94A3B8)
                              : (isSafeZone ? const Color(0xFF1E40AF) : const Color(0xFFEF4444)),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          totalSessions > 0 ? '$attendancePercent%' : '0%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Kehadiran',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4 Stat Counters in a Row (Hadir, Izin, Sakit, Alpa)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('$hadirCount', 'Hadir', const Color(0xFF10B981), isDark),
                  _buildStatBox('$izinCount', 'Izin', const Color(0xFFF59E0B), isDark),
                  _buildStatBox('$sakitCount', 'Sakit', const Color(0xFF3B82F6), isDark),
                  _buildStatBox('$alpaCount', 'Alpa', const Color(0xFFEF4444), isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Safe Tolerance Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1E40AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toleransi Alpa: sisa $remainingAlpa kali dari maks 4 pertemuan sebelum tidak memenuhi syarat UAS.',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. COURSE ATTENDANCE BREAKDOWN (Per Mata Kuliah)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kehadiran Per Mata Kuliah',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            Text(
              '8 Mata Kuliah',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.menu_book_rounded, size: 36, color: isDark ? Colors.white38 : Colors.grey.shade400),
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
            final courseLogs = history.where((h) => h.courseName.toLowerCase() == course.nama.toLowerCase()).toList();
            final courseHadir = courseLogs.where((h) => h.status == 'Hadir').length;
            final int coursePct = courseLogs.isNotEmpty ? ((courseHadir / courseLogs.length) * 100).round() : 100;
            final String badgeText = courseLogs.isNotEmpty ? '$coursePct% Hadir ($courseHadir/${courseLogs.length})' : 'Belum Ada Sesi';

            return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => CourseDetailModal.show(
                context,
                course: course,
                isDark: isDark,
                history: history,
                onShowAbsenceRequest: onShowAbsenceRequest,
              ),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
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
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E40AF), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.nama,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${course.kode} • ${course.sks} SKS • ${course.dosen}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: courseLogs.isNotEmpty
                                ? (coursePct >= 75
                                    ? (isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5))
                                    : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: courseLogs.isNotEmpty
                                  ? (coursePct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pertemuan Indicator Matrix (P1 - P16) based on real sessions recorded
                    Row(
                      children: List.generate(16, (i) {
                        final pNum = i + 1;
                        final isRecorded = pNum <= courseLogs.length;
                        final bool isHadir = isRecorded && courseLogs[courseLogs.length - pNum].status == 'Hadir';

                        Color dotColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0);
                        if (isRecorded) {
                          dotColor = isHadir ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
            ),
          );
        }),
        const SizedBox(height: 20),

        // 4. RIWAYAT PRESENSI PRIBADI REAL-TIME
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Presensi Pribadi',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (history.isNotEmpty && onConfirmResetPersonalAttendance != null) ...[
                  TextButton.icon(
                    onPressed: onConfirmResetPersonalAttendance,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 15, color: Color(0xFFEF4444)),
                    label: const Text(
                      'Kosongkan',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        const SizedBox(height: 10),

        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.how_to_reg_rounded, size: 32, color: Color(0xFF1E40AF)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Belum Ada Riwayat Presensi Pribadi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Presensi kuliah Anda melalui pemindaian QR Code atau lembar absensi kelas akan tercatat aman di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ...history.map((h) => _buildHistoryTile(h, isDark)),
      ],
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
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
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
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
                        color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
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
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Ajukan Izin',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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
      statusBg = isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5);
    } else if (isIzin) {
      statusColor = const Color(0xFFF59E0B);
      statusBg = isDark ? const Color(0xFF713F12) : const Color(0xFFFFFBEB);
    } else if (isSakit) {
      statusColor = const Color(0xFF3B82F6);
      statusBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
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
                        color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.pertemuanKe != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'P${item.pertemuanKe}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
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
