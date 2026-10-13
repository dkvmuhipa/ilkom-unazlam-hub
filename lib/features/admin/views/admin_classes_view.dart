import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_academic_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../models/models.dart';
import '../models/admin_models.dart';
import '../widgets/admin_common_widgets.dart';

class AdminClassesView extends StatefulWidget {
  final bool isAddMode;
  final List<ClassItem> classes;
  final List<AcademicYearItem> academicYears;
  final List<Course> courses;
  final List<StudentProfile> managedAccounts;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onBack;
  final void Function(String view, {StudentProfile? student}) onNavigate;
  final Future<void> Function() onReload;
  final void Function(String message, {bool isError}) onShowMessage;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic>? metadata,
  }) onRecordAudit;
  final Future<bool> Function(String prompt) onConfirmDelete;

  const AdminClassesView({
    super.key,
    this.isAddMode = false,
    required this.classes,
    required this.academicYears,
    required this.courses,
    required this.managedAccounts,
    required this.isLoading,
    required this.loadError,
    required this.onBack,
    required this.onNavigate,
    required this.onReload,
    required this.onShowMessage,
    required this.onRecordAudit,
    required this.onConfirmDelete,
  });

  @override
  State<AdminClassesView> createState() => _AdminClassesViewState();
}

class _AdminClassesViewState extends State<AdminClassesView> {
  String _classSearchQuery = '';

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'M';
  }

  Future<void> _saveClass({
    String? id,
    required String name,
    required String prodi,
    required int semester,
    required String year,
    required int capacity,
  }) async {
    try {
      await AdminAcademicService.saveClass(
        id: id,
        nama: name,
        prodi: prodi,
        semester: semester,
        academicYear: year,
        capacity: capacity,
      );
      widget.onRecordAudit(
        action: id == null ? 'CREATE' : 'UPDATE',
        module: 'KELAS',
        description: '${id == null ? 'Menambahkan' : 'Memperbarui'} kelas $name, semester $semester ($year).',
        metadata: {
          'program_studi': prodi,
          'semester': semester,
          'tahun_akademik': year,
          'kapasitas': capacity,
        },
      );
      await widget.onReload();
      if (!mounted) return;
      widget.onNavigate('kelas');
      widget.onShowMessage(
        id == null ? 'Kelas berhasil disimpan ke Supabase.' : 'Perubahan kelas berhasil disimpan.',
      );
    } catch (error) {
      widget.onShowMessage(error.toString(), isError: true);
    }
  }

  Future<void> _showClassDialog({ClassItem? existing}) async {
    final name = TextEditingController(text: existing?.nama ?? '');
    final capacity = TextEditingController(text: '${existing?.kapasitas ?? 30}');
    final prodis = ['Ilmu Komunikasi', 'Ilmu Pemerintahan', 'Hubungan Internasional'];
    final years = widget.academicYears.map((year) => year.tahun).toList();
    if (existing != null && !years.contains(existing.academicYear)) {
      years.insert(0, existing.academicYear);
    }
    if (years.isEmpty) years.add('2026/2027');
    var prodi = existing?.prodi ?? prodis.first;
    var semester = existing?.semester ?? 1;
    var year = existing?.academicYear ?? years.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Tambah kelas' : 'Edit kelas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama kelas')),
                DropdownButtonFormField<String>(
                  initialValue: prodi,
                  decoration: const InputDecoration(labelText: 'Program studi'),
                  items: prodis.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) {
                    if (v != null) setDialog(() => prodi = v);
                  },
                ),
                DropdownButtonFormField<int>(
                  initialValue: semester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: List.generate(8, (i) => i + 1)
                      .map((v) => DropdownMenuItem(value: v, child: Text('Semester $v')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialog(() => semester = v);
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'Tahun akademik'),
                  items: years.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) {
                    if (v != null) setDialog(() => year = v);
                  },
                ),
                TextField(
                  controller: capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kapasitas mahasiswa'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (result == true) {
      final cap = int.tryParse(capacity.text);
      if (name.text.trim().isEmpty || cap == null || cap < 1) {
        widget.onShowMessage('Lengkapi nama dan kapasitas kelas.', isError: true);
        return;
      }
      await _saveClass(
        id: existing?.id,
        name: name.text.trim(),
        prodi: prodi,
        semester: semester,
        year: year,
        capacity: cap,
      );
    }
  }

  void _showClassDetail(ClassItem cls) {
    final classStudents = widget.managedAccounts
        .where((s) => !s.isAdmin && (s.kelas.toLowerCase() == cls.nama.toLowerCase() || s.semester == cls.semester))
        .toList();
    final classCourses = widget.courses;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.nama,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                      ),
                      Text(
                        '${cls.prodi} • Semester ${cls.semester} • ${cls.academicYear}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kapasitas', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text(
                          '${cls.kapasitas} Kursi',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mahasiswa Aktif', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text(
                          '${classStudents.length} Mahasiswa',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mata Kuliah', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text(
                          '${classCourses.length} MK',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final logs = await SupabaseRepository.getAttendanceLogs();
                      final csv = ExportService.exportAttendanceCsv(
                        courseName: cls.nama,
                        logs: logs,
                        students: widget.managedAccounts,
                      );
                      if (context.mounted) {
                        ExportService.showExportSheet(
                          context,
                          title: 'Presensi ${cls.nama}',
                          fileName: 'presensi_${cls.nama.replaceAll(' ', '_')}.csv',
                          content: csv,
                          subtitle: 'Daftar Presensi Kelas',
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Ekspor Presensi', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showClassDialog(existing: cls);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Kelas', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Mahasiswa Terdaftar (${classStudents.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            if (classStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada mahasiswa yang terdaftar di kelas ini.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              )
            else
              ...classStudents.map(
                (s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          _getInitials(s.nama),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text('NIM ${s.nim} • ${s.jabatan}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onNavigate('detail_mahasiswa', student: s);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTambahKelasForm() {
    final namaController = TextEditingController(text: 'Ilmu Komunikasi');
    final kapasitasController = TextEditingController(text: '30');
    String selectedProdi = 'Ilmu Komunikasi';
    String selectedSemester = 'Semester 1';
    String selectedTA = '2026/2027';

    return StatefulBuilder(
      builder: (ctx, setFormState) => Column(
        children: [
          AdminAppBar(
            title: 'Tambah Kelas',
            showSearch: false,
            onBack: widget.onBack,
            onSearch: () {},
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const AdminFormLabel('Nama Kelas'),
                AdminFormField(
                  controller: namaController,
                  hintText: 'Contoh: Ilmu Komunikasi',
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Program Studi'),
                AdminDropdownField<String>(
                  value: selectedProdi,
                  items: const [
                    'Ilmu Komunikasi',
                    'Ilmu Pemerintahan',
                    'Hubungan Internasional',
                  ],
                  onChanged: (val) {
                    if (val != null) setFormState(() => selectedProdi = val);
                  },
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Semester'),
                AdminDropdownField<String>(
                  value: selectedSemester,
                  items: const [
                    'Semester 1',
                    'Semester 2',
                    'Semester 3',
                    'Semester 4',
                    'Semester 5',
                    'Semester 6',
                    'Semester 7',
                    'Semester 8',
                  ],
                  onChanged: (val) {
                    if (val != null) setFormState(() => selectedSemester = val);
                  },
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Tahun Akademik'),
                AdminDropdownField<String>(
                  value: selectedTA,
                  items: const ['2026/2027', '2025/2026', '2024/2025'],
                  onChanged: (val) {
                    if (val != null) setFormState(() => selectedTA = val);
                  },
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Kapasitas Mahasiswa'),
                AdminFormField(
                  controller: kapasitasController,
                  hintText: 'Contoh: 30',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    final semNum = int.tryParse(
                          selectedSemester.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        1;
                    final name = namaController.text.trim();
                    final kap = int.tryParse(kapasitasController.text);
                    if (name.isEmpty || kap == null || kap < 1) {
                      widget.onShowMessage(
                        'Nama kelas dan kapasitas harus diisi dengan benar.',
                        isError: true,
                      );
                      return;
                    }
                    _saveClass(
                      id: null,
                      name: name,
                      prodi: selectedProdi,
                      semester: semNum,
                      year: selectedTA,
                      capacity: kap,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAddMode) {
      return _buildTambahKelasForm();
    }

    return Column(
      children: [
        AdminAppBar(
          title: 'Data Kelas',
          onBack: widget.onBack,
          onSearch: () {},
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              AdminSearchBox(
                hintText: 'Cari nama kelas...',
                onChanged: (value) => setState(() => _classSearchQuery = value),
              ),
              if (widget.loadError != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    widget.loadError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              if (widget.isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => widget.onNavigate('tambah_kelas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '+ Tambah Kelas',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              () {
                final filteredClasses = widget.classes
                    .where((cls) => '${cls.nama} ${cls.prodi} ${cls.academicYear}'
                        .toLowerCase()
                        .contains(_classSearchQuery.toLowerCase()))
                    .toList();

                if (filteredClasses.isEmpty && !widget.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateWidget(
                      icon: Icons.groups_outlined,
                      title: _classSearchQuery.isEmpty ? 'Belum Ada Data Kelas' : 'Kelas Tidak Ditemukan',
                      subtitle: _classSearchQuery.isEmpty
                          ? 'Daftar kelas akademik di Supabase masih kosong. Tambahkan kelas baru.'
                          : 'Tidak ada kelas yang cocok dengan pencarian "$_classSearchQuery".',
                    ),
                  );
                }

                return Column(
                  children: filteredClasses.map((cls) {
                    final studentCount = widget.managedAccounts
                        .where((s) => !s.isAdmin && (s.kelas.toLowerCase() == cls.nama.toLowerCase() || s.semester == cls.semester))
                        .length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showClassDetail(cls),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ColorfulIconBox(
                              icon: Icons.groups_rounded,
                              color: AppColors.primary,
                              size: 44,
                              iconSize: 22,
                              radius: 13,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cls.nama,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cls.prodi} • Semester ${cls.semester} • ${cls.academicYear} • $studentCount mahasiswa',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onSelected: (val) async {
                                if (val == 'detail') {
                                  _showClassDetail(cls);
                                } else if (val == 'hapus' && cls.id != null) {
                                  if (await widget.onConfirmDelete('Hapus kelas ${cls.nama}?')) {
                                    try {
                                      await AdminAcademicService.deleteClass(cls.id!);
                                      widget.onRecordAudit(
                                        action: 'DELETE',
                                        module: 'KELAS',
                                        description: 'Menghapus kelas ${cls.nama}, semester ${cls.semester}.',
                                        metadata: {'class_id': cls.id},
                                      );
                                      await widget.onReload();
                                    } catch (error) {
                                      widget.onShowMessage(error.toString(), isError: true);
                                    }
                                  }
                                } else if (val == 'edit') {
                                  _showClassDialog(existing: cls);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Detail Kelas'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Data'),
                                ),
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text(
                                    'Hapus Kelas',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }(),
        ],
          ),
        ),
      ],
    );
  }
}
