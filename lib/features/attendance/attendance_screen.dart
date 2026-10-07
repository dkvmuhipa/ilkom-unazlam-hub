import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/export_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/qr_widget.dart';
import '../../core/widgets/scale_button.dart';

class AttendanceHistoryItem {
  final String date;
  final String courseName;
  final String status; // 'Hadir', 'Izin', 'Sakit', 'Alpa'

  const AttendanceHistoryItem({
    required this.date,
    required this.courseName,
    required this.status,
  });
}

class ActiveAttendanceSession {
  final String courseName;
  final int pertemuanKe;
  final String token;
  final DateTime startTime;
  final DateTime expiresAt;
  final Set<String> attendedNims;

  ActiveAttendanceSession({
    required this.courseName,
    required this.pertemuanKe,
    required this.token,
    required this.startTime,
    required this.expiresAt,
    Set<String>? attendedNims,
  }) : attendedNims = attendedNims ?? {};

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get remainingSeconds => expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 9999);
}

class AttendanceScreen extends StatefulWidget {
  final bool canManageClassAttendance;
  final String? userNim;
  final VoidCallback? onBack;

  const AttendanceScreen({
    super.key,
    this.canManageClassAttendance = false,
    this.userNim,
    this.onBack,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late List<AttendanceHistoryItem> _history;

  // Shared active QR session across the class
  static ActiveAttendanceSession? currentSession;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _history = [];
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _countdownTimer?.cancel();
    if (currentSession != null && !currentSession!.isExpired) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (currentSession == null || currentSession!.isExpired) {
          timer.cancel();
          setState(() {
            currentSession = null;
          });
        } else {
          setState(() {});
        }
      });
    }
  }

  String _formatTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showClassAttendanceModal() {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();
    final Map<String, String> statusMap = {
      for (var s in students) s.id: 'Hadir',
    };
    String selectedCourse = DummyData.courses.first.nama;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presensi Pertemuan Kelas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kelola absensi mahasiswa untuk mata kuliah ini',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: DummyData.courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Daftar Mahasiswa (${students.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {
                          for (var s in students) {
                            statusMap[s.id] = 'Hadir';
                          }
                        });
                      },
                      icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF16A34A)),
                      label: const Text('Set Semua Hadir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      final currentStatus = statusMap[s.id] ?? 'Hadir';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF5B3DE8).withValues(alpha: 0.1),
                              child: Text(s.nama.isNotEmpty ? s.nama[0] : 'M', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.nama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                                  Text('${s.nim} • ${s.jabatan}', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: ['Hadir', 'Izin', 'Sakit', 'Alpa'].map((st) {
                                final isSel = currentStatus == st;
                                Color color = st == 'Hadir' ? const Color(0xFF16A34A) : (st == 'Izin' ? const Color(0xFFD97706) : (st == 'Sakit' ? const Color(0xFF2563EB) : const Color(0xFFDC2626)));
                                return InkWell(
                                  onTap: () => setModalState(() => statusMap[s.id] = st),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSel ? color : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSel ? color : const Color(0xFFD1D5DB)),
                                    ),
                                    child: Text(
                                      st[0],
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSel ? Colors.white : const Color(0xFF4B5563)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    for (var s in students) {
                      final st = statusMap[s.id] ?? 'Hadir';
                      SupabaseRepository.logAttendance(
                        courseId: selectedCourse,
                        studentNim: s.nim,
                        pertemuanKe: 1,
                        status: st,
                      );
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Presensi kelas untuk $selectedCourse berhasil disimpan!'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Simpan Rekap Presensi Kelas', style: TextStyle(fontWeight: FontWeight.w700)),
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
        ),
      ),
    );
  }

  void _showGenerateQrModal(BuildContext context) {
    String selectedCourse = DummyData.courses.first.nama;
    int pertemuan = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final courseCode = selectedCourse.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
          final shortCode = courseCode.length > 6 ? courseCode.substring(0, 6) : courseCode;
          final token = 'ILKOM-$shortCode-P$pertemuan';

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('QR Code Presensi Sesi Kelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                          SizedBox(height: 2),
                          Text('Tampilkan kode ini kepada mahasiswa di kelas', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: selectedCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: DummyData.courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 20),

                // ISO-Compliant QR Code View
                QrCodeWidget(
                  data: token,
                  size: 200,
                ),
                const SizedBox(height: 16),

                // Token Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFF5B3DE8)),
                      const SizedBox(width: 8),
                      Text(
                        'TOKEN: $token',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF5B3DE8), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      'Berlaku hingga 15 menit ke depan (10:15 WITA)',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      currentSession = ActiveAttendanceSession(
                        courseName: selectedCourse,
                        pertemuanKe: pertemuan,
                        token: token,
                        startTime: now,
                        expiresAt: now.add(const Duration(minutes: 15)),
                      );
                      _startTimerIfNeeded();
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Sesi presensi "$selectedCourse" aktif selama 15 menit! Timer dimulai.'),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 20),
                  label: const Text('Buka Sesi Presensi Sekarang (15 Menit)', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3DE8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showScanQrModal(BuildContext context) {
    final tokenController = TextEditingController();
    String selectedCourse = DummyData.courses.first.nama;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan / Verifikasi QR Presensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                        SizedBox(height: 2),
                        Text('Pindai QR dosen/ketua kelas atau masukkan token', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: selectedCourse,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Mata Kuliah',
                  labelStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: DummyData.courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedCourse = val);
                },
              ),
              const SizedBox(height: 14),

              // Simulated Camera Scanner Viewfinder
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated Scanner Target Box
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF10B981), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 38, color: Color(0xFF10B981)),
                        SizedBox(height: 6),
                        Text(
                          'Arahkan kamera ke QR Code',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: tokenController,
                decoration: InputDecoration(
                  labelText: 'Atau Masukkan Kode Token Sesi',
                  hintText: 'Contoh: ILKOM-UNAZLAM-P5-9821',
                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  final token = tokenController.text.trim();
                  final session = currentSession;

                  // 1. Validasi sesi aktif
                  if (session == null || session.isExpired) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Tidak ada sesi presensi aktif atau sesi 15 menit telah berakhir/kadaluwarsa!'),
                            ),
                          ],
                        ),
                        backgroundColor: Color(0xFFEF4444),
                        duration: Duration(seconds: 4),
                      ),
                    );
                    return;
                  }

                  // 2. Validasi kesesuaian token (jika diinput manual)
                  if (token.isNotEmpty && token.toUpperCase() != session.token.toUpperCase()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kode Token salah! Token sesi saat ini adalah "${session.token}".'),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                    return;
                  }

                  final targetCourse = session.courseName;
                  final activeNim = widget.userNim ?? '260250023';

                  // 3. Validasi duplikasi presensi
                  if (session.attendedNims.contains(activeNim)) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('NIM $activeNim sudah tercatat hadir untuk sesi $targetCourse ini!'),
                        backgroundColor: const Color(0xFFF59E0B),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  // Simpan ke sesi aktif & Supabase
                  session.attendedNims.add(activeNim);
                  SupabaseRepository.logAttendance(
                    courseId: targetCourse,
                    studentNim: activeNim,
                    pertemuanKe: session.pertemuanKe,
                    status: 'Hadir',
                    catatan: token.isNotEmpty ? 'Presensi Token: $token' : 'Presensi Scanner QR',
                  );

                  setState(() {
                    _history.insert(
                      0,
                      AttendanceHistoryItem(
                        date: 'Hari Ini, ${DateTime.now().day} Okt 2026 (${DateFormat('HH:mm').format(DateTime.now())})',
                        courseName: targetCourse,
                        status: 'Hadir',
                      ),
                    );
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Presensi Hadir untuk "$targetCourse" berhasil diverifikasi! 🎉'),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.verified_rounded, size: 18),
                label: const Text('Verifikasi Kehadiran', style: TextStyle(fontWeight: FontWeight.w700)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSessions = _history.length;
    final hadirCount = _history.where((h) => h.status == 'Hadir').length;
    final izinCount = _history.where((h) => h.status == 'Izin').length;
    final sakitCount = _history.where((h) => h.status == 'Sakit').length;
    final alpaCount = _history.where((h) => h.status == 'Alpa').length;
    final double attendanceRatio = totalSessions > 0 ? (hadirCount / totalSessions) : 1.0;
    final int attendancePercent = (attendanceRatio * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Absensi Saya',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF111827), size: 22),
            tooltip: widget.canManageClassAttendance ? 'Buka QR Presensi Sesi' : 'Scan QR Absensi',
            onPressed: () {
              if (widget.canManageClassAttendance) {
                _showGenerateQrModal(context);
              } else {
                _showScanQrModal(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF111827), size: 22),
            tooltip: 'Export Rekap Presensi (Excel/CSV)',
            onPressed: () {
              ExportService.showExportSheet(
                context,
                title: 'Export Rekap Presensi Mahasiswa',
                subtitle: 'Format data CSV kompatibel dengan Microsoft Excel & Google Sheets',
                fileName: 'Rekap_Presensi_ILKOM_UNAZLAM_2026.csv',
                content: ExportService.exportAttendanceCsv(DummyData.courses.first.nama),
              );
            },
          ),
          if (widget.canManageClassAttendance)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _showClassAttendanceModal,
                icon: const Icon(Icons.playlist_add_check, size: 18, color: Color(0xFF5B3DE8)),
                label: const Text('Presensi Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8))),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DE8).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.canManageClassAttendance
          ? FloatingActionButton.extended(
              onPressed: _showClassAttendanceModal,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Input Presensi Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ==========================================
            // LIVE ACTIVE SESSION COUNTDOWN BANNER
            // ==========================================
            if (currentSession != null && !currentSession!.isExpired) ...[
              Builder(
                builder: (context) {
                  final session = currentSession!;
                  final secsLeft = session.remainingSeconds;
                  final isUrgent = secsLeft < 180; // Kurang dari 3 menit
                  final activeNim = widget.userNim ?? '260250023';
                  final hasAttended = session.attendedNims.contains(activeNim);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF16A34A)).withValues(alpha: 0.08),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'SESI AKTIF',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Live Countdown Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimer(secsLeft),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          session.courseName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Token: ${session.token} • Pertemuan ke-${session.pertemuanKe}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status Info Bar & Actions
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF5B3DE8)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${session.attendedNims.length} Hadir',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF5B3DE8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),

                            if (widget.canManageClassAttendance) ...[
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    currentSession = null;
                                    _countdownTimer?.cancel();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sesi presensi telah ditutup oleh pengurus kelas.'),
                                      backgroundColor: Color(0xFF374151),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.stop_circle_outlined, size: 15, color: Color(0xFFDC2626)),
                                label: const Text('Tutup Sesi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: hasAttended ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  hasAttended ? '✅ Anda Sudah Hadir' : '⚠️ Belum Presensi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: hasAttended ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // QR Action Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B3DE8), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B3DE8).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.canManageClassAttendance ? 'QR Sesi Presensi Aktif' : 'Scan QR Presensi Kelas',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.canManageClassAttendance ? 'Buka kode QR untuk dipindai mahasiswa' : 'Gunakan kamera atau masukkan token sesi kuliah',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ScaleButton(
                    onTap: () {
                      if (widget.canManageClassAttendance) {
                        _showGenerateQrModal(context);
                      } else {
                        _showScanQrModal(context);
                      }
                    },
                    scaleDown: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.canManageClassAttendance ? 'Buka QR' : 'Scan QR',
                        style: const TextStyle(
                          color: Color(0xFF5B3DE8),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Donut Chart Card matching Screen 6
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Circular Progress Donut Ring
                  SizedBox(
                    width: 125,
                    height: 125,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 125,
                          height: 125,
                          child: CircularProgressIndicator(
                            value: totalSessions > 0 ? attendanceRatio : 1.0,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFF3F0FF),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B3DE8)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              totalSessions > 0 ? '$attendancePercent%' : '100%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'Hadir',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4 Stat Counters in a Row (Hadir, Izin, Sakit, Alpa)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('$hadirCount', 'Hadir', const Color(0xFF10B981)),
                      _buildStatBox('$izinCount', 'Izin', const Color(0xFFF59E0B)),
                      _buildStatBox('$sakitCount', 'Sakit', const Color(0xFF3B82F6)),
                      _buildStatBox('$alpaCount', 'Alpa', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Pertemuan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pertemuan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '$totalSessions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Riwayat Absensi Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Absensi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Riwayat Absensi List
            if (_history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.how_to_reg_rounded, size: 32, color: Color(0xFF5B3DE8)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum Ada Riwayat Presensi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Presensi kuliah Anda melalui pemindaian QR Code atau lembar absensi kelas akan tercatat di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), height: 1.4),
                    ),
                  ],
                ),
              )
            else
              ..._history.map((h) => _buildHistoryTile(h)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTile(AttendanceHistoryItem item) {
    final isHadir = item.status == 'Hadir';
    final isIzin = item.status == 'Izin';
    final statusColor = isHadir ? const Color(0xFF10B981) : (isIzin ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final statusBg = isHadir ? const Color(0xFFECFDF5) : (isIzin ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
