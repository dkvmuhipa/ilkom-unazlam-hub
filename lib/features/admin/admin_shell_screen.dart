import 'package:flutter/material.dart';
import '../../core/services/dummy_data.dart';

class AdminShellScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSwitchToStudentView;

  const AdminShellScreen({
    super.key,
    required this.onLogout,
    required this.onSwitchToStudentView,
  });

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedMenu = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _menuTitles = [
    'Dashboard Sistem',
    'Data Kelas',
    'Data Mahasiswa',
    'Data Dosen',
    'Mata Kuliah',
    'Tahun Akademik',
    'Manajemen Akun',
    'Role & Permission',
    'Laporan & Rekap',
    'Pengaturan Sistem',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF111827)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ADMINISTRATOR',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _menuTitles[_selectedMenu],
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Switch to Student View Button
          TextButton.icon(
            onPressed: widget.onSwitchToStudentView,
            icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF5B3DE8)),
            label: const Text(
              'Mode Mahasiswa',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5B3DE8),
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF3F0FF),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildBodyContent(),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_selectedMenu) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildDataKelasTab();
      case 2:
      case 6:
        return _buildDataMahasiswaDanAkunTab();
      case 3:
        return _buildDataDosenTab();
      case 4:
        return _buildMataKuliahTab();
      case 5:
        return _buildTahunAkademikTab();
      case 7:
        return _buildRolePermissionTab();
      case 8:
        return _buildLaporanTab();
      case 9:
        return _buildPengaturanTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Admin Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFDC2626), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Admin',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ILKOM UNAZLAM Hub',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(0, 'Dashboard', Icons.dashboard_outlined),
                  _buildDrawerItem(1, 'Data Kelas', Icons.school_outlined),
                  _buildDrawerItem(2, 'Data Mahasiswa', Icons.people_alt_outlined),
                  _buildDrawerItem(3, 'Data Dosen', Icons.badge_outlined),
                  _buildDrawerItem(4, 'Mata Kuliah', Icons.menu_book_outlined),
                  _buildDrawerItem(5, 'Tahun Akademik', Icons.calendar_month_outlined),
                  _buildDrawerItem(6, 'Manajemen Akun', Icons.manage_accounts_outlined),
                  _buildDrawerItem(7, 'Role & Permission', Icons.security_outlined),
                  _buildDrawerItem(8, 'Laporan & Rekap', Icons.bar_chart_outlined),
                  _buildDrawerItem(9, 'Pengaturan Sistem', Icons.settings_outlined),
                ],
              ),
            ),

            // Drawer Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: widget.onSwitchToStudentView,
                    leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF5B3DE8)),
                    title: const Text('Buka Tampilan Mahasiswa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8))),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    onTap: widget.onLogout,
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                    title: const Text('Keluar dari Akun Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = _selectedMenu == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF3F0FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF6B7280),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFF374151),
          ),
        ),
        onTap: () {
          setState(() => _selectedMenu = index);
          Navigator.pop(context); // Close drawer
        },
      ),
    );
  }

  // 1. DASHBOARD TAB
  Widget _buildDashboardTab() {
    final totalMahasiswa = DummyData.students.where((s) => s.role == 'MAHASISWA').length;
    final totalDosen = DummyData.courses.map((c) => c.dosen).toSet().length;
    final totalMK = DummyData.courses.length;
    final ketuaKelas = DummyData.students.firstWhere(
      (s) => s.jabatan == 'Ketua Kelas',
      orElse: () => DummyData.students.first,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Welcome Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                blurRadius: 16,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'SISTEM ADMINISTRATOR',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Sistem Normal',
                          style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Selamat Datang, Administrator!',
                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Panel kendali utama master data, mahasiswa, dosen, mata kuliah, dan struktur kepengurusan kelas S1 Ilmu Komunikasi FISIP UNAZLAM.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4 KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Mahasiswa',
                count: '$totalMahasiswa',
                subtitle: '23 Akun Aktif',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF5B3DE8),
                bgColor: const Color(0xFFF3F0FF),
                onTap: () => setState(() => _selectedMenu = 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Mata Kuliah',
                count: '$totalMK MK',
                subtitle: 'Semester 1 Ganjil',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                onTap: () => setState(() => _selectedMenu = 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Dosen Pengampu',
                count: '$totalDosen Dosen',
                subtitle: 'FISIP UNAZLAM',
                icon: Icons.badge_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFDCFCE7),
                onTap: () => setState(() => _selectedMenu = 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Ketua Kelas',
                count: ketuaKelas.nama.split(' ').first,
                subtitle: 'Jabatan Aktif 👑',
                icon: Icons.stars_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                onTap: () => setState(() => _selectedMenu = 7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Administrative Actions
        const Text(
          'Aksi Cepat Administrator',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildActionTile(
                title: 'Tetapkan Struktur Pengurus Kelas',
                subtitle: 'Atur Ketua Kelas, Wakil, Bendahara, dan Sekretaris',
                icon: Icons.how_to_reg_rounded,
                onTap: () => setState(() => _selectedMenu = 7),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildActionTile(
                title: 'Kelola Jadwal & Ruang Kuliah',
                subtitle: 'Edit waktu sesi sore (15.30) dan malam (18.30) FISIP',
                icon: Icons.schedule_rounded,
                onTap: () => setState(() => _selectedMenu = 4),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildActionTile(
                title: 'Cadangkan / Backup Data Kelas',
                subtitle: 'Unduh seluruh data absensi, tugas, dan mahasiswa',
                icon: Icons.cloud_download_outlined,
                onTap: () => setState(() => _selectedMenu = 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF5B3DE8), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
    );
  }

  // 2. DATA KELAS TAB
  Widget _buildDataKelasTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kelas S1 Ilmu Komunikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Aktif Berjalan', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Fakultas', 'Ilmu Sosial dan Ilmu Politik (FISIP)'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Program Studi', 'S1 Ilmu Komunikasi'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Tahun Masuk / Angkatan', '2026 (Semester 1)'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Total Mahasiswa Terdaftar', '23 Orang'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Ruang Kuliah Tetap', 'Ruang A1, Ruang A2, Ruang B1'),
            ],
          ),
        ),
      ],
    );
  }

  // 3 & 7. DATA MAHASISWA & MANAJEMEN AKUN
  Widget _buildDataMahasiswaDanAkunTab() {
    final students = DummyData.students.where((s) => s.role == 'MAHASISWA').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total ${students.length} Mahasiswa', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form Tambah Mahasiswa Baru')),
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Tambah Mahasiswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List
        ...students.map((s) {
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF3F0FF),
                  child: Text(
                    s.nama.isNotEmpty ? s.nama[0] : 'M',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5B3DE8)),
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
                              s.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                            ),
                          ),
                          if (s.jabatan != 'Mahasiswa') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: s.jabatan == 'Ketua Kelas'
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.jabatan,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: s.jabatan == 'Ketua Kelas' ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('NIM: ${s.nim} • ${s.email}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                // Toggle Aktif / Nonaktif
                Switch(
                  value: s.isAktif,
                  activeThumbColor: const Color(0xFF16A34A),
                  onChanged: (val) {
                    setState(() {
                      s.isAktif = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Akun ${s.nama} diubah menjadi: ${val ? "Aktif" : "Nonaktif"}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 4. DATA DOSEN TAB
  Widget _buildDataDosenTab() {
    final lecturers = DummyData.courses.map((c) => {'name': c.dosen, 'phone': c.dosenWa, 'mk': c.nama}).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Dosen Pengampu Semester 1', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ...lecturers.map((lec) {
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
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lec['name'] ?? '-',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 2),
                      Text('MK: ${lec['mk']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF5B3DE8), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('WhatsApp: ${lec['phone'] ?? "-"}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 5. MATA KULIAH TAB
  Widget _buildMataKuliahTab() {
    final courses = DummyData.courses;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total ${courses.length} Mata Kuliah', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form Tambah Mata Kuliah')),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tambah MK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3DE8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...courses.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.nama, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(8)),
                      child: Text('${c.sks} SKS', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Kode: ${c.kode} • Dosen: ${c.dosen}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563))),
                const SizedBox(height: 4),
                Text('Jadwal: ${c.hari}, ${c.jamMulai} - ${c.jamSelesai} WITA • Ruangan: ${c.ruangan}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 6. TAHUN AKADEMIK TAB
  Widget _buildTahunAkademikTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Konfigurasi Semester Berjalan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _buildDetailRow('Tahun Akademik', '2026 / 2027'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Semester Aktif', 'Semester 1 (Ganjil)'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Tanggal Mulai Perkuliahan', '1 September 2026'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Perkiraan UTS', '20 - 25 Oktober 2026'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Perkiraan UAS', '15 - 22 Desember 2026'),
            ],
          ),
        ),
      ],
    );
  }

  // 7. ROLE & PERMISSION MATRIX TAB
  Widget _buildRolePermissionTab() {
    final students = DummyData.students.where((s) => s.role == 'MAHASISWA').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Permission Matrix Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF5B3DE8), size: 20),
                  SizedBox(width: 8),
                  Text('Matriks Hak Akses Berdasarkan Jabatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              _buildMatrixRow('Ketua Kelas 👑', 'Absensi Kelas, Pengumuman, Agenda, Kelola Tugas'),
              const Divider(height: 14, color: Color(0xFFF3F4F6)),
              _buildMatrixRow('Bendahara 💰', 'Input Kas Masuk/Keluar, Rekap Keuangan, Update QRIS'),
              const Divider(height: 14, color: Color(0xFFF3F4F6)),
              _buildMatrixRow('Sekretaris 📝', 'Kelola Agenda Kelas, Notulensi, Dokumen Materi'),
              const Divider(height: 14, color: Color(0xFFF3F4F6)),
              _buildMatrixRow('Mahasiswa 🎓', 'Lihat Jadwal, Tugas Pribadi, Absensi Mandiri, Baca Pengumuman'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Assign Jabatan Section
        const Text('Atur Jabatan Mahasiswa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Admin dapat menetapkan jabatan struktural untuk masing-masing mahasiswa.', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
        const SizedBox(height: 14),

        ...students.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 2),
                      Text('NIM: ${s.nim}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                // Dropdown Jabatan
                DropdownButton<String>(
                  value: s.jabatan,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
                  items: ['Mahasiswa', 'Ketua Kelas', 'Wakil Ketua', 'Bendahara', 'Sekretaris', 'Koordinator Perlengkapan']
                      .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                      .toList(),
                  onChanged: (newJabatan) {
                    if (newJabatan != null) {
                      setState(() {
                        s.jabatan = newJabatan;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Jabatan ${s.nama} diubah menjadi $newJabatan!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMatrixRow(String role, String access) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(role, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        const SizedBox(height: 2),
        Text(access, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
      ],
    );
  }

  // 8. LAPORAN & REKAP TAB
  Widget _buildLaporanTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rekapitulasi Perkuliahan Semester 1', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _buildDetailRow('Tingkat Kehadiran Rata-rata', '92.4% (Sangat Baik)'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Tugas Diberikan', '${DummyData.assignments.length} Tugas'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Pengumuman Diposting', '${DummyData.announcements.length} Informasi'),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              _buildDetailRow('Total Saldo Kas Kelas', 'Rp ${DummyData.totalKasSaldo}'),
            ],
          ),
        ),
      ],
    );
  }

  // 9. PENGATURAN SISTEM TAB
  Widget _buildPengaturanTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operasional Sistem & Data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_download_rounded, color: Color(0xFF5B3DE8)),
                title: const Text('Export Seluruh Data (JSON/CSV)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Unduh cadangan data mahasiswa, absensi & jadwal', style: TextStyle(fontSize: 11)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil di-export ke format JSON!')),
                  );
                },
              ),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sync_rounded, color: Color(0xFF10B981)),
                title: const Text('Sinkronisasi Database Supabase', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Perbarui cache data lokal dengan server', style: TextStyle(fontSize: 11)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database Supabase tersinkronisasi!')),
                  );
                },
              ),
              const Divider(height: 16, color: Color(0xFFF3F4F6)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFFD97706)),
                title: const Text('Reset Password Akun Mahasiswa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Kembalikan password mahasiswa ke default NIM', style: TextStyle(fontSize: 11)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password akun disetel ulang ke default.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
      ],
    );
  }
}
