import '../widgets/admin_detail_page.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../models/models.dart';
import '../widgets/admin_bulk_csv_modal.dart';
import '../widgets/admin_common_widgets.dart';

class AdminCoursesView extends StatefulWidget {
  final List<Course> courses;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onBack;
  final Future<void> Function() onReload;
  final void Function(String message, {bool isError}) onShowMessage;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic>? metadata,
  }) onRecordAudit;
  final Future<bool> Function(String prompt) onConfirmDelete;

  const AdminCoursesView({
    super.key,
    required this.courses,
    required this.isLoading,
    required this.loadError,
    required this.onBack,
    required this.onReload,
    required this.onShowMessage,
    required this.onRecordAudit,
    required this.onConfirmDelete,
  });

  @override
  State<AdminCoursesView> createState() => _AdminCoursesViewState();
}

class _AdminCoursesViewState extends State<AdminCoursesView> {
  String _searchQuery = '';

  void _openBulkImport() {
    AdminBulkCsvModal.show(
      context,
      initialType: BulkImportType.courses,
      onReload: widget.onReload,
      onShowMessage: widget.onShowMessage,
      onRecordAudit: widget.onRecordAudit,
    );
  }

  Color _getCourseColor(int index) {
    const colors = [
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF0284C7),
      Color(0xFF6366F1),
    ];
    return colors[index % colors.length];
  }

  void _showCourseDetail(Course course) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (detailContext) => AdminDetailPage(
      pageLabel: 'Detail Mata Kuliah', title: course.nama,
      subtitle: '${course.kode} • ${course.sks} SKS • Semester ${course.semester}',
      icon: Icons.menu_book_outlined,
      onEdit: () { Navigator.pop(detailContext); _showCourseDialog(existing: course); },
      actions: [AdminDetailAction('Ekspor presensi', Icons.download_outlined, () async {
        try {
          final logs = await SupabaseRepository.getAttendanceLogsStrict();
          final students = await SupabaseRepository.getClassDirectory();
          final csv = ExportService.exportAttendanceCsv(courseName: course.nama,
            logs: logs.where((row) => row['course_id']?.toString() == course.id).toList(), students: students);
          if (!detailContext.mounted) return;
          ExportService.showExportSheet(detailContext, title: 'Presensi ${course.nama}',
            fileName: 'presensi_${course.kode}.csv', content: csv, subtitle: 'Rekap mata kuliah');
        } catch (error) {
          if (detailContext.mounted) ScaffoldMessenger.of(detailContext).showSnackBar(SnackBar(content: Text('Ekspor gagal: $error')));
        }
      })],
      tabs: [
        AdminDetailTab('Ringkasan', AdminDetailSection(title: 'Informasi mata kuliah', children: [
          AdminDetailFields({'Kode mata kuliah': course.kode, 'Nama mata kuliah': course.nama,
            'Dosen pengampu': course.dosen, 'Beban studi': '${course.sks} SKS', 'Semester': '${course.semester}'}),
        ])),
        AdminDetailTab('Jadwal', AdminDetailSection(title: 'Jadwal perkuliahan', children: [
          AdminDetailFields({'Hari': course.hari, 'Waktu': '${course.jamMulai}–${course.jamSelesai} WITA',
            'Ruangan': course.ruangan, if (course.linkVirtual?.isNotEmpty == true) 'Tautan daring': course.linkVirtual!}),
        ])),
      ],
    )));
  }
  void _showCourseDialog({Course? existing}) {
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final kodeCtrl = TextEditingController(text: existing?.kode ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminFormField(controller: namaCtrl, hintText: 'Nama Mata Kuliah'),
            const SizedBox(height: 10),
            AdminFormField(
              controller: kodeCtrl,
              hintText: 'Kode Matkul (Contoh: IK-107)',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty || kodeCtrl.text.trim().isEmpty) return;
              final course = Course(
                id: existing?.id ?? '',
                nama: namaCtrl.text.trim(),
                kode: kodeCtrl.text.trim(),
                dosen: existing?.dosen ?? 'Belum ditentukan',
                sks: existing?.sks ?? 2,
                semester: existing?.semester ?? 1,
                hari: existing?.hari ?? 'Senin',
                jamMulai: existing?.jamMulai ?? '08:00',
                jamSelesai: existing?.jamSelesai ?? '09:40',
                ruangan: existing?.ruangan ?? 'Belum ditentukan',
              );
              final ok = existing == null
                  ? await SupabaseRepository.createCourse(course)
                  : await SupabaseRepository.updateCourse(course);
              if (!mounted) return;
              if (ok) {
                widget.onRecordAudit(
                  action: existing == null ? 'CREATE' : 'UPDATE',
                  module: 'MATA_KULIAH',
                  description: '${existing == null ? 'Menambahkan' : 'Memperbarui'} mata kuliah ${course.nama} (${course.kode}).',
                  metadata: {'course_id': course.id},
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await widget.onReload();
                widget.onShowMessage('Mata kuliah berhasil disimpan.');
              } else {
                widget.onShowMessage(
                  'Gagal menyimpan. Pastikan sesi admin aktif dan migrasi Supabase sudah diterapkan.',
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.nama.toLowerCase().contains(q) || c.kode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        AdminAppBar(
          title: 'Mata Kuliah',
          onBack: widget.onBack,
          showSearch: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (widget.loadError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
              AdminSearchBox(
                hintText: 'Cari mata kuliah...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _openBulkImport,
                      icon: const Icon(Icons.file_upload_outlined, size: 17),
                      label: const Text('Import CSV', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCourseDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Tambah Matkul',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty && !widget.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: EmptyStateWidget(
                    icon: Icons.menu_book_outlined,
                    title: _searchQuery.isEmpty ? 'Belum Ada Mata Kuliah' : 'Mata Kuliah Tidak Ditemukan',
                    subtitle: _searchQuery.isEmpty
                        ? 'Daftar mata kuliah di Supabase masih kosong. Tambahkan mata kuliah baru.'
                        : 'Tidak ada mata kuliah yang cocok dengan pencarian "$_searchQuery".',
                  ),
                )
              else
                ...filtered.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final color = _getCourseColor(i);

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
                      onTap: () => _showCourseDetail(c),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ColorfulIconBox(
                              icon: Icons.menu_book_rounded,
                              color: color,
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
                                    c.nama,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c.kode} • ${c.sks} SKS • ${c.dosen}',
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
                                  _showCourseDetail(c);
                                } else if (val == 'hapus' &&
                                    await widget.onConfirmDelete('Hapus mata kuliah ${c.nama}?')) {
                                  final ok = await SupabaseRepository.deleteCourse(c.id);
                                  if (ok) {
                                    widget.onRecordAudit(
                                      action: 'DELETE',
                                      module: 'MATA_KULIAH',
                                      description: 'Menghapus mata kuliah ${c.nama} (${c.kode}).',
                                      metadata: {'course_id': c.id},
                                    );
                                    await widget.onReload();
                                    widget.onShowMessage('Mata kuliah dihapus.');
                                  } else {
                                    widget.onShowMessage('Mata kuliah gagal dihapus.', isError: true);
                                  }
                                } else if (val == 'edit') {
                                  _showCourseDialog(existing: c);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Detail Mata Kuliah'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Data'),
                                ),
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text(
                                    'Hapus',
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
              }),
            ],
          ),
        ),
      ],
    );
  }
}
