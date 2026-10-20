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

  /// Daftar nama agama resmi yang didukung sistem akademik
  static const List<String> supportedReligions = [
    'Islam',
    'Kristen Protestan',
    'Kristen Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
  ];

  /// Mengecek apakah suatu mata kuliah adalah mata kuliah peminatan agama
  static bool isReligionCourse(Course course) {
    final name = course.nama.toLowerCase();
    final code = course.kode.toUpperCase();
    if (name.contains('pendidikan agama') ||
        name.contains('agama islam') ||
        name.contains('agama kristen') ||
        name.contains('agama katolik') ||
        name.contains('agama hindu') ||
        name.contains('agama buddha') ||
        name.contains('agama budha') ||
        name.contains('agama konghucu') ||
        name.contains('agama khonghucu')) {
      return true;
    }
    if (code.startsWith('3 PK 101') || code.startsWith('3PK101')) {
      return true;
    }
    return false;
  }

  /// Mendeteksi kategori agama dari mata kuliah (Islam, Kristen, Katolik, Hindu, Buddha, Konghucu)
  static String? detectCourseReligion(Course course) {
    final name = course.nama.toLowerCase();
    final code = course.kode.toUpperCase();

    if (name.contains('islam') || code.contains('101A')) {
      return 'Islam';
    }
    if (name.contains('kristen') || name.contains('protestan') || code.contains('101B')) {
      return 'Kristen';
    }
    if (name.contains('katolik') || code.contains('101C')) {
      return 'Katolik';
    }
    if (name.contains('hindu') || code.contains('101D')) {
      return 'Hindu';
    }
    if (name.contains('buddha') || name.contains('budha') || code.contains('101E')) {
      return 'Buddha';
    }
    if (name.contains('konghucu') || name.contains('khonghucu') || code.contains('101F')) {
      return 'Konghucu';
    }
    return null;
  }

  /// Memvalidasi apakah mata kuliah cocok untuk agama mahasiswa.
  /// Jika mata kuliah bukan mata kuliah agama -> selalu true.
  /// Jika preferensi agama belum ditentukan -> menggunakan default 'Islam'.
  static bool matchesStudentReligion(Course course, String? studentReligion) {
    if (!isReligionCourse(course)) return true;
    final courseReligion = detectCourseReligion(course);
    if (courseReligion == null) return true;

    final studentRel = (studentReligion != null && studentReligion.trim().isNotEmpty)
        ? studentReligion.trim().toLowerCase()
        : 'islam';

    final cRel = courseReligion.toLowerCase();

    if (cRel == 'islam') {
      return studentRel.contains('islam');
    }
    if (cRel == 'kristen') {
      return studentRel.contains('kristen') || studentRel.contains('protestan');
    }
    if (cRel == 'katolik') {
      return studentRel.contains('katolik');
    }
    if (cRel == 'hindu') {
      return studentRel.contains('hindu');
    }
    if (cRel == 'buddha') {
      return studentRel.contains('buddh') || studentRel.contains('budh');
    }
    if (cRel == 'konghucu') {
      return studentRel.contains('kong');
    }
    return true;
  }

  /// Memfilter daftar mata kuliah berdasarkan preferensi agama mahasiswa
  static List<Course> filterCoursesByReligion(List<Course> courses, String? studentReligion) {
    return courses.where((c) => matchesStudentReligion(c, studentReligion)).toList();
  }
}
