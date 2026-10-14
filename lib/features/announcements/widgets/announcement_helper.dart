import 'package:flutter/material.dart';

class AnnouncementCategoryStyle {
  final String label;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  const AnnouncementCategoryStyle({
    required this.label,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

class AnnouncementHelper {
  static AnnouncementCategoryStyle getCategoryStyle(String category) {
    final lower = category.toLowerCase().trim();

    if (lower.contains('penting') || lower.contains('darurat') || lower.contains('urgent')) {
      return const AnnouncementCategoryStyle(
        label: 'PENTING',
        primaryColor: Color(0xFFDC2626), // Red 600
        backgroundColor: Color(0xFFFEF2F2), // Red 50
        borderColor: Color(0xFFFECACA), // Red 200
        icon: Icons.priority_high_rounded,
      );
    }

    if (lower.contains('akademik') || lower.contains('fakultas') || lower.contains('prodi')) {
      return const AnnouncementCategoryStyle(
        label: 'AKADEMIK',
        primaryColor: Color(0xFF0284C7), // Sky 600
        backgroundColor: Color(0xFFF0F9FF), // Sky 50
        borderColor: Color(0xFFBAE6FD), // Sky 200
        icon: Icons.school_rounded,
      );
    }

    if (lower.contains('dosen') || lower.contains('jadwal') || lower.contains('kuliah')) {
      return const AnnouncementCategoryStyle(
        label: 'DOSEN & KULIAH',
        primaryColor: Color(0xFF7C3AED), // Violet 600
        backgroundColor: Color(0xFFF5F3FF), // Violet 50
        borderColor: Color(0xFFDDD6FE), // Violet 200
        icon: Icons.record_voice_over_rounded,
      );
    }

    // Default: Kelas / Organisasi / Komunitas
    return const AnnouncementCategoryStyle(
      label: 'KELAS & ANGKATAN',
      primaryColor: Color(0xFF059669), // Emerald 600
      backgroundColor: Color(0xFFECFDF5), // Emerald 50
      borderColor: Color(0xFFA7F3D0), // Emerald 200
      icon: Icons.groups_rounded,
    );
  }

  static String formatFriendlyDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(dt.year, dt.month, dt.day);
    final differenceDays = today.difference(aDate).inDays;

    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minuteStr';

    if (differenceDays == 0) {
      return 'Hari ini, $timeStr WIB';
    } else if (differenceDays == 1) {
      return 'Kemarin, $timeStr WIB';
    } else if (differenceDays < 7) {
      const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      return '${days[dt.weekday]}, $timeStr WIB';
    } else {
      const months = [
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
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    }
  }

  static String formatFullDate(DateTime dt) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year} • $hourStr:$minuteStr WIB';
  }

  static String estimateReadingTime(String text) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (wordCount / 160).ceil();
    return minutes <= 1 ? '1 mnt baca' : '$minutes mnt baca';
  }
}
