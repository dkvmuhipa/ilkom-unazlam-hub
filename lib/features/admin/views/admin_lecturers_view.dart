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
          onSearch: () {},
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

  void _showLecturerDetail(LecturerItem d) {
    final taughtCourses = widget.courses.where((c) {
      return c.dosen.toLowerCase().contains(d.nama.toLowerCase()) ||
          d.mataKuliah.toLowerCase().contains(c.nama.toLowerCase());
    }).toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.person_rounded, color: Color(0xFF0284C7), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.nama,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                      ),
                      Text(
                        d.email.isNotEmpty ? d.email : 'Email belum diatur',
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mata Kuliah Utama Diampu:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  Text(d.mataKuliah, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                ],
              ),
            ),
            if (taughtCourses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Mata Kuliah Terkait dalam Jadwal:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              ...taughtCourses.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${c.kode} - ${c.nama} (${c.sks} SKS)', style: const TextStyle(fontSize: 11.5, color: Color(0xFF374151))),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showLecturerDialog(existing: d);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (await widget.onConfirmDelete('Hapus data dosen ${d.nama}?')) {
                        try {
                          await AdminAcademicService.deleteLecturer(d.id);
                          widget.onRecordAudit(
                            action: 'DELETE',
                            module: 'DOSEN',
                            description: 'Menghapus dosen ${d.nama}.',
                            metadata: {'lecturer_id': d.id},
                          );
                          await widget.onReload();
                          widget.onShowMessage('Data dosen berhasil dihapus.');
                        } catch (error) {
                          widget.onShowMessage(error.toString(), isError: true);
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Hapus Dosen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
