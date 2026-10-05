import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  static void showAssignmentDetail(BuildContext context, Assignment assignment, {VoidCallback? onStatusChanged}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssignmentDetailSheet(assignment: assignment, onStatusChanged: onStatusChanged),
    );
  }

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

                      return InkWell(
                        onTap: () => AssignmentsScreen.showAssignmentDetail(
                          context,
                          a,
                          onStatusChanged: () => setState(() {}),
                        ),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
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

class _AssignmentDetailSheet extends StatefulWidget {
  final Assignment assignment;
  final VoidCallback? onStatusChanged;

  const _AssignmentDetailSheet({required this.assignment, this.onStatusChanged});

  @override
  State<_AssignmentDetailSheet> createState() => _AssignmentDetailSheetState();
}

class _AssignmentDetailSheetState extends State<_AssignmentDetailSheet> {
  late String _currentStatus;

  final Map<String, Color> _courseColors = {
    'Pendidikan Kewarganegaraan': const Color(0xFFF59E0B),
    'Pendidikan Pancasila': const Color(0xFF5B3DE8),
    'Ilmu Kealaman Dasar *': const Color(0xFF0284C7),
    'Dasar-Dasar Ilmu Komunikasi': const Color(0xFFEF4444),
    'Pendidikan Agama Islam *': const Color(0xFF10B981),
    'Pengantar Ilmu Politik *': const Color(0xFF8B5CF6),
    'Bahasa Indonesia *': const Color(0xFFD97706),
    'Bahasa Inggris *': const Color(0xFF059669),
  };

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.assignment.status;
  }

  void _setStatus(String status) {
    setState(() {
      _currentStatus = status;
      widget.assignment.status = status;
    });
    widget.onStatusChanged?.call();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final courseColor = _courseColors[a.courseName] ?? const Color(0xFF5B3DE8);

    final now = DateTime.now();
    final difference = a.deadline.difference(now);
    final daysRemaining = difference.inDays;

    String countdownText;
    Color countdownColor;
    Color countdownBg;

    if (_currentStatus == 'selesai') {
      countdownText = '✓ Tugas Selesai';
      countdownColor = const Color(0xFF16A34A);
      countdownBg = const Color(0xFFDCFCE7);
    } else if (difference.isNegative) {
      countdownText = '⚠️ Lewat Deadline';
      countdownColor = const Color(0xFFDC2626);
      countdownBg = const Color(0xFFFEE2E2);
    } else if (daysRemaining == 0) {
      countdownText = '⏰ Berakhir Hari Ini!';
      countdownColor = const Color(0xFFD97706);
      countdownBg = const Color(0xFFFEF3C7);
    } else {
      countdownText = '⏳ Sisa $daysRemaining Hari Lagi';
      countdownColor = const Color(0xFF5B3DE8);
      countdownBg = const Color(0xFFEDE9FE);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: courseColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        a.courseName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: courseColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        a.kategori,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    a.judul,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deadline Card with Countdown Badge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(Icons.alarm_rounded, color: Color(0xFF5B3DE8), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Batas Waktu Pengumpulan',
                                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a.deadline.day} ${_monthName(a.deadline.month)} ${a.deadline.year}, ${a.deadline.hour.toString().padLeft(2, '0')}:${a.deadline.minute.toString().padLeft(2, '0')} WITA',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: countdownBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            countdownText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: countdownColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Selector
                  const Text(
                    'Status Pengerjaan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatusOption(
                        label: 'Belum Mulai',
                        statusKey: 'belum',
                        icon: Icons.radio_button_unchecked_rounded,
                        activeColor: const Color(0xFFEF4444),
                        activeBg: const Color(0xFFFEF2F2),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusOption(
                        label: 'Dikerjakan',
                        statusKey: 'sedang_dikerjakan',
                        icon: Icons.hourglass_top_rounded,
                        activeColor: const Color(0xFFD97706),
                        activeBg: const Color(0xFFFEF3C7),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusOption(
                        label: 'Selesai',
                        statusKey: 'selesai',
                        icon: Icons.check_circle_rounded,
                        activeColor: const Color(0xFF16A34A),
                        activeBg: const Color(0xFFDCFCE7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Detailed Instructions Box
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF5B3DE8)),
                      SizedBox(width: 8),
                      Text(
                        'Petunjuk & Instruksi Tugas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: Text(
                      a.deskripsi.isNotEmpty
                          ? a.deskripsi
                          : 'Belum ada catatan khusus dari dosen untuk tugas ini. Pastikan mengikuti pedoman umum penulisan akademik.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submission Link
                  if (a.linkPengumpulan != null && a.linkPengumpulan!.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.link_rounded, size: 18, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Text(
                          'Tautan Pengumpulan Tugas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF0284C7), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Google Classroom / Drive',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.linkPengumpulan!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6B7280)),
                            tooltip: 'Salin Tautan',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: a.linkPengumpulan!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tautan pengumpulan berhasil disalin!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          ElevatedButton(
                            onPressed: () => _openLink(a.linkPengumpulan!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B3DE8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Buka', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStatus == 'selesai') {
                          _setStatus('belum');
                        } else {
                          _setStatus('selesai');
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_currentStatus == 'selesai'
                                ? 'Selamat! Tugas berhasil ditandai selesai 🎉'
                                : 'Status tugas dikembalikan ke belum selesai.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStatus == 'selesai'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentStatus == 'selesai'
                                ? Icons.undo_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentStatus == 'selesai'
                                ? 'Buka Kembali (Tandai Belum Selesai)'
                                : 'Tandai Tugas Selesai ✓',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String label,
    required String statusKey,
    required IconData icon,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isSelected = _currentStatus == statusKey;

    return Expanded(
      child: InkWell(
        onTap: () => _setStatus(statusKey),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? activeColor : const Color(0xFF9CA3AF)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const m = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return m[month];
  }
}
