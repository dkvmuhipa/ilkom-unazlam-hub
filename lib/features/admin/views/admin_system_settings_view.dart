import '../widgets/admin_detail_page.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_repository.dart';
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
    Color color = const Color(0xFF0F172A),
  }) {
    final isDestructive = color == const Color(0xFFEF4444);
    final iconColor = isDestructive ? const Color(0xFFEF4444) : AppColors.primary;
    final iconBg = isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFFEEF2FF);

    return ScaleButton(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (detailContext) => AdminDetailPage(
      pageLabel: 'Notifikasi', title: 'Pengaturan Notifikasi', subtitle: 'Perangkat dan pengiriman pengumuman', icon: Icons.notifications_outlined,
      actions: [
        AdminDetailAction('Uji Suara Notifikasi', Icons.volume_up_outlined, () async {
          await SoundService.playNotificationSound(force: true);
          if (detailContext.mounted) {
            onShowMessage('Memutar nada notifikasi 🔔');
          }
        }),
        AdminDetailAction('Kirim pengumuman', Icons.campaign_outlined, () { Navigator.pop(detailContext); onBroadcastAnnouncement(); }),
        AdminDetailAction('Bersihkan Duplikat Token', Icons.cleaning_services_outlined, () async {
          final deleted = await SupabaseRepository.cleanStalePushTokens();
          if (detailContext.mounted) {
            onShowMessage('Berhasil merapikan token FCM ($deleted duplikat dihapus).');
            Navigator.pop(detailContext);
          }
        }),
      ],
      tabs: [AdminDetailTab('Ringkasan', AdminDetailSection(title: 'Perangkat terdaftar', children: [
        AdminDetailFields({'Mahasiswa terhubung': '$registeredTokensCount akun unik'}),
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
    final tables = [
      {'name': 'Akun Mahasiswa', 'id': 'students', 'icon': Icons.people_outline},
      {'name': 'Mata Kuliah & Jadwal', 'id': 'courses', 'icon': Icons.menu_book_outlined},
      {'name': 'Tugas & Modul', 'id': 'assignments', 'icon': Icons.assignment_outlined},
      {'name': 'Pengumuman Siaran', 'id': 'announcements', 'icon': Icons.campaign_outlined},
      {'name': 'Kas & Keuangan', 'id': 'treasury_transactions', 'icon': Icons.account_balance_wallet_outlined},
      {'name': 'Kelas & Rombel', 'id': 'academic_classes', 'icon': Icons.groups_outlined},
      {'name': 'Dosen Pengampu', 'id': 'lecturers', 'icon': Icons.person_pin_outlined},
      {'name': 'Tahun Akademik', 'id': 'academic_years', 'icon': Icons.calendar_month_outlined},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF6D28D9), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Backup & Ekspor Database',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Cadangan data lengkap Supabase format JSON.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TABEL DATABASE YANG AKAN DICADANGKAN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < tables.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(tables[i]['icon'] as IconData, size: 16, color: const Color(0xFF6D28D9)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tables[i]['name'] as String,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      tables[i]['id'] as String,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF6D28D9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Catatan: File JSON yang diekspor dapat digunakan untuk arsip fisik atau restore darurat.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
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
                  final tableNames = tables.map((t) => t['id'] as String).toList();
                  final backup = <String, dynamic>{
                    'exported_at': DateTime.now().toUtc().toIso8601String(),
                    'format_version': 1,
                  };
                  for (final table in tableNames) {
                    backup[table] = await client.from(table).select();
                  }
                  final payload = const JsonEncoder.withIndent('  ').convert(backup);
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
                    metadata: {'tabel': tableNames},
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  onShowMessage(switch (exportResult) {
                    FileExportResult.downloaded => 'Backup JSON berhasil diunduh.',
                    FileExportResult.shared =>
                      'Pilih lokasi penyimpanan pada menu berbagi untuk menyimpan backup JSON.',
                    FileExportResult.dismissed => '',
                    FileExportResult.unavailable =>
                      'Ekspor file tidak tersedia. Data backup JSON disalin ke clipboard.',
                  });
                } catch (error) {
                  onShowMessage('Backup gagal: $error', isError: true);
                }
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Ekspor JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
