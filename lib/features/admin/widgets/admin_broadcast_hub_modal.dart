import 'admin_common_widgets.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/waha_service.dart';
import '../../../models/models.dart';
import '../models/admin_models.dart';


/// Modal Pusat Komando Siaran Notifikasi (Broadcast Command Hub)
/// Memfasilitasi Admin untuk mengirim pengumuman instan & push notifikasi FCM
/// dengan penargetan audiens (Semua / Angkatan / Kelas), preview lockscreen,
/// serta pemantauan riwayat siaran.
class AdminBroadcastHubModal extends StatefulWidget {
  final bool fullPage;
  final List<ClassItem> classes;
  final Future<void> Function() onRefresh;
  final void Function(String message, {bool isError}) onShowMessage;
  final void Function({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic> metadata,
  })
  onRecordAudit;

  const AdminBroadcastHubModal({
    super.key,
    this.fullPage = false,
    required this.classes,
    required this.onRefresh,
    required this.onShowMessage,
    required this.onRecordAudit,
  });

  static void show({
    required BuildContext context,
    required List<ClassItem> classes,
    required Future<void> Function() onRefresh,
    required void Function(String message, {bool isError}) onShowMessage,
    required void Function({
      required String action,
      required String module,
      required String description,
      Map<String, dynamic> metadata,
    })
    onRecordAudit,
  }) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100),
        child: AdminBroadcastHubModal(fullPage: true, classes: classes, onRefresh: onRefresh,
          onShowMessage: onShowMessage, onRecordAudit: onRecordAudit)))),
    )));
  }

  @override
  State<AdminBroadcastHubModal> createState() => _AdminBroadcastHubModalState();
}

class _AdminBroadcastHubModalState extends State<AdminBroadcastHubModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  // Settings
  String _selectedCategory = 'Penting';
  String _targetAudience = 'ALL'; // 'ALL', 'ANGKATAN', 'KELAS'
  String _selectedAngkatan = '2024';
  String _selectedKelas = '';
  bool _isPinned = true;
  bool _sendWahaBlast = false;
  bool _isWahaOnline = false;
  int _targetWaCount = 0;
  String _wahaTargetMode = 'JAPRI'; // 'JAPRI' or 'GROUP'
  bool _isSending = false;

  // Data State
  int _targetTokenCount = 0;
  bool _isLoadingTokens = false;
  List<Announcement> _announcements = [];
  bool _isLoadingHistory = false;

  final List<String> _angkatanOptions = [
    '2021',
    '2022',
    '2023',
    '2024',
    '2025',
    '2026',
  ];
  final List<String> _categories = [
    'Penting',
    'Akademik',
    'Info Fakultas',
    'Jadwal Kuliah',
    'Tugas',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.classes.isNotEmpty) {
      _selectedKelas = widget.classes.first.nama;
    }
    _titleCtrl.addListener(() => setState(() {}));
    _bodyCtrl.addListener(() => setState(() {}));

    _updateTargetRecipientCount();
    _loadBroadcastHistory();
    _checkWahaStatus();
  }

  Future<void> _checkWahaStatus() async {
    try {
      final info = await WahaService.getSessionStatus();
      if (mounted) {
        setState(() => _isWahaOnline = info.isConnected);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateTargetRecipientCount() async {
    setState(() => _isLoadingTokens = true);
    try {
      final count = await SupabaseRepository.getPushTokenCountByTarget(
        targetAudience: _targetAudience,
        targetAngkatan: _targetAudience == 'ANGKATAN'
            ? _selectedAngkatan
            : null,
        targetKelas: _targetAudience == 'KELAS' ? _selectedKelas : null,
      );
      if (mounted) setState(() => _targetTokenCount = count);

      // Hitung juga jumlah nomor WhatsApp mahasiswa pada target
      final client = SupabaseService.client;
      if (client != null) {
        var query = client
            .from('students')
            .select('no_wa')
            .eq('is_aktif', true);
        if (_targetAudience == 'KELAS' && _selectedKelas.isNotEmpty) {
          query = query.eq('kelas', _selectedKelas);
        } else if (_targetAudience == 'ANGKATAN') {
          query = query.eq('angkatan', _selectedAngkatan);
        }
        final rows = await query;
        if (mounted) {
          final waList = (rows as List).where((r) {
            final wa = r['no_wa']?.toString().trim();
            return wa != null && wa.isNotEmpty;
          }).toList();
          setState(() => _targetWaCount = waList.length);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingTokens = false);
    }
  }

  Future<void> _loadBroadcastHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final list = await SupabaseRepository.getAnnouncements();
      if (mounted) setState(() => _announcements = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _handleSendBroadcast() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty) {
      widget.onShowMessage(
        'Judul pengumuman tidak boleh kosong.',
        isError: true,
      );
      return;
    }
    if (body.isEmpty) {
      widget.onShowMessage(
        'Isi pesan siaran tidak boleh kosong.',
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final success = await SupabaseRepository.createAnnouncement(
        judul: title,
        isi: body,
        kategori: _selectedCategory,
        isPinned: _isPinned,
        authorName: 'Admin Program Studi',
        authorRole: 'Admin',
        targetAudience: _targetAudience,
        targetAngkatan: _targetAudience == 'ANGKATAN'
            ? _selectedAngkatan
            : null,
        targetKelas: _targetAudience == 'KELAS' ? _selectedKelas : null,
      );

      if (success) {
        widget.onRecordAudit(
          action: 'BROADCAST',
          module: 'PENGUMUMAN',
          description:
              'Menerbitkan pengumuman "$title" ke target $_targetAudience (WAHA: $_sendWahaBlast)',
          metadata: {
            'target_audience': _targetAudience,
            'target_angkatan': _targetAngkatanValue,
            'target_kelas': _targetKelasValue,
            'kategori': _selectedCategory,
            'is_pinned': _isPinned,
            'waha_blast': _sendWahaBlast,
            'waha_target_count': _targetWaCount,
          },
        );

        // Eksekusi Pengiriman Pesan WhatsApp via WAHA Gateway
        var waSummary = '';
        var waFailed = false;
        if (_sendWahaBlast) {
          try {
            final client = SupabaseService.client;
            if (client == null) {
              waFailed = true;
              waSummary = ' WA gagal: koneksi database tidak tersedia.';
            } else {
              var query = client
                  .from('students')
                  .select('nama,nim,no_wa')
                  .eq('is_aktif', true);
              if (_targetAudience == 'KELAS' && _selectedKelas.isNotEmpty) {
                query = query.eq('kelas', _selectedKelas);
              } else if (_targetAudience == 'ANGKATAN') {
                query = query.eq('angkatan', _selectedAngkatan);
              }
              final rows = await query;
              final waList = <String>[];
              for (final row in rows) {
                final phone = row['no_wa']?.toString().trim();
                if (phone != null && phone.isNotEmpty) waList.add(phone);
              }

              final waMessage = WahaService.formatAnnouncementMessage(
                Announcement(
                  id: '',
                  authorName: 'Admin Program Studi',
                  authorRole: 'Admin',
                  judul: title,
                  isi: body,
                  kategori: _selectedCategory,
                  createdAt: DateTime.now(),
                ),
              );
              final status = await WahaService.getSessionStatus();
              if (!status.isConnected) {
                waFailed = true;
                waSummary = ' WA gagal: gateway WhatsApp sedang offline.';
              } else if (_wahaTargetMode == 'GROUP') {
                final groupId = await WahaService.getDefaultGroupId();
                if (groupId == null || groupId.isEmpty) {
                  waFailed = true;
                  waSummary = ' WA gagal: ID grup default belum diatur.';
                } else {
                  final result = await WahaService.sendTextMessage(
                    recipient: groupId,
                    text: waMessage,
                  );
                  waSummary = result.success
                      ? ' WA berhasil dikirim ke grup.'
                      : ' WA gagal dikirim: ${result.errorMessage ?? 'kesalahan gateway'}';
                  waFailed = !result.success;
                }
              } else if (waList.isEmpty) {
                waFailed = true;
                waSummary =
                    ' WA tidak dikirim: tidak ada nomor WhatsApp pada target.';
              } else {
                final report = await WahaService.broadcastMessage(
                  recipients: waList,
                  text: waMessage,
                );
                waSummary =
                    ' WA berhasil ${report.successCount}/${report.total} nomor.';
                if (report.failureCount > 0) {
                  waFailed = true;
                  waSummary += ' ${report.failureCount} gagal.';
                }
              }
            }
          } catch (e) {
            waFailed = true;
            debugPrint('Info: Gagal dispatch WhatsApp WAHA: $e');
            waSummary = ' WA gagal dikirim karena terjadi kesalahan.';
          }
        }

        widget.onShowMessage(
          'Pengumuman berhasil diterbitkan.$waSummary',
          isError: waFailed,
        );

        await widget.onRefresh();
        if (mounted) {
          _titleCtrl.clear();
          _bodyCtrl.clear();
          await _loadBroadcastHistory();
          _tabController.animateTo(1);
        }
      } else {
        widget.onShowMessage(
          'Gagal mengirim siaran. Periksa koneksi database.',
          isError: true,
        );
      }
    } catch (e) {
      widget.onShowMessage('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String? get _targetAngkatanValue =>
      _targetAudience == 'ANGKATAN' ? _selectedAngkatan : null;
  String? get _targetKelasValue =>
      _targetAudience == 'KELAS' ? _selectedKelas : null;

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'penting':
        return const Color(0xFFEF4444);
      case 'akademik':
        return const Color(0xFF2563EB);
      case 'info fakultas':
        return const Color(0xFF7C3AED);
      case 'jadwal kuliah':
        return const Color(0xFFD97706);
      case 'tugas':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 640;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: widget.fullPage ? EdgeInsets.zero : EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 32,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: widget.fullPage ? double.infinity : (MediaQuery.sizeOf(context).width - 96)
            .clamp(0.0, 720.0)
            .toDouble(),
        constraints: BoxConstraints(maxHeight: screenSize.height * (widget.fullPage ? 1 : 0.88)),
        child: Column(
          children: [
            // 1. Header Konsol Modern (Dark Indigo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.cell_tower_rounded,
                      color: Color(0xFFA5B4FC),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Wrap(
                          children: [
                            Text(
                              'BROADCAST COMMAND HUB',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pusat Kendali Pengumuman & Notifikasi Push FCM Langsung',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 2. Tab Navigation
            Container(
              color: const Color(0xFFF8FAFC),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
                tabs: [
                  const Tab(
                    icon: Icon(Icons.send_rounded, size: 16),
                    text: 'Kirim Siaran Baru',
                  ),
                  Tab(
                    icon: const Icon(Icons.history_rounded, size: 16),
                    text: 'Riwayat Siaran (${_announcements.length})',
                  ),
                ],
              ),
            ),

            // 3. Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildComposeTab(isCompact), _buildHistoryTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: COMPOSE & DISPATCH
  // ==========================================
  Widget _buildComposeTab(bool isCompact) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Target Selector Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminAdaptiveRow(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Target Penerima Siaran',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    // Live Recipient Counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _targetTokenCount > 0
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _targetTokenCount > 0
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 13,
                            color: _targetTokenCount > 0
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isLoadingTokens
                                ? 'Menghitung...'
                                : '$_targetTokenCount Perangkat Terjangkau',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _targetTokenCount > 0
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Audience Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAudienceChip(
                      'ALL',
                      'Seluruh Mahasiswa (Semua Angkatan)',
                      Icons.public_rounded,
                    ),
                    _buildAudienceChip(
                      'ANGKATAN',
                      'Khusus Angkatan',
                      Icons.school_rounded,
                    ),
                    _buildAudienceChip(
                      'KELAS',
                      'Khusus Kelas Tertentu',
                      Icons.meeting_room_rounded,
                    ),
                  ],
                ),

                // Sub-selector jika Angkatan dipilih
                if (_targetAudience == 'ANGKATAN') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Angkatan Target:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: _angkatanOptions.map((ang) {
                      final selected = _selectedAngkatan == ang;
                      return ChoiceChip(
                        label: Text('Angkatan $ang'),
                        selected: selected,
                        selectedColor: AppColors.primarySoft,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFF475569),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedAngkatan = ang);
                            _updateTargetRecipientCount();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],

                // Sub-selector jika Kelas dipilih
                if (_targetAudience == 'KELAS' &&
                    widget.classes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Kelas Target:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedKelas.isNotEmpty
                        ? _selectedKelas
                        : widget.classes.first.nama,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: widget.classes.map((c) {
                      return DropdownMenuItem(
                        value: c.nama,
                        child: Text(
                          '${c.nama} (${c.prodi} • Semester ${c.semester})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedKelas = val);
                        _updateTargetRecipientCount();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // B. Kategori & Urgensi
          const AdminFormLabel('Kategori & Tingkat Urgensi'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSel = _selectedCategory == cat;
              final color = _getCategoryColor(cat);
              return FilterChip(
                selected: isSel,
                label: Text(cat),
                avatar: Icon(
                  cat == 'Penting'
                      ? Icons.error_outline_rounded
                      : Icons.label_outline_rounded,
                  size: 14,
                  color: isSel ? color : const Color(0xFF64748B),
                ),
                backgroundColor: Colors.white,
                selectedColor: color.withValues(alpha: 0.12),
                checkmarkColor: color,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSel ? color : const Color(0xFF475569),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSel ? color : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // C. Judul Pengumuman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AdminFormLabel('Judul Siaran Resmi'),
              Text(
                '${_titleCtrl.text.length}/100',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          AdminFormField(
            controller: _titleCtrl,
            hintText:
                'Contoh: [PENTING] Batas Akhir KRS Semester Ganjil 2026/2027',
          ),
          const SizedBox(height: 12),

          // Quick Subject Helpers
          Wrap(
            spacing: 6,
            children: [
              _buildTagChip('[PENTING]'),
              _buildTagChip('[AKADEMIK]'),
              _buildTagChip('[JADWAL]'),
              _buildTagChip('[LIBUR RESMI]'),
              _buildTagChip('[BEASISWA]'),
            ],
          ),
          const SizedBox(height: 16),

          // D. Isi Pengumuman
          const AdminFormLabel('Isi Pengumuman Lengkap'),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tuliskan rincian instruksi akademik resmi kepada seluruh mahasiswa...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Pinning can be controlled here. Push delivery is handled by the
          // server webhook and cannot be toggled by this form.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Sematkan di Atas (Pin)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Switch(
                  value: _isPinned,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isPinned = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Notifikasi push ditangani oleh server setelah pengumuman diterbitkan. Pengiriman bergantung pada konfigurasi FCM server dan token perangkat.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // WAHA WhatsApp Gateway Blast Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _sendWahaBlast
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _sendWahaBlast
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminAdaptiveRow(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AdminAdaptiveRow(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_android_rounded,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(spacing: 8, runSpacing: 8,
                              children: [
                                const Text(
                                  'Blast WhatsApp Otomatis (WAHA Gateway)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isWahaOnline
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _isWahaOnline ? 'ONLINE' : 'OFFLINE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: _isWahaOnline
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _targetWaCount > 0
                                  ? 'Tersedia $_targetWaCount nomor WhatsApp mahasiswa terverifikasi'
                                  : 'Kirim pesan otomatis via REST API WhatsApp',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _sendWahaBlast,
                      activeThumbColor: const Color(0xFF25D366),
                      activeTrackColor: const Color(0xFFA7F3D0),
                      onChanged: (v) {
                        setState(() => _sendWahaBlast = v);
                        if (v && !_isWahaOnline) {
                          widget.onShowMessage(
                            'Perhatian: Server WAHA belum terhubung atau offline. Anda dapat mengaturnya di menu WA Gateway.',
                          );
                        }
                      },
                    ),
                  ],
                ),
                if (_sendWahaBlast) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Target Kirim: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text(
                          'Japri ke Nomor Mahasiswa ($_targetWaCount Nomor)',
                        ),
                        selected: _wahaTargetMode == 'JAPRI',
                        selectedColor: const Color(0xFFDCFCE7),
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _wahaTargetMode == 'JAPRI'
                              ? const Color(0xFF166534)
                              : const Color(0xFF475569),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _wahaTargetMode = 'JAPRI');
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Grup WA Resmi Kelas'),
                        selected: _wahaTargetMode == 'GROUP',
                        selectedColor: const Color(0xFFDCFCE7),
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _wahaTargetMode == 'GROUP'
                              ? const Color(0xFF166534)
                              : const Color(0xFF475569),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _wahaTargetMode = 'GROUP');
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // F. Live Phone Lock Screen Preview (Simulation)
          const Text(
            'Pratinjau Layar Kunci Mahasiswa (Lock Screen Preview)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          _buildPhoneNotificationMockup(),
          const SizedBox(height: 24),

          // G. Dispatch Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _handleSendBroadcast,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isSending
                    ? 'Sedang Menerbitkan Pengumuman...'
                    : 'Terbitkan Pengumuman',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceChip(String key, String label, IconData icon) {
    final selected = _targetAudience == key;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: selected ? AppColors.primary : const Color(0xFF64748B),
      ),
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.primary : const Color(0xFF334155),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? AppColors.primary : const Color(0xFFCBD5E1),
        ),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _targetAudience = key);
          _updateTargetRecipientCount();
        }
      },
    );
  }

  Widget _buildTagChip(String tag) {
    return InkWell(
      onTap: () {
        if (!_titleCtrl.text.contains(tag)) {
          _titleCtrl.text = '$tag ${_titleCtrl.text}'.trim();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // Visual Mockup Notifikasi Android / iOS
  Widget _buildPhoneNotificationMockup() {
    final title = _titleCtrl.text.trim().isEmpty
        ? 'Judul Pengumuman...'
        : _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim().isEmpty
        ? 'Isi ringkasan pengumuman akan muncul di sini...'
        : _bodyCtrl.text.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ILKOM UNAZLAM HUB • Baru Saja',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'FCM v1',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📢 $title',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFCBD5E1),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: BROADCAST HISTORY
  // ==========================================
  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inbox_outlined,
                color: Color(0xFF94A3B8),
                size: 40,
              ),
              const SizedBox(height: 8),
              const Text(
                'Belum ada riwayat siaran.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Siaran pengumuman yang dikirimkan akan tercatat di sini.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadBroadcastHistory,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final a = _announcements[idx];
        final catColor = _getCategoryColor(a.kategori);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: a.isPinned
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
              width: a.isPinned ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.kategori,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: catColor,
                      ),
                    ),
                  ),
                  if (a.isPinned) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.push_pin_rounded,
                            size: 10,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'PINNED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Target Badge
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
                      a.targetAudience == 'ALL'
                          ? 'Semua Mahasiswa'
                          : (a.targetAudience == 'ANGKATAN'
                                ? 'Angkatan ${a.targetAngkatan ?? ""}'
                                : 'Kelas ${a.targetKelas ?? ""}'),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                a.judul,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                a.isi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${a.authorName} • ${_formatDate(a.createdAt)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  // Toggle Pin Button
                  IconButton(
                    icon: Icon(
                      a.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 16,
                      color: a.isPinned
                          ? const Color(0xFFD97706)
                          : const Color(0xFF94A3B8),
                    ),
                    tooltip: a.isPinned
                        ? 'Lepas Sematan (Unpin)'
                        : 'Sematkan di Atas',
                    onPressed: () async {
                      final ok = await SupabaseRepository.togglePinAnnouncement(
                        a.id,
                        !a.isPinned,
                      );
                      if (ok) {
                        await _loadBroadcastHistory();
                        await widget.onRefresh();
                      }
                    },
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: 'Hapus Siaran',
                    onPressed: () => _confirmDeleteAnnouncement(a),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteAnnouncement(Announcement a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengumuman?'),
        content: Text(
          'Pengumuman "${a.judul}" akan dihapus dari feed seluruh mahasiswa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await SupabaseRepository.deleteAnnouncement(a.id);
              if (ok) {
                widget.onRecordAudit(
                  action: 'DELETE',
                  module: 'PENGUMUMAN',
                  description: 'Menghapus pengumuman "${a.judul}"',
                );
                widget.onShowMessage('Pengumuman berhasil dihapus.');
                await _loadBroadcastHistory();
                await widget.onRefresh();
              } else {
                widget.onShowMessage(
                  'Gagal menghapus pengumuman.',
                  isError: true,
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}