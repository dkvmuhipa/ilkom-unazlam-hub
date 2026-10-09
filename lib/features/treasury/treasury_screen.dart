import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/export_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../models/models.dart';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TreasuryScreen extends StatefulWidget {
  final bool canManage;
  final String userNim;
  final String userName;
  final VoidCallback? onBack;

  const TreasuryScreen({
    super.key,
    this.canManage = true,
    this.userNim = '',
    this.userName = 'Pengurus Kelas',
    this.onBack,
  });

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  String _selectedFilter = 'Semua';
  String _selectedCategoryFilter = 'Semua Kategori';
  String _activeTab = 'transaksi'; // 'transaksi' or 'iuran'
  DateTime _selectedPeriod = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  List<TreasuryTransaction> _transactions = [];
  List<StudentProfile> _students = [];
  final Map<String, bool> _iuranStatus = {};
  final Map<String, int> _iuranNominal = {};
  final Set<String> _updatingDues = {};
  bool _isLoading = true;
  String? _loadError;

  String get _periodKey => DateFormat('yyyy-MM').format(_selectedPeriod);
  String get _periodLabel =>
      DateFormat('MMMM yyyy', 'id_ID').format(_selectedPeriod);
  int get _totalPemasukan => _transactions
      .where((tx) => tx.isPemasukan)
      .fold(0, (sum, tx) => sum + tx.nominal);
  int get _totalPengeluaran => _transactions
      .where((tx) => !tx.isPemasukan)
      .fold(0, (sum, tx) => sum + tx.nominal);
  int get _totalSaldo => _totalPemasukan - _totalPengeluaran;

  @override
  void initState() {
    super.initState();
    _loadTreasury();
  }

  Future<void> _loadTreasury() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final results = await Future.wait([
        SupabaseRepository.getTreasuryTransactionsStrict(),
        SupabaseRepository.getClassDirectoryStrict(),
        SupabaseRepository.getTreasuryDuesForPeriod(_periodKey),
      ]);
      final transactions = List<TreasuryTransaction>.from(results[0] as List);
      final classStudents = List<StudentProfile>.from(results[1] as List)
          .where((student) => student.role.toUpperCase() != 'ADMIN')
          .where((student) => student.isAktif)
          .toList();
      final students = widget.canManage
          ? classStudents
          : classStudents
                .where((student) => student.nim == widget.userNim)
                .toList();
      final dues = List<Map<String, dynamic>>.from(results[2] as List);
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _students = students;
        _iuranStatus
          ..clear()
          ..addEntries(
            dues.map(
              (row) => MapEntry(
                row['student_nim'].toString(),
                row['is_lunas'] == true,
              ),
            ),
          );
        _iuranNominal
          ..clear()
          ..addEntries(
            dues.map(
              (row) => MapEntry(
                row['student_nim'].toString(),
                (row['nominal'] as num?)?.toInt() ?? 20000,
              ),
            ),
          );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _toggleIuranStatus(
    StudentProfile student,
    bool currentStatus,
  ) async {
    if (!widget.canManage || _updatingDues.contains(student.nim)) return;
    final newStatus = !currentStatus;
    setState(() {
      _updatingDues.add(student.nim);
    });
    final saved = await SupabaseRepository.saveTreasuryDue(
      studentNim: student.nim,
      period: _periodKey,
      nominal: _iuranNominal[student.nim] ?? 20000,
      isPaid: newStatus,
    );
    if (!mounted) return;
    setState(() {
      _updatingDues.remove(student.nim);
      if (saved) _iuranStatus[student.nim] = newStatus;
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status iuran gagal disimpan. Coba lagi.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _changePeriod(int offset) {
    setState(() {
      _selectedPeriod = DateTime(
        _selectedPeriod.year,
        _selectedPeriod.month + offset,
      );
    });
    _loadTreasury();
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
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
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catat Transaksi Kas Kelas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
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
                          color: isPemasukan
                              ? AppColors.successSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPemasukan
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: isPemasukan
                                  ? AppColors.success
                                  : AppColors.textSub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isPemasukan
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isPemasukan
                                    ? AppColors.success
                                    : AppColors.textSub,
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
                          color: !isPemasukan
                              ? AppColors.errorSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !isPemasukan
                                ? AppColors.error
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: !isPemasukan
                                  ? AppColors.error
                                  : AppColors.textSub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !isPemasukan
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: !isPemasukan
                                    ? AppColors.error
                                    : AppColors.textSub,
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: kategori,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items:
                    [
                          'Iuran Kelas',
                          'Operasional',
                          'Perlengkapan',
                          'Iuran Praktikum',
                          'Sosial',
                          'Lainnya',
                        ]
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => kategori = val);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      int.tryParse(
                        amountController.text.replaceAll(RegExp(r'\D'), ''),
                      ) ??
                      0;
                  if (titleController.text.trim().isEmpty || amount <= 0)
                    return;

                  final newTx = TreasuryTransaction(
                    id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                    judul: titleController.text.trim(),
                    nominal: amount,
                    isPemasukan: isPemasukan,
                    kategori: kategori,
                    tanggal: DateTime.now(),
                    pencatat: widget.userName,
                  );
                  final saved =
                      await SupabaseRepository.createTreasuryTransaction(newTx);
                  if (!ctx.mounted) return;
                  if (!saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Transaksi gagal disimpan. Periksa koneksi dan izin bendahara.',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _transactions.insert(0, newTx));
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
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Transaksi Kas Kelas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
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
                          color: isPemasukan
                              ? AppColors.successSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPemasukan
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: isPemasukan
                                  ? AppColors.success
                                  : AppColors.textSub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isPemasukan
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isPemasukan
                                    ? AppColors.success
                                    : AppColors.textSub,
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
                          color: !isPemasukan
                              ? AppColors.errorSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !isPemasukan
                                ? AppColors.error
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: !isPemasukan
                                  ? AppColors.error
                                  : AppColors.textSub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !isPemasukan
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: !isPemasukan
                                    ? AppColors.error
                                    : AppColors.textSub,
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
                initialValue:
                    [
                      'Iuran Kelas',
                      'Operasional',
                      'Perlengkapan',
                      'Iuran Praktikum',
                      'Sosial',
                      'Lainnya',
                    ].contains(kategori)
                    ? kategori
                    : 'Iuran Kelas',
                decoration: const InputDecoration(labelText: 'Kategori'),
                items:
                    [
                          'Iuran Kelas',
                          'Operasional',
                          'Perlengkapan',
                          'Iuran Praktikum',
                          'Sosial',
                          'Lainnya',
                        ]
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => kategori = val);
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      int.tryParse(amountController.text.trim()) ?? 0;
                  if (titleController.text.trim().isEmpty || amount <= 0)
                    return;

                  final updatedTx = TreasuryTransaction(
                    id: t.id,
                    judul: titleController.text.trim(),
                    nominal: amount,
                    isPemasukan: isPemasukan,
                    kategori: kategori,
                    tanggal: t.tanggal,
                    pencatat: t.pencatat,
                  );
                  final saved =
                      await SupabaseRepository.updateTreasuryTransaction(
                        updatedTx,
                      );
                  if (!ctx.mounted) return;
                  if (!saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perubahan transaksi gagal disimpan.'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    final idx = _transactions.indexWhere((x) => x.id == t.id);
                    if (idx != -1) _transactions[idx] = updatedTx;
                  });
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
        title: const Text(
          'Hapus Transaksi?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Hapus catatan "${t.judul}" senilai ${_formatRupiah(t.nominal)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final deleted =
                  await SupabaseRepository.deleteTreasuryTransaction(t.id);
              if (!ctx.mounted) return;
              if (!deleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi gagal dihapus.')),
                );
                return;
              }
              setState(() => _transactions.removeWhere((x) => x.id == t.id));
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsAppReminder(StudentProfile s) async {
    if (!widget.canManage || s.noWa.trim().isEmpty) return;
    final cleanPhone = s.noWa.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0')
        ? '62${cleanPhone.substring(1)}'
        : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo ${s.nama}, kami mengingatkan iuran kas kelas periode $_periodLabel sebesar ${_formatRupiah(_iuranNominal[s.nim] ?? 20000)} belum tercatat lunas. Silakan hubungi bendahara kelas untuk informasi pembayaran. Terima kasih.',
    );
    final url = 'https://wa.me/$internationalPhone?text=$message';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLaporanLengkapModal(BuildContext context) {
    final pemasukan = _totalPemasukan;
    final pengeluaran = _totalPengeluaran;
    final saldo = _totalSaldo;
    final students = _students;
    final lunasCount = students
        .where((s) => _iuranStatus[s.nim] ?? false)
        .length;
    final totalCount = students.length;
    final pctLunas = totalCount == 0
        ? 0
        : ((lunasCount / totalCount) * 100).toInt();

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
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Color(0xFF5B3DE8),
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
                          'Rekap seluruh transaksi • iuran $_periodLabel',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
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
                            const Color(0xFF5B3DE8),
                            const Color(0xFFF3F0FF),
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
                            final expenses = _transactions
                                .where((tx) => !tx.isPemasukan)
                                .toList();
                            final totals = <String, int>{};
                            for (final tx in expenses) {
                              totals.update(
                                tx.kategori,
                                (v) => v + tx.nominal,
                                ifAbsent: () => tx.nominal,
                              );
                            }
                            if (totals.isEmpty)
                              return <Widget>[
                                const Text(
                                  'Belum ada pengeluaran tercatat untuk kelas.',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ];
                            final maxTotal = totals.values.reduce(
                              (a, b) => a > b ? a : b,
                            );
                            const colors = [
                              Color(0xFF5B3DE8),
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
                                      bottom: entry.key == totals.length - 1
                                          ? 0
                                          : 12,
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
                        Navigator.pop(ctx);
                        ExportService.showExportSheet(
                          context,
                          title: 'Export Laporan Keuangan Kelas',
                          subtitle: 'Seluruh transaksi kas kelas',
                          fileName: 'Laporan_Kas_Kelas.csv',
                          content: ExportService.exportTreasuryCsv(
                            transactions: _transactions,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Export Laporan Lengkap (CSV / Excel)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3DE8),
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
      ),
    );
  }

  Widget _buildLaporanStatCard(
    String title,
    String value,
    Color color,
    Color bg,
    IconData icon,
  ) {
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
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

  Widget _buildIuranMahasiswaSection() {
    final students = _students;
    final lunasCount = students
        .where((s) => _iuranStatus[s.nim] ?? false)
        .length;
    final totalCount = students.length;
    final totalTerkumpul = students.fold<int>(
      0,
      (sum, s) =>
          sum +
          ((_iuranStatus[s.nim] ?? false)
              ? (_iuranNominal[s.nim] ?? 20000)
              : 0),
    );
    final totalTunggakan = students.fold<int>(
      0,
      (sum, s) =>
          sum +
          ((_iuranStatus[s.nim] ?? false)
              ? 0
              : (_iuranNominal[s.nim] ?? 20000)),
    );

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
                    Text(
                      'Terkumpul • $_periodLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(totalTerkumpul),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      '$lunasCount dari $totalCount Mahasiswa',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Tunggakan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(totalTunggakan),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      '${totalCount - lunasCount} Belum Bayar',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
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
            Text(
              widget.canManage
                  ? 'Daftar Mahasiswa ($totalCount)'
                  : 'Status Iuran Saya',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _changePeriod(-1),
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Periode sebelumnya',
                ),
                Text(
                  _periodLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B3DE8),
                  ),
                ),
                IconButton(
                  onPressed: () => _changePeriod(1),
                  icon: const Icon(Icons.chevron_right),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Periode berikutnya',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // List Mahasiswa
        for (var s in students) ...[
          Builder(
            builder: (context) {
              final isLunas = _iuranStatus[s.nim] ?? false;
              final nominal = _iuranNominal[s.nim] ?? 20000;
              final isUpdating = _updatingDues.contains(s.nim);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLunas
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isLunas
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      child: Icon(
                        isLunas
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 18,
                        color: isLunas
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.nama,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${s.nim} • ${isLunas ? "Lunas" : "Tunggakan ${_formatRupiah(nominal)}"}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isLunas
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.canManage && !isLunas && s.noWa.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: Color(0xFF25D366),
                        ),
                        tooltip: 'Kirim Pengingat WA',
                        onPressed: () => _openWhatsAppReminder(s),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (widget.canManage)
                      InkWell(
                        onTap: isUpdating
                            ? null
                            : () => _toggleIuranStatus(s, isLunas),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLunas
                                ? const Color(0xFFF3F4F6)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isUpdating
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLunas ? 'Batalkan' : 'Tandai Lunas',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isLunas
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF16A34A),
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
    final transactions = _transactions.where((t) {
      if (_selectedFilter == 'Pemasukan' && !t.isPemasukan) return false;
      if (_selectedFilter == 'Pengeluaran' && t.isPemasukan) return false;
      if (_selectedCategoryFilter != 'Semua Kategori' &&
          t.kategori != _selectedCategoryFilter)
        return false;
      return true;
    }).toList();

    final availableCategories = [
      'Semua Kategori',
      ..._transactions.map((t) => t.kategori).toSet(),
    ];

    final totalSaldo = _totalSaldo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF111827),
                ),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Text('Kas & Keuangan Kelas'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFF111827),
              size: 22,
            ),
            tooltip: 'Laporan Lengkap & Statistik',
            onPressed: widget.canManage
                ? () => _showLaporanLengkapModal(context)
                : null,
          ),
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: Color(0xFF111827),
              size: 22,
            ),
            tooltip: 'Export Rekap Kas (Excel/CSV)',
            onPressed: widget.canManage
                ? () {
                    ExportService.showExportSheet(
                      context,
                      title: 'Export Rekap Kas Kelas',
                      subtitle: 'Seluruh transaksi kas kelas',
                      fileName: 'Rekap_Kas_Kelas.csv',
                      content: ExportService.exportTreasuryCsv(
                        transactions: _transactions,
                      ),
                    );
                  }
                : null,
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
              label: const Text(
                'Catat Kas',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 36,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Data kas gagal dimuat dari Supabase.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadTreasury,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Transparan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
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
                                      child: const Icon(
                                        Icons.arrow_downward_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pemasukan',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _formatRupiah(_totalPemasukan),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
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
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pengeluaran',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _formatRupiah(_totalPengeluaran),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Dikelola oleh pengurus kas kelas dan dapat dilihat oleh seluruh mahasiswa.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
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
                            onTap: () =>
                                setState(() => _activeTab = 'transaksi'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _activeTab == 'transaksi'
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _activeTab == 'transaksi'
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      size: 15,
                                      color: _activeTab == 'transaksi'
                                          ? const Color(0xFF5B3DE8)
                                          : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Transaksi Kas',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: _activeTab == 'transaksi'
                                            ? const Color(0xFF5B3DE8)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
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
                                color: _activeTab == 'iuran'
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _activeTab == 'iuran'
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.groups_rounded,
                                      size: 15,
                                      color: _activeTab == 'iuran'
                                          ? const Color(0xFF5B3DE8)
                                          : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Iuran Mahasiswa',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: _activeTab == 'iuran'
                                            ? const Color(0xFF5B3DE8)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
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
                    // Filter Tabs & Category Filter
                    Row(
                      children: [
                        ...['Semua', 'Pemasukan', 'Pengeluaran'].map((filter) {
                          final isSelected = filter == _selectedFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedFilter = filter),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSub,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    if (availableCategories.length > 1) ...[
                      const SizedBox(height: 10),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                availableCategories.contains(
                                  _selectedCategoryFilter,
                                )
                                ? _selectedCategoryFilter
                                : 'Semua Kategori',
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            items: availableCategories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(
                                      cat == 'Semua Kategori'
                                          ? Icons.filter_list_rounded
                                          : Icons.label_outline_rounded,
                                      size: 14,
                                      color: cat == 'Semua Kategori'
                                          ? const Color(0xFF6B7280)
                                          : const Color(0xFF5B3DE8),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight:
                                              cat == _selectedCategoryFilter
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: const Color(0xFF1F2937),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategoryFilter = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // List Transaksi
                    if (transactions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
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
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 32,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Belum Ada Catatan Transaksi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Semua pemasukan kas kelas dan pengeluaran operasional akan dicatat secara transparan di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSub,
                                height: 1.4,
                              ),
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
              color: t.isPemasukan
                  ? AppColors.successSoft
                  : AppColors.errorSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              t.isPemasukan
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd MMM yyyy').format(t.tanggal)} • ${t.pencatat}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
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
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textLight,
              ),
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
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF5B3DE8),
                      ),
                      SizedBox(width: 8),
                      Text('Edit Transaksi', style: TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFEF4444),
                        ),
                      ),
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
