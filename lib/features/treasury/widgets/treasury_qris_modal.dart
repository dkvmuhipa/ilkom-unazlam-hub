import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/services/safe_launcher.dart';
import '../../../core/services/waha_service.dart';
import '../../../core/widgets/qr_widget.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class TreasuryQrisModal extends StatefulWidget {
  final List<StudentProfile> students;
  final String? initialNim;
  final String? periodLabel;
  final int defaultNominal;

  const TreasuryQrisModal({
    super.key,
    required this.students,
    this.initialNim,
    this.periodLabel,
    this.defaultNominal = 20000,
  });

  static void show(
    BuildContext context, {
    required List<StudentProfile> students,
    String? initialNim,
    String? periodLabel,
    int defaultNominal = 20000,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TreasuryQrisModal(
        students: students,
        initialNim: initialNim,
        periodLabel: periodLabel,
        defaultNominal: defaultNominal,
      ),
    );
  }

  @override
  State<TreasuryQrisModal> createState() => _TreasuryQrisModalState();
}

class _TreasuryQrisModalState extends State<TreasuryQrisModal> {
  int _activeTab = 0; // 0: QRIS & Rekening, 1: Struk Pembayaran
  late String _selectedNim;

  static const String rekeningNomor = '123-00-1098273-1';
  static const String bankName = 'Bank Mandiri (Kas Kelas)';
  static const String atasNama = 'BENDAHARA ILKOM UNAZLAM 2026';
  static const String qrisPayload =
      '00020101021126580014ID.LINKAJA.WWW011893600911002131234502150000000000000000303UMI51440014ID.CO.QRIS.WWW0215ID10200392819200303UMI5204599953033605405200005802ID5919KAS KELAS ILKOM 266007BANDUNG61054011562070703A016304';

  @override
  void initState() {
    super.initState();
    if (widget.initialNim != null &&
        widget.students.any((s) => s.nim == widget.initialNim)) {
      _selectedNim = widget.initialNim!;
    } else if (widget.students.isNotEmpty) {
      _selectedNim = widget.students.first.nim;
    } else {
      _selectedNim = '';
    }
  }

  StudentProfile? get _selectedStudent {
    try {
      return widget.students.firstWhere((s) => s.nim == _selectedNim);
    } catch (_) {
      return widget.students.isNotEmpty ? widget.students.first : null;
    }
  }

  String get _periodText {
    return widget.periodLabel ??
        DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _getBendaharaPhone() {
    for (final s in widget.students) {
      if (s.role.toUpperCase() == 'BENDAHARA' && s.noWa.isNotEmpty) {
        return s.noWa;
      }
    }
    if (widget.students.isNotEmpty && widget.students.first.noWa.isNotEmpty) {
      return widget.students.first.noWa;
    }
    return '';
  }

  Future<void> _sendWhatsappConfirmation() async {
    final student = _selectedStudent;
    final studentName = student?.nama ?? 'Mahasiswa';
    final studentNim = student?.nim ?? '-';
    final nominalStr = _formatRupiah(widget.defaultNominal);
    final refCode =
        'INV/KAS/${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}/${studentNim.length >= 4 ? studentNim.substring(studentNim.length - 4) : '2026'}';

    final rawText =
        'Halo Bendahara Kelas ILKOM UNAZLAM,\n\n'
        'Saya ingin mengonfirmasi pembayaran Kas Kelas dengan rincian berikut:\n'
        '• No. Ref: $refCode\n'
        '• Nama: $studentName\n'
        '• NIM: $studentNim\n'
        '• Periode: $_periodText\n'
        '• Nominal: $nominalStr\n'
        '• Metode: QRIS / Transfer Mandiri\n\n'
        'Mohon untuk diverifikasi statusnya. Terima kasih! 🙏✨';

    final rawPhone = _getBendaharaPhone().replaceAll(RegExp(r'\D'), '');
    final phone = rawPhone.startsWith('0')
        ? '62${rawPhone.substring(1)}'
        : rawPhone;

    // 1. Coba kirim via WAHA Gateway otomatis jika aktif
    try {
      final wahaStatus = await WahaService.getSessionStatus();
      if (wahaStatus.isConnected && phone.isNotEmpty) {
        final res = await WahaService.sendTextMessage(
          recipient: phone,
          text: rawText,
        );
        if (res.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Konfirmasi pembayaran berhasil dikirim otomatis ke WhatsApp Bendahara! 📨✨',
              ),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback membuka aplikasi WhatsApp via wa.me
    final message = Uri.encodeComponent(rawText);
    final url = phone.isNotEmpty
        ? 'https://wa.me/$phone?text=$message'
        : 'https://wa.me/?text=$message';
    final opened = await safeLaunchUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Draft konfirmasi dibuka di WhatsApp. Lampirkan bukti transfer sebelum mengirim.'
                : 'WhatsApp tidak dapat dibuka. Salin rincian dan kirim secara manual.',
          ),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text('$label berhasil disalin ke clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gateway Pembayaran Kas',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Periode $_periodText • Kas Transparan',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Segmented Tabs: [QRIS & Rekening] vs [Struk Pembayaran]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onTap: () => setState(() => _activeTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTab == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTab == 0
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
                              Icons.qr_code_scanner_rounded,
                              size: 15,
                              color: _activeTab == 0
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'QRIS & Transfer',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _activeTab == 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _activeTab == 0
                                    ? const Color(0xFF1E40AF)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ScaleButton(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTab == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTab == 1
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
                              size: 15,
                              color: _activeTab == 1
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Struk & Tagihan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _activeTab == 1
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _activeTab == 1
                                    ? const Color(0xFF1E40AF)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Modal Body Content (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
              child: _activeTab == 0 ? _buildQrisTab() : _buildReceiptTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisTab() {
    final nominalStr = _formatRupiah(widget.defaultNominal);

    return Column(
      children: [
        // Visual QR Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // QRIS Standard Header Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF86EFAC),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'QRIS RESMI KAS KELAS UNAZLAM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Genuine QR Code Container with Corner Frame
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF)
                              .withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scannable QR Widget
                        QrCodeWidget(
                          data: qrisPayload,
                          size: 190,
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'NMID: ID1020039281920',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                atasNama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tarif Iuran: $nominalStr / Mahasiswa',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detail Rekening Transfer & Quick Copy
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      bankName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      rekeningNomor,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onTap: () => _copyToClipboard(rekeningNomor, 'Nomor Rekening'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: Color(0xFF334155),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Salin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick Copy Nominal Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nominal Tagihan Periode Ini',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      nominalStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onTap: () => _copyToClipboard(
                  widget.defaultNominal.toString(),
                  'Nominal Transfer',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: Color(0xFF334155),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Salin Rp',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Instructions Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Setelah scan QRIS atau transfer, simpan bukti transaksi lalu tekan tombol di bawah untuk kirim konfirmasi langsung ke WhatsApp Bendahara.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Button Konfirmasi WA with ScaleButton
        ScaleButton(
          onTap: _sendWhatsappConfirmation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Konfirmasi Pembayaran via WhatsApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptTab() {
    final student = _selectedStudent;
    final studentName = student?.nama ?? 'Mahasiswa';
    final studentNim = student?.nim ?? '-';
    final nominalStr = _formatRupiah(widget.defaultNominal);
    final refCode =
        'INV/KAS/${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}/${studentNim.length >= 4 ? studentNim.substring(studentNim.length - 4) : '2026'}';
    final nowFormatted = DateFormat(
      'dd MMMM yyyy, HH:mm',
      'id_ID',
    ).format(DateTime.now());

    final receiptText =
        '========================================\n'
        '       STRUK BUKTI TAGIHAN KAS KELAS    \n'
        '         ILKOM UNAZLAM ANGKATAN 2026    \n'
        '========================================\n'
        'No. Referensi : $refCode\n'
        'Waktu Cetak   : $nowFormatted WIB\n'
        'Nama Siswa    : $studentName\n'
        'NIM           : $studentNim\n'
        'Periode       : $_periodText\n'
        '----------------------------------------\n'
        'Iuran Kas Wajib     : $nominalStr\n'
        'Biaya Layanan Admin : Rp 0 (Gratis)\n'
        '----------------------------------------\n'
        'TOTAL PEMBAYARAN    : $nominalStr\n'
        '----------------------------------------\n'
        'Metode Pembayaran   : QRIS / Bank Mandiri\n'
        'No. Rekening Tujuan : $rekeningNomor\n'
        'Atas Nama           : $atasNama\n'
        'Status              : MENUNGGU VERIFIKASI\n'
        '========================================\n'
        'Simpan struk ini sebagai bukti pembayaran sah.\n'
        'Verifikasi kas dikelola oleh Bendahara Kelas.\n';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Picker dropdown
        if (widget.students.isNotEmpty) ...[
          const Text(
            'Pilih Mahasiswa untuk Struk:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.students.any((s) => s.nim == _selectedNim)
                    ? _selectedNim
                    : widget.students.first.nim,
                isExpanded: true,
                items: widget.students.map((s) {
                  return DropdownMenuItem<String>(
                    value: s.nim,
                    child: Text(
                      '${s.nama} (${s.nim})',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedNim = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Digital Struk Container (Authentic POS Ticket Aesthetic)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Serrated / Header Strip
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 18,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STRUK RESMI TAGIHAN KAS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'ILKOM UNAZLAM • ANGKATAN 2026',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'E-RECEIPT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Struk Details Body
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ref Code & Timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          refCode,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        Text(
                          nowFormatted,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 12),

                    // Student Info
                    _buildReceiptRow(
                      'Nama Mahasiswa',
                      studentName,
                      isBold: true,
                    ),
                    const SizedBox(height: 6),
                    _buildReceiptRow('NIM', studentNim),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Periode Kas', _periodText),
                    const SizedBox(height: 12),

                    // Dashed separator
                    Row(
                      children: List.generate(
                        26,
                        (index) => Expanded(
                          child: Container(
                            height: 1.5,
                            color: index.isEven
                                ? const Color(0xFFCBD5E1)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Financial Items
                    _buildReceiptRow('Iuran Kas Bulanan', nominalStr),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Biaya Platform Admin', 'Rp 0 (Gratis)'),
                    const SizedBox(height: 10),
                    const Divider(
                      height: 1,
                      thickness: 1.5,
                      color: Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 10),

                    // Total Highlight
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL TAGIHAN',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          nominalStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Payment Target Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tujuan Pembayaran:',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$bankName: $rekeningNomor',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'a.n. $atasNama',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Notice Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: const Text(
                  'Struk elektronik ini merupakan tanda bukti tagihan sah kelas ILKOM UNAZLAM.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Action Buttons: Salin Teks Struk & Kirim ke WA
        Row(
          children: [
            Expanded(
              child: ScaleButton(
                onTap: () => _copyToClipboard(receiptText, 'Teks Struk'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF334155),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Salin Struk',
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
              flex: 2,
              child: ScaleButton(
                onTap: _sendWhatsappConfirmation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Kirim Struk ke WA',
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
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
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
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
