import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/lecturer_reminder_service.dart';
import '../../../core/services/safe_launcher.dart';
import '../../../core/services/waha_service.dart';
import '../../../core/widgets/scale_button.dart';
import '../../../models/models.dart';

class LecturerReminderModal {
  static Future<void> show(
    BuildContext context, {
    required Course course,
    required String senderName,
    bool isDark = false,
    VoidCallback? onSent,
  }) async {
    final contactedTime = await LecturerReminderService.getContactedTimeToday(course.id);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _LecturerReminderModalContent(
        course: course,
        senderName: senderName,
        isDark: isDark,
        initialContactedTime: contactedTime,
        onSent: onSent,
      ),
    );
  }
}

class _LecturerReminderModalContent extends StatefulWidget {
  final Course course;
  final String senderName;
  final bool isDark;
  final String? initialContactedTime;
  final VoidCallback? onSent;

  const _LecturerReminderModalContent({
    required this.course,
    required this.senderName,
    required this.isDark,
    this.initialContactedTime,
    this.onSent,
  });

  @override
  State<_LecturerReminderModalContent> createState() => _LecturerReminderModalContentState();
}

class _LecturerReminderModalContentState extends State<_LecturerReminderModalContent> {
  late ReminderScenario _selectedScenario;
  late TextEditingController _messageController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customPhoneController = TextEditingController();
  bool _isSendingWaha = false;
  String? _contactedTime;

  @override
  void initState() {
    super.initState();
    _contactedTime = widget.initialContactedTime;
    _customPhoneController.text = widget.course.dosenWa ?? '';

    // Pilih skenario awal secara cerdas berdasarkan waktu dan status perkuliahan
    if (widget.course.isRescheduled) {
      _selectedScenario = ReminderScenario.reschedule;
    } else if (widget.course.ruangan.toLowerCase().contains('zoom') ||
        widget.course.ruangan.toLowerCase().contains('online')) {
      _selectedScenario = ReminderScenario.onlineZoom;
    } else {
      _selectedScenario = ReminderScenario.today;
    }

    _messageController = TextEditingController(text: _generateCurrentMessage());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _notesController.dispose();
    _customPhoneController.dispose();
    super.dispose();
  }

  String _generateCurrentMessage() {
    return LecturerReminderService.buildMessage(
      course: widget.course,
      senderName: widget.senderName,
      scenario: _selectedScenario,
      customNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      virtualLink: widget.course.linkVirtual,
    );
  }

  void _onScenarioChanged(ReminderScenario scenario) {
    setState(() {
      _selectedScenario = scenario;
      _messageController.text = _generateCurrentMessage();
    });
    HapticFeedback.selectionClick();
  }

  void _onNotesChanged() {
    setState(() {
      _messageController.text = _generateCurrentMessage();
    });
  }

  Future<void> _sendViaWhatsAppDirect() async {
    final rawPhone = _customPhoneController.text.trim().isNotEmpty
        ? _customPhoneController.text.trim()
        : (widget.course.dosenWa ?? '');

    if (rawPhone.isEmpty) {
      _showErrorSnackBar('Nomor WhatsApp dosen belum diisi. Masukkan nomor kontak terlebih dahulu.');
      return;
    }

    final formattedPhone = LecturerReminderService.formatPhoneForWhatsApp(rawPhone);
    final text = Uri.encodeComponent(_messageController.text.trim());
    final url = 'https://wa.me/$formattedPhone?text=$text';

    await safeLaunchUrl(url);
    await _markAsContacted();

    if (mounted) {
      Navigator.pop(context);
      _showSuccessSnackBar('Aplikasi WhatsApp dibuka untuk dosen ${widget.course.dosen}! 💬');
    }
  }

  Future<void> _sendViaWahaGateway() async {
    final rawPhone = _customPhoneController.text.trim().isNotEmpty
        ? _customPhoneController.text.trim()
        : (widget.course.dosenWa ?? '');

    if (rawPhone.isEmpty) {
      _showErrorSnackBar('Nomor WhatsApp dosen belum diisi.');
      return;
    }

    setState(() => _isSendingWaha = true);

    try {
      final formattedPhone = LecturerReminderService.formatPhoneForWhatsApp(rawPhone);
      final text = _messageController.text.trim();

      // Cek konektivitas WAHA Gateway
      final status = await WahaService.getSessionStatus();
      if (!status.isConnected) {
        // Fallback otomatis ke direct WhatsApp jika gateway belum terhubung
        setState(() => _isSendingWaha = false);
        _showWarningSnackBar(
          'WAHA Gateway belum aktif di port 3000. Mengalihkan ke WhatsApp langsung...',
        );
        await _sendViaWhatsAppDirect();
        return;
      }

      final result = await WahaService.sendTextMessage(
        recipient: formattedPhone,
        text: text,
      );

      if (result.success) {
        await _markAsContacted();
        if (mounted) {
          Navigator.pop(context);
          _showSuccessSnackBar(
            'Pesan pengingat berhasil dikirim secara otomatis via WAHA ke ${widget.course.dosen}! 🚀✨',
          );
        }
      } else {
        throw Exception(result.errorMessage ?? 'Server WAHA menolak pengiriman pesan.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingWaha = false);
        _showErrorSnackBar('Pengiriman via WAHA gagal ($e). Mencoba lewat WhatsApp langsung...');
        await _sendViaWhatsAppDirect();
      }
    }
  }

  Future<void> _markAsContacted() async {
    await LecturerReminderService.markContactedToday(widget.course.id, widget.course.dosen);
    final newTime = await LecturerReminderService.getContactedTimeToday(widget.course.id);
    if (mounted) {
      setState(() => _contactedTime = newTime);
      widget.onSent?.call();
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _messageController.text.trim()));
    HapticFeedback.lightImpact();
    _showSuccessSnackBar('Format pesan akademik disalin ke clipboard! 📋');
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showWarningSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final inputFill = isDark ? const Color(0xFF28283E) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? const Color(0xFF38384E) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final hasDosenWa = _customPhoneController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Lecturer Info & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.course.dosen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Dosen',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.course.nama} • ${widget.course.hari}, ${widget.course.jamMulai} WIB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // Badge jika sudah dihubungi hari ini
          if (_contactedTime != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Sudah dihubungi hari ini pukul $_contactedTime WIB',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skenario Pengingat (Chips)
                  Text(
                    'PILIH TUJUAN / SKENARIO PESAN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ReminderScenario.values.map((sc) {
                        final isSelected = _selectedScenario == sc;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sc.label),
                            selected: isSelected,
                            onSelected: (_) => _onScenarioChanged(sc),
                            selectedColor: const Color(0xFF1E40AF),
                            backgroundColor: inputFill,
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF1E40AF) : inputBorder,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nomor WhatsApp Dosen
                  Row(
                    children: [
                      Text(
                        'NOMOR WHATSAPP DOSEN',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (!hasDosenWa)
                        const Text(
                          '*Wajib diisi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _customPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 081234567890 (Nomor WA resmi dosen)',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(
                        Icons.phone_rounded,
                        size: 17,
                        color: Color(0xFF10B981),
                      ),
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Catatan Tambahan (Opsional)
                  Text(
                    'CATATAN TAMBAHAN (OPSIONAL)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    onChanged: (_) => _onNotesChanged(),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Proyektor sudah disiapkan di ruang 302',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: Color(0xFF6366F1),
                      ),
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Live Preview Pesan Akademik
                  Row(
                    children: [
                      Text(
                        'DRAF PESAN AKADEMIK (BISA DIEDIT LANGSUNG)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textSecondary,
                        ),
                      ),
                      const Spacer(),
                      ScaleButton(
                        onTap: _copyToClipboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 12, color: Color(0xFF1E40AF)),
                              SizedBox(width: 4),
                              Text(
                                'Salin Teks',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: inputBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 7,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: textPrimary,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Action Buttons: Direct WA & WAHA Gateway
          Row(
            children: [
              // 1. Direct WA Personal Komti (Primary)
              Expanded(
                flex: 5,
                child: ScaleButton(
                  onTap: _sendViaWhatsAppDirect,
                  scaleDown: 0.96,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_rounded, color: Colors.white, size: 17),
                        SizedBox(width: 8),
                        Text(
                          'Kirim WhatsApp',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. WAHA Gateway Automatis
              Expanded(
                flex: 4,
                child: ScaleButton(
                  onTap: _isSendingWaha ? null : _sendViaWahaGateway,
                  scaleDown: 0.96,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E2E42) : const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF42425E) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: _isSendingWaha
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Via WAHA Bot',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
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
    );
  }
}
