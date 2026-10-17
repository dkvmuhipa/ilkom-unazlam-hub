import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';

  ThemeMode get themeMode => ThemeMode.light;
  bool get isDarkMode => false;

  ThemeNotifier() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Pastikan preferensi tersimpan selalu di-reset ke mode terang
      await prefs.setString(_prefKey, 'light');
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Aplikasi strictly hanya menggunakan mode terang
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, 'light');
    } catch (_) {}
  }

  void toggleTheme() {
    // No-op: Mode gelap dinonaktifkan
  }
}

// Global static access for clean state propagation across widget tree
class ThemeScope {
  static final ThemeNotifier notifier = ThemeNotifier();
}
