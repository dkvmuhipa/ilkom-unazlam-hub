import '../widgets/admin_detail_page.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_academic_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/services/supabase_service.dart';
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
    String? oldName,
    required String name,
    required String prodi,
    required int semester,
    required String year,
    required int capacity,
  }) async {
    try {
      await AdminAcademicService.saveClass(
        id: id,
        oldNama: oldName,
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
    final prodis = ClassItem.availableProdis;
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
        oldName: existing?.nama,
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
      actions: [
        AdminDetailAction('Kelola Mahasiswa', Icons.group_add_outlined, () {
          _showBulkAssignStudentsDialog(cls, detailContext);
        }),
        AdminDetailAction('Ekspor presensi', Icons.download_outlined, () async {
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
        }),
      ],
      tabs: [
        AdminDetailTab('Ringkasan', AdminDetailSection(title: 'Informasi kelas', children: [
          AdminDetailFields({'Program studi': cls.prodi, 'Semester': '${cls.semester}', 'Tahun akademik': cls.academicYear,
            'Kapasitas': '${cls.kapasitas} kursi', 'Mahasiswa terdaftar': '${students.length} mahasiswa'}),
        ])),
        AdminDetailTab('Mahasiswa', AdminDetailSection(title: 'Mahasiswa terdaftar (${students.length}/${cls.kapasitas})', children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onPressed: () => _showBulkAssignStudentsDialog(cls, detailContext),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Pilih & Masukkan Mahasiswa Sekaligus',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada mahasiswa yang terdaftar di kelas ini.\nKlik tombol di atas untuk memilih dan memasukkan mahasiswa sekaligus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
              ),
            ),
          for (final student in students)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                child: Text(
                  student.nama.isNotEmpty ? student.nama[0].toUpperCase() : 'M',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              title: Text(student.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              subtitle: Text('NIM ${student.nim} • Semester ${student.semester}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 20),
                    tooltip: 'Keluarkan dari kelas',
                    onPressed: () async {
                      if (await widget.onConfirmDelete('Keluarkan ${student.nama} (${student.nim}) dari kelas ${cls.nama}?')) {
                        try {
                          await AdminAcademicService.removeStudentFromClass(student.nim);
                          widget.onRecordAudit(
                            action: 'REMOVE_FROM_CLASS',
                            module: 'KELAS',
                            description: 'Mengeluarkan mahasiswa ${student.nama} (${student.nim}) dari kelas ${cls.nama}.',
                            metadata: {'student_nim': student.nim, 'class_name': cls.nama},
                          );
                          await widget.onReload();
                          if (detailContext.mounted) Navigator.pop(detailContext);
                          widget.onShowMessage('${student.nama} berhasil dikeluarkan dari kelas.');
                        } catch (e) {
                          widget.onShowMessage(e.toString(), isError: true);
                        }
                      }
                    },
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
              onTap: () {
                Navigator.pop(detailContext);
                widget.onNavigate('detail_mahasiswa', student: student);
              },
            ),
        ])),
        AdminDetailTab('Mata Kuliah', AdminDetailSection(title: 'Mata kuliah semester ${cls.semester}', children: [
          if (courses.isEmpty) const Text('Belum ada mata kuliah untuk semester ini.'),
          for (final course in courses) ListTile(contentPadding: EdgeInsets.zero,
            title: Text(course.nama), subtitle: Text('${course.kode} • ${course.sks} SKS\n${course.dosen}')),
        ])),
      ],
    )));
  }

  Future<void> _showBulkAssignStudentsDialog(ClassItem cls, BuildContext detailContext) async {
    final nonAdminStudents = widget.managedAccounts.where((s) => !s.isAdmin).toList();
    final initialInClass = nonAdminStudents
        .where((s) => s.kelas.trim().toLowerCase() == cls.nama.trim().toLowerCase())
        .map((s) => s.nim)
        .toSet();

    final selectedNims = Set<String>.from(initialInClass);
    var filterMode = 'semester';
    var searchQuery = '';
    var isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          final filtered = nonAdminStudents.where((s) {
            if (filterMode == 'semester' && s.semester != cls.semester) return false;
            if (filterMode == 'unassigned') {
              final k = s.kelas.trim().toLowerCase();
              final isNone = k.isEmpty || k == 'ilmu komunikasi' || k == '-';
              if (!isNone && !initialInClass.contains(s.nim)) return false;
            }
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              return s.nama.toLowerCase().contains(q) || s.nim.contains(q);
            }
            return true;
          }).toList();

          final allFilteredSelected = filtered.isNotEmpty && filtered.every((s) => selectedNims.contains(s.nim));

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kelola Rombel: ${cls.nama}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cls.prodi} • Semester ${cls.semester} • Kapasitas ${cls.kapasitas}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => setModalState(() => searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau NIM mahasiswa...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('Semester ${cls.semester}', 'semester', filterMode, (m) => setModalState(() => filterMode = m)),
                              const SizedBox(width: 8),
                              _buildFilterChip('Belum Masuk Kelas', 'unassigned', filterMode, (m) => setModalState(() => filterMode = m)),
                              const SizedBox(width: 8),
                              _buildFilterChip('Semua Mahasiswa', 'all', filterMode, (m) => setModalState(() => filterMode = m)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: allFilteredSelected,
                              onChanged: isSaving
                                  ? null
                                  : (val) {
                                      setModalState(() {
                                        if (val == true) {
                                          for (final s in filtered) {
                                            selectedNims.add(s.nim);
                                          }
                                        } else {
                                          for (final s in filtered) {
                                            selectedNims.remove(s.nim);
                                          }
                                        }
                                      });
                                    },
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: isSaving
                                    ? null
                                    : () {
                                        setModalState(() {
                                          if (!allFilteredSelected) {
                                            for (final s in filtered) {
                                              selectedNims.add(s.nim);
                                            }
                                          } else {
                                            for (final s in filtered) {
                                              selectedNims.remove(s.nim);
                                            }
                                          }
                                        });
                                      },
                                child: Text(
                                  allFilteredSelected ? 'Batalkan Semua (${filtered.length})' : 'Pilih Semua (${filtered.length})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: selectedNims.length > cls.kapasitas ? Colors.amber.shade50 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedNims.length > cls.kapasitas ? Colors.amber.shade300 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                '${selectedNims.length} / ${cls.kapasitas}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: selectedNims.length > cls.kapasitas ? Colors.amber.shade900 : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Text('Tidak ada mahasiswa yang sesuai dengan filter/pencarian.', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
                            itemBuilder: (ctx, idx) {
                              final s = filtered[idx];
                              final isChecked = selectedNims.contains(s.nim);
                              final wasAlreadyInClass = initialInClass.contains(s.nim);
                              final hasOtherClass = !wasAlreadyInClass && s.kelas.trim().isNotEmpty && s.kelas.trim().toLowerCase() != 'ilmu komunikasi' && s.kelas.trim() != '-';

                              return CheckboxListTile(
                                value: isChecked,
                                enabled: !isSaving,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedNims.add(s.nim);
                                    } else {
                                      selectedNims.remove(s.nim);
                                    }
                                  });
                                },
                                title: Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                subtitle: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text('NIM ${s.nim} • Sem. ${s.semester}', style: const TextStyle(fontSize: 12)),
                                    if (wasAlreadyInClass)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade200)),
                                        child: Text('Di kelas ini', style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.w700)),
                                      )
                                    else if (hasOtherClass)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.shade200)),
                                        child: Text('Kelas: ${s.kelas}', style: TextStyle(fontSize: 10, color: Colors.amber.shade800, fontWeight: FontWeight.w700)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                                        child: const Text('Belum ada kelas', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setModalState(() => isSaving = true);
                                  try {
                                    final toAdd = selectedNims.difference(initialInClass).toList();
                                    final toRemove = initialInClass.difference(selectedNims).toList();

                                    if (toAdd.isNotEmpty) {
                                      await AdminAcademicService.assignStudentsToClass(
                                        targetClass: cls.nama,
                                        studentNims: toAdd,
                                      );
                                    }
                                    if (toRemove.isNotEmpty) {
                                      final client = SupabaseService.client;
                                      if (client != null) {
                                        await client.from('students').update({'kelas': ''}).inFilter('nim', toRemove);
                                      }
                                    }

                                    widget.onRecordAudit(
                                      action: 'UPDATE_ROSTER',
                                      module: 'KELAS',
                                      description: 'Memperbarui rombel kelas ${cls.nama}: ${toAdd.length} ditambahkan, ${toRemove.length} dikeluarkan.',
                                      metadata: {
                                        'class_name': cls.nama,
                                        'added_nims': toAdd,
                                        'removed_nims': toRemove,
                                        'total_students': selectedNims.length,
                                      },
                                    );

                                    await widget.onReload();
                                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                    if (detailContext.mounted) Navigator.pop(detailContext);
                                    widget.onShowMessage('Rombel ${cls.nama} berhasil diperbarui (${selectedNims.length} mahasiswa terdaftar).');
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    widget.onShowMessage(e.toString(), isError: true);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  'Simpan (${selectedNims.length} Mahasiswa)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String mode, String currentMode, ValueChanged<String> onSelected) {
    final isSel = currentMode == mode;
    return InkWell(
      onTap: () => onSelected(mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? AppColors.primary : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
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
                  items: ClassItem.availableProdis,
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
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cls.prodi} • Semester ${cls.semester} • ${cls.academicYear} • $studentCount mahasiswa',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onSelected: (val) async {
                                if (val == 'detail') {
                                  _showClassDetail(cls);
                                } else if (val == 'hapus' && cls.id != null) {
                                  final enrolledCount = widget.managedAccounts
                                      .where((s) => !s.isAdmin && s.kelas.trim().toLowerCase() == cls.nama.trim().toLowerCase())
                                      .length;
                                  if (enrolledCount > 0) {
                                    widget.onShowMessage(
                                      'Tidak dapat menghapus kelas "${cls.nama}" karena masih memiliki $enrolledCount mahasiswa terdaftar. Silakan pindahkan mahasiswa ke kelas lain terlebih dahulu.',
                                      isError: true,
                                    );
                                    return;
                                  }
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
