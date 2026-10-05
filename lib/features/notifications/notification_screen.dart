import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ClassNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String category; // 'deadline', 'announcement', 'treasury', 'attendance', 'voting'
  bool isRead;

  ClassNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final VoidCallback? onBack;

  const NotificationScreen({super.key, this.onNavigateTab, this.onBack});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedFilter = 'Semua';

  final List<ClassNotificationItem> _notifications = [
    ClassNotificationItem(
      id: 'notif_1',
      title: 'Pengingat Deadline Tugas',
      message: 'Tugas Proposal Kampanye PR mata kuliah Public Relations deadline dalam 24 jam ke depan.',
      time: '15 menit yang lalu',
      category: 'deadline',
      isRead: false,
    ),
    ClassNotificationItem(
      id: 'notif_2',
      title: 'Voting Baru Dibuka',
      message: 'Ketua Kelas membuka voting untuk menentukan Jadwal Pengganti Kuliah Pengantar Ilmu Jurnalistik.',
      time: '1 jam yang lalu',
      category: 'voting',
      isRead: false,
    ),
    ClassNotificationItem(
      id: 'notif_3',
      title: 'Pengumuman Penting',
      message: 'Kuliah Teori Komunikasi besok dimulai pukul 08:30 WITA di Ruang Lab Multimedia.',
      time: '3 jam yang lalu',
      category: 'announcement',
      isRead: false,
    ),
    ClassNotificationItem(
      id: 'notif_4',
      title: 'Iuran Kas Bulan Oktober',
      message: 'Bendahara telah membuka rekap pembayaran uang kas kelas untuk bulan Oktober (Rp 20.000).',
      time: 'Kemarin',
      category: 'treasury',
      isRead: true,
    ),
    ClassNotificationItem(
      id: 'notif_5',
      title: 'Presensi Kelas Terverifikasi',
      message: 'Kehadiran Anda pada mata kuliah Pendidikan Pancasila Sesi 5 berhasil tercatat Hadir.',
      time: '2 hari lalu',
      category: 'attendance',
      isRead: true,
    ),
  ];

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'deadline':
        return const Color(0xFFEF4444);
      case 'voting':
        return const Color(0xFF8B5CF6);
      case 'announcement':
        return const Color(0xFF3B82F6);
      case 'treasury':
        return const Color(0xFF10B981);
      case 'attendance':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'deadline':
        return Icons.timer_outlined;
      case 'voting':
        return Icons.how_to_vote_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'treasury':
        return Icons.account_balance_wallet_outlined;
      case 'attendance':
        return Icons.fact_check_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'Belum Dibaca') return !n.isRead;
      if (_selectedFilter == 'Tugas & Deadline') return n.category == 'deadline';
      if (_selectedFilter == 'Pengumuman') return n.category == 'announcement';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null || widget.onNavigateTab != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                tooltip: 'Kembali',
                onPressed: widget.onBack ?? () => widget.onNavigateTab?.call(0),
              )
            : null,
        title: Row(
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount Baru',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n.isRead = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai telah dibaca'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text(
                'Tandai Dibaca',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B3DE8)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Belum Dibaca', 'Tugas & Deadline', 'Pengumuman'].map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = f),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF5B3DE8) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
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

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada notifikasi di filter ini',
                          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final notif = filtered[i];
                      final catColor = _getCategoryColor(notif.category);
                      final catIcon = _getCategoryIcon(notif.category);

                      return Dismissible(
                        key: ValueKey(notif.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() => _notifications.removeWhere((n) => n.id == notif.id));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: notif.isRead ? Colors.white : const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: notif.isRead ? const Color(0xFFE5E7EB) : const Color(0xFFDDD6FE),
                              width: notif.isRead ? 1 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() => notif.isRead = true);
                              if (notif.category == 'deadline') {
                                widget.onNavigateTab?.call(2); // Tugas
                              } else if (notif.category == 'announcement') {
                                widget.onNavigateTab?.call(7); // Pengumuman
                              } else if (notif.category == 'treasury') {
                                widget.onNavigateTab?.call(8); // Kas
                              } else if (notif.category == 'attendance') {
                                widget.onNavigateTab?.call(5); // Absensi
                              }
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(catIcon, color: catColor, size: 20),
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
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w800,
                                                color: const Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          if (!notif.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF5B3DE8),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif.time,
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
