import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AttendanceHistoryItem {
  final String date;
  final String courseName;
  final String status; // 'Hadir', 'Izin', 'Sakit', 'Alpa'

  const AttendanceHistoryItem({
    required this.date,
    required this.courseName,
    required this.status,
  });
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<AttendanceHistoryItem> _history = const [
    AttendanceHistoryItem(date: '5 Okt 2026', courseName: 'Pendidikan Pancasila', status: 'Hadir'),
    AttendanceHistoryItem(date: '1 Okt 2026', courseName: 'Ilmu Kealaman Dasar', status: 'Hadir'),
    AttendanceHistoryItem(date: '28 Sep 2026', courseName: 'Pendidikan Agama Islam', status: 'Izin'),
    AttendanceHistoryItem(date: '22 Sep 2026', courseName: 'Dasar-Dasar Ilmu Komunikasi', status: 'Hadir'),
    AttendanceHistoryItem(date: '18 Sep 2026', courseName: 'Pendidikan Kewarganegaraan', status: 'Hadir'),
    AttendanceHistoryItem(date: '15 Sep 2026', courseName: 'Pengantar Ilmu Politik', status: 'Hadir'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Absensi Saya',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Donut Chart Card matching Screen 6
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Circular Progress Donut Ring (90% Hadir)
                  SizedBox(
                    width: 125,
                    height: 125,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 125,
                          height: 125,
                          child: CircularProgressIndicator(
                            value: 0.90,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFF3F0FF),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B3DE8)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '90%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Hadir',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4 Stat Counters in a Row (Hadir, Izin, Sakit, Alpa)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('9', 'Hadir', const Color(0xFF10B981)),
                      _buildStatBox('1', 'Izin', const Color(0xFFF59E0B)),
                      _buildStatBox('0', 'Sakit', const Color(0xFF3B82F6)),
                      _buildStatBox('0', 'Alpa', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Pertemuan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pertemuan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '10',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Riwayat Absensi Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Absensi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Riwayat Absensi List matching Screen 6
            ..._history.map((h) => _buildHistoryTile(h)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
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

  Widget _buildHistoryTile(AttendanceHistoryItem item) {
    final isHadir = item.status == 'Hadir';
    final isIzin = item.status == 'Izin';
    final statusColor = isHadir ? const Color(0xFF10B981) : (isIzin ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final statusBg = isHadir ? const Color(0xFFECFDF5) : (isIzin ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Dot
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
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
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
