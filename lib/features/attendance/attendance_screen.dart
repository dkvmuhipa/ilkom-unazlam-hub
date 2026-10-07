import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  int _activeTab = 0; // 0: Presensi Saya, 1: Rekap Seluruh Kelas (Khusus Pengurus/Admin)

  @override
  void initState() {
    super.initState();
    _initPersonalHistory();
    _startTimerIfNeeded();
  }

  void _initPersonalHistory() {
    // Generate realistic personal attendance records for the logged-in student
    final activeNim = widget.userNim ?? '260250023';
    final isSpecialCase = activeNim.endsWith('7') || activeNim.endsWith('9');
    
    _history = [
      AttendanceHistoryItem(
        date: 'Senin, 05 Okt 2026 (15:35 WITA)',
        courseName: 'Pendidikan Pancasila',
        status: 'Hadir',
      ),
      AttendanceHistoryItem(
        date: 'Senin, 05 Okt 2026 (18:40 WITA)',
        courseName: 'Pendidikan Kewarganegaraan',
        status: 'Hadir',
      ),
      AttendanceHistoryItem(
        date: 'Selasa, 29 Sep 2026 (15:35 WITA)',
        courseName: 'Pendidikan Agama Islam *',
        status: isSpecialCase ? 'Izin' : 'Hadir',
      ),
      AttendanceHistoryItem(
        date: 'Rabu, 23 Sep 2026 (15:32 WITA)',
        courseName: 'Bahasa Indonesia *',
        status: 'Hadir',
      ),
      AttendanceHistoryItem(
        date: 'Kamis, 17 Sep 2026 (18:35 WITA)',
        courseName: 'Bahasa Inggris *',
        status: 'Hadir',
      ),
      AttendanceHistoryItem(
        date: 'Jumat, 11 Sep 2026 (18:31 WITA)',
        courseName: 'Pengantar Ilmu Politik *',
        status: 'Hadir',
      ),
    ];
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
    final activeNim = widget.userNim ?? '260250023';
    final studentProfile = DummyData.students.firstWhere(
      (s) => s.nim == activeNim,
      orElse: () => DummyData.students.first,
    );

    final totalSessions = _history.length;
    final hadirCount = _history.where((h) => h.status == 'Hadir').length;
    final izinCount = _history.where((h) => h.status == 'Izin').length;
    final sakitCount = _history.where((h) => h.status == 'Sakit').length;
    final alpaCount = _history.where((h) => h.status == 'Alpa').length;
    final double attendanceRatio = totalSessions > 0 ? (hadirCount / totalSessions) : 1.0;
    final int attendancePercent = (attendanceRatio * 100).round();
    final bool isSafeZone = attendancePercent >= 75;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.canManageClassAttendance ? 'Presensi & Kehadiran' : 'Presensi Saya',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.canManageClassAttendance
                  ? 'Akses Pengurus • ${studentProfile.nama}'
                  : '${studentProfile.nama} • ${studentProfile.nim}',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // QR Trigger Button
          IconButton(
            icon: Icon(
              widget.canManageClassAttendance ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
              color: const Color(0xFF5B3DE8),
              size: 22,
            ),
            tooltip: widget.canManageClassAttendance ? 'Buka QR Presensi Sesi' : 'Scan QR Absensi',
            onPressed: () {
              if (widget.canManageClassAttendance) {
                _showGenerateQrModal(context);
              } else {
                _showScanQrModal(context);
              }
            },
          ),
          // Export Button (Personal vs Class)
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: isDark ? Colors.white70 : const Color(0xFF374151), size: 22),
            tooltip: widget.canManageClassAttendance
                ? 'Export Rekap Presensi Kelas (Excel/CSV)'
                : 'Export Rekap Kehadiran Saya (CSV)',
            onPressed: () {
              if (widget.canManageClassAttendance) {
                ExportService.showExportSheet(
                  context,
                  title: 'Export Rekap Presensi Seluruh Kelas',
                  subtitle: 'Format data CSV kompatibel dengan Microsoft Excel & Google Sheets',
                  fileName: 'Rekap_Presensi_Kelas_ILKOM_UNAZLAM_2026.csv',
                  content: ExportService.exportAttendanceCsv(DummyData.courses.first.nama),
                );
              } else {
                ExportService.showExportSheet(
                  context,
                  title: 'Export Rekap Presensi Pribadi',
                  subtitle: 'Khusus data kehadiran atas nama ${studentProfile.nama} (${studentProfile.nim})',
                  fileName: 'Presensi_${studentProfile.nim}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
                  content: ExportService.exportPersonalAttendanceCsv(
                    studentNim: studentProfile.nim,
                    studentName: studentProfile.nama,
                    history: _history,
                  ),
                );
              }
            },
          ),
          if (widget.canManageClassAttendance)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showClassAttendanceModal,
                icon: const Icon(Icons.fact_check_outlined, size: 16, color: Color(0xFF5B3DE8)),
                label: const Text('Input Kelas', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8))),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: const Color(0xFF5B3DE8).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (widget.canManageClassAttendance && _activeTab == 1)
          ? FloatingActionButton.extended(
              onPressed: _showClassAttendanceModal,
              backgroundColor: const Color(0xFF5B3DE8),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
              label: const Text('Input Presensi Pertemuan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            // ==========================================
            // ROLE SELECTOR TAB (ONLY FOR KETUA KELAS / ADMIN)
            // ==========================================
            if (widget.canManageClassAttendance) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? (isDark ? const Color(0xFF5B3DE8) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: _activeTab == 0
                                    ? (_activeTab == 0 && isDark ? Colors.white : const Color(0xFF5B3DE8))
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Presensi Saya',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                  color: _activeTab == 0
                                      ? (_activeTab == 0 && isDark ? Colors.white : const Color(0xFF1E293B))
                                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? (isDark ? const Color(0xFF5B3DE8) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
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
                                color: _activeTab == 1
                                    ? (_activeTab == 1 && isDark ? Colors.white : const Color(0xFF5B3DE8))
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Rekap Seluruh Kelas',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                  color: _activeTab == 1
                                      ? (_activeTab == 1 && isDark ? Colors.white : const Color(0xFF1E293B))
                                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
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
            ],

            // ==========================================
            // LIVE ACTIVE SESSION COUNTDOWN BANNER
            // ==========================================
            if (currentSession != null && !currentSession!.isExpired) ...[
              Builder(
                builder: (context) {
                  final session = currentSession!;
                  final secsLeft = session.remainingSeconds;
                  final isUrgent = secsLeft < 180;
                  final hasAttended = session.attendedNims.contains(activeNim);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                          : (isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUrgent
                            ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
                            : (isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF16A34A)).withValues(alpha: 0.1),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                                    : (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7)),
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
                                    color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimer(secsLeft),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
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
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF5B3DE8)),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.canManageClassAttendance
                                        ? '${session.attendedNims.length} Hadir'
                                        : (hasAttended ? 'Tercatat Hadir' : 'Menunggu Presensi'),
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
                                  backgroundColor: isDark ? const Color(0xFF2E1A1A) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: hasAttended
                                      ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                                      : (isDark ? const Color(0xFF713F12) : const Color(0xFFFEF3C7)),
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

            // ==========================================
            // VIEW SEPARATION: TAB 1 (CLASS RECAP FOR ADMIN/KETUA)
            // ==========================================
            if (widget.canManageClassAttendance && _activeTab == 1) ...[
              _buildClassRecapView(isDark),
            ] else ...[
              // ==========================================
              // VIEW SEPARATION: TAB 0 (PERSONAL ATTENDANCE VIEW)
              // ==========================================
              _buildPersonalAttendanceView(
                isDark: isDark,
                totalSessions: totalSessions,
                hadirCount: hadirCount,
                izinCount: izinCount,
                sakitCount: sakitCount,
                alpaCount: alpaCount,
                attendanceRatio: attendanceRatio,
                attendancePercent: attendancePercent,
                isSafeZone: isSafeZone,
                studentName: studentProfile.nama,
                studentNim: studentProfile.nim,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 1: REKAP KELAS LENGKAP (KHUSUS PENGURUS & ADMIN)
  // =========================================================================
  Widget _buildClassRecapView(bool isDark) {
    final students = DummyData.students.where((s) => s.role != 'ADMIN').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Banner
        Container(
          width: double.infinity,
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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka QR Presensi Kuliah',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Generate QR Code & Token sesi 15 menit',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onTap: () => _showGenerateQrModal(context),
                scaleDown: 0.92,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Buka Sesi',
                    style: TextStyle(
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

        // Class Quick Overview
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Mahasiswa',
                value: '${students.length}',
                subtitle: 'Mahasiswa Terdaftar',
                icon: Icons.groups_rounded,
                color: const Color(0xFF5B3DE8),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Rata-Rata Kelas',
                value: '95.6%',
                subtitle: 'Tingkat Kehadiran',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rekap Kehadiran Mahasiswa (${students.length})',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            TextButton.icon(
              onPressed: _showClassAttendanceModal,
              icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF5B3DE8)),
              label: const Text(
                'Presensi Cepat',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Students Table List
        ...students.asMap().entries.map((entry) {
          final index = entry.key;
          final s = entry.value;
          final isPunctual = (index % 7 != 0);
          final hadirPct = isPunctual ? 100 - (index % 3) * 5 : 70;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF5B3DE8).withValues(alpha: 0.1),
                  child: Text(
                    s.nama.isNotEmpty ? s.nama[0] : 'M',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nama,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.nim} • ${s.jabatan}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hadirPct >= 75
                        ? (isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5))
                        : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$hadirPct%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: hadirPct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // VIEW 2: TAMPILAN PRESENSI PRIBADI MAHASISWA (PRIVAT & USER FRIENDLY)
  // =========================================================================
  Widget _buildPersonalAttendanceView({
    required bool isDark,
    required int totalSessions,
    required int hadirCount,
    required int izinCount,
    required int sakitCount,
    required int alpaCount,
    required double attendanceRatio,
    required int attendancePercent,
    required bool isSafeZone,
    required String studentName,
    required String studentNim,
  }) {
    final maxAlpaAllowed = 4;
    final remainingAlpa = (maxAlpaAllowed - alpaCount).clamp(0, maxAlpaAllowed);

    return Column(
      children: [
        // 1. Scan QR Quick Trigger Banner (Khusus Mahasiswa)
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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan QR Presensi Kuliah',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pindai QR dosen/ketua kelas atau input token',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onTap: () => _showScanQrModal(context),
                scaleDown: 0.92,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Scan QR',
                    style: TextStyle(
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

        // 2. HERO ATTENDANCE CARD (Donut Progress + Safe Zone Status)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Kehadiran',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Semester Ganjil 2026/2027',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  // Safe Zone Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSafeZone
                          ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                          : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSafeZone ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSafeZone ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          size: 13,
                          color: isSafeZone ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSafeZone ? 'Syarat Ujian Aman' : 'Batas Kritis (<75%)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isSafeZone ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Circular Gauge Donut
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: totalSessions > 0 ? attendanceRatio : 1.0,
                        strokeWidth: 11,
                        backgroundColor: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF3F0FF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSafeZone ? const Color(0xFF5B3DE8) : const Color(0xFFEF4444),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          totalSessions > 0 ? '$attendancePercent%' : '100%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Kehadiran',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4 Stat Counters in a Row (Hadir, Izin, Sakit, Alpa)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('$hadirCount', 'Hadir', const Color(0xFF10B981), isDark),
                  _buildStatBox('$izinCount', 'Izin', const Color(0xFFF59E0B), isDark),
                  _buildStatBox('$sakitCount', 'Sakit', const Color(0xFF3B82F6), isDark),
                  _buildStatBox('$alpaCount', 'Alpa', const Color(0xFFEF4444), isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Safe Tolerance Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF5B3DE8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toleransi Alpa: sisa $remainingAlpa kali dari maks 4 pertemuan sebelum tidak memenuhi syarat UAS.',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. COURSE ATTENDANCE BREAKDOWN (Per Mata Kuliah)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kehadiran Per Mata Kuliah',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            Text(
              '8 Mata Kuliah',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...DummyData.courses.map((course) {
          // Check if this course is in personal history
          final courseSessions = _history.where((h) => h.courseName == course.nama).length;
          final isAttended = courseSessions > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B3DE8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF5B3DE8), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.nama,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${course.kode} • ${course.sks} SKS • ${course.dosen}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAttended
                            ? (isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5))
                            : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAttended ? '100% Hadir' : 'Belum Ada Sesi',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isAttended
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pertemuan Indicator Matrix (P1 - P16)
                Row(
                  children: List.generate(16, (i) {
                    final pNum = i + 1;
                    final isP1Attended = (pNum == 1 && isAttended);
                    final isPastSession = pNum == 1;

                    Color dotColor = isP1Attended
                        ? const Color(0xFF10B981)
                        : (isPastSession ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0)));

                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'P1 (Selesai)',
                      style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : const Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Target Minimal 12/16 Pertemuan (75%)',
                      style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : const Color(0xFF94A3B8)),
                    ),
                    Text(
                      'P16 (UAS)',
                      style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),

        // 4. PERSONAL ATTENDANCE LOGS TIMELINE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Scan Presensi Pribadi',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
              ),
              child: Text(
                'Terbaru',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
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
                Text(
                  'Belum Ada Riwayat Presensi Pribadi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Presensi kuliah Anda melalui pemindaian QR Code atau lembar absensi kelas akan tercatat aman di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ..._history.map((h) => _buildHistoryTile(h, isDark)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF111827)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
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

  Widget _buildHistoryTile(AttendanceHistoryItem item, bool isDark) {
    final isHadir = item.status == 'Hadir';
    final isIzin = item.status == 'Izin';
    final statusColor = isHadir ? const Color(0xFF10B981) : (isIzin ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final statusBg = isHadir
        ? (isDark ? const Color(0xFF14532D) : const Color(0xFFECFDF5))
        : (isIzin
            ? (isDark ? const Color(0xFF713F12) : const Color(0xFFFFFBEB))
            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
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
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
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
