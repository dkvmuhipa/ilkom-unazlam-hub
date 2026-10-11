import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AuditLogItem {
  final String id;
  final String actor;
  final String role;
  final String action;
  final String details;
  final DateTime timestamp;
  final String module; // 'Kas', 'Jadwal', 'Tugas', 'Presensi', 'Pengumuman', 'Anggota'

  AuditLogItem({
    required this.id,
    required this.actor,
    required this.role,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.module,
  });
}

class AuditLogScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AuditLogScreen({super.key, this.onBack});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _selectedModule = 'Semua';

  final List<AuditLogItem> _logs = [
    AuditLogItem(
      id: 'log_1',
      actor: 'Nur Farida',
      role: 'Ketua Kelas',
      action: 'Membuka Sesi Presensi QR',
      details: 'Sesi presensi dibuka untuk mata kuliah Pendidikan Kewarganegaraan Pertemuan 5.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      module: 'Presensi',
    ),
    AuditLogItem(
      id: 'log_2',
      actor: 'Alya Nabilah',
      role: 'Bendahara',
      action: 'Mencatat Pemasukan Kas',
      details: 'Pemasukan kas bulanan Rp 100.000 dari 5 mahasiswa (Alya, Farida, Stefani, Helen, Rizki).',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      module: 'Kas',
    ),
    AuditLogItem(
      id: 'log_3',
      actor: 'Nur Farida',
      role: 'Ketua Kelas',
      action: 'Mempublikasikan Pengumuman',
      details: 'Pengumuman kategori Akademik disematkan: "Perubahan Ruang Kuliah Teori Komunikasi ke Lab".',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      module: 'Pengumuman',
    ),
    AuditLogItem(
      id: 'log_4',
      actor: 'System Admin',
      role: 'Administrator',
      action: 'Memperbarui Struktur Pengurus',
      details: 'Memperbarui penugasan pengurus kelas: Stefani diangkat menjadi Sekretaris Kelas.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      module: 'Anggota',
    ),
    AuditLogItem(
      id: 'log_5',
      actor: 'Nur Farida',
      role: 'Ketua Kelas',
      action: 'Menambahkan Tugas Baru',
      details: 'Menambahkan tugas "Proposal Kampanye PR" untuk mata kuliah Public Relations.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      module: 'Tugas',
    ),
    AuditLogItem(
      id: 'log_6',
      actor: 'Alya Nabilah',
      role: 'Bendahara',
      action: 'Mencatat Pengeluaran Kas',
      details: 'Pengeluaran kas Rp 35.000 untuk fotokopi modul & silabus kuliah.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      module: 'Kas',
    ),
  ];

  Color _getModuleColor(String mod) {
    switch (mod) {
      case 'Kas':
        return const Color(0xFF10B981);
      case 'Presensi':
        return const Color(0xFF0284C7);
      case 'Pengumuman':
        return const Color(0xFFF59E0B);
      case 'Tugas':
        return const Color(0xFF8B5CF6);
      case 'Anggota':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF1E40AF);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedModule == 'Semua'
        ? _logs
        : _logs.where((l) => l.module == _selectedModule).toList();

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
          'Audit Log Aktivitas Kelas',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Kas', 'Presensi', 'Pengumuman', 'Tugas', 'Anggota'].map((m) {
                  final isSel = _selectedModule == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedModule = m),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF1E40AF) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Log List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final log = filtered[i];
                final modColor = _getModuleColor(log.module);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: modColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.module,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: modColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    log.action,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(log.timestamp),
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.details,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.35),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Oleh: ${log.actor} (${log.role})',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                            ),
                          ],
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
    );
  }
}
