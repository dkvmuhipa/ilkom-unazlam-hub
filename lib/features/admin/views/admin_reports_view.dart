import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../models/models.dart';
import '../widgets/admin_common_widgets.dart';

class AdminReportsView extends StatelessWidget {
  final Future<Map<String, String>>? reportFuture;
  final List<StudentProfile> managedAccounts;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final void Function(String view)? onNavigate;

  const AdminReportsView({
    super.key,
    required this.reportFuture,
    required this.managedAccounts,
    required this.onRefresh,
    required this.onBack,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminAppBar(
          title: 'Laporan & Rekapitulasi',
          showSearch: false,
          onSearch: onRefresh,
          onBack: onBack,
        ),
        Expanded(
          child: FutureBuilder<Map<String, String>>(
            future: reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CA3AF), size: 36),
                        const SizedBox(height: 10),
                        Text('Laporan gagal dimuat: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final report = snapshot.data ?? {};
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                children: [
                  // Banner Matriks Presensi 16 Sesi & BAP (Feature Highlight - UNAZLAM Brand)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF58138A), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D28D9).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AdminAdaptiveRow(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.table_chart_rounded, color: Color(0xFFFDE68A), size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Matriks Presensi 16 Pertemuan (BAP)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Pantau kehadiran P1 - P16, kalkulasi batas kelayakan UAS 75%, dan cetak Berita Acara.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFDDD6FE),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () => onNavigate?.call('matriks_presensi'),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: const Text('Buka Matriks', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF1E1B4B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ketuk laporan untuk melihat pratinjau data dan mengekspor berkas dalam format CSV / Excel.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildReportCard(
                    title: 'Rekap Presensi Seluruh Kelas',
                    subtitle: report['attendance'] ?? '-',
                    icon: Icons.checklist_rounded,
                    color: const Color(0xFF10B981),
                    onDownload: () async {
                      final logs = await SupabaseRepository.getAttendanceLogs();
                      final csv = ExportService.exportAttendanceCsv(
                        courseName: 'Semua Mata Kuliah',
                        logs: logs,
                        students: managedAccounts,
                      );
                      if (context.mounted) {
                        ExportService.showExportSheet(
                          context,
                          title: 'Rekap Presensi Mahasiswa',
                          fileName: 'rekap_presensi_semua_kelas.csv',
                          content: csv,
                          subtitle: 'Daftar Presensi Seluruh Kelas',
                        );
                      }
                    },
                  ),
                  _buildReportCard(
                    title: 'Laporan Keuangan Kas Kelas',
                    subtitle: report['treasury'] ?? '-',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    onDownload: () async {
                      List<TreasuryTransaction> txs = [];
                      try {
                        txs = await SupabaseRepository.getTreasuryTransactions();
                      } catch (_) {}
                      final csv = ExportService.exportTreasuryCsv(transactions: txs);
                      if (context.mounted) {
                        ExportService.showExportSheet(
                          context,
                          title: 'Laporan Kas Kelas',
                          fileName: 'laporan_kas_kelas_${DateTime.now().year}.csv',
                          content: csv,
                          subtitle: 'Rekap Transaksi & Saldo Kas Kelas',
                        );
                      }
                    },
                  ),
                  _buildReportCard(
                    title: 'Distribusi Tugas Mahasiswa',
                    subtitle: report['assignments'] ?? '-',
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFFF59E0B),
                    onDownload: () async {
                      List<Assignment> asgs = [];
                      try {
                        asgs = await SupabaseRepository.getAssignments();
                      } catch (_) {}
                      final csv = ExportService.exportAssignmentsCsv(assignments: asgs);
                      if (context.mounted) {
                        ExportService.showExportSheet(
                          context,
                          title: 'Distribusi Tugas Kuliah',
                          fileName: 'rekap_distribusi_tugas.csv',
                          content: csv,
                          subtitle: 'Daftar Tugas dan Tenggat Pengumpulan',
                        );
                      }
                    },
                  ),
                  _buildReportCard(
                    title: 'Akun Mahasiswa Aktif',
                    subtitle: report['students'] ?? '-',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0284C7),
                    onDownload: () {
                      final csv = ExportService.exportStudentsCsv(students: managedAccounts);
                      ExportService.showExportSheet(
                        context,
                        title: 'Daftar Akun Mahasiswa Terdaftar',
                        fileName: 'data_mahasiswa_aktif.csv',
                        content: csv,
                        subtitle: 'Master Data Profil Mahasiswa',
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onDownload,
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
        child: InkWell(
          onTap: onDownload,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_download_outlined, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'CSV',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
