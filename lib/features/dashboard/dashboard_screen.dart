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
  final Function(String nim)? onSwitchSimulation;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
    this.onOpenDrawer,
    this.userName,
    this.userNim,
    this.onSwitchSimulation,
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

  void _showSimulationPicker(BuildContext context, StudentProfile currentStudent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: Color(0xFF5B3DE8), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Simulasi Fitur Jabatan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih profil untuk menguji antarmuka & fitur khusus masing-masing jabatan:',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              _buildSimulationTile(
                icon: Icons.military_tech_rounded,
                title: 'Nur Farida',
                roleSubtitle: 'Ketua Kelas • Ilmu Komunikasi',
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                isSelected: currentStudent.isKetuaKelas,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSwitchSimulation?.call('260250023');
                },
              ),
              _buildSimulationTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Alya Nabilah',
                roleSubtitle: 'Bendahara Kelas • Semester 1',
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                isSelected: currentStudent.isBendahara,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSwitchSimulation?.call('260250005');
                },
              ),
              _buildSimulationTile(
                icon: Icons.description_rounded,
                title: 'Stefani',
                roleSubtitle: 'Sekretaris Kelas • Semester 1',
                color: const Color(0xFF6D28D9),
                bgColor: const Color(0xFFEDE9FE),
                isSelected: currentStudent.isSekretaris,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSwitchSimulation?.call('260250025');
                },
              ),
              _buildSimulationTile(
                icon: Icons.school_rounded,
                title: 'Happy Helen',
                roleSubtitle: 'Mahasiswa Biasa • Semester 1',
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                isSelected: currentStudent.isMahasiswa && !currentStudent.isKetuaKelas && !currentStudent.isBendahara && !currentStudent.isSekretaris,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSwitchSimulation?.call('260250001');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimulationTile({
    required IconData icon,
    required String title,
    required String roleSubtitle,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? bgColor.withValues(alpha: 0.5) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE5E7EB),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        subtitle: Text(roleSubtitle, style: TextStyle(fontSize: 11, color: isSelected ? color : const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: color, size: 20) : null,
      ),
    );
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
              // TOP HEADER WITH GREETING & ROLE PILL
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo,',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                firstName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('👋', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: student.isKetuaKelas
                                ? const Color(0xFFD97706)
                                : (student.isBendahara
                                    ? const Color(0xFF16A34A)
                                    : (student.isSekretaris ? const Color(0xFF6D28D9) : const Color(0xFF5B3DE8))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Role simulation quick badge button
                      InkWell(
                        onTap: () => _showSimulationPicker(context, student),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                student.isKetuaKelas
                                    ? '👑 Ketua'
                                    : (student.isBendahara
                                        ? '💰 Bendahara'
                                        : (student.isSekretaris ? '📝 Sekretaris' : '🎓 Mahasiswa')),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF5B3DE8)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Notification Bell
                      InkWell(
                        onTap: () => widget.onNavigateTab(7),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                                  width: 8,
                                  height: 8,
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
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ==========================================
              // HERO CARDS DYNAMIC BASED ON JABATAN
              // ==========================================
              if (student.isBendahara) ...[
                // BENDAHARA HERO CARD: KAS KELAS (Image 3)
                _buildBendaharaHeroKasCard(context),
              ] else if (student.isSekretaris) ...[
                // SEKRETARIS HERO CARD: AGENDA HARI INI (Image 1)
                _buildSekretarisHeroAgendaCard(context),
              ] else ...[
                // KETUA KELAS & MAHASISWA HERO CAROUSEL (Image 2)
                _buildStandardHeroCarousel(context, nearestAssignment),
              ],
              const SizedBox(height: 22),

              // ==========================================
              // MENU CEPAT DYNAMIC BASED ON JABATAN
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

              if (student.isBendahara) ...[
                // BENDAHARA QUICK MENUS (Image 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Kas Kelas',
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => widget.onNavigateTab(8),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Tambah\nPemasukan',
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      onTap: () => _showCatatKasDialog(context, isPemasukan: true),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'Tambah\nPengeluaran',
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                      onTap: () => _showCatatKasDialog(context, isPemasukan: false),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Rekap',
                      color: const Color(0xFF5B3DE8),
                      bgColor: const Color(0xFFF3F0FF),
                      onTap: () => widget.onNavigateTab(8),
                    ),
                  ],
                ),
              ] else if (student.isSekretaris) ...[
                // SEKRETARIS QUICK MENUS (Image 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickMenuItem(
                      icon: Icons.event_note_rounded,
                      label: 'Agenda',
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                      onTap: () => widget.onNavigateTab(6),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.campaign_outlined,
                      label: 'Pengumuman',
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => widget.onNavigateTab(7),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.folder_outlined,
                      label: 'Dokumen',
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      onTap: () => widget.onNavigateTab(10),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.people_alt_outlined,
                      label: 'Kelas',
                      color: const Color(0xFF5B3DE8),
                      bgColor: const Color(0xFFF3F0FF),
                      onTap: () => widget.onNavigateTab(3),
                    ),
                  ],
                ),
              ] else ...[
                // KETUA KELAS & MAHASISWA QUICK MENUS (Image 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickMenuItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Jadwal',
                      color: const Color(0xFF5B3DE8),
                      bgColor: const Color(0xFFF3F0FF),
                      onTap: () => widget.onNavigateTab(1),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.assignment_outlined,
                      label: 'Tugas',
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => widget.onNavigateTab(2),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Absensi',
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                      onTap: () => widget.onNavigateTab(5),
                    ),
                    _buildQuickMenuItem(
                      icon: Icons.people_alt_outlined,
                      label: 'Kelas',
                      color: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFEDE9FE),
                      onTap: () => widget.onNavigateTab(3),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // ==========================================
              // SPECIAL SECTION: AKSES KETUA KELAS (Image 2)
              // ==========================================
              if (student.isKetuaKelas) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.military_tech_rounded, size: 20, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Text(
                            'Akses Ketua Kelas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildKetuaShortcut(
                            icon: Icons.campaign_rounded,
                            label: 'Pengumuman',
                            onTap: () => widget.onNavigateTab(7),
                          ),
                          _buildKetuaShortcut(
                            icon: Icons.calendar_today_rounded,
                            label: 'Agenda',
                            onTap: () => widget.onNavigateTab(6),
                          ),
                          _buildKetuaShortcut(
                            icon: Icons.donut_large_rounded,
                            label: 'Rekap Kelas',
                            onTap: () => _showRekapKelasModal(context),
                          ),
                          _buildKetuaShortcut(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Kas Kelas',
                            onTap: () => widget.onNavigateTab(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ==========================================
              // SPECIAL SECTION: TRANSAKSI TERBARU (Bendahara - Image 3)
              // ==========================================
              if (student.isBendahara) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaksi Terbaru',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    ),
                    InkWell(
                      onTap: () => widget.onNavigateTab(8),
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...DummyData.treasuryTransactions.take(3).map((tx) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tx.isPemasukan ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tx.isPemasukan ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: tx.isPemasukan ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.judul, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text('${tx.tanggal.day} ${_monthName(tx.tanggal.month)} 2026 • ${tx.kategori}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        Text(
                          '${tx.isPemasukan ? "+" : "-"} Rp ${tx.nominal}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: tx.isPemasukan ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
              ],

              // ==========================================
              // PENGUMUMAN TERBARU SECTION
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

              // Announcement Card
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
                            const Text(
                              '5 Oktober 2026',
                              style: TextStyle(
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B3DE8), Color(0xFF755BF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3DE8).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text('Kas Kelas • Oktober 2026', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigateTab(8),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF5B3DE8), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Rp 750.000',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 16),
                      SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                          Text('Rp 1.250.000', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
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
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 16),
                      SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                          Text('Rp 500.000', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSekretarisHeroAgendaCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B3DE8), Color(0xFF755BF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3DE8).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  Icon(Icons.event_note_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text('Agenda Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigateTab(6),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF5B3DE8), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Rapat Persiapan Presentasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white70, size: 15),
              SizedBox(width: 6),
              Text('13.00 - 14.00 WITA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              SizedBox(width: 16),
              Icon(Icons.location_on_outlined, color: Colors.white70, size: 15),
              SizedBox(width: 4),
              Text('Ruang B2 • FISIP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardHeroCarousel(BuildContext context, Assignment? nearestAssignment) {
    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView(
            controller: _heroController,
            onPageChanged: (index) => setState(() => _currentHeroPage = index),
            children: [
              // Slide 0: Kuliah Hari Ini (matching Screen 3)
              _buildHeroCard(
                gradientColors: const [Color(0xFF5B3DE8), Color(0xFF755BF7)],
                shadowColor: const Color(0xFF5B3DE8),
                badgeIcon: Icons.school_outlined,
                badgeText: 'Kuliah Hari Ini',
                title: 'Pendidikan Pancasila',
                line1Icon: Icons.access_time_rounded,
                line1Text: '15.30 - 17.45 WITA',
                line2Icon: Icons.location_on_outlined,
                line2Text: 'Ruang A1 • Bapak Muh Fadly, S.Ag.',
                onTapArrow: () => widget.onNavigateTab(1),
              ),

              // Slide 1: Tugas Terdekat
              _buildHeroCard(
                gradientColors: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                shadowColor: const Color(0xFF4338CA),
                badgeIcon: Icons.assignment_outlined,
                badgeText: 'Tugas Terdekat',
                title: nearestAssignment?.judul ?? 'Makalah Analisis Nilai Pancasila',
                line1Icon: Icons.calendar_today_outlined,
                line1Text: 'Deadline: 8 Oktober 2026',
                line2Icon: Icons.book_outlined,
                line2Text: nearestAssignment?.courseName ?? 'Pendidikan Pancasila',
                onTapArrow: () => widget.onNavigateTab(2),
              ),

              // Slide 2: Status Presensi
              _buildHeroCard(
                gradientColors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                shadowColor: const Color(0xFF0F766E),
                badgeIcon: Icons.fact_check_outlined,
                badgeText: 'Status Presensi',
                title: '90% Kehadiran Perkuliahan',
                line1Icon: Icons.check_circle_outline,
                line1Text: '9 Hadir • 1 Izin • 0 Alpa',
                line2Icon: Icons.info_outline_rounded,
                line2Text: 'Total 10 Sesi Berjalan (Aman)',
                onTapArrow: () => widget.onNavigateTab(5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isSelected = index == _currentHeroPage;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 18 : 6,
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
    required IconData badgeIcon,
    required String badgeText,
    required String title,
    required IconData line1Icon,
    required String line1Text,
    required IconData line2Icon,
    required String line2Text,
    required VoidCallback onTapArrow,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: shadowColor.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(badgeIcon, color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Text(badgeText, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(line1Icon, color: Colors.white70, size: 14),
                        const SizedBox(width: 5),
                        Text(line1Text, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(line2Icon, color: Colors.white70, size: 14),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(line2Text, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onTapArrow,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Center(
                    child: Icon(Icons.arrow_forward_rounded, color: gradientColors.first, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKetuaShortcut({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFB45309), size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)),
              child: Center(child: Icon(icon, color: color, size: 24)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return m[month];
  }
}
