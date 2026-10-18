import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/services/waha_service.dart';

/// Design tokens adaptif untuk Modal WAHA (Light & Dark Theme Safe)
class _ModalThemeTokens {
  final bool isDark;
  final Color cardBg;
  final Color headerBg;
  final Color borderCol;
  final Color textMain;
  final Color textSub;
  final Color inputBg;
  final Color fieldLabel;
  final Color surfaceSubtle;

  _ModalThemeTokens({
    required this.isDark,
    required this.cardBg,
    required this.headerBg,
    required this.borderCol,
    required this.textMain,
    required this.textSub,
    required this.inputBg,
    required this.fieldLabel,
    required this.surfaceSubtle,
  });

  factory _ModalThemeTokens.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ModalThemeTokens(
      isDark: isDark,
      cardBg: isDark ? const Color(0xFF1E293B) : Colors.white,
      headerBg: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      borderCol: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      textMain: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      textSub: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      inputBg: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      fieldLabel: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
      surfaceSubtle: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
    );
  }
}

class AdminWahaGatewayModal extends StatefulWidget {
  final void Function(String message, {bool isError}) onShowMessage;

  const AdminWahaGatewayModal({
    super.key,
    required this.onShowMessage,
  });

  static Future<void> show({
    required BuildContext context,
    required void Function(String message, {bool isError}) onShowMessage,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminWahaGatewayModal(onShowMessage: onShowMessage),
    );
  }

  @override
  State<AdminWahaGatewayModal> createState() => _AdminWahaGatewayModalState();
}

class _AdminWahaGatewayModalState extends State<AdminWahaGatewayModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Controllers Konfigurasi
  late final TextEditingController _urlCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _sessionCtrl;
  late final TextEditingController _defaultGroupCtrl;

  // Controllers Test Message
  final TextEditingController _testPhoneCtrl = TextEditingController();
  final TextEditingController _testMessageCtrl = TextEditingController(
    text: 'Halo! Ini adalah pesan uji coba otomatis dari Sistem Informasi ILKOM UNAZLAM Hub 🎓🚀',
  );

  // Auto Reminder (Kombinasi Cerdas) State
  AutoReminderConfig _autoConfig = const AutoReminderConfig(
    enabled: true,
    komtiPhone: '',
    komtiName: 'Ketua Kelas ILKOM',
    delayMinutes: 45,
    hMinusOneHour: '18:00',
    todayHour: '06:30',
    autoSendIfNoReply: true,
  );
  late final TextEditingController _komtiPhoneCtrl;
  late final TextEditingController _delayMinutesCtrl;
  late final TextEditingController _hMinusOneCtrl;
  late final TextEditingController _todayHourCtrl;
  bool _autoEnabled = true;
  bool _isSavingAutoConfig = false;
  bool _isSyncingCourses = false;
  bool _isTestingAutoReminder = false;

  bool _isCloudMode = false;
  bool _isLoadingStatus = true;
  bool _isSavingConfig = false;
  bool _isSendingTest = false;
  bool _isActionRunning = false;

  WahaSessionInfo _sessionInfo = WahaSessionInfo.offline();
  Uint8List? _qrCodeBytes;
  Timer? _qrPollingTimer;
  bool _isCheckingStatus = false;
  bool _autoConfigLoaded = false;
  String? _message;
  bool _messageIsError = false;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _urlCtrl = TextEditingController();
    _apiKeyCtrl = TextEditingController();
    _sessionCtrl = TextEditingController(text: WahaService.defaultSession);
    _defaultGroupCtrl = TextEditingController();

    _komtiPhoneCtrl = TextEditingController();
    _delayMinutesCtrl = TextEditingController(text: '45');
    _hMinusOneCtrl = TextEditingController(text: '18:00');
    _todayHourCtrl = TextEditingController(text: '06:30');

    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _qrPollingTimer?.cancel();
    _tabController.dispose();
    _urlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _sessionCtrl.dispose();
    _defaultGroupCtrl.dispose();
    _testPhoneCtrl.dispose();
    _testMessageCtrl.dispose();

    _komtiPhoneCtrl.dispose();
    _delayMinutesCtrl.dispose();
    _hMinusOneCtrl.dispose();
    _todayHourCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoadingStatus = true);
    final url = await WahaService.getBaseUrl();
    final key = await WahaService.getApiKey();
    final sess = await WahaService.getSessionName();
    final group = await WahaService.getDefaultGroupId();
    final isCloud = await WahaService.isCloudMode();

    if (mounted) {
      setState(() {
        _urlCtrl.text = url;
        _apiKeyCtrl.text = key;
        _sessionCtrl.text = sess;
        _defaultGroupCtrl.text = group ?? '';
        _isCloudMode = isCloud;

      });
      await _checkStatus();
    }
  }

  Future<void> _checkStatus({bool showLoading = true}) async {
    if (!mounted || _isCheckingStatus) return;
    _isCheckingStatus = true;
    if (showLoading) setState(() => _isLoadingStatus = true);
    try {
      final info = await WahaService.getSessionStatus();
      if (!mounted) return;
      final becameConnected = info.isConnected && !_sessionInfo.isConnected;
      final becameFailed = info.status == WahaStatus.failed &&
          _sessionInfo.status != WahaStatus.failed;
      setState(() {
        _sessionInfo = info;
        _isLoadingStatus = false;
        if (!info.needsScanQr) _qrCodeBytes = null;
      });
      if (becameConnected) {
        _showMessage('WhatsApp berhasil ditautkan ke akun kampus!');
      } else if (becameFailed) {
        _showMessage('Sesi WhatsApp gagal. Tekan Pulihkan Sesi WhatsApp untuk mencoba kembali.', isError: true);
      }
      if (info.needsScanQr) await _fetchQrCode();
      if (info.supportsAutoReminder && !_autoConfigLoaded) {
        final config = await WahaService.getAutoReminderConfig();
        if (!mounted) return;
        setState(() {
          _autoConfigLoaded = true;
          _autoConfig = config;
          _autoEnabled = config.enabled;
          _komtiPhoneCtrl.text = config.komtiPhone;
          _delayMinutesCtrl.text = config.delayMinutes.toString();
          _hMinusOneCtrl.text = config.hMinusOneHour;
          _todayHourCtrl.text = config.todayHour;
        });
      }
      if (mounted) _startQrPolling();
    } finally {
      _isCheckingStatus = false;
    }
  }

  void _startQrPolling() {
    if (_qrPollingTimer?.isActive ?? false) return;
    // Keep watching through QR -> STARTING -> WORKING, and later disconnects.
    _qrPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkStatus(showLoading: false);
    });
  }

  Future<void> _fetchQrCode() async {
    final bytes = await WahaService.getQrCodeBytes();
    if (mounted && bytes != null && _sessionInfo.needsScanQr) {
      setState(() => _qrCodeBytes = bytes);
    }
  }

  Future<void> _handleSaveConfig() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      _showMessage('URL server WAHA tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => _isSavingConfig = true);
    _autoConfigLoaded = false;
    await WahaService.saveSettings(
      baseUrl: url,
      apiKey: _apiKeyCtrl.text.trim(),
      sessionName: _sessionCtrl.text.trim(),
      defaultGroupId: _defaultGroupCtrl.text.trim().isEmpty ? null : _defaultGroupCtrl.text.trim(),
      isCloudMode: _isCloudMode,
    );

    _showMessage('Konfigurasi WAHA berhasil disimpan!');
    setState(() => _isSavingConfig = false);
    await _checkStatus();
  }

  Future<void> _handleStartSession() async {
    setState(() => _isActionRunning = true);
    final ok = await WahaService.startSession();
    if (mounted) {
      setState(() => _isActionRunning = false);
      if (ok) {
        _showMessage('Memulai sesi WhatsApp di WAHA...');
        await Future.delayed(const Duration(milliseconds: 1500));
        await _checkStatus();
      } else {
        _showMessage('Gagal memulai sesi. Pastikan server WAHA aktif.', isError: true);
      }
    }
  }

  Future<void> _handleLogoutSession() async {
    final tokens = _ModalThemeTokens.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.borderCol),
        ),
        title: Text(
          'Putuskan Tautan WhatsApp?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tokens.textMain),
        ),
        content: Text(
          'Perangkat WhatsApp akan di-logout dari server WAHA. Anda perlu memindai QR code kembali untuk menautkannya.',
          style: TextStyle(fontSize: 13, color: tokens.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: tokens.textSub)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Putuskan Tautan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionRunning = true);
    final ok = await WahaService.logoutSession();
    if (mounted) {
      setState(() => _isActionRunning = false);
      if (ok) {
        _showMessage('Sesi WhatsApp berhasil diputuskan.');
        await _checkStatus();
      } else {
        _showMessage('Gagal logout sesi WAHA.', isError: true);
      }
    }
  }

  Future<void> _handleSendTestMessage() async {
    final phone = _testPhoneCtrl.text.trim();
    final text = _testMessageCtrl.text.trim();

    if (phone.isEmpty) {
      _showMessage('Masukkan nomor WhatsApp tujuan uji coba.', isError: true);
      return;
    }
    if (text.isEmpty) {
      _showMessage('Pesan uji coba tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => _isSendingTest = true);
    final res = await WahaService.sendTextMessage(recipient: phone, text: text);
    if (!mounted) return;
    setState(() => _isSendingTest = false);

    if (res.success) {
      _showMessage('Pesan uji coba WhatsApp BERHASIL terkirim ke $phone! 📨✨');
    } else {
      _showMessage(res.errorMessage ?? 'Gagal mengirim pesan uji coba.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _ModalThemeTokens.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 640;

    return Dialog(
      backgroundColor: tokens.cardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 32,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: tokens.borderCol),
      ),
      child: Container(
        width: (MediaQuery.sizeOf(context).width - 96).clamp(0.0, 760.0).toDouble(),
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.90),
        child: Column(
          children: [
            // Header
            _buildModalHeader(tokens),

            if (_message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: (_messageIsError ? Colors.red : Colors.green)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _messageIsError ? Icons.error_outline : Icons.info_outline,
                          color: _messageIsError ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_message!, style: TextStyle(color: tokens.textMain, fontSize: 12))),
                        IconButton(
                          tooltip: 'Tutup notifikasi',
                          onPressed: () => setState(() => _message = null),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Status Bar Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: _buildStatusBarCard(tokens),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.borderCol)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isCompact,
                tabAlignment: isCompact ? TabAlignment.start : TabAlignment.fill,
                labelColor: AppColors.primary,
                unselectedLabelColor: tokens.textSub,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'Tautan WhatsApp (QR)'),
                  Tab(icon: Icon(Icons.send_rounded, size: 18), text: 'Uji Coba Kirim'),
                  Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Konfigurasi Server'),
                  Tab(icon: Icon(Icons.alarm_on_rounded, size: 18), text: 'Auto-Pengingat Dosen'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQrScannerTab(tokens),
                  _buildTestSendTab(tokens),
                  _buildConfigTab(tokens),
                  _buildAutoReminderTab(tokens),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader(_ModalThemeTokens tokens) {
    Color statusPillBg;
    Color statusPillText;
    String statusPillLabel;

    if (_sessionInfo.isConnected) {
      statusPillBg = const Color(0xFFDCFCE7);
      statusPillText = const Color(0xFF15803D);
      statusPillLabel = 'ONLINE & SIAP';
    } else if (_sessionInfo.needsScanQr) {
      statusPillBg = const Color(0xFFFEF3C7);
      statusPillText = const Color(0xFFB45309);
      statusPillLabel = 'PERLU SCAN QR';
    } else {
      statusPillBg = tokens.surfaceSubtle;
      statusPillText = tokens.textSub;
      statusPillLabel = 'OFFLINE';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 14),
      decoration: BoxDecoration(
        color: tokens.headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: tokens.borderCol)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: Color(0xFF059669),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'WhatsApp Gateway Hub',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tokens.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusPillBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusPillText,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              statusPillLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusPillText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Kirim pesan WhatsApp otomatis untuk Pengumuman, Kas & Notifikasi Kampus',
                  style: TextStyle(fontSize: 11.5, color: tokens.textSub),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: tokens.textSub),
            tooltip: 'Tutup',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBarCard(_ModalThemeTokens tokens) {
    Color bg;
    Color border;
    Color textCol;
    IconData icon;
    String statusTitle;
    String statusDesc;

    switch (_sessionInfo.status) {
      case WahaStatus.working:
        bg = tokens.isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5);
        border = const Color(0xFF10B981).withValues(alpha: 0.5);
        textCol = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        statusTitle = 'TERHUBUNG (ONLINE)';
        statusDesc = 'Nomor: ${_sessionInfo.phoneNumber ?? "Akun Kampus"} (${_sessionInfo.pushName ?? "Admin"})';
        break;
      case WahaStatus.scanQrCode:
        bg = tokens.isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB);
        border = const Color(0xFFF59E0B).withValues(alpha: 0.5);
        textCol = const Color(0xFFF59E0B);
        icon = Icons.qr_code_2_rounded;
        statusTitle = 'MENUNGGU SCAN QR CODE';
        statusDesc = 'Buka tab "Tautan WhatsApp (QR)" untuk memindai dari aplikasi WhatsApp di HP.';
        break;
      case WahaStatus.starting:
        bg = tokens.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF);
        border = const Color(0xFF3B82F6).withValues(alpha: 0.5);
        textCol = const Color(0xFF3B82F6);
        icon = Icons.hourglass_top_rounded;
        statusTitle = 'MEMULAI ENGINE...';
        statusDesc = 'Server sedang menyiapkan sesi WhatsApp Web...';
        break;
      case WahaStatus.stopped:
        bg = tokens.surfaceSubtle;
        border = tokens.borderCol;
        textCol = tokens.textSub;
        icon = Icons.pause_circle_rounded;
        statusTitle = 'SESI DIMATIKAN';
        statusDesc = 'Tekan tombol "Mulai Sesi WhatsApp" untuk menyalakan engine.';
        break;
      case WahaStatus.failed:
      case WahaStatus.offline:
        bg = tokens.isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2);
        border = const Color(0xFFEF4444).withValues(alpha: 0.5);
        textCol = const Color(0xFFEF4444);
        icon = Icons.cloud_off_rounded;
        statusTitle = _sessionInfo.isOffline ? 'SERVER WAHA OFFLINE' : 'ENGINE GAGAL';
        statusDesc = _sessionInfo.errorMessage ?? 'Engine sesi gagal atau terputus. Pulihkan sesi, lalu pindai QR kembali jika diminta.';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: textCol, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: textCol,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: border.withValues(alpha: 0.7)),
                      ),
                      child: Text(
                        _isCloudMode ? '☁️ Cloud' : '💻 Port 3000',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textSub,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusDesc,
                  style: TextStyle(fontSize: 11, color: textCol.withValues(alpha: 0.95), fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: _isLoadingStatus
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: textCol),
                  )
                : Icon(Icons.refresh_rounded, size: 18, color: textCol),
            tooltip: 'Segarkan Status',
            onPressed: _isLoadingStatus ? null : _checkStatus,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: QR CODE SCANNER & SESSION PAIRING
  // ===========================================================================
  Widget _buildQrScannerTab(_ModalThemeTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          if (_sessionInfo.isConnected) ...[
            // Status Sudah Terhubung (Sleek SaaS Hero Card)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.borderCol),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'WhatsApp Gateway Siap Digunakan!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: tokens.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Akun terhubung: ${_sessionInfo.phoneNumber ?? "Nomor Aktif"} • ${_sessionInfo.pushName ?? "Admin"}',
                    style: TextStyle(fontSize: 12.5, color: tokens.textSub, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // Detail Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.borderCol),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 12,
                      children: [
                        _buildStatItem('Engine', 'Baileys REST', tokens),
                        _buildStatItem('Sesi', _sessionInfo.name, tokens),
                        _buildStatItem('Kecepatan', '750ms Throttle', tokens),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isActionRunning ? null : _handleLogoutSession,
                        icon: const Icon(Icons.logout_rounded, size: 15, color: Color(0xFFDC2626)),
                        label: const Text('Putuskan Tautan (Logout)', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _tabController.animateTo(1),
                        icon: const Icon(Icons.send_rounded, size: 15),
                        label: const Text('Uji Coba Kirim Pesan', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (_sessionInfo.needsScanQr) ...[
            // Tampilan Scan QR Code
            LayoutBuilder(
              builder: (context, qrConstraints) {
                final isNarrow = qrConstraints.maxWidth < 520;
                final qrContainer = Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _qrCodeBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _qrCodeBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(height: 8),
                              Text('Memuat QR Code...', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                );

                final instructions = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pindai QR Code untuk Menautkan WhatsApp',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tokens.textMain),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep('1', 'Buka aplikasi WhatsApp di HP Anda.', tokens),
                    _buildInstructionStep('2', 'Ketuk Titik Tiga (⋮) di Android atau Pengaturan di iPhone.', tokens),
                    _buildInstructionStep('3', 'Pilih menu "Perangkat Tertaut" (Linked Devices).', tokens),
                    _buildInstructionStep('4', 'Ketuk "Tautkan Perangkat", lalu arahkan kamera ke QR code.', tokens),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _fetchQrCode,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Segarkan QR Code'),
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.isDark ? AppColors.primary : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      Center(child: qrContainer),
                      const SizedBox(height: 20),
                      instructions,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    qrContainer,
                    const SizedBox(width: 20),
                    Expanded(child: instructions),
                  ],
                );
              },
            ),
          ] else ...[
            // Status Offline / Stopped
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.borderCol),
              ),
              child: Column(
                children: [
                  Icon(Icons.power_settings_new_rounded, color: tokens.textSub, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _sessionInfo.isOffline
                        ? 'Server WAHA Belum Dapat Dihubungi'
                        : _sessionInfo.status == WahaStatus.failed
                            ? 'Sesi WhatsApp Gagal'
                            : _sessionInfo.status == WahaStatus.starting
                                ? 'Sesi WhatsApp Sedang Dimulai'
                                : 'Sesi WhatsApp Sedang Berhenti',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tokens.textMain),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _sessionInfo.isOffline
                        ? 'Jalankan gateway di laptop (start_waha_port_3000.bat) atau periksa konfigurasi server.'
                        : 'Tekan tombol di bawah untuk menyalakan engine WhatsApp dan menampilkan kode QR.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: tokens.textSub),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _isActionRunning ? null : _handleStartSession,
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: Text(
                          _sessionInfo.status == WahaStatus.failed
                              ? 'Pulihkan Sesi WhatsApp'
                              : 'Mulai Sesi WhatsApp',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(2),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: Text('Periksa URL Server', style: TextStyle(color: tokens.textMain, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: tokens.borderCol),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, _ModalThemeTokens tokens) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: tokens.textSub, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.textMain)),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text, _ModalThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: tokens.isDark ? AppColors.primary : const Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: tokens.textMain, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: UJI COBA KIRIM PESAN CEPAT
  // ===========================================================================
  Widget _buildTestSendTab(_ModalThemeTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uji Coba Pengiriman Pesan WhatsApp',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: tokens.textMain),
          ),
          const SizedBox(height: 4),
          Text(
            'Kirimkan pesan uji coba ke nomor Anda untuk memastikan gateway berjalan mulus.',
            style: TextStyle(fontSize: 12, color: tokens.textSub),
          ),
          const SizedBox(height: 14),

          // Template Chips
          Text(
            'Template Cepat:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.textSub),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip('🎓 Info Kuliah', '[PENGUMUMAN ILKOM UNAZLAM]\nKuliah Pengantar Ilmu Komunikasi sesi berikutnya akan diadakan di Lab Multimedia Lt. 2 pada pukul 09.00 WITA. Harap hadir tepat waktu.', tokens),
              _buildTemplateChip('💰 Tagihan Kas', '[PENGINGAT KAS ILKOM UNAZLAM]\nHalo Mahasiswa, kami mengingatkan untuk iuran kas kelas semester ini sebesar Rp 25.000. Konfirmasi pembayaran dapat menghubungi Bendahara.', tokens),
              _buildTemplateChip('✨ Uji Coba', 'Halo! Ini adalah pesan uji coba otomatis dari WhatsApp Gateway Sistem Informasi ILKOM UNAZLAM Hub 🎓🚀', tokens),
            ],
          ),
          const SizedBox(height: 18),

          // Nomor HP Penerima
          Text(
            'Nomor WhatsApp Tujuan *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _testPhoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Contoh: 08123456789 atau 628123456789',
              hintStyle: TextStyle(fontSize: 12, color: tokens.textSub.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.phone_rounded, size: 18, color: tokens.textSub),
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 16),

          // Isi Pesan
          Text(
            'Isi Pesan Uji Coba *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _testMessageCtrl,
            maxLines: 4,
            style: TextStyle(color: tokens.textMain, fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Tuliskan pesan yang ingin dikirimkan...',
              hintStyle: TextStyle(fontSize: 12, color: tokens.textSub.withValues(alpha: 0.6)),
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _isSendingTest || !_sessionInfo.isConnected ? null : _handleSendTestMessage,
              icon: _isSendingTest
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSendingTest
                    ? 'Sedang Mengirim Pesan...'
                    : (!_sessionInfo.isConnected ? 'WhatsApp Belum Terhubung' : 'Kirim Pesan Uji Coba Sekarang'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String label, String message, _ModalThemeTokens tokens) {
    return InkWell(
      onTap: () {
        setState(() => _testMessageCtrl.text = message);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderCol),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.textMain),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: KONFIGURASI SERVER WAHA
  // ===========================================================================
  Widget _buildConfigTab(_ModalThemeTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Environment Switcher Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Penempatan Server (Deployment Target)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: tokens.textMain),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, modeConstraints) {
                    final isNarrow = modeConstraints.maxWidth < 420;
                    final localBtn = InkWell(
                      onTap: () {
                        setState(() {
                          _isCloudMode = false;
                          _urlCtrl.text = WahaService.defaultLocalUrl;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isCloudMode ? tokens.cardBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !_isCloudMode ? const Color(0xFF059669) : tokens.borderCol,
                            width: !_isCloudMode ? 1.8 : 1,
                          ),
                          boxShadow: !_isCloudMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💻', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 8),
                            Text(
                              'Laptop Lokal (Port 3000)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: !_isCloudMode ? const Color(0xFF059669) : tokens.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final cloudBtn = InkWell(
                      onTap: () {
                        setState(() {
                          _isCloudMode = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isCloudMode ? tokens.cardBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isCloudMode ? const Color(0xFF059669) : tokens.borderCol,
                            width: _isCloudMode ? 1.8 : 1,
                          ),
                          boxShadow: _isCloudMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('☁️', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 8),
                            Text(
                              'Cloud / VPS (24 Jam)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _isCloudMode ? const Color(0xFF059669) : tokens.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          localBtn,
                          const SizedBox(height: 8),
                          cloudBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: localBtn),
                        const SizedBox(width: 10),
                        Expanded(child: cloudBtn),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // URL Server
          Text(
            'Base URL Server WAHA *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _urlCtrl,
            style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: _isCloudMode ? 'Contoh: https://waha-ilkom.up.railway.app' : 'http://localhost:3000',
              hintStyle: TextStyle(fontSize: 12, color: tokens.textSub.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.link_rounded, size: 18, color: tokens.textSub),
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            !_isCloudMode ? 'Gunakan http://localhost:3000 untuk server native di laptop Anda.' : 'Masukkan domain HTTPS publik dari deployment Railway/Render/VPS Anda.',
            style: TextStyle(fontSize: 10.5, color: tokens.textSub),
          ),
          const SizedBox(height: 14),

          // API Key
          Text(
            'WAHA API Key (Opsional / X-Api-Key)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: true,
            style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Biarkan kosong jika server WAHA lokal tidak memakai API key',
              hintStyle: TextStyle(fontSize: 12, color: tokens.textSub.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.key_rounded, size: 18, color: tokens.textSub),
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 14),

          // Session Name
          Text(
            'Nama Sesi WAHA (Session Name)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _sessionCtrl,
            style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'default',
              hintStyle: TextStyle(fontSize: 12, color: tokens.textSub.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.badge_rounded, size: 18, color: tokens.textSub),
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 14),

          // ID Grup WA Kelas Default (Opsional)
          Text(
            'ID Grup WhatsApp Kelas Default (Opsional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _defaultGroupCtrl,
            style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Contoh: 120363028374829102@g.us',
              hintStyle: TextStyle(fontSize: 12, color: tokens.textSub.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.groups_rounded, size: 18, color: tokens.textSub),
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 22),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _isSavingConfig ? null : _handleSaveConfig,
              icon: _isSavingConfig
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Simpan Pengaturan Server', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: OTOMATISASI PENGINGAT DOSEN (KOMBINASI CERDAS)
  // ===========================================================================
  Widget _buildAutoReminderTab(_ModalThemeTokens tokens) {
    if (!_sessionInfo.supportsAutoReminder) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Text(
          _sessionInfo.isOffline
              ? 'Hubungkan server untuk memeriksa dukungan pengingat otomatis.'
              : 'Server ini belum mendukung pengingat otomatis dosen. '
                  'Fitur ini memerlukan gateway ILKOM dengan scheduler pengingat. '
                  'WAHA Core mendukung tautan WhatsApp dan pengiriman pesan, '
                  'tetapi tidak menyediakan endpoint auto-reminder.',
          style: TextStyle(color: tokens.textMain, fontSize: 13, height: 1.5),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Penjelasan Kombinasi Cerdas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode Kombinasi Cerdas (Smart Auto-Reminder)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem WAHA otomatis mengirimkan draf konfirmasi ke WhatsApp Komti terlebih dahulu. Jika Komti sibuk atau lupa membalas dalam batas waktu tunggu, pesan otomatis terkirim resmi ke WhatsApp Dosen pengampu.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: const Color(0xFF047857),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Switch: Aktifkan Fitur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.borderCol),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Aktifkan Otomatisasi Pengingat Dosen',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: tokens.textMain),
                ),
                subtitle: Text(
                  'Scheduler di server WAHA akan memeriksa jadwal kuliah H-1 dan Hari-H secara berkala',
                  style: TextStyle(fontSize: 11, color: tokens.textSub),
                ),
                value: _autoEnabled,
                activeThumbColor: const Color(0xFF059669),
                onChanged: (val) => setState(() => _autoEnabled = val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Input Nomor WhatsApp Komti
          Text(
            'Nomor WhatsApp Komti / Koordinator Kelas *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _komtiPhoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Contoh: 081234567890 atau 6281234567890',
              hintStyle: TextStyle(fontSize: 12, color: tokens.textSub.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.person_pin_rounded, size: 18, color: tokens.textSub),
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 14),

          // Durasi Tunggu Konfirmasi
          Text(
            'Batas Waktu Tunggu Konfirmasi Komti (Menit)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _delayMinutesCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '45 (menit)',
              prefixIcon: Icon(Icons.timer_outlined, size: 18, color: tokens.textSub),
              suffixText: 'Menit',
              filled: true,
              fillColor: tokens.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
            ),
          ),
          const SizedBox(height: 14),

          // Baris Jadwal Jam Eksekusi (H-1 & Hari-H)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jam Pengingat H-1 (WITA)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _hMinusOneCtrl,
                      style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '18:00',
                        prefixIcon: Icon(Icons.schedule_rounded, size: 18, color: tokens.textSub),
                        filled: true,
                        fillColor: tokens.inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jam Pengingat Hari-H (WITA)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.fieldLabel),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _todayHourCtrl,
                      style: TextStyle(color: tokens.textMain, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '06:30',
                        prefixIcon: Icon(Icons.today_rounded, size: 18, color: tokens.textSub),
                        filled: true,
                        fillColor: tokens.inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.borderCol)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Panduan Balasan Interaktif Komti di WhatsApp
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      'Perintah Balasan Komti via WhatsApp:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Balas "KIRIM <kode>" : Pesan langsung terkirim seketika ke WhatsApp dosen.\n• Balas "BATAL <kode>" : Membatalkan pengiriman pengingat.\n• Tanpa Balasan  : Otomatis terkirim ke dosen setelah waktu tunggu selesai.',
                  style: TextStyle(fontSize: 11, color: tokens.textSub, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Tombol Simpan Konfigurasi
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _isSavingAutoConfig ? null : _saveAutoConfig,
              icon: _isSavingAutoConfig
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Simpan Pengaturan Pengingat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Baris Aksi Pendukung (Sinkronkan Jadwal & Uji Coba Simulasi)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSyncingCourses ? null : _syncCourses,
                  icon: _isSyncingCourses
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8))
                      : const Icon(Icons.sync_rounded, size: 15),
                  label: const Text('Sinkronkan Jadwal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTestingAutoReminder ? null : _triggerTestSimulation,
                  icon: _isTestingAutoReminder
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8))
                      : const Icon(Icons.play_arrow_rounded, size: 16, color: Color(0xFF2563EB)),
                  label: const Text('Uji Simulasi Sekarang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveAutoConfig() async {
    setState(() => _isSavingAutoConfig = true);
    final delay = int.tryParse(_delayMinutesCtrl.text.trim()) ?? 45;
    final cfg = AutoReminderConfig(
      enabled: _autoEnabled,
      komtiPhone: _komtiPhoneCtrl.text.trim(),
      komtiName: _autoConfig.komtiName,
      delayMinutes: delay,
      hMinusOneHour: _hMinusOneCtrl.text.trim().isEmpty ? '18:00' : _hMinusOneCtrl.text.trim(),
      todayHour: _todayHourCtrl.text.trim().isEmpty ? '06:30' : _todayHourCtrl.text.trim(),
      autoSendIfNoReply: true,
      pendingCount: _autoConfig.pendingCount,
    );

    final ok = await WahaService.saveAutoReminderConfig(cfg);
    if (mounted) {
      setState(() {
        _isSavingAutoConfig = false;
        if (ok) _autoConfig = cfg;
      });
      if (ok) {
        _showMessage('Pengaturan pengingat otomatis berhasil disimpan!');
      } else {
        _showMessage('Gagal menyimpan ke server WAHA.', isError: true);
      }
    }
  }

  Future<void> _syncCourses() async {
    setState(() => _isSyncingCourses = true);
    try {
      final courses = await SupabaseRepository.getCourses();
      final phone = _komtiPhoneCtrl.text.trim();
      final ok = await WahaService.syncCoursesToGateway(
        courses: courses,
        komtiPhone: phone,
        komtiName: _autoConfig.komtiName,
      );
      if (mounted) {
        setState(() => _isSyncingCourses = false);
        if (ok) {
          _showMessage('Berhasil menyinkronkan ${courses.length} mata kuliah ke server gateway!');
        } else {
          _showMessage('Gagal menyinkronkan mata kuliah ke gateway.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncingCourses = false);
        _showMessage('Gagal mengambil data jadwal: $e', isError: true);
      }
    }
  }

  Future<void> _triggerTestSimulation() async {
    if (!_sessionInfo.isConnected) {
      _showMessage('Server WAHA belum terhubung ke WhatsApp. Scan QR terlebih dahulu.', isError: true);
      return;
    }
    setState(() => _isTestingAutoReminder = true);
    final res = await WahaService.triggerAutoReminderSimulation();
    if (mounted) {
      setState(() => _isTestingAutoReminder = false);
      if (res['success'] == true) {
        _showMessage(res['message']?.toString() ?? 'Simulasi berhasil dipicu!');
      } else {
        _showMessage(res['error']?.toString() ?? 'Gagal memicu simulasi pengingat.', isError: true);
      }
    }
  }
}
