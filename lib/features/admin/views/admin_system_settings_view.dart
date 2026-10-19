import '../widgets/admin_detail_page.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/models.dart';
import '../models/admin_models.dart';
import '../widgets/admin_common_widgets.dart';

class AdminSystemSettingsView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final void Function(String view) onNavigate;
  final VoidCallback onBroadcastAnnouncement;
  final int registeredTokensCount;
  final List<AcademicYearItem> academicYears;
  final List<ClassItem> classes;
  final List<LecturerItem> lecturers;
  final List<Course> courses;
  final void Function(String message, {bool isError}) onShowMessage;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic>? metadata,
  })
  onRecordAudit;

  const AdminSystemSettingsView({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.onNavigate,
    required this.onBroadcastAnnouncement,
    required this.registeredTokensCount,
    required this.academicYears,
    required this.classes,
    required this.lecturers,
    required this.courses,
    required this.onShowMessage,
    required this.onRecordAudit,
  });

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF111827),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: color == const Color(0xFFEF4444) ? color : AppColors.primary,
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (detailContext) => AdminDetailPage(
      pageLabel: 'Notifikasi', title: 'Pengaturan Notifikasi', subtitle: 'Perangkat dan pengiriman pengumuman', icon: Icons.notifications_outlined,
      actions: [AdminDetailAction('Kirim pengumuman', Icons.campaign_outlined, () { Navigator.pop(detailContext); onBroadcastAnnouncement(); })],
      tabs: [AdminDetailTab('Ringkasan', AdminDetailSection(title: 'Perangkat terdaftar', children: [
        AdminDetailFields({'Token perangkat': '$registeredTokensCount token terdaftar'}),
        const Text('Notifikasi memerlukan izin pada perangkat mahasiswa. Token terdaftar belum memastikan pesan sampai ke perangkat.', style: TextStyle(fontSize: 14, height: 1.7)),
      ]))],
    )));
  }
  void _showAppProfileDialog(BuildContext context) {
    final activeYear = academicYears.where((year) => year.isAktif).firstOrNull?.tahun ?? 'Belum ditetapkan';
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AdminDetailPage(
      pageLabel: 'Profil Aplikasi', title: 'ILKOM UNAZLAM Hub', subtitle: 'Manajemen kelas dan akademik', icon: Icons.school_outlined,
      tabs: [AdminDetailTab('Ringkasan', AdminDetailSection(title: 'Data akademik', children: [
        AdminDetailFields({'Tahun akademik aktif': activeYear, 'Kelas': '${classes.length} kelas', 'Dosen': '${lecturers.length} dosen', 'Mata kuliah': '${courses.length} mata kuliah', 'Koneksi': SupabaseService.client == null ? 'Belum terhubung' : 'Supabase dikonfigurasi'}),
      ]))],
    )));
  }
  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(scrollable: true, insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Backup & Arsip Data',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: const Text(
          'Unduh salinan data yang tersimpan di Supabase: akun mahasiswa, mata kuliah, tugas, pengumuman, transaksi kas, kelas, dosen, dan tahun akademik.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final client = SupabaseService.client;
                if (client == null) {
                  throw Exception('Supabase belum terhubung.');
                }
                final tables = [
                  'students',
                  'courses',
                  'assignments',
                  'announcements',
                  'treasury_transactions',
                  'academic_classes',
                  'lecturers',
                  'academic_years',
                ];
                final backup = <String, dynamic>{
                  'exported_at': DateTime.now().toUtc().toIso8601String(),
                  'format_version': 1,
                };
                for (final table in tables) {
                  backup[table] = await client.from(table).select();
                }
                final payload = const JsonEncoder.withIndent('  ')
                    .convert(backup);
                final exportResult = await ExportService.exportFile(
                  'ilkom_hub_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json',
                  payload,
                );
                if (exportResult == FileExportResult.dismissed) return;
                if (exportResult == FileExportResult.unavailable) {
                  await Clipboard.setData(ClipboardData(text: payload));
                }
                onRecordAudit(
                  action: 'EXPORT',
                  module: 'BACKUP',
                  description: 'Mengekspor backup JSON data aplikasi.',
                  metadata: {'tabel': tables},
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                onShowMessage(switch (exportResult) {
                  FileExportResult.downloaded =>
                    'Backup JSON berhasil diunduh.',
                  FileExportResult.shared => 'Pilih lokasi penyimpanan pada menu berbagi untuk menyimpan backup JSON.',
                  FileExportResult.dismissed => '',
                  FileExportResult.unavailable => 'Ekspor file tidak tersedia. Data backup JSON disalin ke clipboard.',
                });
              } catch (error) {
                onShowMessage('Backup gagal: $error', isError: true);
              }
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Ekspor JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminDetailPage(
      pageLabel: 'Tentang Aplikasi', title: 'ILKOM UNAZLAM Hub', subtitle: 'Universitas Al-Azhar Menggala', icon: Icons.info_outline,
      tabs: [AdminDetailTab('Tentang', AdminDetailSection(title: 'Tentang platform', children: [
        Text('Aplikasi pengelolaan kelas terpadu Ilmu Komunikasi Universitas Al-Azhar Menggala (UNAZLAM).', style: TextStyle(fontSize: 15, height: 1.8)),
        Text('Satu Kelas, Banyak Cerita, Lebih Banyak Karya.', style: TextStyle(fontSize: 15, height: 1.8)),
      ]))],
    )));
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminAppBar(
          title: 'Pengaturan Sistem',
          showSearch: false,
          onBack: onBack,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              _buildSettingCard(
                icon: Icons.app_shortcut_outlined,
                title: 'Profil Aplikasi',
                onTap: () => _showAppProfileDialog(context),
              ),
              _buildSettingCard(
                icon: Icons.shield_outlined,
                title: 'Role & Permission',
                onTap: () => onNavigate('role_permission'),
              ),
              _buildSettingCard(
                icon: Icons.history_rounded,
                title: 'Log Aktivitas Admin',
                onTap: () => onNavigate('audit_logs'),
              ),
              _buildSettingCard(
                icon: Icons.cloud_download_outlined,
                title: 'Backup Data',
                onTap: () => _showBackupDialog(context),
              ),
              _buildSettingCard(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                onTap: () => _showNotificationSettingsDialog(context),
              ),
              _buildSettingCard(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () => _showAboutDialog(context),
              ),
              _buildSettingCard(
                icon: Icons.logout_rounded,
                title: 'Keluar',
                color: const Color(0xFFEF4444),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
