import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/services/waha_service.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

/// Modal dialog untuk mengirimkan pengingat iuran kas kelas secara massal
/// melalui WAHA (WhatsApp HTTP API) Gateway atau Direct WhatsApp.
class TreasuryBulkReminderModal extends StatefulWidget {
  final List<StudentProfile> students;
  final Map<String, bool> iuranStatus;
  final Map<String, int> iuranNominal;
  final String periodLabel;
  final VoidCallback? onRefresh;

  const TreasuryBulkReminderModal({
    super.key,
    required this.students,
    required this.iuranStatus,
    required this.iuranNominal,
    required this.periodLabel,
    this.onRefresh,
  });

  static Future<void> show(
    BuildContext context, {
    required List<StudentProfile> students,
    required Map<String, bool> iuranStatus,
    required Map<String, int> iuranNominal,
    required String periodLabel,
    VoidCallback? onRefresh,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TreasuryBulkReminderModal(
        students: students,
        iuranStatus: iuranStatus,
        iuranNominal: iuranNominal,
        periodLabel: periodLabel,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  State<TreasuryBulkReminderModal> createState() =>
      _TreasuryBulkReminderModalState();
}

class _TreasuryBulkReminderModalState extends State<TreasuryBulkReminderModal> {
  WahaSessionInfo _sessionInfo = WahaSessionInfo.offline();
  bool _isLoadingStatus = true;
  bool _isSending = false;
  bool _showPreview = false;

  late List<StudentProfile> _unpaidStudents;
  final Set<String> _selectedNims = {};
  final Map<String, bool> _sendResults = {}; // nim -> success

  int _currentIndex = 0;
  String _currentStudentName = '';
  WahaBroadcastReport? _completedReport;

  @override
  void initState() {
    super.initState();
    _initUnpaidList();
    _checkWahaStatus();
  }

  void _initUnpaidList() {
    _unpaidStudents = widget.students.where((s) {
      final isPaid = widget.iuranStatus[s.nim] ?? false;
      return !isPaid;
    }).toList();

    // Pilih semua yang memiliki nomor WA secara default
    for (final s in _unpaidStudents) {
      if (s.noWa.trim().isNotEmpty) {
        _selectedNims.add(s.nim);
      }
    }
  }

  Future<void> _checkWahaStatus() async {
    if (!mounted) return;
    setState(() => _isLoadingStatus = true);

    try {
      final status = await WahaService.getSessionStatus();
      if (!mounted) return;
      setState(() {
        _sessionInfo = status;
        _isLoadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sessionInfo = WahaSessionInfo.offline();
        _isLoadingStatus = false;
      });
    }
  }

  String _formatRupiah(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _buildPreviewText(StudentProfile sample) {
    final nominal = widget.iuranNominal[sample.nim] ?? 20000;
    return WahaService.formatTreasuryReminderMessage(
      studentName: sample.nama,
      studentNim: sample.nim,
      unpaidMonthsCount: 1,
      totalAmount: nominal,
      periodLabel: widget.periodLabel,
    );
  }

  void _toggleSelectAll() {
    if (_isSending) return;
    setState(() {
      final selectable =
          _unpaidStudents.where((s) => s.noWa.trim().isNotEmpty).map((s) => s.nim).toSet();
      if (_selectedNims.length == selectable.length) {
        _selectedNims.clear();
      } else {
        _selectedNims.addAll(selectable);
      }
    });
  }

  Future<void> _startSending() async {
    final targetStudents =
        _unpaidStudents.where((s) => _selectedNims.contains(s.nim)).toList();

    if (targetStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 mahasiswa penerima pengingat.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _currentIndex = 0;
      _sendResults.clear();
      _completedReport = null;
    });

    int success = 0;
    int failure = 0;
    final failedList = <String>[];
    final total = targetStudents.length;

    for (int i = 0; i < total; i++) {
      if (!mounted) break;
      final student = targetStudents[i];

      setState(() {
        _currentIndex = i + 1;
        _currentStudentName = student.nama;
      });

      final nominal = widget.iuranNominal[student.nim] ?? 20000;
      final text = WahaService.formatTreasuryReminderMessage(
        studentName: student.nama,
        studentNim: student.nim,
        unpaidMonthsCount: 1,
        totalAmount: nominal,
        periodLabel: widget.periodLabel,
      );

      final res = await WahaService.sendTextMessage(
        recipient: student.noWa,
        text: text,
      );

      if (mounted) {
        setState(() {
          _sendResults[student.nim] = res.success;
        });
      }

      if (res.success) {
        success++;
      } else {
        failure++;
        failedList.add('${student.nama} (${student.nim})');
      }

      // Throttle jeda 750ms antar pengiriman untuk mencegah blokir WhatsApp
      if (i < total - 1) {
        await Future.delayed(const Duration(milliseconds: 750));
      }
    }

    if (mounted) {
      setState(() {
        _isSending = false;
        _completedReport = WahaBroadcastReport(
          total: total,
          successCount: success,
          failureCount: failure,
          failedRecipients: failedList,
        );
      });
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSelectable =
        _unpaidStudents.where((s) => s.noWa.trim().isNotEmpty).length;
    final isAllSelected =
        totalSelectable > 0 && _selectedNims.length == totalSelectable;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3E3955) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.forward_to_inbox_rounded,
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
                        'Tagih Kas Massal via WAHA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kirim otomatis pesan tagihan ke WhatsApp mahasiswa',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2D2942) : const Color(0xFFF1F5F9),
          ),

          // Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // WAHA Status Card
                  _buildWahaStatusCard(isDark),
                  const SizedBox(height: 16),

                  // Progress atau Hasil Laporan jika ada
                  if (_isSending || _completedReport != null) ...[
                    _buildSendingProgressCard(isDark),
                    const SizedBox(height: 16),
                  ],

                  // Accordion Preview Pesan
                  _buildMessagePreviewAccordion(isDark),
                  const SizedBox(height: 16),

                  // Header List Penerima & Tombol Pilih Semua
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Penerima Tagihan (${_selectedNims.length}/${_unpaidStudents.length})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_unpaidStudents.length} Belum Lunas',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!_isSending && totalSelectable > 0)
                        ScaleButton(
                          onTap: _toggleSelectAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF26223D)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAllSelected ? 'Batal Semua' : 'Pilih Semua',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // List Mahasiswa Belum Lunas
                  if (_unpaidStudents.isEmpty)
                    _buildEmptyAllPaidNotice(isDark)
                  else
                    ..._unpaidStudents.map((s) => _buildStudentItem(s, isDark)),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(isDark),
        ],
      ),
    );
  }

  Widget _buildWahaStatusCard(bool isDark) {
    final isOnline = _sessionInfo.isConnected;
    final isScanQr = _sessionInfo.needsScanQr;

    Color bg;
    Color border;
    Color accent;
    String statusTitle;
    String statusDesc;
    IconData icon;

    if (_isLoadingStatus) {
      bg = isDark ? const Color(0xFF242036) : const Color(0xFFF8FAFC);
      border = const Color(0xFFCBD5E1);
      accent = const Color(0xFF64748B);
      statusTitle = 'MEMERIKSA GATEWAY WAHA...';
      statusDesc = 'Mendeteksi koneksi server WhatsApp Gateway...';
      icon = Icons.sync_rounded;
    } else if (isOnline) {
      bg = isDark ? const Color(0xFF143026) : const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      accent = const Color(0xFF059669);
      statusTitle = 'WAHA GATEWAY ONLINE';
      statusDesc =
          'Terhubung ke ${_sessionInfo.pushName ?? _sessionInfo.phoneNumber ?? "WhatsApp"} • Siap kirim otomatis';
      icon = Icons.check_circle_rounded;
    } else if (isScanQr) {
      bg = isDark ? const Color(0xFF38291A) : const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      accent = const Color(0xFFD97706);
      statusTitle = 'PERLU SCAN QR WHATSAPP';
      statusDesc = 'Buka Admin Gateway untuk memindai kode QR WhatsApp.';
      icon = Icons.qr_code_rounded;
    } else {
      bg = isDark ? const Color(0xFF321D24) : const Color(0xFFFEF2F2);
      border = const Color(0xFFFECDD3);
      accent = const Color(0xFFDC2626);
      statusTitle = 'SERVER WAHA OFFLINE';
      statusDesc =
          'Server port 3000 belum aktif. Pastikan start_waha_port_3000.bat dijalankan.';
      icon = Icons.cloud_off_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusDesc,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoadingStatus ? null : _checkWahaStatus,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            splashRadius: 16,
            color: accent,
            tooltip: 'Periksa Ulang Status WAHA',
          ),
        ],
      ),
    );
  }

  Widget _buildSendingProgressCard(bool isDark) {
    if (_isSending) {
      final total =
          _unpaidStudents.where((s) => _selectedNims.contains(s.nim)).length;
      final pct = total > 0 ? _currentIndex / total : 0.0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mengirim Tagihan: $_currentIndex dari $total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: const Color(0xFFEDE9FE),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sedang memproses: $_currentStudentName...',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF3B82F6),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    if (_completedReport != null) {
      final r = _completedReport!;
      final isAllSuccess = r.failureCount == 0;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isAllSuccess
              ? (isDark ? const Color(0xFF132E22) : const Color(0xFFECFDF5))
              : (isDark ? const Color(0xFF332018) : const Color(0xFFFFFBEB)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isAllSuccess
                ? const Color(0xFFA7F3D0)
                : const Color(0xFFFDE68A),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAllSuccess
                      ? Icons.task_alt_rounded
                      : Icons.warning_amber_rounded,
                  color: isAllSuccess
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isAllSuccess
                      ? 'Semua Pesan Berhasil Terkirim! 🚀'
                      : 'Pengiriman Selesai dengan Sebagian Gagal',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isAllSuccess
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r.successCount} berhasil terkirim via WhatsApp, ${r.failureCount} gagal.',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMessagePreviewAccordion(bool isDark) {
    final sampleStudent = _unpaidStudents.isNotEmpty
        ? _unpaidStudents.first
        : StudentProfile(
            id: 'sample',
            nim: '202401001',
            nama: 'Mahasiswa ILKOM',
            email: 'sample@student.unazlam.ac.id',
            noWa: '081234567890',
          );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26223D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF383256) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showPreview = !_showPreview),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye_rounded,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lihat Template Draf Pesan WhatsApp',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _showPreview
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (_showPreview) ...[
            Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF383256)
                  : const Color(0xFFE2E8F0),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF152A20)
                    : const Color(0xFFDCF8C6), // WhatsApp bubble green
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF234D3A)
                      : const Color(0xFFC7EBB0),
                ),
              ),
              child: Text(
                _buildPreviewText(sampleStudent),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyAllPaidNotice(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132E22) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.celebration_rounded,
            color: Color(0xFF059669),
            size: 36,
          ),
          SizedBox(height: 10),
          Text(
            'Luar Biasa! Semua Kas Lunas ✨',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF065F46),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Seluruh mahasiswa di kelas ini telah melunasi iuran kas untuk periode ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(StudentProfile s, bool isDark) {
    final isSelected = _selectedNims.contains(s.nim);
    final hasNoWa = s.noWa.trim().isNotEmpty;
    final nominal = widget.iuranNominal[s.nim] ?? 20000;
    final sendResult = _sendResults[s.nim];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242036) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF383256) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (hasNoWa && !_isSending)
                ? (val) {
                    setState(() {
                      if (val == true) {
                        _selectedNims.add(s.nim);
                      } else {
                        _selectedNims.remove(s.nim);
                      }
                    });
                  }
                : null,
            activeColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nama,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${s.nim} • ${_formatRupiah(nominal)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!hasNoWa)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'No WA Kosong',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      )
                    else
                      Text(
                        '(${s.noWa})',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (sendResult != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sendResult
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sendResult
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 12,
                    color: sendResult
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sendResult ? 'Terkirim' : 'Gagal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: sendResult
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    final count = _selectedNims.length;
    final canSend = count > 0 && !_isSending && _sessionInfo.isConnected;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2D2942) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ScaleButton(
                onTap: canSend ? _startSending : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: canSend
                        ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF6D28D9)],
                          )
                        : null,
                    color: canSend
                        ? null
                        : (isDark
                            ? const Color(0xFF332F4A)
                            : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: canSend
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    count > 0
                                        ? 'Kirim Tagihan ke $count Mahasiswa 🚀'
                                        : 'Pilih Mahasiswa Penerima',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: canSend
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
