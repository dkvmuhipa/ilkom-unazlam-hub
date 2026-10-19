import '../widgets/admin_detail_page.dart';
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
  final _newClassName = TextEditingController();
  final _newClassCapacity = TextEditingController(text: '30');
  String _newClassProdi = 'Ilmu Komunikasi';
  String _newClassSemester = 'Semester 1';
  String? _newClassYear;

  @override
  void dispose() {
    _newClassName.dispose();
    _newClassCapacity.dispose();
    super.dispose();
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
    if (years.isEmpty) {
      widget.onShowMessage('Tambahkan tahun akademik terlebih dahulu.', isError: true);
      name.dispose();
      capacity.dispose();
      return;
    }
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
    final students = widget.managedAccounts.where((student) => !student.isAdmin && student.kelas.toLowerCase() == cls.nama.toLowerCase()).toList();
    final courses = widget.courses.where((course) => course.semester == cls.semester).toList();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (detailContext) => AdminDetailPage(
      pageLabel: 'Detail Kelas', title: cls.nama,
      subtitle: '${cls.prodi} • Semester ${cls.semester} • ${cls.academicYear}', icon: Icons.groups_outlined,
      onEdit: () { Navigator.pop(detailContext); _showClassDialog(existing: cls); },
      actions: [AdminDetailAction('Ekspor presensi', Icons.download_outlined, () async {
        try {
          final logs = await SupabaseRepository.getAttendanceLogsStrict();
          final csv = ExportService.exportAttendanceCsv(courseName: cls.nama,
            logs: logs.where((row) => students.any((student) => student.nim == row['student_nim'])).toList(), students: students);
          if (!detailContext.mounted) return;
          ExportService.showExportSheet(detailContext, title: 'Presensi ${cls.nama}',
            fileName: 'presensi_${cls.nama.replaceAll(' ', '_')}.csv', content: csv, subtitle: 'Rekap kelas');
        } catch (error) {
          if (detailContext.mounted) ScaffoldMessenger.of(detailContext).showSnackBar(SnackBar(content: Text('Ekspor gagal: $error')));
        }
      })],
      tabs: [
        AdminDetailTab('Ringkasan', AdminDetailSection(title: 'Informasi kelas', children: [
          AdminDetailFields({'Program studi': cls.prodi, 'Semester': '${cls.semester}', 'Tahun akademik': cls.academicYear,
            'Kapasitas': '${cls.kapasitas} kursi', 'Mahasiswa terdaftar': '${students.length} mahasiswa'}),
        ])),
        AdminDetailTab('Mahasiswa', AdminDetailSection(title: 'Mahasiswa terdaftar', children: [
          if (students.isEmpty) const Text('Belum ada mahasiswa yang terdaftar di kelas ini.'),
          for (final student in students) ListTile(contentPadding: EdgeInsets.zero,
            title: Text(student.nama), subtitle: Text('NIM ${student.nim}'), trailing: const Icon(Icons.chevron_right),
            onTap: () { Navigator.pop(detailContext); widget.onNavigate('detail_mahasiswa', student: student); }),
        ])),
        AdminDetailTab('Mata Kuliah', AdminDetailSection(title: 'Mata kuliah semester ${cls.semester}', children: [
          if (courses.isEmpty) const Text('Belum ada mata kuliah untuk semester ini.'),
          for (final course in courses) ListTile(contentPadding: EdgeInsets.zero,
            title: Text(course.nama), subtitle: Text('${course.kode} • ${course.sks} SKS\n${course.dosen}')),
        ])),
      ],
    )));
  }
  Widget _buildTambahKelasForm() {
    final years = widget.academicYears.map((year) => year.tahun).toSet().toList();
    if (years.isEmpty) return const Center(child: Text('Tambahkan tahun akademik sebelum membuat kelas.'));
    if (!years.contains(_newClassYear)) {
      _newClassYear = widget.academicYears.firstWhere((year) => year.isAktif, orElse: () => widget.academicYears.first).tahun;
    }

    return StatefulBuilder(
      builder: (ctx, setFormState) => Column(
        children: [
          AdminAppBar(
            title: 'Tambah Kelas',
            showSearch: false,
            onBack: widget.onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const AdminFormLabel('Nama Kelas'),
                AdminFormField(
                  controller: _newClassName,
                  hintText: 'Contoh: Ilmu Komunikasi',
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Program Studi'),
                AdminDropdownField<String>(
                  value: _newClassProdi,
                  items: const [
                    'Ilmu Komunikasi',
                    'Ilmu Pemerintahan',
                    'Hubungan Internasional',
                  ],
                  onChanged: (val) {
                    if (val != null) setFormState(() => _newClassProdi = val);
                  },
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Semester'),
                AdminDropdownField<String>(
                  value: _newClassSemester,
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
                    if (val != null) setFormState(() => _newClassSemester = val);
                  },
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Tahun Akademik'),
                AdminDropdownField<String>(
                  value: _newClassYear!,
                  items: years,
                  onChanged: (val) {
                    if (val != null) setFormState(() => _newClassYear = val);
                  },
                ),
                const SizedBox(height: 14),
                const AdminFormLabel('Kapasitas Mahasiswa'),
                AdminFormField(
                  controller: _newClassCapacity,
                  hintText: 'Contoh: 30',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    final semNum = int.tryParse(
                          _newClassSemester.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        1;
                    final name = _newClassName.text.trim();
                    final kap = int.tryParse(_newClassCapacity.text);
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
                      prodi: _newClassProdi,
                      semester: semNum,
                      year: _newClassYear!,
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
          showSearch: false,
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
                        .where((s) => !s.isAdmin && s.kelas.toLowerCase() == cls.nama.toLowerCase())
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
