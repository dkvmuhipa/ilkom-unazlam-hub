import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/export_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TreasuryScreen extends StatefulWidget {
  final bool canManage;
  final VoidCallback? onBack;

  const TreasuryScreen({
    super.key,
    this.canManage = true,
    this.onBack,
  });

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  String _selectedFilter = 'Semua';
  String _activeTab = 'transaksi'; // 'transaksi' or 'iuran'
  final Map<String, bool> _iuranStatus = {};

  @override
  void initState() {
    super.initState();
    _loadIuranStatus();
  }

  Future<void> _loadIuranStatus() async {
    for (int i = 0; i < DummyData.students.length; i++) {
      final s = DummyData.students[i];
      _iuranStatus[s.id] = (i % 6 != 0);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var s in DummyData.students) {
        final val = prefs.getBool('iuran_status_${s.id}');
        if (val != null) {
          _iuranStatus[s.id] = val;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleIuranStatus(String studentId, bool currentStatus) async {
    final newStatus = !currentStatus;
    setState(() {
      _iuranStatus[studentId] = newStatus;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('iuran_status_$studentId', newStatus);
    } catch (_) {}
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showAddTransactionModal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isPemasukan = true;
    String kategori = 'Kas Bulanan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catat Transaksi Kas Kelas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => isPemasukan = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isPemasukan ? AppColors.successSoft : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isPemasukan ? AppColors.success : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 16, color: isPemasukan ? AppColors.success : AppColors.textSub),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isPemasukan ? FontWeight.w700 : FontWeight.w500,
                                color: isPemasukan ? AppColors.success : AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => isPemasukan = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isPemasukan ? AppColors.errorSoft : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: !isPemasukan ? AppColors.error : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 16, color: !isPemasukan ? AppColors.error : AppColors.textSub),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !isPemasukan ? FontWeight.w700 : FontWeight.w500,
                                color: !isPemasukan ? AppColors.error : AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Misal: Iuran Kas Bulan Maret atau Beli Baterai',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Nominal (Rp)',
                  hintText: 'Contoh: 150000',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(amountController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
                  if (titleController.text.trim().isEmpty || amount <= 0) return;

                  final newTx = TreasuryTransaction(
                    id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                    judul: titleController.text.trim(),
                    nominal: amount,
                    isPemasukan: isPemasukan,
                    kategori: kategori,
                    tanggal: DateTime.now(),
                    pencatat: 'Alya Nabilah (Bendahara)',
                  );
                  setState(() {
                    DummyData.treasuryTransactions.insert(0, newTx);
                  });
                  SupabaseRepository.createTreasuryTransaction(newTx);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi kas berhasil dicatat!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Simpan Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTransactionModal(TreasuryTransaction t) {
    final titleController = TextEditingController(text: t.judul);
    final amountController = TextEditingController(text: t.nominal.toString());
    bool isPemasukan = t.isPemasukan;
    String kategori = t.kategori;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Transaksi Kas Kelas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => isPemasukan = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isPemasukan ? AppColors.successSoft : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isPemasukan ? AppColors.success : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 16, color: isPemasukan ? AppColors.success : AppColors.textSub),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isPemasukan ? FontWeight.w700 : FontWeight.w500,
                                color: isPemasukan ? AppColors.success : AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => isPemasukan = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isPemasukan ? AppColors.errorSoft : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: !isPemasukan ? AppColors.error : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 16, color: !isPemasukan ? AppColors.error : AppColors.textSub),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !isPemasukan ? FontWeight.w700 : FontWeight.w500,
                                color: !isPemasukan ? AppColors.error : AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Transaksi',
                  hintText: 'Misal: Iuran Kas, Fotocopy Materi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: ['Iuran Kelas', 'Operasional', 'Perlengkapan', 'Iuran Praktikum', 'Sosial', 'Lainnya'].contains(kategori) ? kategori : 'Iuran Kelas',
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: ['Iuran Kelas', 'Operasional', 'Perlengkapan', 'Iuran Praktikum', 'Sosial', 'Lainnya']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => kategori = val);
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(amountController.text.trim()) ?? 0;
                  if (titleController.text.trim().isEmpty || amount <= 0) return;

                  final updatedTx = TreasuryTransaction(
                    id: t.id,
                    judul: titleController.text.trim(),
                    nominal: amount,
                    isPemasukan: isPemasukan,
                    kategori: kategori,
                    tanggal: t.tanggal,
                    pencatat: t.pencatat,
                  );
                  final idx = DummyData.treasuryTransactions.indexWhere((x) => x.id == t.id);
                  if (idx != -1) {
                    setState(() {
                      DummyData.treasuryTransactions[idx] = updatedTx;
                    });
                  }
                  SupabaseRepository.updateTreasuryTransaction(updatedTx);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi kas berhasil diperbarui!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTransaction(TreasuryTransaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Hapus catatan "${t.judul}" senilai ${_formatRupiah(t.nominal)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                DummyData.treasuryTransactions.removeWhere((x) => x.id == t.id);
              });
              SupabaseRepository.deleteTreasuryTransaction(t.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaksi berhasil dihapus.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsAppReminder(StudentProfile s) async {
    final cleanPhone = s.noWa.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo ${s.nama}, kami dari Bendahara Kelas ILKOM UNAZLAM mengingatkan untuk iuran kas kelas bulan Oktober senilai Rp 20.000. Mohon kerja samanya ya, terima kasih banyak! 🙏',
    );
    final url = 'https://wa.me/$internationalPhone?text=$message';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLaporanLengkapModal(BuildContext context) {
    final pemasukan = DummyData.totalKasPemasukan;
    final pengeluaran = DummyData.totalKasPengeluaran;
    final saldo = DummyData.totalKasSaldo;
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();
    final lunasCount = students.where((s) => _iuranStatus[s.id] ?? false).length;
    final totalCount = students.length;
    final pctLunas = totalCount == 0 ? 0 : ((lunasCount / totalCount) * 100).toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
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
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFF5B3DE8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan Keuangan Komprehensif',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        ),
                        Text('Semester 1 • Tahun Akademik 2026/2027', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
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
                          child: _buildLaporanStatCard('Total Pemasukan', _formatRupiah(pemasukan), const Color(0xFF10B981), const Color(0xFFDCFCE7), Icons.arrow_downward_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildLaporanStatCard('Total Pengeluaran', _formatRupiah(pengeluaran), const Color(0xFFEF4444), const Color(0xFFFEE2E2), Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLaporanStatCard('Saldo Kas Bersih', _formatRupiah(saldo), const Color(0xFF5B3DE8), const Color(0xFFF3F0FF), Icons.account_balance_wallet_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildLaporanStatCard('Kepatuhan Iuran', '$pctLunas% ($lunasCount/$totalCount)', const Color(0xFFF59E0B), const Color(0xFFFEF3C7), Icons.verified_user_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rincian Pos Pengeluaran
                    const Text('Distribusi Pengeluaran Kelas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
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
                          _buildExpenseRow('Fotokopi Silabus & Makalah', 'Rp 45.000', 0.28, const Color(0xFF5B3DE8)),
                          const SizedBox(height: 12),
                          _buildExpenseRow('Konsumsi Dosen Tamu Praktikum', 'Rp 70.000', 0.44, const Color(0xFF0284C7)),
                          const SizedBox(height: 12),
                          _buildExpenseRow('Spidol Whiteboard & ATK Kelas', 'Rp 25.000', 0.16, const Color(0xFFF59E0B)),
                          const SizedBox(height: 12),
                          _buildExpenseRow('Kas Cadangan & Kebersihan', 'Rp 20.000', 0.12, const Color(0xFF10B981)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Export / Share Actions
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ExportService.showExportSheet(
                          context,
                          title: 'Export Laporan Keuangan Kelas',
                          subtitle: 'File rekap keuangan resmi kelas ILKOM UNAZLAM 2026',
                          fileName: 'Laporan_Keuangan_ILKOM_UNAZLAM_2026.csv',
                          content: ExportService.exportTreasuryCsv(),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export Laporan Lengkap (CSV / Excel)', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3DE8),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaporanStatCard(String title, String value, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(String label, String amount, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151)))),
            Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
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

  Widget _buildIuranMahasiswaSection() {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();
    final lunasCount = students.where((s) => _iuranStatus[s.id] ?? false).length;
    final totalCount = students.length;
    final totalTerkumpul = lunasCount * 20000;
    final totalTunggakan = (totalCount - lunasCount) * 20000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Terkumpul Bulan Ini', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(totalTerkumpul),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                    Text('$lunasCount dari $totalCount Mahasiswa', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Tunggakan', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(totalTunggakan),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                    ),
                    Text('${totalCount - lunasCount} Belum Bayar', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daftar Mahasiswa ($totalCount)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            const Text('Tarif: Rp 20.000 / Bulan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B3DE8))),
          ],
        ),
        const SizedBox(height: 10),

        // List Mahasiswa
        for (var s in students) ...[
          Builder(
            builder: (context) {
              final isLunas = _iuranStatus[s.id] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isLunas ? const Color(0xFFE5E7EB) : const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isLunas ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      child: Icon(
                        isLunas ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 18,
                        color: isLunas ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nama, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                          Text('${s.nim} • ${isLunas ? "Lunas" : "Tunggakan Rp 20.000"}', style: TextStyle(fontSize: 10.5, color: isLunas ? const Color(0xFF16A34A) : const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (!isLunas && s.noWa.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                        tooltip: 'Kirim Pengingat WA',
                        onPressed: () => _openWhatsAppReminder(s),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (widget.canManage)
                      InkWell(
                        onTap: () => _toggleIuranStatus(s.id, isLunas),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLunas ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isLunas ? 'Batalkan' : 'Tandai Lunas',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isLunas ? const Color(0xFF6B7280) : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = DummyData.treasuryTransactions.where((t) {
      if (_selectedFilter == 'Pemasukan') return t.isPemasukan;
      if (_selectedFilter == 'Pengeluaran') return !t.isPemasukan;
      return true;
    }).toList();

    final totalSaldo = DummyData.totalKasSaldo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Text('Kas & Keuangan Kelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Color(0xFF111827), size: 22),
            tooltip: 'Laporan Lengkap & Statistik',
            onPressed: () => _showLaporanLengkapModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF111827), size: 22),
            tooltip: 'Export Rekap Kas (Excel/CSV)',
            onPressed: () {
              ExportService.showExportSheet(
                context,
                title: 'Export Rekap Kas Kelas',
                subtitle: 'Format data CSV kompatibel dengan Microsoft Excel & Google Sheets',
                fileName: 'Rekap_Kas_ILKOM_UNAZLAM_2026.csv',
                content: ExportService.exportTreasuryCsv(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddTransactionModal,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Catat Kas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Saldo Card (Modern Royal Violet)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Saldo Kas Kelas',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Transparan',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(totalSaldo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mini Visual Breakdown (Pemasukan vs Pengeluaran)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                    Text(
                                      _formatRupiah(DummyData.totalKasPemasukan),
                                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                    Text(
                                      _formatRupiah(DummyData.totalKasPengeluaran),
                                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, size: 16, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dikelola oleh Bendahara Kelas (Alya Nabilah) untuk keperluan akademik & praktikum.',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Mode Switcher: Transaksi vs Iuran Mahasiswa
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = 'transaksi'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTab == 'transaksi' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _activeTab == 'transaksi'
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '💳 Transaksi Kas',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _activeTab == 'transaksi' ? const Color(0xFF5B3DE8) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = 'iuran'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTab == 'iuran' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _activeTab == 'iuran'
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '📋 Iuran Mahasiswa',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _activeTab == 'iuran' ? const Color(0xFF5B3DE8) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_activeTab == 'iuran') ...[
              _buildIuranMahasiswaSection(),
            ] else ...[
              // Filter Tabs
              Row(
                children: ['Semua', 'Pemasukan', 'Pengeluaran'].map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = filter),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

            // List Transaksi
            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F2F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum Ada Catatan Transaksi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Semua pemasukan kas kelas dan pengeluaran operasional akan dicatat secara transparan di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSub, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              ...transactions.map((t) => _buildTransactionCard(t)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TreasuryTransaction t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.isPemasukan ? AppColors.successSoft : AppColors.errorSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              t.isPemasukan ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 20,
              color: t.isPemasukan ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.judul,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd MMM yyyy').format(t.tanggal)} • ${t.pencatat}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${t.isPemasukan ? "+" : "-"}${_formatRupiah(t.nominal)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.isPemasukan ? AppColors.success : AppColors.error,
            ),
          ),
          if (widget.canManage) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textLight),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditTransactionModal(t);
                } else if (val == 'delete') {
                  _confirmDeleteTransaction(t);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5B3DE8)),
                      SizedBox(width: 8),
                      Text('Edit Transaksi', style: TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(fontSize: 12.5, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
