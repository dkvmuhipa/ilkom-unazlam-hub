import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../models/attendance_models.dart';

class CourseDetailModal {
  static void show(
    BuildContext context, {
    required Course course,
    required bool isDark,
    required List<AttendanceHistoryItem> history,
    required void Function(BuildContext context, {String? preselectedCourse, int? preselectedPertemuan}) onShowAbsenceRequest,
  }) {
    final courseLogs = history.where((h) => h.courseName.toLowerCase() == course.nama.toLowerCase()).toList();
    final courseHadir = courseLogs.where((h) => h.status == 'Hadir').length;
    final courseIzin = courseLogs.where((h) => h.status == 'Izin').length;
    final courseSakit = courseLogs.where((h) => h.status == 'Sakit').length;
    final courseAlpa = courseLogs.where((h) => h.status == 'Alpa').length;
    final int coursePct = courseLogs.isNotEmpty ? ((courseHadir / courseLogs.length) * 100).round() : 100;
    final bool isCourseSafe = coursePct >= 75;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.nama,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.kode} • ${course.sks} SKS • ${course.dosen}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isCourseSafe
                                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                      : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCourseSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  courseLogs.isNotEmpty ? '$coursePct%' : '100%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isCourseSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isCourseSafe
                                                ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                                                : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isCourseSafe ? 'Syarat UAS Aman' : 'Batas Kritis (<75%)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isCourseSafe ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target kelayakan: Min. 12 dari 16 pertemuan wajib hadir',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat('$courseHadir', 'Hadir', const Color(0xFF10B981), isDark),
                              _buildMiniStat('$courseIzin', 'Izin', const Color(0xFFF59E0B), isDark),
                              _buildMiniStat('$courseSakit', 'Sakit', const Color(0xFF3B82F6), isDark),
                              _buildMiniStat('$courseAlpa', 'Alpa', const Color(0xFFEF4444), isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rincian 16 Pertemuan Kuliah',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          '${courseLogs.length} Sesi Terlaksana',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ...List.generate(16, (index) {
                      final pNum = index + 1;
                      AttendanceHistoryItem? matchedLog;
                      for (final l in courseLogs) {
                        if (l.pertemuanKe == pNum) {
                          matchedLog = l;
                          break;
                        }
                      }
                      if (matchedLog == null && pNum <= courseLogs.length) {
                        matchedLog = courseLogs[courseLogs.length - pNum];
                      }

                      final bool isRecorded = matchedLog != null;
                      final status = matchedLog?.status ?? 'Mendatang';
                      Color stColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
                      Color stBg = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9);

                      if (status == 'Hadir') {
                        stColor = const Color(0xFF10B981);
                        stBg = isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5);
                      } else if (status == 'Izin') {
                        stColor = const Color(0xFFF59E0B);
                        stBg = isDark ? const Color(0xFF713F12) : const Color(0xFFFFFBEB);
                      } else if (status == 'Sakit') {
                        stColor = const Color(0xFF3B82F6);
                        stBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
                      } else if (status == 'Alpa') {
                        stColor = const Color(0xFFEF4444);
                        stBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222234) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRecorded
                                ? (isDark ? const Color(0xFF3E3E4E) : const Color(0xFFE2E8F0))
                                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isRecorded
                                    ? (stColor.withValues(alpha: 0.12))
                                    : (isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF8FAFC)),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'P$pNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isRecorded ? stColor : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pertemuan $pNum',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    isRecorded
                                        ? (matchedLog.catatan != null && matchedLog.catatan!.isNotEmpty
                                            ? '${matchedLog.date} • ${matchedLog.catatan}'
                                            : matchedLog.date)
                                        : 'Belum dijadwalkan / Mendatang',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: stBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: stColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Footer Action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onShowAbsenceRequest(context, preselectedCourse: course.nama);
                      },
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
                      label: const Text('Ajukan Izin / Sakit Matkul Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E40AF),
                        side: const BorderSide(color: Color(0xFF1E40AF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMiniStat(String value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
