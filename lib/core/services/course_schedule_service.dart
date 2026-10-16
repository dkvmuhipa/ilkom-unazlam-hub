import 'package:intl/intl.dart';
import '../../models/models.dart';

class ScheduleDayInfo {
  final String dayName;
  final String dayLabel;
  final DateTime date;
  final int daysAhead;
  final List<Course> courses;

  const ScheduleDayInfo({
    required this.dayName,
    required this.dayLabel,
    required this.date,
    required this.daysAhead,
    required this.courses,
  });
}

class CourseScheduleService {
  static const List<String> dayNames = [
    '',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Mengembalikan nama hari dalam bahasa Indonesia untuk suatu DateTime.
  static String getDayName(DateTime date) {
    if (date.weekday >= 1 && date.weekday <= 7) {
      return dayNames[date.weekday];
    }
    return '';
  }

  /// Mengembalikan mata kuliah untuk hari ini, diurutkan berdasarkan jam mulai efektif.
  static List<Course> getTodayCourses(List<Course> allCourses, [DateTime? now]) {
    final dt = now ?? DateTime.now();
    final today = getDayName(dt);
    final list = allCourses
        .where((c) => c.hari.trim().toLowerCase() == today.toLowerCase())
        .toList();
    list.sort((a, b) => a.effectiveJamMulai.compareTo(b.effectiveJamMulai));
    return list;
  }

  /// Menghitung apakah hari ini masih ada kelas yang belum selesai.
  static bool hasRemainingCoursesToday(List<Course> todayCourses, [DateTime? now]) {
    if (todayCourses.isEmpty) return false;
    final dt = now ?? DateTime.now();
    for (final c in todayCourses) {
      if (c.isCancelledToday) continue;
      try {
        final endParts = c.effectiveJamSelesai.split(':');
        if (endParts.length == 2) {
          final endDt = DateTime(
            dt.year,
            dt.month,
            dt.day,
            int.parse(endParts[0]),
            int.parse(endParts[1]),
          );
          if (dt.isBefore(endDt)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  /// Mencari hari perkuliahan aktif berikutnya beserta jadwalnya (offset 1 s/d 7 hari ke depan).
  /// Mengabaikan hari yang tidak memiliki jadwal sama sekali (melewati hari kosong / libur).
  static ScheduleDayInfo? getNextActiveDayInfo(List<Course> allCourses, [DateTime? now]) {
    final dt = now ?? DateTime.now();
    for (int offset = 1; offset <= 7; offset++) {
      final targetDate = dt.add(Duration(days: offset));
      final targetDay = getDayName(targetDate);
      final list = allCourses
          .where((c) => c.hari.trim().toLowerCase() == targetDay.toLowerCase())
          .toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
        String label;
        if (offset == 1) {
          label = 'Besok ($targetDay)';
        } else if (offset == 2) {
          label = 'Lusa ($targetDay)';
        } else {
          label = '$targetDay, ${DateFormat('d MMM', 'id_ID').format(targetDate)}';
        }
        return ScheduleDayInfo(
          dayName: targetDay,
          dayLabel: label,
          date: targetDate,
          daysAhead: offset,
          courses: list,
        );
      }
    }
    return null;
  }

  /// Mengembalikan urutan hari perkuliahan yang benar (Senin - Minggu).
  static int getDayOrder(String dayName) {
    switch (dayName.trim().toLowerCase()) {
      case 'senin':
        return 1;
      case 'selasa':
        return 2;
      case 'rabu':
        return 3;
      case 'kamis':
        return 4;
      case 'jumat':
        return 5;
      case 'sabtu':
        return 6;
      case 'minggu':
        return 7;
      default:
        return 99;
    }
  }
}
