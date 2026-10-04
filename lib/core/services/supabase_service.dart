import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://boffbpvyqhajfiqzyztx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvZmZicHZ5cWhhamZpcXp5enR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExMTY0MzQsImV4cCI6MjEwNjY5MjQzNH0.taJwWfaI0SuBOU3D7SFF2MRuXsCzkdj4Wrsc5DG5GJw';

  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}

class SupabaseService {
  static Future<void> initialize() async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
        );
        debugPrint('Supabase berhasil diinisialisasi untuk ILKOM UNAZLAM!');
      } catch (e) {
        debugPrint('Gagal inisialisasi Supabase: $e');
      }
    } else {
      debugPrint('Supabase belum dikonfigurasi. Aplikasi berjalan dalam mode Mock/Offline Data.');
    }
  }

  static SupabaseClient? get client {
    if (SupabaseConfig.isConfigured) {
      return Supabase.instance.client;
    }
    return null;
  }
}
