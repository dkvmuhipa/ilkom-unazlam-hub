import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../core/constants/app_colors.dart';
import '../../core/services/safe_launcher.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/models.dart';
import 'widgets/assignment_detail_sheet.dart';

class AssignmentsScreen extends StatefulWidget {
  final bool canManage;
  final String? userNim;
  final VoidCallback? onBack;
  const AssignmentsScreen({
    super.key,
    this.canManage = true,
    this.userNim,
    this.onBack,
  });

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
      builder: (ctx) => AssignmentDetailSheet(
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
  List<Assignment> _assignments = [];
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _loadError;
  RealtimeChannel? _assignmentsChannel;
  RealtimeChannel? _studentAssignmentsChannel;
  RealtimeChannel? _settingsChannel;

  @override
  void initState() {
    super.initState();
    _loadPersonalAssignmentStatuses();
    _initRealtime();
  }

  void _initRealtime() {
    _assignmentsChannel = SupabaseRepository.subscribeToAssignments(() {
      if (mounted) {
        _loadPersonalAssignmentStatuses(silent: true);
      }
    });
    _studentAssignmentsChannel =
        SupabaseRepository.subscribeToStudentAssignments(() {
          if (mounted) {
            _loadPersonalAssignmentStatuses(silent: true);
          }
        });
    _settingsChannel = SupabaseRepository.subscribeToTable(
      table: 'app_settings',
      onDataChanged: () {
        if (mounted) {
          _loadPersonalAssignmentStatuses(silent: true);
        }
      },
    );
  }

  @override
  void dispose() {
    SupabaseRepository.unsubscribeChannel(_assignmentsChannel);
    SupabaseRepository.unsubscribeChannel(_studentAssignmentsChannel);
    SupabaseRepository.unsubscribeChannel(_settingsChannel);
    super.dispose();
  }

  Future<void> _loadPersonalAssignmentStatuses({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final nim = widget.userNim;
      final results = await Future.wait<dynamic>([
        SupabaseRepository.getAssignmentsStrict(),
        SupabaseRepository.getCoursesStrict(),
        (nim != null && nim.isNotEmpty)
            ? SupabaseRepository.getPersonalAssignmentStatusesStrict(nim)
            : Future.value(<String, String>{}),
      ]);
      final loadedAssignments = results[0] as List<Assignment>;
      final loadedCourses = results[1] as List<Course>;
      final cloudStatuses = results[2] as Map<String, String>;

      for (final assignment in loadedAssignments) {
        assignment.status = cloudStatuses[assignment.id] ?? 'belum';
      }

      if (mounted) {
        setState(() {
          _assignments = loadedAssignments;
          _courses = loadedCourses;
          _loadError = null;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Gagal memuat tugas kelas dari Supabase: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError =
              'Tugas gagal dimuat dari server. Periksa koneksi lalu coba lagi.';
        });
      }
    }
  }

  final Map<String, Color> _courseColors = {
    'Pendidikan Kewarganegaraan': const Color(0xFFF59E0B),
    'Pendidikan Pancasila': const Color(0xFF6D28D9),
    'Ilmu Kealaman Dasar': const Color(0xFF0284C7),
    'Dasar-Dasar Ilmu Komunikasi': const Color(0xFFEF4444),
    'Pendidikan Agama Islam': const Color(0xFF10B981),
    'Pengantar Ilmu Politik': const Color(0xFF8B5CF6),
    'Bahasa Indonesia': const Color(0xFFD97706),
    'Bahasa Inggris Komunikasi': const Color(0xFF059669),
  };

  Future<void> _cycleStatus(Assignment assignment) async {
    final nim = widget.userNim ?? '';
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
        return const Color(0xFFF5F3FF);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  void _showAddAssignmentDialog() {
    final availableCourses = _courses.isNotEmpty ? _courses : <Course>[];
    if (_isLoading || _loadError != null || availableCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mata kuliah belum berhasil dimuat. Coba muat ulang dahulu.',
          ),
        ),
      );
      return;
    }
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final linkController = TextEditingController();
    String selectedCourse = availableCourses.first.nama;
    String kategori = 'Individu';
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));
    bool isSubmitting = false;

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
              Icon(Icons.add_task_rounded, color: Color(0xFF6D28D9), size: 22),
              SizedBox(width: 8),
              Text(
                'Tambah Tugas Baru',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 96)
                  .clamp(0.0, 380.0)
                  .toDouble(),
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
                    items: availableCourses
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
                      if (val != null) {
                        setDialogState(() => selectedCourse = val);
                      }
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final categoryField = DropdownButtonFormField<String>(
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
                          if (val != null) {
                            setDialogState(() => kategori = val);
                          }
                        },
                      );
                      final deadlineField = InkWell(
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
                      );

                      if (constraints.maxWidth < 340) {
                        return Column(
                          children: [
                            categoryField,
                            const SizedBox(height: 12),
                            deadlineField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: categoryField),
                          const SizedBox(width: 10),
                          Expanded(child: deadlineField),
                        ],
                      );
                    },
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final judul = titleController.text.trim();
                      if (judul.isEmpty) return;

                      setDialogState(() => isSubmitting = true);

                      final course = availableCourses.firstWhere(
                        (c) => c.nama == selectedCourse,
                        orElse: () => availableCourses.first,
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
                      final messenger = ScaffoldMessenger.of(context);

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
                        setDialogState(() => isSubmitting = false);
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Tugas gagal disimpan ke server.'),
                          ),
                        );
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadPersonalAssignmentStatuses(silent: true);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Tugas "$judul" berhasil ditambahkan!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Simpan Tugas'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Assignment> filteredList = _assignments;
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
      if (!_isLoading && _loadError == null)
        ..._courses.map((c) => c.nama).toSet(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF111827),
                ),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
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
          // Filter Chips & Course Dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Aktif',
                        _assignments
                            .where(
                              (a) =>
                                  a.status != 'selesai' &&
                                  a.status != 'dinilai',
                            )
                            .length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Selesai',
                        _assignments
                            .where(
                              (a) =>
                                  a.status == 'selesai' ||
                                  a.status == 'dinilai',
                            )
                            .length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Semua', _assignments.length),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availableCourses.contains(_selectedCourseFilter)
                          ? _selectedCourseFilter
                          : 'Semua Mata Kuliah',
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      items: availableCourses.map((c) {
                        final countInCourse = c == 'Semua Mata Kuliah'
                            ? _assignments.length
                            : _assignments
                                  .where((a) => a.courseName == c)
                                  .length;
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Row(
                            children: [
                              Icon(
                                c == 'Semua Mata Kuliah'
                                    ? Icons.tune_rounded
                                    : Icons.menu_book_rounded,
                                size: 15,
                                color: c == 'Semua Mata Kuliah'
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF6D28D9),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: c == _selectedCourseFilter
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (countInCourse > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$countInCourse',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
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

          // Assignment Progress Bar
          Builder(
            builder: (context) {
              final total = _assignments.length;
              final finished = _assignments
                  .where((a) => a.status == 'selesai' || a.status == 'dinilai')
                  .length;
              final percent = total > 0 ? (finished / total) : 0.0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 9,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progres Tugas Semester Ini: $finished/$total selesai',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              Text(
                                '${(percent * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6D28D9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Assignment List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 38,
                            color: AppColors.textSub,
                          ),
                          const SizedBox(height: 12),
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _loadPersonalAssignmentStatuses,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredList.isEmpty
                ? EmptyStateWidget(
                    icon: _selectedTab == 'Selesai'
                        ? Icons.checklist_rtl_rounded
                        : Icons.task_alt_rounded,
                    title: _assignments.isEmpty
                        ? 'Belum Ada Tugas'
                        : _selectedTab == 'Selesai'
                        ? 'Belum Ada Tugas Selesai'
                        : 'Semua Tugas Telah Tuntas! 🎉',
                    subtitle: _assignments.isEmpty
                        ? 'Tugas dari pengurus kelas akan muncul di sini.'
                        : _selectedTab == 'Selesai'
                        ? 'Tugas yang sudah selesai atau dinilai akan muncul di sini.'
                        : 'Bagus sekali! Tidak ada tenggat tugas yang menumpuk saat ini.',
                    actionLabel: widget.canManage ? 'Buat Tugas Baru' : null,
                    onAction: widget.canManage
                        ? _showAddAssignmentDialog
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final a = filteredList[index];
                      final courseColor =
                          _courseColors[a.courseName] ??
                          const Color(0xFF6D28D9);
                      final isDone =
                          a.status == 'selesai' || a.status == 'dinilai';

                      return InkWell(
                        onTap: () => AssignmentsScreen.showAssignmentDetail(
                          context,
                          a,
                          userNim: widget.userNim,
                          canManage: widget.canManage,
                          onStatusChanged: () => setState(() {}),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
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
                                    color: isDone
                                        ? const Color(0xFF10B981)
                                        : courseColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Course Pill, Category & Status / Quick Check Action
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: courseColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.sizeOf(context)
                                                    .width *
                                                .52,
                                          ),
                                          child: Text(
                                            a.courseName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: courseColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.sizeOf(context)
                                                    .width *
                                                .28,
                                          ),
                                          child: Text(
                                            a.kategori,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Quick Checkbox / Status Indicator
                                      InkWell(
                                        onTap: () => _cycleStatus(a),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusBgColor(a.status),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: _statusTextColor(a.status)
                                                  .withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isDone
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                          .radio_button_unchecked_rounded,
                                                size: 13,
                                                color: _statusTextColor(
                                                  a.status,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _statusLabel(a.status),
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: _statusTextColor(
                                                    a.status,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Assignment Title
                                  Text(
                                    a.judul,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDone
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF0F172A),
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      height: 1.25,
                                    ),
                                  ),

                                  if (a.deskripsi.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      a.deskripsi,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                  const SizedBox(height: 10),

                                  // Bottom Row: Deadline & Link
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_month_outlined,
                                            size: 14,
                                            color: _deadlineColor(a),
                                          ),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  MediaQuery.sizeOf(context)
                                                      .width *
                                                  .48,
                                            ),
                                            child: Text(
                                              '${a.deadline.day} ${_monthName(a.deadline.month)} ${a.deadline.year}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF475569),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _deadlineColor(a)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _deadlineLabel(a),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _deadlineColor(a),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (a.linkPengumpulan != null &&
                                          a.linkPengumpulan!.isNotEmpty)
                                        InkWell(
                                          onTap: () =>
                                              safeLaunchUrl(a.linkPengumpulan!),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F3FF),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFDDD6FE),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.link_rounded,
                                                  size: 12,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Link Tugas',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 13,
                                          color: Color(0xFF94A3B8),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedTab == label;
    return InkWell(
      onTap: () => setState(() => _selectedTab = label),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFF755BF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
