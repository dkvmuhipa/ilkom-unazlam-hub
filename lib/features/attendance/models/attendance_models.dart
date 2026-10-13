class AttendanceHistoryItem {
  final String date;
  final String courseName;
  final String status; // 'Hadir', 'Izin', 'Sakit', 'Alpa'
  final int? pertemuanKe;
  final String? catatan;

  const AttendanceHistoryItem({
    required this.date,
    required this.courseName,
    required this.status,
    this.pertemuanKe,
    this.catatan,
  });
}

class ActiveAttendanceSession {
  final String? id;
  final String courseName;
  final int pertemuanKe;
  final String token;
  final String pinCode;
  final DateTime startTime;
  final DateTime expiresAt;
  final Set<String> attendedNims;

  ActiveAttendanceSession({
    this.id,
    required this.courseName,
    required this.pertemuanKe,
    required this.token,
    String? pinCode,
    required this.startTime,
    required this.expiresAt,
    Set<String>? attendedNims,
  })  : pinCode = pinCode ??
            (token.replaceAll(RegExp(r'\D'), '').length >= 4
                ? token.replaceAll(RegExp(r'\D'), '').substring(token.replaceAll(RegExp(r'\D'), '').length - 4)
                : (token.length >= 4 ? token.substring(token.length - 4) : '1234')),
        attendedNims = attendedNims ?? {};

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get remainingSeconds => expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 9999);

  static ActiveAttendanceSession fromMap(Map<String, dynamic> map) {
    final start = DateTime.tryParse(map['start_time']?.toString() ?? '') ?? DateTime.now();
    final expires = DateTime.tryParse(map['expires_at']?.toString() ?? '') ?? DateTime.now().add(const Duration(minutes: 15));
    final attended = (map['attended_nims'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
    return ActiveAttendanceSession(
      id: map['id']?.toString(),
      courseName: map['course_name']?.toString() ?? '',
      pertemuanKe: (map['pertemuan_ke'] as num?)?.toInt() ?? 1,
      token: map['token']?.toString() ?? '',
      pinCode: map['pin_code']?.toString(),
      startTime: start,
      expiresAt: expires,
      attendedNims: attended,
    );
  }
}
