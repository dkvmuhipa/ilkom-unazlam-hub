import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;
import '../../core/services/export_service.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/qr_widget.dart';
import '../../models/models.dart';
export 'models/attendance_models.dart';
import 'models/attendance_models.dart';
import 'widgets/absence_request_modal.dart';
import 'widgets/attendance_qr_modal.dart';
import 'widgets/attendance_scanner_modal.dart';

import 'views/class_attendance_recap_view.dart';
import 'views/personal_attendance_view.dart';
import 'widgets/class_attendance_modal.dart';

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

  // Global Class-Wide Session state
  static ActiveAttendanceSession? currentSession;

  static Future<ActiveAttendanceSession?> syncActiveSessionFromCloud() async {
    try {
      final data = await SupabaseRepository.getActiveAttendanceSession();
      if (data != null) {
        final session = ActiveAttendanceSession.fromMap(data);
        currentSession = session;
        return session;
      } else {
        if (currentSession != null && currentSession!.isExpired) {
          currentSession = null;
        }
        return null;
      }
    } catch (_) {
      return currentSession;
    }
  }

  static void showActiveQrModal(
    BuildContext context, {
    ActiveAttendanceSession? session,
    VoidCallback? onClosed,
  }) {
    final active = session ?? currentSession;
    if (active == null || active.isExpired) return;
    AttendanceQrModal.show(context, active: active, onClosed: onClosed);
  }

  static void showStudentScanner(
    BuildContext context, {
    required String userNim,
    List<Course> courses = const [],
    VoidCallback? onSuccess,
  }) {
    AttendanceScannerModal.show(context, userNim: userNim, courses: courses, onSuccess: onSuccess);
  }

  // =========================================================================
  // PENGAJUAN IZIN / SAKIT MANDIRI (SELF-REPORT ABSENCE)
  // =========================================================================
  static void showAbsenceRequestModal(
    BuildContext context, {
    required String userNim,
    List<Course> courses = const [],
    String? preselectedCourse,
    int? preselectedPertemuan,
    VoidCallback? onSuccess,
  }) {
    AbsenceRequestModal.show(
      context,
      userNim: userNim,
      courses: courses,
      preselectedCourse: preselectedCourse,
      preselectedPertemuan: preselectedPertemuan,
      onSuccess: onSuccess,
    );
  }

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Timer? _countdownTimer;
  int _activeTab = 0; // 0: Presensi Saya, 1: Rekap Seluruh Kelas
  ActiveAttendanceSession? get currentSession => AttendanceScreen.currentSession;
  set currentSession(ActiveAttendanceSession? s) => AttendanceScreen.currentSession = s;

  List<AttendanceHistoryItem> _history = [];
  List<Map<String, dynamic>> _allClassLogs = [];
  List<Course> _courses = [];
  List<StudentProfile> _students = [];
  bool _isLoadingAttendance = true;
  String? _attendanceLoadError;
  RealtimeChannel? _sessionsChannel;
  RealtimeChannel? _recordsChannel;

  @override
  void initState() {
    super.initState();
    AttendanceScreen.syncActiveSessionFromCloud().then((_) {
      if (mounted) {
        setState(() {});
        _startTimerIfNeeded();
      }
    });
    _loadRealAttendanceData();
    _startTimerIfNeeded();
    _initRealtime();
  }

  void _initRealtime() {
    _sessionsChannel = SupabaseRepository.subscribeToAttendanceSessions(() {
      if (mounted) {
        AttendanceScreen.syncActiveSessionFromCloud().then((_) {
          if (mounted) {
            setState(() {});
            _startTimerIfNeeded();
          }
        });
      }
    });
    _recordsChannel = SupabaseRepository.subscribeToAttendanceRecords(() {
      if (mounted) {
        _loadRealAttendanceData(silent: true);
      }
    });
  }

  Future<void> _loadRealAttendanceData({bool silent = false}) async {
    final activeNim = widget.userNim ?? '';
    if (mounted && !silent) {
      setState(() {
        _isLoadingAttendance = true;
        _attendanceLoadError = null;
      });
    }

    try {
      if (!widget.canManageClassAttendance && activeNim.isEmpty) {
        throw StateError('NIM akun tidak ditemukan. Silakan masuk kembali.');
      }
      List<Map<String, dynamic>> rawLogs;
      try {
        rawLogs = await SupabaseRepository.getAttendanceLogsStrict(
          studentNim: widget.canManageClassAttendance ? null : activeNim,
        );
      } catch (err) {
        debugPrint('Warning: getAttendanceLogsStrict gagal ($err), mencoba getAttendanceLogs fallback');
        rawLogs = await SupabaseRepository.getAttendanceLogs(
          studentNim: widget.canManageClassAttendance ? null : activeNim,
        );
      }
      
      final courses = await SupabaseRepository.getCourses();
      final students = await SupabaseRepository.getClassDirectory();
      
      if (!mounted) return;

      setState(() {
        _courses = courses;
        _students = students;
        _allClassLogs = rawLogs;

        // 2. Filter riwayat presensi khusus untuk mahasiswa yang sedang aktif login
        final personalLogs = rawLogs.where((l) => l['student_nim'] == activeNim).toList();

        _history = personalLogs.map((l) {
          final createdAt = l['created_at'] != null ? DateTime.parse(l['created_at']) : DateTime.now();
          final formattedDate = '${DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(createdAt)} (${DateFormat('HH:mm').format(createdAt)} WITA)';

          String cName = 'Mata Kuliah';
          if (l['courses'] != null && l['courses']['nama_mk'] != null) {
            cName = l['courses']['nama_mk'].toString();
          } else if (l['course_id'] != null) {
            cName = 'Mata Kuliah';
          }

          final rawSt = (l['status'] ?? 'hadir').toString().toLowerCase();
          String stFormatted = 'Hadir';
          if (rawSt == 'izin') stFormatted = 'Izin';
          if (rawSt == 'sakit') stFormatted = 'Sakit';
          if (rawSt == 'alpa') stFormatted = 'Alpa';

          return AttendanceHistoryItem(
            date: formattedDate,
            courseName: cName,
            status: stFormatted,
            pertemuanKe: (l['pertemuan_ke'] as num?)?.toInt(),
            catatan: l['catatan']?.toString(),
          );
        }).toList();

        _isLoadingAttendance = false;
      });
    } catch (e) {
      debugPrint('Error load real attendance: $e');
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
          _attendanceLoadError =
              'Riwayat presensi gagal dimuat. Periksa koneksi lalu coba lagi.';
        });
      }
    }
  }

  void _confirmResetPersonalAttendance() {
    final activeNim = widget.userNim ?? '';
    if (activeNim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'NIM akun tidak ditemukan. Masuk kembali sebelum mengubah riwayat.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Riwayat Presensi Pribadi?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'Semua catatan scan presensi Anda akan dihapus karena belum ada aktivitas perkuliahan yang aktif. Riwayat Anda akan kembali bersih/kosong.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _history = [];
                _allClassLogs.removeWhere((l) => l['student_nim'] == activeNim);
              });
              await SupabaseRepository.clearAttendanceLogs(studentNim: activeNim);
              await _loadRealAttendanceData();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat presensi pribadi telah berhasil dikosongkan.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Kosongkan Sekarang'),
          ),
        ],
      ),
    );
  }

  void _confirmResetAllAttendance() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Rekap Seluruh Kelas?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'Semua catatan log presensi kelas akan dibersihkan dari server karena belum ada perkuliahan aktif. Rekap kehadiran seluruh mahasiswa akan kembali ke kondisi awal (0 sesi).',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _history = [];
                _allClassLogs = [];
              });
              await SupabaseRepository.clearAttendanceLogs();
              await _loadRealAttendanceData();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rekap presensi seluruh kelas telah berhasil dikosongkan.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Kosongkan Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SupabaseRepository.unsubscribeChannel(_sessionsChannel);
    SupabaseRepository.unsubscribeChannel(_recordsChannel);
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
    ClassAttendanceModal.show(
      context,
      students: _students,
      courses: _courses,
      onSaved: () async {
        await _loadRealAttendanceData();
      },
    );
  }

  void _showGenerateQrModal(BuildContext context) {
    String selectedCourse = _courses.isNotEmpty ? _courses.first.nama : 'Mata Kuliah';
    int pertemuan = 5;
    String token = _generateAttendanceToken();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
                  items: _courses.isEmpty
                      ? [
                          DropdownMenuItem(
                            value: selectedCourse,
                            child: Text(selectedCourse, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                        ]
                      : _courses.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedCourse = val;
                        token = _generateAttendanceToken();
                      });
                    }
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 8),
                      Text(
                        'TOKEN: $token',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF), letterSpacing: 0.5),
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
                    final expiresAt = now.add(const Duration(minutes: 15));
                    final newSession = ActiveAttendanceSession(
                      courseName: selectedCourse,
                      pertemuanKe: pertemuan,
                      token: token,
                      startTime: now,
                      expiresAt: expiresAt,
                    );

                    setState(() {
                      currentSession = newSession;
                      _startTimerIfNeeded();
                    });

                    // Simpan sesi presensi ke cloud Supabase agar realtime ke seluruh kelas
                    SupabaseRepository.createAttendanceSession(
                      courseName: selectedCourse,
                      pertemuanKe: pertemuan,
                      token: token,
                      pinCode: newSession.pinCode,
                      expiresAt: expiresAt,
                      createdBy: widget.userNim,
                    ).then((created) {
                      if (created != null && created['id'] != null && mounted) {
                        setState(() {
                          currentSession = ActiveAttendanceSession.fromMap(created);
                        });
                      }
                    });

                    // Broadcast class announcement so every classmate sees it in Notifications & Announcements
                    SupabaseRepository.createAnnouncement(
                      judul: 'Presensi Dibuka: $selectedCourse Pertemuan $pertemuan',
                      isi: 'Sesi presensi QR untuk mata kuliah $selectedCourse (Pertemuan $pertemuan) telah dibuka oleh pengurus kelas dan berlaku selama 15 menit. Silakan scan QR di kelas atau masukkan Token "$token" / PIN "${newSession.pinCode}" langsung di aplikasi.',
                      kategori: 'Kelas',
                      isPinned: true,
                      authorName: 'Pengurus Kelas (Ketua)',
                    );

                    Navigator.pop(ctx);

                    // Re-open persistent active session presenter modal so Ketua can project/show it to the entire class
                    AttendanceScreen.showActiveQrModal(context, session: newSession);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Sesi presensi "$selectedCourse" aktif selama 15 menit! Pengumuman kelas telah disiarkan.'),
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
                    backgroundColor: const Color(0xFF1E40AF),
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

  String _generateAttendanceToken() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }

  void _showScanQrModal(BuildContext context) {
    AttendanceScreen.showStudentScanner(
      context,
      userNim: widget.userNim ?? '',
      courses: _courses,
      onSuccess: () => _loadRealAttendanceData(),
    );
  }

  void _showAbsenceRequestSheet(BuildContext context, {String? preselectedCourse, int? preselectedPertemuan}) {
    AttendanceScreen.showAbsenceRequestModal(
      context,
      userNim: widget.userNim ?? '',
      courses: _courses,
      preselectedCourse: preselectedCourse,
      preselectedPertemuan: preselectedPertemuan,
      onSuccess: () => _loadRealAttendanceData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeNim = widget.userNim ?? '';
    final studentProfile = _students.firstWhere(
      (s) => s.nim == activeNim,
      orElse: () => StudentProfile(
        id: '',
        nim: activeNim,
        nama: activeNim.isEmpty ? 'Mahasiswa' : 'Mahasiswa $activeNim',
        email: '',
        noWa: '',
      ),
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF111827)),
          tooltip: 'Kembali',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
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
          // Prominent Buka QR / Scan QR Action Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.canManageClassAttendance) {
                  _showGenerateQrModal(context);
                } else {
                  _showScanQrModal(context);
                }
              },
              icon: Icon(
                widget.canManageClassAttendance ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
                size: 16,
              ),
              label: Text(
                widget.canManageClassAttendance ? 'Buka QR' : 'Scan QR',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
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
                  content: ExportService.exportAttendanceCsv(
                    courseName: _courses.isNotEmpty ? _courses.first.nama : 'Mata Kuliah ILKOM',
                    logs: _allClassLogs,
                    students: _students,
                  ),
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
                icon: const Icon(Icons.fact_check_outlined, size: 16, color: Color(0xFF1E40AF)),
                label: const Text('Input Kelas', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.canManageClassAttendance
          ? FloatingActionButton.extended(
              onPressed: () => _showGenerateQrModal(context),
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text(
                'Buka Presensi QR',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
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
                                ? (isDark ? const Color(0xFF1E40AF) : Colors.white)
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
                                    ? (_activeTab == 0 && isDark ? Colors.white : const Color(0xFF1E40AF))
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
                                ? (isDark ? const Color(0xFF1E40AF) : Colors.white)
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
                                    ? (_activeTab == 1 && isDark ? Colors.white : const Color(0xFF1E40AF))
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
            // KETUA KELAS / DOSEN: HERO CARD BUKA PRESENSI QR
            // ==========================================
            if (widget.canManageClassAttendance && (currentSession == null || currentSession!.isExpired)) ...[
              _buildStartAttendanceHeroCard(context, isDark),
              const SizedBox(height: 16),
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
                                  const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF1E40AF)),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.canManageClassAttendance
                                        ? '${session.attendedNims.length} Hadir'
                                        : (hasAttended ? 'Tercatat Hadir' : 'Menunggu Presensi'),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Tombol Tampilkan QR Code (Dapat dilihat oleh siapapun/Ketua untuk proyektor)
                            TextButton.icon(
                              onPressed: () => AttendanceScreen.showActiveQrModal(context, session: session),
                              icon: const Icon(Icons.qr_code_rounded, size: 15, color: Color(0xFF1E40AF)),
                              label: const Text('Lihat QR', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                backgroundColor: isDark ? const Color(0xFF2E2E3E) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            if (widget.canManageClassAttendance) ...[
                              TextButton.icon(
                                onPressed: () {
                                  final activeId = currentSession?.id;
                                  setState(() {
                                    currentSession = null;
                                    _countdownTimer?.cancel();
                                  });
                                  SupabaseRepository.closeAttendanceSession(sessionId: activeId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sesi presensi telah ditutup oleh pengurus kelas.'),
                                      backgroundColor: Color(0xFF374151),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.stop_circle_outlined, size: 15, color: Color(0xFFDC2626)),
                                label: const Text('Tutup', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  backgroundColor: isDark ? const Color(0xFF2E1A1A) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ] else ...[
                              if (!hasAttended)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showScanQrModal(context),
                                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                                      label: const Text('Presensi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      onPressed: () => _showAbsenceRequestSheet(
                                        context,
                                        preselectedCourse: session.courseName,
                                        preselectedPertemuan: session.pertemuanKe,
                                      ),
                                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 13),
                                      label: const Text('Izin/Sakit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                                        side: BorderSide(color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFFBBF24)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '✅ Sudah Hadir',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF16A34A),
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
            if (_attendanceLoadError != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Text(_attendanceLoadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loadRealAttendanceData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ] else if (_isLoadingAttendance) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                ),
              ),
            ] else if (widget.canManageClassAttendance && _activeTab == 1) ...[
              ClassAttendanceRecapView(
                isDark: isDark,
                allClassLogs: _allClassLogs,
                students: _students,
                onShowGenerateQr: () => _showGenerateQrModal(context),
                onShowClassAttendanceModal: _showClassAttendanceModal,
                onConfirmResetAllAttendance: _confirmResetAllAttendance,
              ),
            ] else ...[
              PersonalAttendanceView(
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
                history: _history,
                courses: _courses,
                onShowScanQr: () => _showScanQrModal(context),
                onShowAbsenceRequest: (ctx, {preselectedCourse, preselectedPertemuan}) => _showAbsenceRequestSheet(
                  ctx,
                  preselectedCourse: preselectedCourse,
                  preselectedPertemuan: preselectedPertemuan,
                ),
                onConfirmResetPersonalAttendance: _confirmResetPersonalAttendance,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStartAttendanceHeroCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E40AF), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFBBF24)),
                    SizedBox(width: 5),
                    Text(
                      'PENGURUS KELAS / DOSEN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.qr_code_2_rounded, size: 28, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Buka Sesi Presensi Kuliah',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate QR Code dinamis dan kode PIN 4 digit untuk presensi mahasiswa di kelas hari ini secara realtime.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showGenerateQrModal(context),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text(
                    'Buka Presensi QR',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E40AF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showClassAttendanceModal,
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text(
                  'Input Manual',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
