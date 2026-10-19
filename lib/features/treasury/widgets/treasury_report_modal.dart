import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/export_service.dart';
import '../../../models/models.dart';

class TreasuryReportModal extends StatelessWidget {
  final num pemasukan;
  final num pengeluaran;
  final num saldo;
  final String periodLabel;
  final List<StudentProfile> students;
  final Map<String, bool> iuranStatus;
  final List<TreasuryTransaction> transactions;

  const TreasuryReportModal({
    super.key,
    required this.pemasukan,
    required this.pengeluaran,
    required this.saldo,
    required this.periodLabel,
    required this.students,
    required this.iuranStatus,
    required this.transactions,
  });

  static void show(
    BuildContext context, {
    required num pemasukan,
    required num pengeluaran,
    required num saldo,
    required String periodLabel,
    required List<StudentProfile> students,
    required Map<String, bool> iuranStatus,
    required List<TreasuryTransaction> transactions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => TreasuryReportModal(
        pemasukan: pemasukan,
        pengeluaran: pengeluaran,
        saldo: saldo,
        periodLabel: periodLabel,
        students: students,
        iuranStatus: iuranStatus,
        transactions: transactions,
      ),
    );
  }

  static String _formatRupiah(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final lunasCount = students.where((s) => iuranStatus[s.nim] ?? false).length;
    final totalCount = students.length;
    final pctLunas = totalCount == 0 ? 0 : ((lunasCount / totalCount) * 100).toInt();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF6D28D9),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Laporan Keuangan Komprehensif',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Rekap seluruh transaksi • iuran $periodLabel',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: ListView(
                children: [
                  // Summary Grid 2x2
                  Row(
                    children: [
                      Expanded(
                        child: _buildLaporanStatCard(
                          'Total Pemasukan',
                          _formatRupiah(pemasukan),
                          const Color(0xFF10B981),
                          const Color(0xFFDCFCE7),
                          Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildLaporanStatCard(
                          'Total Pengeluaran',
                          _formatRupiah(pengeluaran),
                          const Color(0xFFEF4444),
                          const Color(0xFFFEE2E2),
                          Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLaporanStatCard(
                          'Saldo Kas Bersih',
                          _formatRupiah(saldo),
                          const Color(0xFF6D28D9),
                          const Color(0xFFF5F3FF),
                          Icons.account_balance_wallet_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildLaporanStatCard(
                          'Kepatuhan Iuran',
                          '$pctLunas% ($lunasCount/$totalCount)',
                          const Color(0xFFF59E0B),
                          const Color(0xFFFEF3C7),
                          Icons.verified_user_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Rincian Pos Pengeluaran
                  const Text(
                    'Distribusi Pengeluaran Kelas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        ...() {
                          final expenses = transactions.where((tx) => !tx.isPemasukan).toList();
                          final totals = <String, int>{};
                          for (final tx in expenses) {
                            totals.update(
                              tx.kategori,
                              (v) => v + tx.nominal,
                              ifAbsent: () => tx.nominal,
                            );
                          }
                          if (totals.isEmpty) {
                            return <Widget>[
                              const Text(
                                'Belum ada pengeluaran tercatat untuk kelas.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ];
                          }
                          final maxTotal = totals.values.reduce((a, b) => a > b ? a : b);
                          const colors = [
                            Color(0xFF6D28D9),
                            Color(0xFF0284C7),
                            Color(0xFFF59E0B),
                            Color(0xFF10B981),
                          ];
                          return totals.entries
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: entry.key == totals.length - 1 ? 0 : 12,
                                  ),
                                  child: _buildExpenseRow(
                                    entry.value.key,
                                    _formatRupiah(entry.value.value),
                                    entry.value.value / maxTotal,
                                    colors[entry.key % colors.length],
                                  ),
                                ),
                              )
                              .toList();
                        }(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Export / Share Actions
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ExportService.showExportSheet(
                        context,
                        title: 'Export Laporan Keuangan Kelas',
                        subtitle: 'Seluruh transaksi kas kelas',
                        fileName: 'Laporan_Kas_Kelas.csv',
                        content: ExportService.exportTreasuryCsv(
                          transactions: transactions,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Export Laporan Lengkap (CSV / Excel)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanStatCard(
    String label,
    String value,
    Color color,
    Color bg,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.85),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(
    String label,
    String amount,
    double ratio,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
