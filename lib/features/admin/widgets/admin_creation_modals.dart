import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';
import '../models/admin_models.dart';
import 'admin_broadcast_hub_modal.dart';
import 'admin_common_widgets.dart';
import 'admin_waha_gateway_modal.dart';

class AdminCreationModals {
  static void showWahaGatewayDialog({
    required BuildContext context,
    required void Function(String message, {bool isError}) onShowMessage,
  }) {
    AdminWahaGatewayModal.show(
      context: context,
      onShowMessage: onShowMessage,
    );
  }

  static void showBroadcastAnnouncementDialog({
    required BuildContext context,
    List<ClassItem> classes = const [],
    required Future<void> Function() onRefresh,
    required void Function(String message, {bool isError}) onShowMessage,
    required void Function({
      required String action,
      required String module,
      required String description,
      Map<String, dynamic> metadata,
    }) onRecordAudit,
  }) {
    AdminBroadcastHubModal.show(
      context: context,
      classes: classes,
      onRefresh: onRefresh,
      onShowMessage: onShowMessage,
      onRecordAudit: onRecordAudit,
    );
  }

  static void showCreateAssignmentDialog({
    required BuildContext context,
    required List<Course> courses,
    required Future<void> Function() onRefresh,
    required void Function(String message, {bool isError}) onShowMessage,
    required void Function({
      required String action,
      required String module,
      required String description,
    }) onRecordAudit,
  }) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String selectedCourseId = courses.isNotEmpty ? courses.first.id : '';
    String selectedCourseName = courses.isNotEmpty ? courses.first.nama : 'Perkuliahan Umum';
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    String category = 'Individu';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.post_add_rounded, color: Color(0xFF0EA5E9), size: 24),
              SizedBox(width: 10),
              Text('Rilis Tugas Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminFormLabel('Judul Tugas'),
                AdminFormField(controller: titleCtrl, hintText: 'Contoh: Analisis Kasus Komunikasi Massa'),
                const SizedBox(height: 12),
                const AdminFormLabel('Mata Kuliah'),
                if (courses.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourseId.isNotEmpty ? selectedCourseId : courses.first.id,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCourseId = val;
                          selectedCourseName = courses.firstWhere((c) => c.id == val, orElse: () => courses.first).nama;
                        });
                      }
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Belum ada mata kuliah terdaftar', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ),
                const SizedBox(height: 12),
                const AdminFormLabel('Deskripsi & Petunjuk'),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Rincian tugas, format pengumpulan, bobot penilaian...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                const AdminFormLabel('Link / Tautan Pengumpulan (Opsional)'),
                AdminFormField(controller: linkCtrl, hintText: 'https://forms.gle/... atau Classroom'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tenggat Waktu:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: Text('${deadline.day}/${deadline.month}/${deadline.year} 23:59'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            deadline = DateTime(picked.year, picked.month, picked.day, 23, 59);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton.icon(
              icon: const Icon(Icons.publish_rounded, size: 16),
              label: const Text('Rilis Tugas & Notif'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  onShowMessage('Judul tugas harus diisi.', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final ok = await SupabaseRepository.createAssignment(
                  courseId: selectedCourseId,
                  courseName: selectedCourseName,
                  judul: titleCtrl.text.trim(),
                  deskripsi: descCtrl.text.trim(),
                  kategori: category,
                  deadline: deadline,
                  linkPengumpulan: linkCtrl.text.trim().isNotEmpty ? linkCtrl.text.trim() : null,
                );
                if (ok) {
                  onRecordAudit(
                    action: 'CREATE',
                    module: 'TUGAS',
                    description: 'Merilis tugas "${titleCtrl.text.trim()}" untuk $selectedCourseName.',
                  );
                  onShowMessage('Tugas baru berhasil dirilis. Pengiriman notifikasi mengikuti konfigurasi layanan.');
                  await onRefresh();
                } else {
                  onShowMessage('Gagal merilis tugas.', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      descCtrl.dispose();
      linkCtrl.dispose();
    });
  }

  static void showQuickExportModal({
    required BuildContext context,
    required void Function(String view) onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ekspor Rekapitulasi Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Pilih laporan yang ingin diunduh dalam format berkas CSV/Excel:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E7EB))),
              leading: const Icon(Icons.fact_check_rounded, color: Color(0xFF10B981)),
              title: const Text('Rekapitulasi Presensi Perkuliahan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('Riwayat kehadiran, izin, sakit per mahasiswa', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                onNavigate('laporan');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E7EB))),
              leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              title: const Text('Laporan Kas & Keuangan Kelas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('Seluruh arus kas masuk, pengeluaran & saldo', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                onNavigate('laporan');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E7EB))),
              leading: const Icon(Icons.people_alt_rounded, color: Color(0xFF0EA5E9)),
              title: const Text('Data Seluruh Akun Mahasiswa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('NIM, nama lengkap, kontak & status aktif', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                onNavigate('manajemen_akun');
              },
            ),
          ],
        ),
      ),
    );
  }
}
