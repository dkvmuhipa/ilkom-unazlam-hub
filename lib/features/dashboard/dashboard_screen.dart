import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../core/services/supabase_repository.dart';
import '../../core/widgets/scale_button.dart';
import '../../core/widgets/universal_search_modal.dart';
import '../../models/models.dart';
import '../announcements/announcements_screen.dart';
import '../attendance/attendance_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final VoidCallback? onOpenDrawer;
  final String? userName;
  final String? userNim;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
    this.onOpenDrawer,
    this.userName,
    this.userNim,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _heroController;
  int _currentHeroPage = 0;
  List<Map<String, dynamic>> _realAttendanceLogs = [];

  @override
  void initState() {
    super.initState();
    _heroController = PageController(viewportFraction: 0.92);
    _loadDashboardAttendance();
  }

  Future<void> _loadDashboardAttendance() async {
    try {
      final logs = await SupabaseRepository.getAttendanceLogs();
      if (mounted) {
        setState(() {
          _realAttendanceLogs = logs;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _showRekapKelasModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final totalSessions = _realAttendanceLogs.length;
        final totalHadir = _realAttendanceLogs
            .where(
              (l) => (l['status'] ?? '').toString().toLowerCase() == 'hadir',
            )
            .length;
        final totalIzin = _realAttendanceLogs
            .where(
              (l) => (l['status'] ?? '').toString().toLowerCase() == 'izin',
            )
            .length;
        final totalSakit = _realAttendanceLogs
            .where(
              (l) => (l['status'] ?? '').toString().toLowerCase() == 'sakit',
            )
            .length;
        final totalAlpa = _realAttendanceLogs
            .where(
              (l) => (l['status'] ?? '').toString().toLowerCase() == 'alpa',
            )
            .length;

        final avgPct = totalSessions > 0
            ? ((totalHadir / totalSessions) * 100).round()
            : 100;
        final students = DummyData.students
            .where((s) => s.role != 'ADMIN')
            .toList();

        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekap Kelas',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Rekap Keseluruhan Pertemuan Perkuliahan',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Donut Chart Card (matching Screen 8 in Ketua Kelas mockup)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      // Donut Ring
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: totalSessions > 0
                                    ? (totalHadir / totalSessions)
                                    : 1.0,
                                strokeWidth: 10,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF5B3DE8),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$avgPct%',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  'Rata-rata\nKehadiran',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade500,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4 Stat Counters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCounter(
                            '$totalHadir',
                            'Hadir',
                            const Color(0xFF10B981),
                          ),
                          _buildStatCounter(
                            '$totalIzin',
                            'Izin',
                            const Color(0xFFF59E0B),
                          ),
                          _buildStatCounter(
                            '$totalSakit',
                            'Sakit',
                            const Color(0xFF0284C7),
                          ),
                          _buildStatCounter(
                            '$totalAlpa',
                            'Alpa',
                            const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Daftar Kehadiran Mahasiswa (${students.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      final sLogs = _realAttendanceLogs
                          .where((l) => l['student_nim'] == s.nim)
                          .toList();
                      final sHadir = sLogs
                          .where(
                            (l) =>
                                (l['status'] ?? '').toString().toLowerCase() ==
                                'hadir',
                          )
                          .length;
                      final int pctNum = sLogs.isNotEmpty
                          ? ((sHadir / sLogs.length) * 100).round()
                          : 100;
                      final isSafe = pctNum >= 75;
                      final color = isSafe
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withValues(alpha: 0.12),
                              child: Text(
                                s.nama.isNotEmpty ? s.nama[0] : 'M',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    sLogs.isNotEmpty
                                        ? '${s.nim} • $sHadir/${sLogs.length} Pertemuan'
                                        : '${s.nim} • Semester 1',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              sLogs.isNotEmpty ? '$pctNum%' : '100%',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCounter(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showCatatKasDialog(BuildContext context, {required bool isPemasukan}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            Text(
              isPemasukan ? 'Tambah Pemasukan Kas' : 'Tambah Pengeluaran Kas',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Keterangan',
                hintText: isPemasukan
                    ? 'Misal: Iuran Kas Bulan Oktober'
                    : 'Misal: Beli Spidol & Penghapus',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah (Rp)',
                hintText: 'Misal: 50000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                if (titleController.text.isNotEmpty && amount > 0) {
                  setState(() {
                    DummyData.treasuryTransactions.insert(
                      0,
                      TreasuryTransaction(
                        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                        judul: titleController.text.trim(),
                        nominal: amount,
                        isPemasukan: isPemasukan,
                        kategori: isPemasukan ? 'Iuran Kelas' : 'Operasional',
                        tanggal: DateTime.now(),
                        pencatat: 'Bendahara Kelas',
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${isPemasukan ? "Pemasukan" : "Pengeluaran"} berhasil dicatat!',
                      ),
                      backgroundColor: isPemasukan
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPemasukan
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Simpan Transaksi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resolve current student
    final student = DummyData.students.firstWhere(
      (s) => s.nim == widget.userNim,
      orElse: () => DummyData.students.firstWhere(
        (s) => s.jabatan == 'Ketua Kelas',
        orElse: () => DummyData.students.first,
      ),
    );

    // Dynamic greeting texts
    final firstName = student.nama.split(' ').first;
    final subtitleText = '${student.prodi} • Semester ${student.semester}';

    final latestAnnouncement = DummyData.announcements.isNotEmpty
        ? DummyData.announcements.first
        : null;
    final activeAssignments = DummyData.assignments
        .where((a) => a.status != 'selesai')
        .toList();
    final nearestAssignment = activeAssignments.isNotEmpty
        ? activeAssignments.first
        : (DummyData.assignments.isNotEmpty
              ? DummyData.assignments.first
              : null);

    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat pagi'
        : hour < 15
        ? 'Selamat siang'
        : hour < 19
        ? 'Selamat sore'
        : 'Selamat malam';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. TOP HEADER (CLEAN & RESPONSIVE - NO OVERFLOW)
              // ==========================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          firstName,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F0FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    student.isKetuaKelas
                                        ? Icons.workspace_premium_outlined
                                        : student.isBendahara
                                        ? Icons.account_balance_wallet_outlined
                                        : student.isSekretaris
                                        ? Icons.description_outlined
                                        : Icons.school_outlined,
                                    size: 12,
                                    color: const Color(0xFF5B3DE8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    student.isKetuaKelas
                                        ? 'Ketua Kelas'
                                        : student.isBendahara
                                        ? 'Bendahara'
                                        : student.isSekretaris
                                        ? 'Sekretaris'
                                        : 'Mahasiswa',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5B3DE8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              subtitleText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Search Quick Button
                  InkWell(
                    onTap: () => UniversalSearchModal.show(
                      context,
                      onNavigateTab: widget.onNavigateTab,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell
                  InkWell(
                    onTap: () => widget.onNavigateTab(11),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: Color(0xFF111827),
                          ),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.onOpenDrawer != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.onOpenDrawer,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          size: 20,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // ==========================================
              // LIVE ACTIVE ATTENDANCE SESSION ALERT (CLASS-WIDE)
              // ==========================================
              if (AttendanceScreen.currentSession != null &&
                  !AttendanceScreen.currentSession!.isExpired) ...[
                Builder(
                  builder: (context) {
                    final session = AttendanceScreen.currentSession!;
                    final secsLeft = session.remainingSeconds;
                    final hasAttended = session.attendedNims.contains(
                      student.nim,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.25),
                            blurRadius: 12,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
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
                                      'SESI PRESENSI DIBUKA',
                                      style: TextStyle(
                                        fontSize: 9.5,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 13,
                                      color: Color(0xFFFBBF24),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${secsLeft ~/ 60}:${(secsLeft % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFFBBF24),
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
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pertemuan ke-${session.pertemuanKe} • Token: ${session.token}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  hasAttended
                                      ? '✅ Anda Sudah Hadir'
                                      : '${session.attendedNims.length} Mahasiswa Hadir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: hasAttended
                                        ? const Color(0xFF4ADE80)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Tombol Lihat QR Code
                              TextButton.icon(
                                onPressed: () =>
                                    AttendanceScreen.showActiveQrModal(
                                      context,
                                      session: session,
                                    ),
                                icon: const Icon(
                                  Icons.qr_code_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Lihat QR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Tombol Scan Langsung jika belum hadir
                              if (!hasAttended)
                                ElevatedButton.icon(
                                  onPressed: () => widget.onNavigateTab(5),
                                  icon: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Absen',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // ==========================================
              // 2. HERO CARD (STREAMLINED & DYNAMIC)
              // ==========================================
              if (student.isBendahara) ...[
                _buildBendaharaHeroKasCard(context),
              ] else if (student.isSekretaris) ...[
                _buildSekretarisHeroAgendaCard(context),
              ] else ...[
                _buildStandardHeroCarousel(context, nearestAssignment),
              ],
              const SizedBox(height: 22),

              // ==========================================
              // 3. MENU CEPAT (4 PRIMARY PILLARS)
              // ==========================================
              const Text(
                'Menu Cepat',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickMenuItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Presensi QR',
                    color: const Color(0xFF5B3DE8),
                    bgColor: const Color(0xFFF3F0FF),
                    onTap: () => widget.onNavigateTab(5),
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Jadwal Kuliah',
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                    onTap: () => widget.onNavigateTab(1),
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.assignment_outlined,
                    label: 'Tugas Kuliah',
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFEF3C7),
                    onTap: () => widget.onNavigateTab(2),
                  ),
                  _buildQuickMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Kas Kelas',
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                    onTap: () => widget.onNavigateTab(8),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 4. KETUA KELAS QUICK COMMAND BAR (SLEEK & COMPACT)
              // ==========================================
              if (student.isKetuaKelas) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B3DE8).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 16,
                                color: Color(0xFF5B3DE8),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Aksi Cepat Ketua',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _showRekapKelasModal(context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.donut_large_rounded,
                                    size: 13,
                                    color: Color(0xFF5B3DE8),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Rekap Presensi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5B3DE8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKetuaChip(
                              icon: Icons.campaign_rounded,
                              label: 'Pengumuman',
                              color: const Color(0xFF5B3DE8),
                              bgColor: const Color(0xFFF3F0FF),
                              onTap: () => widget.onNavigateTab(7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildKetuaChip(
                              icon: Icons.event_note_rounded,
                              label: 'Agenda',
                              color: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFE0F2FE),
                              onTap: () => widget.onNavigateTab(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildKetuaChip(
                              icon: Icons.how_to_vote_rounded,
                              label: 'Voting',
                              color: const Color(0xFFF59E0B),
                              bgColor: const Color(0xFFFEF3C7),
                              onTap: () => widget.onNavigateTab(12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildKetuaChip(
                              icon: Icons.groups_rounded,
                              label: 'Anggota',
                              color: const Color(0xFF10B981),
                              bgColor: const Color(0xFFECFDF5),
                              onTap: () => widget.onNavigateTab(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ==========================================
              // 5. PENGINGAT DEADLINE TERDEKAT (COMPACT)
              // ==========================================
              _buildReminderCard(context, nearestAssignment),
              const SizedBox(height: 20),

              // ==========================================
              // 6. PENGUMUMAN TERBARU
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengumuman Terbaru',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                  ),
                  InkWell(
                    onTap: () => widget.onNavigateTab(7),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B3DE8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: () {
                  if (latestAnnouncement != null) {
                    AnnouncementsScreen.showAnnouncementDetail(
                      context,
                      latestAnnouncement,
                    );
                  } else {
                    widget.onNavigateTab(7);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: latestAnnouncement != null
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          latestAnnouncement != null
                              ? Icons.campaign_rounded
                              : Icons.info_outline_rounded,
                          color: latestAnnouncement != null
                              ? const Color(0xFFB45309)
                              : const Color(0xFF5B3DE8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestAnnouncement?.judul ??
                                  'Belum Ada Pengumuman Baru',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              latestAnnouncement?.isi ?? 'Informasi akademik dan pengumuman kelas akan disampaikan di sini.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF4B5563),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              latestAnnouncement != null
                                  ? '${latestAnnouncement.createdAt.day} ${_monthName(latestAnnouncement.createdAt.month)} ${latestAnnouncement.createdAt.year}'
                                  : 'Update Terkini',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HERO CARDS
  // ==========================================
  Widget _buildBendaharaHeroKasCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Glowing Radial Orbs
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Watermark
            Positioned(
              right: -10,
              bottom: -15,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 130,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'KAS KELAS • OKTOBER 2026',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onNavigateTab(8),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Detail',
                                style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF4F46E5),
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Rp ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        _formatNumber(DummyData.totalKasSaldo),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_downward_rounded,
                                color: Color(0xFF34D399),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pemasukan',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatNumber(DummyData.totalKasPemasukan)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_upward_rounded,
                                color: Color(0xFFF87171),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatNumber(DummyData.totalKasPengeluaran)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showCatatKasDialog(context, isPemasukan: true),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text(
                            'Catat Masuk',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF10B981),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showCatatKasDialog(context, isPemasukan: false),
                          icon: const Icon(Icons.remove_rounded, size: 15),
                          label: const Text(
                            'Catat Keluar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.22,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }

  Widget _buildSekretarisHeroAgendaCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: -15,
              child: Icon(
                Icons.event_note_rounded,
                size: 130,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'AGENDA HARI INI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onNavigateTab(6),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Detail',
                                style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF4F46E5),
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final daysOfWeek = [
                        'Senin',
                        'Selasa',
                        'Rabu',
                        'Kamis',
                        'Jumat',
                        'Sabtu',
                        'Minggu',
                      ];
                      final todayName = daysOfWeek[DateTime.now().weekday - 1];
                      final todayCourses = DummyData.courses
                          .where(
                            (c) =>
                                c.hari.toLowerCase() == todayName.toLowerCase(),
                          )
                          .toList();
                      final c = todayCourses.isNotEmpty
                          ? todayCourses.first
                          : null;

                      if (c == null) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tidak Ada Perkuliahan Hari Ini',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Agenda kelas kosong. Waktu luang untuk belajar mandiri.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.nama,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '${c.jamMulai} - ${c.jamSelesai} WITA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '${c.ruangan} • FISIP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardHeroCarousel(
    BuildContext context,
    Assignment? nearestAssignment,
  ) {
    // Dynamic course for today
    final daysOfWeek = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final todayDayName = daysOfWeek[DateTime.now().weekday - 1];
    final todayCourses = DummyData.courses
        .where((c) => c.hari.toLowerCase() == todayDayName.toLowerCase())
        .toList();
    final todayCourse = todayCourses.isNotEmpty ? todayCourses.first : null;

    final hasUpcoming = nearestAssignment != null;
    final totalAttendanceSessions = _realAttendanceLogs.length;
    final totalHadir = _realAttendanceLogs
        .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'hadir')
        .length;
    final totalIzin = _realAttendanceLogs
        .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'izin')
        .length;
    final totalAlpa = _realAttendanceLogs
        .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'alpa')
        .length;

    return Column(
      children: [
        SizedBox(
          height: 192,
          child: PageView(
            controller: _heroController,
            clipBehavior: Clip.none,
            onPageChanged: (index) => setState(() => _currentHeroPage = index),
            children: [
              // Slide 0: Kuliah Hari Ini (matching Screen 3)
              _buildHeroCard(
                gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                shadowColor: const Color(0xFF4F46E5),
                watermarkIcon: Icons.school_rounded,
                badgeDotColor: todayCourse != null
                    ? const Color(0xFF34D399)
                    : const Color(0xFF9CA3AF),
                badgeText: 'KULIAH HARI INI',
                tagText: todayDayName,
                title: todayCourse?.nama ?? 'Tidak Ada Kuliah Hari Ini',
                line1Icon: Icons.access_time_filled_rounded,
                line1Text: todayCourse != null
                    ? '${todayCourse.jamMulai} - ${todayCourse.jamSelesai} WITA'
                    : 'Tidak ada sesi perkuliahan terjadwal',
                line2Icon: Icons.location_on_rounded,
                line2Text: todayCourse != null
                    ? '${todayCourse.ruangan} • ${todayCourse.dosen}'
                    : 'Manfaatkan waktu untuk belajar mandiri',
                actionLabel: 'Buka Jadwal',
                onTapArrow: () => widget.onNavigateTab(1),
              ),

              // Slide 1: Tugas Terdekat
              _buildHeroCard(
                gradientColors: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                shadowColor: const Color(0xFF1E3A8A),
                watermarkIcon: Icons.assignment_turned_in_rounded,
                badgeDotColor: hasUpcoming
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF34D399),
                badgeText: 'TUGAS TERDEKAT',
                tagText: hasUpcoming
                    ? 'Batas: ${nearestAssignment.deadline.day} ${_monthName(nearestAssignment.deadline.month)}'
                    : 'Selesai',
                title: nearestAssignment?.judul ?? 'Tidak Ada Tugas Aktif',
                line1Icon: Icons.event_available_rounded,
                line1Text: hasUpcoming
                    ? 'Deadline: ${nearestAssignment.deadline.day} ${_monthName(nearestAssignment.deadline.month)} ${nearestAssignment.deadline.year}'
                    : 'Semua tugas kuliah telah selesai',
                line2Icon: Icons.menu_book_rounded,
                line2Text: hasUpcoming
                    ? nearestAssignment.courseName
                    : 'Belum ada tugas baru yang diberikan dosen',
                actionLabel: hasUpcoming ? 'Detail Tugas' : 'Buka Tugas',
                onTapArrow: () => widget.onNavigateTab(2),
              ),

              // Slide 2: Status Presensi
              _buildHeroCard(
                gradientColors: const [Color(0xFF065F46), Color(0xFF0D9488)],
                shadowColor: const Color(0xFF065F46),
                watermarkIcon: Icons.verified_user_rounded,
                badgeDotColor: const Color(0xFF34D399),
                badgeText: 'STATUS PRESENSI',
                tagText: totalAttendanceSessions > 0
                    ? '${((totalHadir / totalAttendanceSessions) * 100).round()}% Kehadiran'
                    : '100% Kehadiran',
                title: totalAttendanceSessions > 0
                    ? '$totalHadir Hadir dari $totalAttendanceSessions Sesi'
                    : 'Performa Kehadiran Aman',
                line1Icon: Icons.check_circle_rounded,
                line1Text:
                    '$totalHadir Hadir • $totalIzin Izin • $totalAlpa Alpa',
                line2Icon: Icons.shield_rounded,
                line2Text: totalAttendanceSessions > 0
                    ? '$totalAttendanceSessions Sesi Tercatat di Supabase'
                    : 'Presensi semester 1 berjalan tertib',
                actionLabel: 'Cek Presensi',
                onTapArrow: () => widget.onNavigateTab(5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isSelected = index == _currentHeroPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 22 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5B3DE8)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required List<Color> gradientColors,
    required Color shadowColor,
    required IconData watermarkIcon,
    required Color badgeDotColor,
    required String badgeText,
    required String tagText,
    required String title,
    required IconData line1Icon,
    required String line1Text,
    required IconData line2Icon,
    required String line2Text,
    required String actionLabel,
    required VoidCallback onTapArrow,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Base Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Top-right ambient glowing radial orb
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Bottom-right secondary orb
            Positioned(
              right: 60,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Subtle Watermark Icon in background
            Positioned(
              right: -10,
              bottom: -15,
              child: Icon(
                watermarkIcon,
                size: 130,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),

            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapArrow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Status badge pill & Tag chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: badgeDotColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: badgeDotColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  badgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tagText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Center Title & Meta Details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  line1Icon,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  line1Text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  line2Icon,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  line2Text,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Bottom Row: Action pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  actionLabel,
                                  style: TextStyle(
                                    color: gradientColors.first,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: gradientColors.first,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKetuaChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: onTap,
      scaleDown: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ScaleButton(
        onTap: onTap,
        scaleDown: 0.97,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E4F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Icon(icon, color: color, size: 21)),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    Assignment? nearestAssignment,
  ) {
    if (nearestAssignment == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF16A34A),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak Ada Tugas Tertunda',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Semua tugas perkuliahan telah diselesaikan atau belum ada tugas baru.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateTab(2),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'Lihat Tugas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B3DE8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final diff = nearestAssignment.deadline.difference(DateTime.now());
    final daysLeft = diff.isNegative ? 0 : diff.inDays;
    final hoursLeft = diff.isNegative ? 0 : (diff.inHours % 24);
    final minutesLeft = diff.isNegative ? 0 : (diff.inMinutes % 60);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.alarm_outlined,
                      size: 13,
                      color: Color(0xFFFCA5A5),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'PENGINGAT DEADLINE TERDEKAT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFCA5A5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pengingat aktif! Notifikasi push dikirim 2 jam sebelum batas pengumpulan.',
                      ),
                      backgroundColor: Color(0xFF4338CA),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nearestAssignment.judul,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Mata Kuliah: ${nearestAssignment.courseName}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFC7D2FE)),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCountdownBlock(
                    daysLeft.toString().padLeft(2, '0'),
                    'HARI',
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    ':',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildCountdownBlock(
                    hoursLeft.toString().padLeft(2, '0'),
                    'JAM',
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    ':',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildCountdownBlock(
                    minutesLeft.toString().padLeft(2, '0'),
                    'MENIT',
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onNavigateTab(2),
                icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                label: const Text(
                  'Detail Tugas',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBlock(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA5B4FC),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return m[month];
  }

  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
