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
    final dosenCtrl = TextEditingController(text: existing?.dosen ?? '');
    final dosenWaCtrl = TextEditingController(text: existing?.dosenWa ?? '');
    final ruanganCtrl = TextEditingController(text: existing?.ruangan ?? '');
    final linkVirtualCtrl = TextEditingController(text: existing?.linkVirtual ?? '');
    final jamMulaiCtrl = TextEditingController(text: existing?.jamMulai ?? '08:00');
    final jamSelesaiCtrl = TextEditingController(text: existing?.jamSelesai ?? '09:40');

    int sks = existing?.sks ?? 2;
    int semester = existing?.semester ?? 1;
    String hari = existing?.hari ?? 'Senin';
    const hariOptions = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AdminSpaciousModal(
          title: existing == null ? 'Tambah Mata Kuliah Baru' : 'Edit Mata Kuliah',
          subtitle: existing == null
              ? 'Lengkapi rincian kurikulum, jadwal, dan dosen pengampu.'
              : 'Perbarui informasi mata kuliah ${existing.kode}',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF0EA5E9),
          maxWidth: 680,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Identitas Mata Kuliah
              const Text(
                'IDENTITAS MATA KULIAH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              AdminAdaptiveRow(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Nama Mata Kuliah *'),
                        AdminFormField(
                          controller: namaCtrl,
                          hintText: 'Contoh: Teori Komunikasi Massa',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Kode Matkul *'),
                        AdminFormField(
                          controller: kodeCtrl,
                          hintText: 'Contoh: IK-101',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // SKS & Semester
              AdminAdaptiveRow(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Bobot SKS'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [1, 2, 3, 4, 6].map((s) {
                            final isSel = sks == s;
                            return ChoiceChip(
                              label: Text('$s SKS'),
                              selected: isSel,
                              selectedColor: const Color(0xFFE0F2FE),
                              onSelected: (_) => setDialogState(() => sks = s),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Semester Ditawarkan'),
                        AdminDropdownField<int>(
                          value: semester,
                          items: List.generate(8, (i) => i + 1),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => semester = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Dosen Pengampu
              const Text(
                'DOSEN PENGAMPU & KONTAK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              AdminAdaptiveRow(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Nama Dosen Pengampu'),
                        AdminFormField(
                          controller: dosenCtrl,
                          hintText: 'Contoh: Dr. Sarah Wijaya, M.Si',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('WhatsApp Dosen (Opsional)'),
                        AdminFormField(
                          controller: dosenWaCtrl,
                          hintText: 'Contoh: 081234567890',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Jadwal & Ruangan
              const Text(
                'JADWAL & LOKASI PERKULIAHAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              AdminAdaptiveRow(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Hari Kuliah'),
                        AdminDropdownField<String>(
                          value: hariOptions.contains(hari) ? hari : hariOptions.first,
                          items: hariOptions,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => hari = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Jam Mulai'),
                        AdminFormField(
                          controller: jamMulaiCtrl,
                          hintText: '08:00',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Jam Selesai'),
                        AdminFormField(
                          controller: jamSelesaiCtrl,
                          hintText: '09:40',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AdminAdaptiveRow(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Ruangan Kuliah / Lab'),
                        AdminFormField(
                          controller: ruanganCtrl,
                          hintText: 'Contoh: Ruang 302 / Lab Multimedia',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminFormLabel('Tautan Kelas Virtual (Opsional)'),
                        AdminFormField(
                          controller: linkVirtualCtrl,
                          hintText: 'https://meet.google.com/...',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final nama = namaCtrl.text.trim();
                      final kode = kodeCtrl.text.trim();
                      if (nama.isEmpty || kode.isEmpty) {
                        widget.onShowMessage('Nama mata kuliah dan kode wajib diisi.', isError: true);
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final course = Course(
                        id: existing?.id ?? '',
                        nama: nama,
                        kode: kode,
                        dosen: dosenCtrl.text.trim().isNotEmpty ? dosenCtrl.text.trim() : 'Belum ditentukan',
                        dosenWa: dosenWaCtrl.text.trim().isNotEmpty ? dosenWaCtrl.text.trim() : null,
                        sks: sks,
                        semester: semester,
                        hari: hari,
                        jamMulai: jamMulaiCtrl.text.trim().isNotEmpty ? jamMulaiCtrl.text.trim() : '08:00',
                        jamSelesai: jamSelesaiCtrl.text.trim().isNotEmpty ? jamSelesaiCtrl.text.trim() : '09:40',
                        ruangan: ruanganCtrl.text.trim().isNotEmpty ? ruanganCtrl.text.trim() : 'Belum ditentukan',
                        linkVirtual: linkVirtualCtrl.text.trim().isNotEmpty ? linkVirtualCtrl.text.trim() : null,
                      );
                      final ok = existing == null
                          ? await SupabaseRepository.createCourse(course)
                          : await SupabaseRepository.updateCourse(course);
                      if (!mounted) return;
                      setDialogState(() => isSaving = false);
                      if (ok) {
                        widget.onRecordAudit(
                          action: existing == null ? 'CREATE' : 'UPDATE',
                          module: 'MATA_KULIAH',
                          description:
                              '${existing == null ? 'Menambahkan' : 'Memperbarui'} mata kuliah ${course.nama} (${course.kode}).',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan Mata Kuliah'),
            ),
          ],
        ),
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
