import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dummy_data.dart';
import '../../models/models.dart';
import '../announcements/announcements_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
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
                        Text('Rekap Kelas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                        Text('Pendidikan Pancasila • Oktober 2026', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      // Donut Ring (90% Rata-rata Kehadiran)
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: 0.90,
                                strokeWidth: 10,
                                backgroundColor: Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B3DE8)),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '90%',
                                  style: TextStyle(
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
                          _buildStatCounter('22', 'Hadir', const Color(0xFF10B981)),
                          _buildStatCounter('2', 'Izin', const Color(0xFFF59E0B)),
                          _buildStatCounter('1', 'Sakit', const Color(0xFF0284C7)),
                          _buildStatCounter('0', 'Alpha', const Color(0xFFEF4444)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Daftar Kehadiran Mahasiswa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: DummyData.students.where((s) => s.role != 'ADMIN').length,
                    itemBuilder: (ctx, i) {
                      final s = DummyData.students.where((s) => s.role != 'ADMIN').toList()[i];
                      final pct = (i % 5 == 0) ? '80%' : '100%';
                      final color = pct == '100%' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5), overflow: TextOverflow.ellipsis),
                                  Text('${s.nim} • ${pct == "100%" ? "5/5 Pertemuan" : "4/5 Pertemuan"}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            Text(
                              pct,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color),
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
        Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPemasukan ? 'Tambah Pemasukan Kas' : 'Tambah Pengeluaran Kas',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Keterangan',
                hintText: isPemasukan ? 'Misal: Iuran Kas Bulan Oktober' : 'Misal: Beli Spidol & Penghapus',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      content: Text('${isPemasukan ? "Pemasukan" : "Pengeluaran"} berhasil dicatat!'),
                      backgroundColor: isPemasukan ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPemasukan ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan Transaksi', style: TextStyle(fontWeight: FontWeight.w700)),
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
    String subtitleText;
    if (student.isKetuaKelas) {
      subtitleText = 'Ketua Kelas • Ilmu Komunikasi • Semester 1';
    } else if (student.isBendahara) {
      subtitleText = 'Bendahara Kelas • Semester 1';
    } else if (student.isSekretaris) {
      subtitleText = 'Sekretaris Kelas • Semester 1';
    } else {
      subtitleText = 'Mahasiswa • Ilmu Komunikasi • Semester 1';
    }

    final latestAnnouncement = DummyData.announcements.isNotEmpty ? DummyData.announcements.first : null;
    final activeAssignments = DummyData.assignments.where((a) => a.status != 'selesai').toList();
    final nearestAssignment = activeAssignments.isNotEmpty
        ? activeAssignments.first
        : (DummyData.assignments.isNotEmpty ? DummyData.assignments.first : null);

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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Halo, $firstName',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('👋', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: student.isKetuaKelas
                                ? const Color(0xFFD97706)
                                : (student.isBendahara
                                    ? const Color(0xFF16A34A)
                                    : (student.isSekretaris ? const Color(0xFF6D28D9) : const Color(0xFF6B7280))),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Text(
                      student.isKetuaKelas
                          ? '👑 Ketua'
                          : (student.isBendahara
                              ? '💰 Bendahara'
                              : (student.isSekretaris ? '📝 Sekretaris' : '🎓 Mahasiswa')),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell
                  InkWell(
                    onTap: () => widget.onNavigateTab(11),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF111827)),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF111827)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              Text('👑', style: TextStyle(fontSize: 14)),
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
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.donut_large_rounded, size: 13, color: Color(0xFF5B3DE8)),
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
              _buildReminderCard(context),
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
                    AnnouncementsScreen.showAnnouncementDetail(context, latestAnnouncement);
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
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Color(0xFFB45309),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestAnnouncement?.judul ?? 'Perubahan Ruang Kuliah',
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
                              latestAnnouncement?.isi ?? 'Kuliah Pendidikan Kewarganegaraan besok dipindahkan ke Ruang B2.',
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
                                  : '5 Oktober 2026',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                              Icon(Icons.arrow_forward_rounded, color: Color(0xFF4F46E5), size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70),
                      ),
                      Text(
                        '750.000',
                        style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 16),
                              SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                                  Text(
                                    'Rp 1.250.000',
                                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 16),
                              SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                                  Text(
                                    'Rp 500.000',
                                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
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
                          onPressed: () => _showCatatKasDialog(context, isPemasukan: true),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Catat Masuk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF10B981),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCatatKasDialog(context, isPemasukan: false),
                          icon: const Icon(Icons.remove_rounded, size: 15),
                          label: const Text('Catat Keluar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.22),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_note_rounded, color: Colors.white, size: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                              Icon(Icons.arrow_forward_rounded, color: Color(0xFF4F46E5), size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Rapat Persiapan Presentasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
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
                        child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        '13.00 - 14.00 WITA',
                        style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Ruang B2 • FISIP',
                        style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
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

  Widget _buildStandardHeroCarousel(BuildContext context, Assignment? nearestAssignment) {
    return Column(
      children: [
        SizedBox(
          height: 184,
          child: PageView(
            controller: _heroController,
            onPageChanged: (index) => setState(() => _currentHeroPage = index),
            children: [
              // Slide 0: Kuliah Hari Ini (matching Screen 3)
              _buildHeroCard(
                gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                shadowColor: const Color(0xFF4F46E5),
                watermarkIcon: Icons.school_rounded,
                badgeDotColor: const Color(0xFF34D399),
                badgeText: 'KULIAH HARI INI',
                tagText: 'Semester 1',
                title: 'Pendidikan Pancasila',
                line1Icon: Icons.access_time_filled_rounded,
                line1Text: '15.30 - 17.45 WITA',
                line2Icon: Icons.location_on_rounded,
                line2Text: 'Ruang A1 • Bapak Muh Fadly, S.Ag.',
                actionLabel: 'Buka Jadwal',
                onTapArrow: () => widget.onNavigateTab(1),
              ),

              // Slide 1: Tugas Terdekat
              _buildHeroCard(
                gradientColors: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                shadowColor: const Color(0xFF1E3A8A),
                watermarkIcon: Icons.assignment_turned_in_rounded,
                badgeDotColor: const Color(0xFFFBBF24),
                badgeText: 'TUGAS TERDEKAT',
                tagText: 'Batas: 8 Okt',
                title: nearestAssignment?.judul ?? 'Makalah Analisis Nilai Pancasila',
                line1Icon: Icons.event_available_rounded,
                line1Text: 'Deadline: 8 Oktober 2026',
                line2Icon: Icons.menu_book_rounded,
                line2Text: nearestAssignment?.courseName ?? 'Pendidikan Pancasila',
                actionLabel: 'Detail Tugas',
                onTapArrow: () => widget.onNavigateTab(2),
              ),

              // Slide 2: Status Presensi
              _buildHeroCard(
                gradientColors: const [Color(0xFF065F46), Color(0xFF0D9488)],
                shadowColor: const Color(0xFF065F46),
                watermarkIcon: Icons.verified_user_rounded,
                badgeDotColor: const Color(0xFF34D399),
                badgeText: 'STATUS PRESENSI',
                tagText: '90% Kehadiran',
                title: 'Performa Kehadiran Aman',
                line1Icon: Icons.check_circle_rounded,
                line1Text: '9 Hadir • 1 Izin • 0 Alpa',
                line2Icon: Icons.shield_rounded,
                line2Text: '10 Sesi Berjalan (Memenuhi Syarat UTS)',
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
                color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFD1D5DB),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Status badge pill & Tag chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
                                        color: badgeDotColor.withValues(alpha: 0.8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
                                child: Icon(line1Icon, color: Colors.white, size: 12),
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
                                child: Icon(line2Icon, color: Colors.white, size: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)),
              child: Center(child: Icon(icon, color: color, size: 24)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⏰', style: TextStyle(fontSize: 12)),
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
                      content: Text('🔔 Pengingat aktif! Notifikasi push dikirim 2 jam sebelum batas pengumpulan.'),
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
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Proposal Kampanye PR',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Mata Kuliah: Public Relations • Dosen: Dr. Siti Nurhaliza',
            style: TextStyle(fontSize: 11.5, color: Color(0xFFC7D2FE)),
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
                  _buildCountdownBlock('01', 'HARI'),
                  const SizedBox(width: 4),
                  const Text(':', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(width: 4),
                  _buildCountdownBlock('14', 'JAM'),
                  const SizedBox(width: 4),
                  const Text(':', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(width: 4),
                  _buildCountdownBlock('35', 'MENIT'),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onNavigateTab(2),
                icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                label: const Text('Detail Tugas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return m[month];
  }
}
