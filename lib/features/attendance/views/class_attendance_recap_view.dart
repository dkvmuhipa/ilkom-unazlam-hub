import 'package:flutter/material.dart';

import '../../../models/models.dart';

class ClassAttendanceRecapView extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> allClassLogs;
  final List<StudentProfile> students;
  final VoidCallback onConfirmResetAllAttendance;

  const ClassAttendanceRecapView({
    super.key,
    required this.isDark,
    required this.allClassLogs,
    required this.students,
    required this.onConfirmResetAllAttendance,
  });

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStudents = students.where((s) => s.role != 'ADMIN').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class Quick Overview
        Builder(
          builder: (context) {
            final totalLogs = allClassLogs.length;
            final hadirLogs = allClassLogs
                .where(
                  (l) =>
                      (l['status'] ?? '').toString().toLowerCase() == 'hadir',
                )
                .length;
            final classAvgStr = totalLogs > 0
                ? '${((hadirLogs / totalLogs) * 100).toStringAsFixed(1)}%'
                : '0.0%';

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Mahasiswa',
                    value: '${activeStudents.length}',
                    subtitle: 'Mahasiswa Terdaftar',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF6D28D9),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Rata-Rata Kelas',
                    value: classAvgStr,
                    subtitle: totalLogs > 0
                        ? '$hadirLogs / $totalLogs Hadir'
                        : 'Belum Ada Sesi',
                    icon: Icons.trending_up_rounded,
                    color: totalLogs > 0
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    isDark: isDark,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Rekap Kehadiran Mahasiswa (${activeStudents.length})',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (allClassLogs.isNotEmpty) ...[
              TextButton.icon(
                onPressed: onConfirmResetAllAttendance,
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
              const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Students Table List with Real Data from allClassLogs
        if (activeStudents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                    Icons.people_outline_rounded,
                    size: 36,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada data mahasiswa terdaftar',
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
          ...activeStudents.map((s) {
            final sLogs = allClassLogs
                .where((l) => l['student_nim'] == s.nim)
                .toList();
            final sHadir = sLogs
                .where(
                  (l) =>
                      (l['status'] ?? '').toString().toLowerCase() == 'hadir',
                )
                .length;
            final int hadirPct = sLogs.isNotEmpty
                ? ((sHadir / sLogs.length) * 100).round()
                : 0;
            final String sessionInfo = sLogs.isNotEmpty
                ? '$sHadir/${sLogs.length} Sesi'
                : 'Belum Ada Sesi';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E2E3E)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6D28D9)
                        .withValues(alpha: 0.1),
                    child: Text(
                      s.nama.isNotEmpty ? s.nama[0] : 'M',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nama,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.nim} • ${s.jabatan} • $sessionInfo',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sLogs.isNotEmpty
                          ? (hadirPct >= 75
                                ? (isDark
                                      ? const Color(0xFF14532D)
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
                      sLogs.isNotEmpty ? '$hadirPct%' : '-',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: sLogs.isNotEmpty
                            ? (hadirPct >= 75
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                            : (isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
