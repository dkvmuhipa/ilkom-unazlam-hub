import '../widgets/admin_detail_page.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_academic_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/saas_components.dart';
import '../../../models/models.dart';
import '../models/admin_models.dart';
import '../widgets/admin_common_widgets.dart';

class AdminLecturersView extends StatefulWidget {
  final List<LecturerItem> lecturers;
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

  const AdminLecturersView({
    super.key,
    required this.lecturers,
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
  State<AdminLecturersView> createState() => _AdminLecturersViewState();
}

class _AdminLecturersViewState extends State<AdminLecturersView> {
  String _dosenSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.lecturers.where((d) {
      if (_dosenSearchQuery.isEmpty) return true;
      final q = _dosenSearchQuery.toLowerCase();
      return d.nama.toLowerCase().contains(q) || d.mataKuliah.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        AdminAppBar(
          title: 'Data Dosen',
          showSearch: false,
          onBack: widget.onBack,
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
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.loadError!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.isLoading) const LinearProgressIndicator(),
              AdminSearchBox(
                hintText: 'Cari nama dosen...',
                onChanged: (val) => setState(() => _dosenSearchQuery = val),
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: () => _showLecturerDialog(),
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
                  '+ Tambah Dosen',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty && !widget.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: EmptyStateWidget(
                    icon: Icons.person_search_outlined,
                    title: _dosenSearchQuery.isEmpty ? 'Belum Ada Data Dosen' : 'Dosen Tidak Ditemukan',
                    subtitle: _dosenSearchQuery.isEmpty
                        ? 'Daftar dosen pengampu di Supabase masih kosong. Tambahkan dosen pengampu baru.'
                        : 'Tidak ada dosen yang cocok dengan pencarian "$_dosenSearchQuery".',
                  ),
                )
              else
                ...filtered.map((d) {
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
                      onTap: () => _showLecturerDetail(d),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            SaaSAvatar(
                              name: d.nama,
                              size: 44,
                              radius: 13,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.nama,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.mataKuliah,
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
                                  _showLecturerDetail(d);
                                } else if (val == 'hapus' &&
                                    await widget.onConfirmDelete('Hapus data dosen ${d.nama}?')) {
                                  try {
                                    await AdminAcademicService.deleteLecturer(d.id);
                                    widget.onRecordAudit(
                                      action: 'DELETE',
                                      module: 'DOSEN',
                                      description: 'Menghapus data dosen ${d.nama}.',
                                      metadata: {'lecturer_id': d.id},
                                    );
                                    await widget.onReload();
                                  } catch (error) {
                                    widget.onShowMessage(error.toString(), isError: true);
                                  }
                                } else if (val == 'edit') {
                                  _showLecturerDialog(existing: d);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Detail Dosen'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Data'),
                                ),
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text(
                                    'Hapus Dosen',
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

  void _showLecturerDetail(LecturerItem lecturer) {
    final courses = widget.courses.where((course) => course.dosen.toLowerCase() == lecturer.nama.toLowerCase() || lecturer.mataKuliah.toLowerCase().contains(course.nama.toLowerCase())).toList();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (detailContext) => AdminDetailPage(
      pageLabel: 'Detail Dosen', title: lecturer.nama, subtitle: lecturer.email.isEmpty ? 'Kontak belum diisi' : lecturer.email,
      icon: Icons.person_outline,
      onEdit: () { Navigator.pop(detailContext); _showLecturerDialog(existing: lecturer); },
      tabs: [
        AdminDetailTab('Profil', AdminDetailSection(title: 'Profil dosen', children: [
          AdminDetailFields({'Nama lengkap': lecturer.nama, 'Email': lecturer.email, 'Bidang / mata kuliah': lecturer.mataKuliah}),
        ])),
        AdminDetailTab('Pengajaran', AdminDetailSection(title: 'Mata kuliah yang diampu', children: [
          if (courses.isEmpty) const Text('Belum ada mata kuliah yang terhubung dengan dosen ini.'),
          for (final course in courses) ListTile(contentPadding: EdgeInsets.zero,
            title: Text(course.nama), subtitle: Text('${course.kode} • ${course.sks} SKS\n${course.hari}, ${course.jamMulai}–${course.jamSelesai} WITA')),
        ])),
      ],
    )));
  }
  Future<void> _showLecturerDialog({LecturerItem? existing}) async {
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final matkulCtrl = TextEditingController(text: existing?.mataKuliah ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Tambah Dosen Pengampu' : 'Edit Dosen Pengampu',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminFormField(
              controller: namaCtrl,
              hintText: 'Nama Lengkap & Gelar',
            ),
            const SizedBox(height: 10),
            AdminFormField(
              controller: matkulCtrl,
              hintText: 'Mata Kuliah Diampu',
            ),
            const SizedBox(height: 10),
            AdminFormField(controller: emailCtrl, hintText: 'Email dosen (opsional)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true) {
      if (namaCtrl.text.trim().isEmpty || matkulCtrl.text.trim().isEmpty) {
        widget.onShowMessage('Nama dan mata kuliah wajib diisi.', isError: true);
        return;
      }
      try {
        await AdminAcademicService.saveLecturer(
          id: existing?.id,
          nama: namaCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          course: matkulCtrl.text.trim(),
        );
        widget.onRecordAudit(
          action: existing == null ? 'CREATE' : 'UPDATE',
          module: 'DOSEN',
          description: '${existing == null ? 'Menambahkan' : 'Memperbarui'} data dosen ${namaCtrl.text.trim()}.',
          metadata: {'mata_kuliah': matkulCtrl.text.trim()},
        );
        await widget.onReload();
        widget.onShowMessage('Data dosen tersimpan.');
      } catch (error) {
        widget.onShowMessage(error.toString(), isError: true);
      }
    }
  }
}
