import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/assignment_file_picker.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/picked_assignment_file.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/models.dart';

class AssignmentsScreen extends StatefulWidget {
  final bool canManage;
  final String? userNim;
  const AssignmentsScreen({super.key, this.canManage = true, this.userNim});

  static void showAssignmentDetail(
    BuildContext context,
    Assignment assignment, {
    VoidCallback? onStatusChanged,
    String? userNim,
    bool canManage = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssignmentDetailSheet(
        assignment: assignment,
        onStatusChanged: onStatusChanged,
        userNim: userNim,
        canManage: canManage,
      ),
    );
  }

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String _selectedTab = 'Aktif';
  String _selectedCourseFilter = 'Semua Mata Kuliah';

  @override
  void initState() {
    super.initState();
    _loadPersonalAssignmentStatuses();
  }

  Future<void> _loadPersonalAssignmentStatuses() async {
    final nim = widget.userNim ?? 'default';
    try {
      await SupabaseRepository.getAssignments();
      final cloudStatuses =
          await SupabaseRepository.getPersonalAssignmentStatuses(nim);
      final prefs = await SharedPreferences.getInstance();
      for (var a in DummyData.assignments) {
        final saved =
            cloudStatuses[a.id] ??
            (SupabaseService.client == null
                ? prefs.getString('assignment_status_${nim}_${a.id}')
                : null);
        if (saved != null) {
          a.status = saved;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

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

  Future<void> _cycleStatus(Assignment assignment) async {
    final nim = widget.userNim ?? 'default';
    final previousStatus = assignment.status;
    final nextStatus = previousStatus == 'belum'
        ? 'sedang_dikerjakan'
        : previousStatus == 'sedang_dikerjakan'
        ? 'selesai'
        : 'belum';
    setState(() {
      assignment.status = nextStatus;
    });

    final saved = await SupabaseRepository.updateAssignmentStatus(
      assignment.id,
      nextStatus,
      studentNim: nim,
    );
    if (!saved) {
      if (mounted) setState(() => assignment.status = previousStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status tugas gagal disimpan.')),
        );
      }
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'assignment_status_${nim}_${assignment.id}',
        nextStatus,
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status tugas diubah: ${_statusLabel(assignment.status)}',
        ),
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
      case 'dikumpulkan':
        return 'Menunggu Nilai';
      case 'dinilai':
        return 'Sudah Dinilai';
      case 'selesai':
        return 'Selesai';
      default:
        return 'Belum Mulai';
    }
  }

  String _deadlineLabel(Assignment assignment) {
    if (assignment.status == 'selesai' || assignment.status == 'dinilai') {
      return assignment.status == 'dinilai' ? 'Sudah dinilai' : 'Tugas selesai';
    }
    if (assignment.status == 'dikumpulkan') return 'Menunggu penilaian';
    final today = DateUtils.dateOnly(DateTime.now());
    final deadline = DateUtils.dateOnly(assignment.deadline);
    final daysLeft = deadline.difference(today).inDays;
    if (daysLeft < 0) return 'Terlambat ${daysLeft.abs()} hari';
    if (daysLeft == 0) return 'Tenggat hari ini';
    if (daysLeft == 1) return 'Tenggat besok';
    return '$daysLeft hari lagi';
  }

  Color _deadlineColor(Assignment assignment) {
    if (assignment.status == 'selesai' || assignment.status == 'dinilai') {
      return const Color(0xFF059669);
    }
    final daysLeft = DateUtils.dateOnly(assignment.deadline)
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
    if (daysLeft < 0) return const Color(0xFFDC2626);
    if (daysLeft <= 2) return const Color(0xFFD97706);
    return const Color(0xFF6B7280);
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'belum':
        return const Color(0xFFEF4444);
      case 'sedang_dikerjakan':
        return const Color(0xFFD97706);
      case 'selesai':
      case 'dinilai':
        return const Color(0xFF059669);
      case 'dikumpulkan':
        return const Color(0xFF2563EB);
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
      case 'dinilai':
        return const Color(0xFFDCFCE7);
      case 'dikumpulkan':
        return const Color(0xFFEFF6FF);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  void _showAddAssignmentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final linkController = TextEditingController();
    String selectedCourse = DummyData.courses.first.nama;
    String kategori = 'Individu';
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: Color(0xFF5B3DE8), size: 22),
              SizedBox(width: 8),
              Text(
                'Tambah Tugas Baru',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourse,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: DummyData.courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.nama,
                            child: Text(
                              c.nama,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedCourse = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Tugas',
                      hintText: 'Misal: Makalah Komunikasi Massa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: kategori,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ['Individu', 'Kelompok', 'Praktikum', 'Ujian']
                              .map(
                                (k) => DropdownMenuItem(
                                  value: k,
                                  child: Text(
                                    k,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setDialogState(() => kategori = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDeadline,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDeadline = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Deadline',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi / Instruksi',
                      hintText:
                          'Tuliskan detail tugas atau format pengumpulan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Tautan Google Drive / Form (Opsional)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final judul = titleController.text.trim();
                if (judul.isEmpty) return;

                final course = DummyData.courses.firstWhere(
                  (c) => c.nama == selectedCourse,
                  orElse: () => DummyData.courses.first,
                );

                final newAssignment = Assignment(
                  id: 'asg_${DateTime.now().millisecondsSinceEpoch}',
                  courseId: course.id,
                  courseName: course.nama,
                  judul: judul,
                  deskripsi: descController.text.trim(),
                  kategori: kategori,
                  deadline: selectedDeadline,
                  linkPengumpulan: linkController.text.trim().isNotEmpty
                      ? linkController.text.trim()
                      : null,
                  status: 'belum',
                );

                final saved = await SupabaseRepository.createAssignment(
                  courseId: course.id,
                  courseName: course.nama,
                  judul: judul,
                  deskripsi: descController.text.trim(),
                  kategori: kategori,
                  deadline: selectedDeadline,
                  linkPengumpulan: newAssignment.linkPengumpulan,
                );
                if (!saved) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tugas gagal disimpan ke server.'),
                      ),
                    );
                  }
                  return;
                }
                if (mounted) setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tugas "$judul" berhasil ditambahkan!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan Tugas'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Assignment> filteredList = DummyData.assignments;
    if (_selectedTab == 'Aktif') {
      filteredList = filteredList
          .where((a) => a.status != 'selesai' && a.status != 'dinilai')
          .toList();
    } else if (_selectedTab == 'Selesai') {
      filteredList = filteredList
          .where((a) => a.status == 'selesai' || a.status == 'dinilai')
          .toList();
    }

    if (_selectedCourseFilter != 'Semua Mata Kuliah') {
      filteredList = filteredList
          .where((a) => a.courseName == _selectedCourseFilter)
          .toList();
    }

    final availableCourses = [
      'Semua Mata Kuliah',
      ...DummyData.courses.map((c) => c.nama).toSet(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddAssignmentDialog,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded, size: 20),
              label: const Text(
                'Tambah Tugas',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          : null,
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
      ),
      body: Column(
        children: [
          // Filter Chips matching Screen 5 (Aktif, Selesai, Semua) & Course Dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildFilterChip('Aktif'),
                    const SizedBox(width: 10),
                    _buildFilterChip('Selesai'),
                    const SizedBox(width: 10),
                    _buildFilterChip('Semua'),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availableCourses.contains(_selectedCourseFilter)
                          ? _selectedCourseFilter
                          : 'Semua Mata Kuliah',
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      items: availableCourses.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Row(
                            children: [
                              Icon(
                                c == 'Semua Mata Kuliah'
                                    ? Icons.filter_alt_outlined
                                    : Icons.book_outlined,
                                size: 14,
                                color: c == 'Semua Mata Kuliah'
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF5B3DE8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: c == _selectedCourseFilter
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: const Color(0xFF1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCourseFilter = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Assignment List
          Expanded(
            child: filteredList.isEmpty
                ? EmptyStateWidget(
                    icon: _selectedTab == 'Selesai'
                        ? Icons.checklist_rtl_rounded
                        : Icons.task_alt_rounded,
                    title: _selectedTab == 'Selesai'
                        ? 'Belum Ada Tugas Selesai'
                        : 'Semua Tugas Telah Tuntas! 🎉',
                    subtitle: _selectedTab == 'Selesai'
                        ? 'Tandai tugas yang sudah dikerjakan sebagai selesai untuk memantau progres.'
                        : 'Bagus sekali! Tidak ada tenggat tugas yang menumpuk saat ini.',
                    actionLabel: widget.canManage ? 'Buat Tugas Baru' : null,
                    onAction: widget.canManage
                        ? _showAddAssignmentDialog
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final a = filteredList[index];
                      final courseColor =
                          _courseColors[a.courseName] ??
                          const Color(0xFF5B3DE8);

                      return InkWell(
                        onTap: () => AssignmentsScreen.showAssignmentDetail(
                          context,
                          a,
                          userNim: widget.userNim,
                          canManage: widget.canManage,
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
                                      color: courseColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.description_outlined,
                                      color: courseColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 18,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _cycleStatus(a),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF3F4F6),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${a.deadline.day} ${_monthName(a.deadline.month)} ${a.deadline.year}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF6B7280),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _deadlineLabel(a),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _deadlineColor(a),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _cycleStatus(a),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
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
    const m = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
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
  final String? userNim;
  final bool canManage;

  const _AssignmentDetailSheet({
    required this.assignment,
    this.onStatusChanged,
    this.userNim,
    this.canManage = false,
  });

  @override
  State<_AssignmentDetailSheet> createState() => _AssignmentDetailSheetState();
}

class _AssignmentDetailSheetState extends State<_AssignmentDetailSheet> {
  late String _currentStatus;
  String _submissionUrl = '';
  String _submissionNotes = '';
  String _submittedAt = '';
  double? _grade;
  String _feedback = '';
  String _gradedAt = '';
  bool _isSavingSubmission = false;

  String get _submissionDisplayLabel {
    final uri = Uri.tryParse(_submissionUrl);
    return uri?.hasScheme == true
        ? _submissionUrl
        : _submissionUrl.split('/').last;
  }

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
    _loadSubmissionData();
  }

  Future<void> _loadSubmissionData() async {
    final nim = widget.userNim ?? 'default';
    try {
      if (SupabaseService.client != null) {
        final submission =
            await SupabaseRepository.getPersonalAssignmentSubmission(
              widget.assignment.id,
              nim,
            );
        if (mounted && submission != null) {
          setState(() {
            _submissionUrl = submission['link_pengumpulan']?.toString() ?? '';
            _submissionNotes = submission['catatan']?.toString() ?? '';
            _currentStatus = submission['status']?.toString() ?? _currentStatus;
            widget.assignment.status = _currentStatus;
            _grade = (submission['nilai'] as num?)?.toDouble();
            _feedback = submission['umpan_balik']?.toString() ?? '';
            final submittedAt = submission['submitted_at']?.toString();
            _submittedAt = submittedAt == null
                ? ''
                : DateTime.parse(submittedAt).toLocal().toString();
            final gradedAt = submission['graded_at']?.toString();
            _gradedAt = gradedAt == null
                ? ''
                : DateTime.parse(gradedAt).toLocal().toString();
          });
        }
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _submissionUrl =
            prefs.getString('asg_sub_url_${nim}_${widget.assignment.id}') ?? '';
        _submissionNotes =
            prefs.getString('asg_sub_notes_${nim}_${widget.assignment.id}') ??
            '';
        _submittedAt =
            prefs.getString('asg_sub_time_${nim}_${widget.assignment.id}') ??
            '';
      });
    } catch (_) {}
  }

  Future<bool> _saveSubmission(String url, String notes) async {
    final nim = widget.userNim ?? 'default';
    final now = DateTime.now();
    final formattedTime =
        '${now.day} ${_monthName(now.month)} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WITA';
    final saved = await SupabaseRepository.updateAssignmentStatus(
      widget.assignment.id,
      'dikumpulkan',
      studentNim: nim,
      submissionUrl: url,
      notes: notes,
    );
    if (!saved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengumpulan tugas gagal disimpan ke server.'),
          ),
        );
      }
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('asg_sub_url_${nim}_${widget.assignment.id}', url);
      await prefs.setString(
        'asg_sub_notes_${nim}_${widget.assignment.id}',
        notes,
      );
      await prefs.setString(
        'asg_sub_time_${nim}_${widget.assignment.id}',
        formattedTime,
      );
    } catch (_) {}
    setState(() {
      _submissionUrl = url;
      _submissionNotes = notes;
      _submittedAt = formattedTime;
      _currentStatus = 'dikumpulkan';
      widget.assignment.status = 'dikumpulkan';
    });
    widget.onStatusChanged?.call();
    return true;
  }

  Future<void> _setStatus(String status) async {
    final nim = widget.userNim ?? 'default';
    final previousStatus = _currentStatus;
    setState(() {
      _currentStatus = status;
      widget.assignment.status = status;
    });
    final saved = await SupabaseRepository.updateAssignmentStatus(
      widget.assignment.id,
      status,
      studentNim: nim,
    );
    if (!saved) {
      if (mounted) {
        setState(() {
          _currentStatus = previousStatus;
          widget.assignment.status = previousStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status tugas gagal disimpan.')),
        );
      }
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'assignment_status_${nim}_${widget.assignment.id}',
        status,
      );
    } catch (_) {}
    widget.onStatusChanged?.call();
  }

  Future<void> _openLink(String url) async {
    try {
      final parsed = Uri.tryParse(url);
      final target = parsed?.hasScheme == true
          ? url
          : await SupabaseRepository.createAssignmentSubmissionSignedUrl(url);
      final uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (error) {
      debugPrint('Gagal membuka berkas pengumpulan: $error');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Berkas tidak dapat dibuka. Periksa akses penyimpanan Supabase.',
            ),
          ),
        );
    }
  }

  Future<void> _showAssignmentSubmissions() async {
    final submissions = SupabaseRepository.getAssignmentSubmissions(
      widget.assignment.id,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pengumpulan Mahasiswa',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: submissions,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Pengumpulan gagal dimuat.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5B3DE8),
                        ),
                      );
                    }
                    final rows = snapshot.data!
                        .where(
                          (row) =>
                              row['status'] == 'dikumpulkan' ||
                              row['status'] == 'dinilai' ||
                              (row['link_pengumpulan']?.toString().isNotEmpty ??
                                  false),
                        )
                        .toList();
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada mahasiswa yang mengumpulkan tugas.',
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final nim = row['student_nim']?.toString() ?? '';
                        final link = row['link_pengumpulan']?.toString() ?? '';
                        final grade = (row['nilai'] as num?)?.toDouble();
                        final submittedAt = row['submitted_at']?.toString();
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFEDE9FE),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF5B3DE8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NIM $nim',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      grade == null
                                          ? 'Belum dinilai'
                                          : 'Nilai ${grade.toStringAsFixed(grade % 1 == 0 ? 0 : 1)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: grade == null
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF047857),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (submittedAt != null)
                                      Text(
                                        'Dikirim ${DateTime.tryParse(submittedAt)?.toLocal().toString().substring(0, 16) ?? submittedAt}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    if (row['umpan_balik']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true)
                                      Text(
                                        'Catatan: ${row['umpan_balik']}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (link.isNotEmpty)
                                IconButton(
                                  tooltip: 'Buka tugas',
                                  onPressed: () => _openLink(link),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    color: Color(0xFF5B3DE8),
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Beri nilai',
                                onPressed: () => _showGradeDialog(
                                  nim,
                                  grade,
                                  row['umpan_balik']?.toString() ?? '',
                                ),
                                icon: const Icon(
                                  Icons.rate_review_outlined,
                                  color: Color(0xFF5B3DE8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGradeDialog(
    String studentNim,
    double? oldGrade,
    String oldFeedback,
  ) async {
    final gradeController = TextEditingController(
      text: oldGrade?.toString() ?? '',
    );
    final feedbackController = TextEditingController(text: oldFeedback);
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Nilai pengumpulan · $studentNim'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nilai (0–100)',
                  suffixText: '/ 100',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Umpan balik (opsional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final grade = double.tryParse(
                gradeController.text.trim().replaceAll(',', '.'),
              );
              if (grade == null || grade < 0 || grade > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan nilai antara 0 sampai 100.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, (
                grade,
                feedbackController.text.trim(),
              ));
            },
            child: const Text('Simpan nilai'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await SupabaseRepository.gradeAssignmentSubmission(
        assignmentId: widget.assignment.id,
        studentNim: studentNim,
        grade: result.$1,
        feedback: result.$2,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onStatusChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nilai dan umpan balik berhasil disimpan.'),
        ),
      );
    } catch (error) {
      debugPrint('Gagal menyimpan nilai tugas: $error');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nilai gagal disimpan. Periksa migrasi dan izin akun.',
            ),
          ),
        );
    }
  }

  void _showSubmitFormDialog() {
    if (_grade != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tugas sudah dinilai. Hubungi pengurus bila perlu mengajukan revisi.',
          ),
        ),
      );
      return;
    }
    final linkController = TextEditingController(
      text: Uri.tryParse(_submissionUrl)?.hasScheme == true
          ? _submissionUrl
          : '',
    );
    final notesController = TextEditingController(text: _submissionNotes);
    PickedAssignmentFile? selectedFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.drive_folder_upload_rounded,
                color: Color(0xFF5B3DE8),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Kumpulkan Tugas',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih berkas tugas atau tempel tautan Drive yang dapat dibuka dosen. Batas berkas 20 MB.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSavingSubmission
                        ? null
                        : () async {
                            try {
                              final file = await pickAssignmentFile();
                              if (file == null || !ctx.mounted) return;
                              if (file.bytes.lengthInBytes > 20 * 1024 * 1024) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ukuran berkas maksimal 20 MB.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setDialogState(() => selectedFile = file);
                            } catch (error) {
                              debugPrint('Gagal memilih berkas tugas: $error');
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Berkas tidak dapat dibaca. Coba pilih berkas lain.',
                                    ),
                                  ),
                                );
                            }
                          },
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: Text(
                      selectedFile?.name ?? 'Pilih berkas dari perangkat',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Tautan Tugas (Google Drive / GitHub / dll)',
                      hintText: 'https://drive.google.com/...',
                      prefixIcon: const Icon(Icons.link_rounded, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Catatan Pengumpulan (Opsional)',
                      hintText: 'Misal: Revisi Bab 3 sudah disesuaikan',
                      prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSavingSubmission ? null : () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: _isSavingSubmission
                  ? null
                  : () async {
                      var link = linkController.text.trim();
                      final parsedLink = Uri.tryParse(link);
                      if (selectedFile == null &&
                          (parsedLink == null ||
                              !['http', 'https'].contains(parsedLink.scheme) ||
                              parsedLink.host.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Pilih berkas atau masukkan tautan https yang valid.',
                            ),
                          ),
                        );
                        return;
                      }
                      final notes = notesController.text.trim();
                      setState(() => _isSavingSubmission = true);
                      if (selectedFile != null) {
                        try {
                          link =
                              await SupabaseRepository.uploadAssignmentSubmissionFile(
                                assignmentId: widget.assignment.id,
                                studentNim: widget.userNim ?? '',
                                fileName: selectedFile!.name,
                                bytes: selectedFile!.bytes,
                                contentType: selectedFile!.contentType,
                              );
                        } catch (error) {
                          debugPrint('Gagal mengunggah berkas tugas: $error');
                          if (mounted)
                            setState(() => _isSavingSubmission = false);
                          if (ctx.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Berkas gagal diunggah. Pastikan migrasi penilaian sudah diterapkan.',
                                ),
                              ),
                            );
                          return;
                        }
                      }
                      final saved = await _saveSubmission(link, notes);
                      if (mounted) setState(() => _isSavingSubmission = false);
                      if (saved && ctx.mounted) Navigator.pop(ctx);
                      if (saved && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tautan tugas berhasil dikirim. Menunggu penilaian.',
                            ),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isSavingSubmission ? 'Menyimpan...' : 'Kirim untuk Dinilai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final a = widget.assignment;
    final titleController = TextEditingController(text: a.judul);
    final descController = TextEditingController(text: a.deskripsi);
    final linkController = TextEditingController(text: a.linkPengumpulan ?? '');
    String selectedCourse = a.courseName;
    String kategori = a.kategori;
    DateTime selectedDeadline = a.deadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF5B3DE8), size: 22),
              SizedBox(width: 8),
              Text(
                'Edit Tugas',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourse,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: DummyData.courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.nama,
                            child: Text(
                              c.nama,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedCourse = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Tugas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: kategori,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ['Individu', 'Kelompok', 'Praktikum', 'Ujian']
                              .map(
                                (k) => DropdownMenuItem(
                                  value: k,
                                  child: Text(
                                    k,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setDialogState(() => kategori = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDeadline,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 60),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDeadline = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Deadline',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi / Instruksi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Tautan Google Drive / Form',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final judul = titleController.text.trim();
                if (judul.isEmpty) return;

                final course = DummyData.courses.firstWhere(
                  (c) => c.nama == selectedCourse,
                  orElse: () => DummyData.courses.first,
                );

                final oldValues = (
                  a.judul,
                  a.courseName,
                  a.courseId,
                  a.kategori,
                  a.deadline,
                  a.deskripsi,
                  a.linkPengumpulan,
                );
                setState(() {
                  a.judul = judul;
                  a.courseName = course.nama;
                  a.courseId = course.id;
                  a.kategori = kategori;
                  a.deadline = selectedDeadline;
                  a.deskripsi = descController.text.trim();
                  a.linkPengumpulan = linkController.text.trim().isNotEmpty
                      ? linkController.text.trim()
                      : null;
                });
                final saved = await SupabaseRepository.updateAssignment(a);
                if (!saved) {
                  setState(() {
                    a.judul = oldValues.$1;
                    a.courseName = oldValues.$2;
                    a.courseId = oldValues.$3;
                    a.kategori = oldValues.$4;
                    a.deadline = oldValues.$5;
                    a.deskripsi = oldValues.$6;
                    a.linkPengumpulan = oldValues.$7;
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perubahan tugas gagal disimpan.'),
                      ),
                    );
                  }
                  return;
                }

                Navigator.pop(ctx);
                widget.onStatusChanged?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tugas berhasil diperbarui!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Tugas?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus tugas "${widget.assignment.judul}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final saved = await SupabaseRepository.deleteAssignment(
                widget.assignment.id,
              );
              if (!saved) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tugas gagal dihapus dari server.'),
                    ),
                  );
                }
                return;
              }
              Navigator.pop(ctx); // pop confirm dialog
              Navigator.pop(context); // pop detail sheet
              widget.onStatusChanged?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tugas berhasil dihapus.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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
      countdownText = 'Tugas Selesai';
      countdownColor = const Color(0xFF16A34A);
      countdownBg = const Color(0xFFDCFCE7);
    } else if (difference.isNegative) {
      countdownText = 'Lewat Deadline';
      countdownColor = const Color(0xFFDC2626);
      countdownBg = const Color(0xFFFEE2E2);
    } else if (daysRemaining == 0) {
      countdownText = 'Berakhir Hari Ini';
      countdownColor = const Color(0xFFD97706);
      countdownBg = const Color(0xFFFEF3C7);
    } else {
      countdownText = 'Sisa $daysRemaining Hari Lagi';
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                Row(
                  children: [
                    if (widget.canManage)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF5B3DE8),
                          size: 20,
                        ),
                        tooltip: 'Edit Tugas',
                        onPressed: _showEditDialog,
                      ),
                    if (widget.canManage)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        tooltip: 'Hapus Tugas',
                        onPressed: _confirmDelete,
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
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
                          child: const Icon(
                            Icons.alarm_rounded,
                            color: Color(0xFF5B3DE8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Batas Waktu Pengumpulan',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a.deadline.day} ${_monthName(a.deadline.month)} ${a.deadline.year}, ${a.deadline.hour.toString().padLeft(2, '0')}:${a.deadline.minute.toString().padLeft(2, '0')} WITA',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
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
                  if (!widget.canManage &&
                      _currentStatus != 'dikumpulkan' &&
                      _currentStatus != 'dinilai') ...[
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
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Detailed Instructions Box
                  const Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: Color(0xFF5B3DE8),
                      ),
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
                      a.deskripsi.isNotEmpty ? a.deskripsi : 'Belum ada catatan khusus dari dosen untuk tugas ini. Pastikan mengikuti pedoman umum penulisan akademik.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submission Link
                  if (a.linkPengumpulan != null &&
                      a.linkPengumpulan!.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
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
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: Color(0xFF0284C7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Google Classroom / Drive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.linkPengumpulan!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            tooltip: 'Salin Tautan',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: a.linkPengumpulan!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tautan pengumpulan berhasil disalin!',
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Buka',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Section: Bukti & Catatan Pengumpulan Mahasiswa
                  if (widget.canManage) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Penilaian tugas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF312E81),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Periksa tautan mahasiswa, lalu masukkan nilai dan umpan balik.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF5B556F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: _showAssignmentSubmissions,
                            icon: const Icon(
                              Icons.rate_review_outlined,
                              size: 17,
                            ),
                            label: const Text('Penilaian'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.drive_folder_upload_rounded,
                            size: 18,
                            color: Color(0xFF5B3DE8),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pengumpulan Tugas Saya',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _grade == null
                            ? _showSubmitFormDialog
                            : null,
                        icon: Icon(
                          _grade != null
                              ? Icons.verified_rounded
                              : _submissionUrl.isNotEmpty
                              ? Icons.edit_note_rounded
                              : Icons.upload_file_rounded,
                          size: 16,
                          color: const Color(0xFF5B3DE8),
                        ),
                        label: Text(
                          _grade != null
                              ? 'Sudah Dinilai'
                              : _submissionUrl.isNotEmpty
                              ? 'Ubah Tugas'
                              : 'Kirim Tugas',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5B3DE8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_submissionUrl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF059669),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Tugas Telah Dikumpulkan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              const Spacer(),
                              if (_submittedAt.isNotEmpty)
                                Text(
                                  _submittedAt,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.link_rounded,
                                size: 14,
                                color: Color(0xFF047857),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _submissionDisplayLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF065F46),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                  color: Color(0xFF047857),
                                ),
                                tooltip: 'Buka Tugas Saya',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _openLink(_submissionUrl),
                              ),
                            ],
                          ),
                          if (_submissionNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Catatan: $_submissionNotes',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF047857),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Anda belum mengunggah link/berkas tugas ini.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showSubmitFormDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B3DE8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Kirim',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_grade != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.grade_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 18,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Nilai ${_grade!.toStringAsFixed(_grade! % 1 == 0 ? 0 : 1)} / 100',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const Spacer(),
                              if (_gradedAt.isNotEmpty)
                                Text(
                                  _gradedAt,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                            ],
                          ),
                          if (_feedback.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Text(
                              _feedback,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (_currentStatus == 'dikumpulkan') ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Tugas telah dikirim dan sedang menunggu penilaian.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : const Color(0xFF9CA3AF),
              ),
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
    const m = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return m[month];
  }
}
