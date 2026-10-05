import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String _selectedTab = 'Aktif';

  final Map<String, Color> _courseColors = {
    'Pendidikan Kewarganegaraan': const Color(0xFFF59E0B),
    'Pendidikan Pancasila': const Color(0xFF5B3DE8),
    'Ilmu Kealaman Dasar': const Color(0xFF0284C7),
    'Dasar-Dasar Ilmu Komunikasi': const Color(0xFFEF4444),
    'Pendidikan Agama Islam': const Color(0xFF10B981),
    'Pengantar Ilmu Politik': const Color(0xFF8B5CF6),
    'Bahasa Indonesia': const Color(0xFFD97706),
    'Bahasa Inggris Komunikasi': const Color(0xFF059669),
  };

  void _cycleStatus(Assignment assignment) {
    setState(() {
      if (assignment.status == 'belum') {
        assignment.status = 'sedang_dikerjakan';
      } else if (assignment.status == 'sedang_dikerjakan') {
        assignment.status = 'selesai';
      } else {
        assignment.status = 'belum';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status tugas diubah: ${_statusLabel(assignment.status)}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'belum':
        return 'Belum Selesai';
      case 'sedang_dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return 'Belum Mulai';
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'belum':
        return const Color(0xFFEF4444);
      case 'sedang_dikerjakan':
        return const Color(0xFFD97706);
      case 'selesai':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'belum':
        return const Color(0xFFFEF2F2);
      case 'sedang_dikerjakan':
        return const Color(0xFFFEF3C7);
      case 'selesai':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Assignment> filteredList = DummyData.assignments;
    if (_selectedTab == 'Aktif') {
      filteredList = DummyData.assignments.where((a) => a.status != 'selesai').toList();
    } else if (_selectedTab == 'Selesai') {
      filteredList = DummyData.assignments.where((a) => a.status == 'selesai').toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Tugas Kelas',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF111827), size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips matching Screen 5 (Aktif, Selesai, Semua)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(
              children: [
                _buildFilterChip('Aktif'),
                const SizedBox(width: 10),
                _buildFilterChip('Selesai'),
                const SizedBox(width: 10),
                _buildFilterChip('Semua'),
              ],
            ),
          ),

          // Assignment List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada tugas di kategori ini',
                          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final a = filteredList[index];
                      final courseColor = _courseColors[a.courseName] ?? const Color(0xFF5B3DE8);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon box in course color
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: courseColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.description_outlined, color: courseColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.courseName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: courseColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        a.judul,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF9CA3AF)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _cycleStatus(a),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF3F4F6)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF9CA3AF)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${a.deadline.day} ${_monthName(a.deadline.month)} ${a.deadline.year}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () => _cycleStatus(a),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusBgColor(a.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _statusLabel(a.status),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: _statusTextColor(a.status),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const m = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return m[month];
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedTab == label;
    return InkWell(
      onTap: () => setState(() => _selectedTab = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
