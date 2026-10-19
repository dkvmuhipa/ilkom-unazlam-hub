import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_academic_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/admin_models.dart';
import '../widgets/admin_common_widgets.dart';

class AdminAcademicYearView extends StatelessWidget {
  final List<AcademicYearItem> academicYears;
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

  const AdminAcademicYearView({
    super.key,
    required this.academicYears,
    required this.isLoading,
    required this.loadError,
    required this.onBack,
    required this.onReload,
    required this.onShowMessage,
    required this.onRecordAudit,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminAppBar(
          title: 'Tahun Akademik',
          showSearch: false,
          onBack: onBack,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (loadError != null)
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
                          loadError!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isLoading) const LinearProgressIndicator(),
              ElevatedButton(
                onPressed: () => _showTambahTahunAkademikDialog(context),
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
                  '+ Tambah Tahun Akademik',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              if (academicYears.isEmpty && !isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: EmptyStateWidget(
                    icon: Icons.calendar_today_outlined,
                    title: 'Belum Ada Tahun Akademik',
                    subtitle: 'Tambahkan tahun akademik baru untuk memulai pengelolaan kalender perkuliahan.',
                  ),
                )
              else
                ...academicYears.map((ta) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: AdminAdaptiveRow(
                    children: [
                      Text(
                        ta.tahun,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      if (ta.isAktif)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        onSelected: (val) async {
                          if (val == 'aktif' && ta.id != null) {
                            try {
                              await AdminAcademicService.setActiveAcademicYear(ta.id!);
                              onRecordAudit(
                                action: 'UPDATE',
                                module: 'TAHUN_AKADEMIK',
                                description: 'Menetapkan ${ta.tahun} sebagai tahun akademik aktif.',
                                metadata: {'academic_year_id': ta.id},
                              );
                              await onReload();
                              onShowMessage('${ta.tahun} ditetapkan sebagai tahun aktif.');
                            } catch (error) {
                              onShowMessage(error.toString(), isError: true);
                            }
                          } else if (val == 'hapus' &&
                              ta.id != null &&
                              await onConfirmDelete('Hapus tahun akademik ${ta.tahun}?')) {
                            try {
                              await AdminAcademicService.deleteAcademicYear(ta.id!);
                              onRecordAudit(
                                action: 'DELETE',
                                module: 'TAHUN_AKADEMIK',
                                description: 'Menghapus tahun akademik ${ta.tahun}.',
                                metadata: {'academic_year_id': ta.id},
                              );
                              await onReload();
                            } catch (error) {
                              onShowMessage(error.toString(), isError: true);
                            }
                          } else if (val == 'edit') {
                            if (context.mounted) {
                              _showTambahTahunAkademikDialog(context, existing: ta);
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'aktif',
                            child: Text('Jadikan Tahun Aktif'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'hapus',
                            child: Text('Hapus', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showTambahTahunAkademikDialog(BuildContext context, {AcademicYearItem? existing}) {
    final ctrl = TextEditingController(text: existing?.tahun ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Tambah Tahun Akademik' : 'Edit Tahun Akademik',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: AdminFormField(
          controller: ctrl,
          hintText: 'Contoh: 2027/2028',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final year = ctrl.text.trim();
              if (!RegExp(r'^\d{4}/\d{4}$').hasMatch(year)) {
                onShowMessage('Format tahun harus seperti 2026/2027.', isError: true);
                return;
              }
              try {
                await AdminAcademicService.saveAcademicYear(id: existing?.id, year: year);
                onRecordAudit(
                  action: existing == null ? 'CREATE' : 'UPDATE',
                  module: 'TAHUN_AKADEMIK',
                  description: '${existing == null ? 'Menambahkan' : 'Memperbarui'} tahun akademik $year.',
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                await onReload();
                onShowMessage('Tahun akademik tersimpan.');
              } catch (error) {
                onShowMessage(error.toString(), isError: true);
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
}
