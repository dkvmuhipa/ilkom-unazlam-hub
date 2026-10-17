import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../core/constants/app_colors.dart';
import '../../core/services/export_service.dart';
import '../../core/services/safe_launcher.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/services/waha_service.dart';
import '../../core/widgets/scale_button.dart';
import '../../models/models.dart';
import 'widgets/treasury_qris_modal.dart';
import 'widgets/treasury_report_modal.dart';
import 'widgets/treasury_transaction_modal.dart';

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
  String _duesFilter = 'Semua'; // 'Semua', 'Lunas', 'Belum Lunas'
  String _searchQuery = '';
  bool _hideBalance = false;

  final TextEditingController _searchController = TextEditingController();

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
  RealtimeChannel? _treasuryChannel;
  RealtimeChannel? _treasuryDuesChannel;

  String get _periodKey => DateFormat('yyyy-MM').format(_selectedPeriod);
  String get _periodLabel =>
      DateFormat('MMMM yyyy', 'id_ID').format(_selectedPeriod);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedPeriod.year == now.year &&
        _selectedPeriod.month == now.month;
  }

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
    _initRealtime();
  }

  void _initRealtime() {
    _treasuryChannel = SupabaseRepository.subscribeToTreasury(() {
      if (mounted) {
        _loadTreasury(silent: true);
      }
    });
    _treasuryDuesChannel = SupabaseRepository.subscribeToTreasuryDues(() {
      if (mounted) {
        _loadTreasury(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    SupabaseRepository.unsubscribeChannel(_treasuryChannel);
    SupabaseRepository.unsubscribeChannel(_treasuryDuesChannel);
    super.dispose();
  }

  Future<void> _loadTreasury({bool silent = false}) async {
    if (mounted && !silent) {
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
    } else {
      HapticFeedback.lightImpact();
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

  void _resetToCurrentMonth() {
    setState(() {
      _selectedPeriod = DateTime(
        DateTime.now().year,
        DateTime.now().month,
      );
    });
    _loadTreasury();
  }

  String _formatRupiah(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _showAddTransactionModal() {
    TreasuryTransactionModal.show(
      context,
      userName: widget.userName,
      onSaved: (newTx) {
        if (mounted) {
          setState(() => _transactions.insert(0, newTx));
        }
      },
    );
  }

  void _showEditTransactionModal(TreasuryTransaction t) {
    TreasuryTransactionModal.show(
      context,
      transaction: t,
      userName: widget.userName,
      onSaved: (updatedTx) {
        if (mounted) {
          setState(() {
            final idx = _transactions.indexWhere((x) => x.id == updatedTx.id);
            if (idx != -1) _transactions[idx] = updatedTx;
          });
        }
      },
      onDeleted: (deletedId) {
        if (mounted) {
          setState(() {
            _transactions.removeWhere((x) => x.id == deletedId);
          });
        }
      },
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
              final messenger = ScaffoldMessenger.of(context);
              final deleted =
                  await SupabaseRepository.deleteTreasuryTransaction(t.id);
              if (!ctx.mounted) return;
              if (!deleted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Transaksi gagal dihapus.')),
                );
                return;
              }
              if (mounted) {
                setState(() => _transactions.removeWhere((x) => x.id == t.id));
              }
              Navigator.pop(ctx);
              messenger.showSnackBar(
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

    final nominalStr = _formatRupiah(_iuranNominal[s.nim] ?? 20000);
    final rawMessage = 'Halo *${s.nama}* (NIM: ${s.nim}),\n\n'
        'Kami mengingatkan tagihan iuran kas kelas periode $_periodLabel sebesar $nominalStr belum tercatat lunas.\n\n'
        'Pembayaran dapat dilakukan melalui scan QRIS resmi kelas atau transfer ke Bank Mandiri: 123-00-1098273-1 a.n. BENDAHARA ILKOM UNAZLAM 2026.\n\n'
        'Setelah transfer, silakan kirim bukti ke nomor ini. Terima kasih! 🙏✨';

    // 1. Coba kirim otomatis jika WAHA Gateway aktif
    try {
      final wahaStatus = await WahaService.getSessionStatus();
      if (wahaStatus.isConnected) {
        final res = await WahaService.sendTextMessage(recipient: s.noWa, text: rawMessage);
        if (res.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesan pengingat kas otomatis berhasil dikirim ke WhatsApp ${s.nama}! 📨✨'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback membuka aplikasi WhatsApp via wa.me
    final cleanPhone = s.noWa.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = cleanPhone.startsWith('0')
        ? '62${cleanPhone.substring(1)}'
        : cleanPhone;
    final message = Uri.encodeComponent(rawMessage);
    final url = 'https://wa.me/$internationalPhone?text=$message';
    safeLaunchUrl(url);
  }

  void _copyDuesBroadcast() {
    final unPaid = _students.where((s) => (_iuranStatus[s.nim] ?? false) == false).toList();
    final paid = _students.where((s) => (_iuranStatus[s.nim] ?? false) == true).toList();

    final buffer = StringBuffer();
    buffer.writeln('*📢 REKAP IURAN KAS KELAS ILKOM UNAZLAM*');
    buffer.writeln('*Periode: $_periodLabel*');
    buffer.writeln('────────────────────────────');
    buffer.writeln('Total Mahasiswa : ${_students.length}');
    buffer.writeln('✅ Sudah Lunas   : ${paid.length}');
    buffer.writeln('⏳ Belum Lunas   : ${unPaid.length}');
    buffer.writeln('────────────────────────────');

    if (unPaid.isNotEmpty) {
      buffer.writeln('\n*⚠️ DAFTAR MAHASISWA BELUM LUNAS:*');
      for (int i = 0; i < unPaid.length; i++) {
        final s = unPaid[i];
        final nominal = _formatRupiah(_iuranNominal[s.nim] ?? 20000);
        buffer.writeln('${i + 1}. ${s.nama} (${s.nim}) - $nominal');
      }
      buffer.writeln('\n💡 *Info Pembayaran Kas:*');
      buffer.writeln('• Rek Mandiri: 123-00-1098273-1 a.n. BENDAHARA ILKOM 2026');
      buffer.writeln('• Atau scan QRIS melalui Aplikasi ILKOM UNAZLAM Hub');
      buffer.writeln('• Kirim bukti transfer ke nomor Bendahara Kelas');
    } else {
      buffer.writeln('\n🎉 *Alhamdulillah, semua mahasiswa telah melunasi kas untuk periode ini!*');
    }
    buffer.writeln('\n_Terima kasih atas kerja sama dan partisipasi aktif semuanya! 🙏_');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks rekap tagihan berhasil disalin! Siap dikirim ke grup WhatsApp kelas. 📋'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _showQrisPaymentModal() {
    TreasuryQrisModal.show(
      context,
      students: _students,
      initialNim: widget.userNim,
      periodLabel: _periodLabel,
      defaultNominal: 20000,
    );
  }

  void _showLaporanLengkapModal(BuildContext context) {
    TreasuryReportModal.show(
      context,
      pemasukan: _totalPemasukan,
      pengeluaran: _totalPengeluaran,
      saldo: _totalSaldo,
      periodLabel: _periodLabel,
      students: _students,
      iuranStatus: _iuranStatus,
      transactions: _transactions,
    );
  }

  void _showTransactionReceipt(TreasuryTransaction tx) {
    final isIncome = tx.isPemasukan;
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final amountFormatted =
        '${isIncome ? "+" : "-"}${_formatRupiah(tx.nominal)}';
    final dateFormatted =
        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(tx.tanggal);

    final receiptText =
        '========================================\n'
        '       BUKTI TRANSAKSI KAS RESMI        \n'
        '      INFORMATIKA UNAZLAM ANGKATAN 2026 \n'
        '========================================\n'
        'ID Transaksi : ${tx.id}\n'
        'Keterangan   : ${tx.judul}\n'
        'Kategori     : ${tx.kategori}\n'
        'Jenis Arus   : ${isIncome ? "Pemasukan (+)" : "Pengeluaran (-)"}\n'
        'Nominal      : $amountFormatted\n'
        'Tanggal      : $dateFormatted WIB\n'
        'Dicatat Oleh : ${tx.pencatat}\n'
        '========================================\n'
        'Catatan kas ini tersimpan secara transparan\n'
        'dalam pembukuan digital kelas UNAZLAM.\n';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukti Transaksi Kas',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Struk Elektronik Terverifikasi',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Digital Receipt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge Jenis Arus
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isIncome ? 'KAS MASUK' : 'KAS KELUAR',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Amount Display
                    Text(
                      amountFormatted,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.judul,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Key-Values
                    _buildReceiptRow('Kategori', tx.kategori),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Waktu Transaksi', dateFormatted),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Dicatat Oleh', tx.pencatat),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                      'ID Transaksi',
                      tx.id.length > 18 ? tx.id.substring(0, 18) : tx.id,
                      isMonospace: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: receiptText));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Rincian transaksi berhasil disalin!'),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 16, color: Color(0xFF334155)),
                            SizedBox(width: 6),
                            Text(
                              'Salin Rincian',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScaleButton(
                      onTap: () {
                        final msg = Uri.encodeComponent(
                          'Berikut rincian transaksi kas kelas ILKOM UNAZLAM:\n\n'
                          '• ${tx.judul}\n'
                          '• Nominal: $amountFormatted\n'
                          '• Kategori: ${tx.kategori}\n'
                          '• Tanggal: $dateFormatted\n'
                          '• Dicatat: ${tx.pencatat}\n\n'
                          'Kas tercatat secara transparan di UNAZLAM Class Manager.',
                        );
                        safeLaunchUrl('https://wa.me/?text=$msg');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Bagikan ke WA',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isMonospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _transactions.where((t) {
      if (_selectedFilter == 'Pemasukan' && !t.isPemasukan) return false;
      if (_selectedFilter == 'Pengeluaran' && t.isPemasukan) return false;
      if (_selectedCategoryFilter != 'Semua Kategori' &&
          t.kategori != _selectedCategoryFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = t.judul.toLowerCase().contains(q);
        final matchCat = t.kategori.toLowerCase().contains(q);
        final matchAmount = t.nominal.toString().contains(q);
        if (!matchTitle && !matchCat && !matchAmount) return false;
      }
      return true;
    }).toList();

    final availableCategories = [
      'Semua Kategori',
      ..._transactions.map((t) => t.kategori).toSet(),
    ];

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
            tooltip: 'Export Rekap Kas (CSV)',
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
          ? ScaleButton(
              onTap: _showAddTransactionModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Catat Kas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _loadTreasury,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadTreasury(silent: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ultra-Modern Fintech Balance Card
                        _buildFintechBalanceCard(),
                        const SizedBox(height: 16),

                        // Period Switcher Banner
                        _buildPeriodSwitcher(),
                        const SizedBox(height: 16),

                        // Tab Switcher: Transaksi Kas vs Iuran Mahasiswa
                        _buildTabSwitcher(),
                        const SizedBox(height: 16),

                        // Tab Body
                        if (_activeTab == 'iuran') ...[
                          _buildIuranMahasiswaSection(),
                        ] else ...[
                          _buildTransaksiSection(
                            transactions,
                            availableCategories,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFintechBalanceCard() {
    final totalSaldo = _totalSaldo;
    final totalFlow = _totalPemasukan + _totalPengeluaran;
    final incomeRatio = totalFlow > 0 ? (_totalPemasukan / totalFlow) : 0.5;
    final expenseRatio = totalFlow > 0 ? (_totalPengeluaran / totalFlow) : 0.5;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Midnight Dark
            Color(0xFF1E1B4B), // Deep Indigo
            Color(0xFF1E40AF), // Royal Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Subtle Background Circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            left: 100,
            bottom: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Card Brand & Verified Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // EMV Chip Simulation
                        Container(
                          width: 32,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.memory_rounded,
                            size: 14,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'KAS KELAS ILKOM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'TRANSPARAN',
                            style: TextStyle(
                              color: Color(0xFF86EFAC),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Balance Label & Eye Toggle
                Row(
                  children: [
                    const Text(
                      'Total Saldo Bersih Saat Ini',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ScaleButton(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _hideBalance = !_hideBalance);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _hideBalance
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Amount Text
                Text(
                  _hideBalance ? 'Rp • • • • • • • •' : _formatRupiah(totalSaldo),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Animated Cashflow Comparison Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (incomeRatio * 100).toInt().clamp(5, 95),
                              child: Container(
                                color: const Color(0xFF10B981), // Emerald
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              flex: (expenseRatio * 100).toInt().clamp(5, 95),
                              child: Container(
                                color: const Color(0xFFF43F5E), // Coral
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Inflow & Outflow Pill Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
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
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pemasukan',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _hideBalance
                                            ? '••••'
                                            : _formatRupiah(_totalPemasukan),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
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
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pengeluaran',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _hideBalance
                                            ? '••••'
                                            : _formatRupiah(_totalPengeluaran),
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
                  ],
                ),
                const SizedBox(height: 16),

                // Card Action Hub (Quick Buttons)
                Row(
                  children: [
                    Expanded(
                      child: ScaleButton(
                        onTap: _showQrisPaymentModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 16,
                                color: Color(0xFF1E40AF),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Bayar QRIS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ScaleButton(
                        onTap: () => _showLaporanLengkapModal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Laporan Kas',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ScaleButton(
                onTap: () => _changePeriod(-1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Periode Pembukuan',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _periodLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (!_isCurrentMonth) ...[
                ScaleButton(
                  onTap: _resetToCurrentMonth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bulan Ini',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ScaleButton(
                onTap: () => _changePeriod(1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    final txCount = _transactions.length;
    final lunasCount =
        _students.where((s) => _iuranStatus[s.nim] ?? false).length;
    final totalCount = _students.length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: ScaleButton(
              onTap: () => setState(() => _activeTab = 'transaksi'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'transaksi'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTab == 'transaksi'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: _activeTab == 'transaksi'
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Transaksi Kas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _activeTab == 'transaksi'
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _activeTab == 'transaksi'
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _activeTab == 'transaksi'
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$txCount',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _activeTab == 'transaksi'
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ScaleButton(
              onTap: () => setState(() => _activeTab = 'iuran'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      _activeTab == 'iuran' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTab == 'iuran'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 16,
                      color: _activeTab == 'iuran'
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Iuran Mahasiswa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _activeTab == 'iuran'
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _activeTab == 'iuran'
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _activeTab == 'iuran'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$lunasCount/$totalCount',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _activeTab == 'iuran'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiSection(
    List<TreasuryTransaction> transactions,
    List<String> availableCategories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar for Transactions
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari catatan transaksi kas...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filter Pills: [Semua, Pemasukan, Pengeluaran]
        Row(
          children: [
            ...['Semua', 'Pemasukan', 'Pengeluaran'].map((filter) {
              final isSelected = filter == _selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ScaleButton(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
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
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: availableCategories.contains(_selectedCategoryFilter)
                    ? _selectedCategoryFilter
                    : 'Semua Kategori',
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
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
                              ? const Color(0xFF64748B)
                              : const Color(0xFF1E40AF),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: cat == _selectedCategoryFilter
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
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 32,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Belum Ada Catatan Transaksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Semua pemasukan kas dan pengeluaran kelas akan tercatat rapi di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ...transactions.map((t) => _buildTransactionCard(t)),
      ],
    );
  }

  Widget _buildTransactionCard(TreasuryTransaction t) {
    final isIncome = t.isPemasukan;
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return ScaleButton(
      onTap: () => _showTransactionReceipt(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: color, width: 4),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.kategori,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM yyyy').format(t.tanggal),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.judul,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Oleh ${t.pencatat}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? "+" : "-"}${_formatRupiah(t.nominal)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    if (widget.canManage) ...[
                      const SizedBox(height: 2),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
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
                                  color: Color(0xFF1E40AF),
                                ),
                                SizedBox(width: 8),
                                Text('Edit', style: TextStyle(fontSize: 12.5)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIuranMahasiswaSection() {
    final students = _students;
    final lunasCount =
        students.where((s) => _iuranStatus[s.nim] ?? false).length;
    final totalCount = students.length;
    final pctLunas =
        totalCount > 0 ? (lunasCount / totalCount).clamp(0.0, 1.0) : 0.0;

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

    final filteredStudents = students.where((s) {
      final isLunas = _iuranStatus[s.nim] ?? false;
      if (_duesFilter == 'Lunas' && !isLunas) return false;
      if (_duesFilter == 'Belum Lunas' && isLunas) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNama = s.nama.toLowerCase().contains(q);
        final matchNim = s.nim.toLowerCase().contains(q);
        if (!matchNama && !matchNim) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Health & Progress Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kepatuhan Iuran • $_periodLabel',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$lunasCount dari $totalCount Mahasiswa (${(pctLunas * 100).toInt()}%)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pctLunas,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terkumpul',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRupiah(totalTerkumpul),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF047857),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Tunggakan',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRupiah(totalTunggakan),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDC2626),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Search bar & Filter Pills for Dues
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari mahasiswa atau NIM...',
                    hintStyle: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            ...['Semua', 'Lunas', 'Belum Lunas'].map((filter) {
              final isSelected = filter == _duesFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ScaleButton(
                  onTap: () => setState(() => _duesFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (widget.canManage)
              ScaleButton(
                onTap: _copyDuesBroadcast,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share_rounded, size: 12, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'Rekap WA',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // List Mahasiswa
        for (var s in filteredStudents) ...[
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLunas
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFFECDD3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                              color: Color(0xFF0F172A),
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
                      ScaleButton(
                        onTap: () => _openWhatsAppReminder(s),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    if (widget.canManage)
                      ScaleButton(
                        onTap: isUpdating
                            ? null
                            : () => _toggleIuranStatus(s, isLunas),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isLunas
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLunas
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF86EFAC),
                            ),
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
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF15803D),
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
}
