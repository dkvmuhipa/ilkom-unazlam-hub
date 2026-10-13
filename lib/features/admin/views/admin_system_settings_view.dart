import 'dart:convert';

import 'package:flutter/material.dart';

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
  }) onRecordAudit;

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Pengaturan Notifikasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.token_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$registeredTokensCount token FCM aktif terdaftar dari instalasi mahasiswa.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Status Layanan:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Firebase Cloud Messaging (FCM v1) Terintegrasi\n• Supabase Database Webhook & Edge Function Aktif\n• Notifikasi otomatis terkirim saat rilis tugas atau pengumuman baru.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF4B5563)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              onBroadcastAnnouncement();
            },
            icon: const Icon(Icons.campaign_outlined, size: 16),
            label: const Text('Kirim Pengumuman'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppProfileDialog(BuildContext context) {
    final activeYear = academicYears.firstWhere(
      (y) => y.isAktif,
      orElse: () => AcademicYearItem(tahun: '2026/2027', isAktif: true),
    ).tahun;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Profil Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ILKOM UNAZLAM Hub',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Platform Manajemen Kelas & Akademik Terpadu',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
            ),
            const Divider(height: 20),
            _buildProfileInfoRow('Target Pengguna', 'Mahasiswa & Pengurus Kelas'),
            _buildProfileInfoRow('Tahun Akademik', activeYear),
            _buildProfileInfoRow('Kelas Terdaftar', '${classes.length} Kelas'),
            _buildProfileInfoRow('Dosen Pengampu', '${lecturers.length} Dosen'),
            _buildProfileInfoRow('Mata Kuliah', '${courses.length} MK'),
            _buildProfileInfoRow(
              'Basis Data',
              SupabaseService.client != null ? 'Supabase Connected 🟢' : 'Offline / Standalone 🟡',
            ),
            _buildProfileInfoRow('Versi Rilis', 'v2.5.0 Production'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF111827), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                if (client == null) throw Exception('Supabase belum terhubung.');
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
                final payload = const JsonEncoder.withIndent('  ').convert(backup);
                ExportService.downloadFile(
                  'ilkom_hub_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json',
                  payload,
                );
                onRecordAudit(
                  action: 'EXPORT',
                  module: 'BACKUP',
                  description: 'Mengekspor backup JSON data aplikasi.',
                  metadata: {'tabel': tables},
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                onShowMessage('Backup JSON dibuat dari data Supabase.');
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tentang ILKOM Hub',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: const Text(
          'Aplikasi Pengelolaan Kelas Terpadu Ilmu Komunikasi Universitas Al-Azhar Menggala (UNAZLAM).\n\n"Satu Kelas, Banyak Cerita, Lebih Banyak Karya."',
          style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF4B5563)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminAppBar(
          title: 'Pengaturan Sistem',
          showSearch: false,
          onBack: onBack,
          onSearch: () {},
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
