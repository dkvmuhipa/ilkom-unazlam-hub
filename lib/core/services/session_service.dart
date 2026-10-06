import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyIsLoggedIn = 'app_is_logged_in';
  static const String _keyUserNim = 'app_user_nim';
  static const String _keyUserName = 'app_user_name';
  static const String _keyIsAdmin = 'app_is_admin';

  /// Menyimpan sesi login ke penyimpanan lokal permanen
  static Future<void> saveSession({
    required String nim,
    required String name,
    required bool isAdmin,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserNim, nim);
      await prefs.setString(_keyUserName, name);
      await prefs.setBool(_keyIsAdmin, isAdmin);
    } catch (_) {}
  }

  /// Mengambil data sesi login yang tersimpan
  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return null;

      final nim = prefs.getString(_keyUserNim) ?? '';
      final name = prefs.getString(_keyUserName) ?? '';
      final isAdmin = prefs.getBool(_keyIsAdmin) ?? false;

      if (nim.isEmpty) return null;

      return {
        'isLoggedIn': true,
        'userNim': nim,
        'userName': name,
        'isAdmin': isAdmin,
      };
    } catch (_) {
      return null;
    }
  }

  /// Menghapus sesi login saat user menekan Logout
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserNim);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyIsAdmin);
    } catch (_) {}
  }
}
