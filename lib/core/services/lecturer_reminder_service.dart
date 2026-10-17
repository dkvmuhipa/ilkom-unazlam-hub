import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

enum ReminderScenario {
  hMinusOne,
  today,
  reschedule,
  onlineZoom,
}

extension ReminderScenarioExtension on ReminderScenario {
  String get label {
    switch (this) {
      case ReminderScenario.hMinusOne:
        return 'Konfirmasi H-1 (Besok)';
      case ReminderScenario.today:
        return 'Pengingat Hari-H (Siap Kelas)';
      case ReminderScenario.reschedule:
        return 'Penyesuaian Jadwal / Ruangan';
      case ReminderScenario.onlineZoom:
        return 'Kuliah Daring (Link Virtual)';
    }
  }

  String get badgeDescription {
    switch (this) {
      case ReminderScenario.hMinusOne:
        return 'Konfirmasi kesiapan kuliah esok hari';
      case ReminderScenario.today:
        return 'Mengingatkan sesi kuliah beberapa jam sebelum mulai';
      case ReminderScenario.reschedule:
        return 'Mengabarkan jadwal pengganti atau perpindahan ruang';
      case ReminderScenario.onlineZoom:
        return 'Menyampaikan tautan Zoom / Google Meet perkuliahan';
    }
  }
}

class LecturerReminderService {
  /// Mendapatkan salam waktu berdasarkan jam saat ini (Pagi/Siang/Sore/Malam)
  static String getTimeSalutation() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  /// Menghasilkan format pesan WhatsApp resmi dengan etika komunikasi akademik kampus
  static String buildMessage({
    required Course course,
    required String senderName,
    required ReminderScenario scenario,
    String? customNotes,
    String? virtualLink,
  }) {
    final salutation = getTimeSalutation();
    final cleanSender = senderName.trim().isNotEmpty ? senderName.trim() : 'Ketua Kelas';
    final dosenName = course.dosen.trim();
    final effectiveRuang = course.effectiveRuangan;
    final cleanNotes = customNotes?.trim();
    final link = (virtualLink != null && virtualLink.trim().isNotEmpty)
        ? virtualLink.trim()
        : (course.linkVirtual != null && course.linkVirtual!.trim().isNotEmpty
            ? course.linkVirtual!.trim()
            : null);

    final sb = StringBuffer();

    // Salam Pembuka & Permohonan Maaf
    sb.writeln('Assalamu’alaikum Warahmatullahi Wabarakatuh,');
    sb.writeln('$salutation Bapak/Ibu $dosenName.');
    sb.writeln();
    sb.writeln('Mohon maaf mengganggu waktu dan aktivitas Bapak/Ibu. Saya *$cleanSender*, mahasiswa S1 Ilmu Komunikasi UNAZLAM (Koordinator/Ketua Kelas ILKOM 2026).');
    sb.writeln();

    switch (scenario) {
      case ReminderScenario.hMinusOne:
        sb.writeln('Izin mengonfirmasi terkait agenda perkuliahan untuk *esok hari*:');
        sb.writeln('📚 *Mata Kuliah* : ${course.nama} (${course.kode})');
        sb.writeln('🗓️ *Hari / Waktu* : ${course.hari}, ${course.jamMulai} - ${course.jamSelesai} WIB');
        sb.writeln('📍 *Ruangan*     : $effectiveRuang');
        sb.writeln('🎯 *Beban Studi* : ${course.sks} SKS');
        sb.writeln();
        if (cleanNotes != null && cleanNotes.isNotEmpty) {
          sb.writeln('Catatan tambahan:');
          sb.writeln('💬 $cleanNotes');
          sb.writeln();
        }
        sb.writeln('Mohon konfirmasi apakah perkuliahan esok hari dapat dilaksanakan sesuai jadwal di atas, atau apakah ada arahan/materi yang perlu rekan-rekan mahasiswa persiapkan terlebih dahulu?');
        break;

      case ReminderScenario.today:
        sb.writeln('Izin mengingatkan bahwa *hari ini* terjadwal sesi perkuliahan:');
        sb.writeln('📚 *Mata Kuliah* : ${course.nama} (${course.kode})');
        sb.writeln('⏰ *Waktu*       : Hari ini, Pukul ${course.jamMulai} - ${course.jamSelesai} WIB');
        sb.writeln('📍 *Ruangan*     : $effectiveRuang');
        sb.writeln();
        if (cleanNotes != null && cleanNotes.isNotEmpty) {
          sb.writeln('Catatan tambahan:');
          sb.writeln('💬 $cleanNotes');
          sb.writeln();
        }
        sb.writeln('Ruang kelas dan rekan-rekan mahasiswa saat ini telah siap. Mohon konfirmasi kesediaan Bapak/Ibu atau arahan jika ada penyesuaian waktu.');
        break;

      case ReminderScenario.reschedule:
        sb.writeln('Izin menyampaikan pembaruan / penyesuaian jadwal perkuliahan:');
        sb.writeln('📚 *Mata Kuliah* : ${course.nama} (${course.kode})');
        sb.writeln('🗓️ *Jadwal Baru* : ${course.hari}, ${course.jamMulai} - ${course.jamSelesai} WIB');
        sb.writeln('📍 *Ruangan*     : $effectiveRuang');
        sb.writeln('📌 *Keterangan*  : ${course.isRescheduled ? "Jadwal Pengganti / Reschedule" : "Penyesuaian Ruang Kuliah"}');
        sb.writeln();
        if (cleanNotes != null && cleanNotes.isNotEmpty) {
          sb.writeln('Informasi detail:');
          sb.writeln('💬 $cleanNotes');
          sb.writeln();
        }
        sb.writeln('Seluruh rekan mahasiswa kelas telah berkoordinasi dan menyetujui jadwal ini. Mohon konfirmasi kesediaan Bapak/Ibu.');
        break;

      case ReminderScenario.onlineZoom:
        sb.writeln('Izin mengonfirmasi pelaksanaan sesi perkuliahan secara *daring (online)* untuk:');
        sb.writeln('📚 *Mata Kuliah* : ${course.nama} (${course.kode})');
        sb.writeln('⏰ *Waktu*       : ${course.hari}, Pukul ${course.jamMulai} - ${course.jamSelesai} WIB');
        if (link != null && link.isNotEmpty) {
          sb.writeln('🔗 *Tautan Virtual* : $link');
        } else {
          sb.writeln('🔗 *Tautan Virtual* : (Tautan Zoom/Google Meet akan kami kirimkan sesaat lagi)');
        }
        sb.writeln();
        if (cleanNotes != null && cleanNotes.isNotEmpty) {
          sb.writeln('Catatan sesi:');
          sb.writeln('💬 $cleanNotes');
          sb.writeln();
        }
        sb.writeln('Ruang pertemuan virtual telah kami siapkan. Mohon arahan bila Bapak/Ibu telah berkenan untuk bergabung ke dalam room.');
        break;
    }

    sb.writeln();
    sb.writeln('Terima kasih banyak atas perhatian, bimbingan, dan waktu yang Bapak/Ibu luangkan.');
    sb.writeln();
    sb.writeln('Wassalamu’alaikum Warahmatullahi Wabarakatuh.');

    return sb.toString();
  }

  /// Format nomor telepon ke format internasional WhatsApp (628xxx)
  static String formatPhoneForWhatsApp(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    }
    return digits;
  }

  /// Menandai bahwa dosen pada mata kuliah ini telah dihubungi hari ini
  static Future<void> markContactedToday(String courseId, String lecturerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = 'lecturer_contacted_${courseId}_$todayStr';
      final timestamp = DateFormat('HH:mm').format(DateTime.now());
      await prefs.setString(key, timestamp);
    } catch (_) {}
  }

  /// Mengecek apakah dosen mata kuliah ini sudah dihubungi hari ini
  static Future<String?> getContactedTimeToday(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = 'lecturer_contacted_${courseId}_$todayStr';
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }
}
