import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

class AdminAuditService {
  static Future<void> record({
    required String action,
    required String module,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final client = SupabaseService.client;
      if (client == null) return;
      await client.rpc('log_admin_activity', params: {
        'p_action_type': action,
        'p_target_module': module,
        'p_description': description,
        'p_metadata': metadata,
      });
    } catch (error) {
      // Audit write errors must not undo the successfully completed operation.
      debugPrint('Gagal mencatat aktivitas admin: $error');
    }
  }

  static Future<List<Map<String, dynamic>>> list({int limit = 200}) async {
    final client = SupabaseService.client;
    if (client == null) throw const AdminAuditException('Supabase belum terhubung.');
    try {
      final rows = await client
          .from('audit_logs')
          .select('id,user_identifier,user_name,action_type,target_module,description,metadata,created_at')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Gagal memuat log aktivitas admin: $error');
      throw const AdminAuditException(
        'Riwayat gagal dimuat. Pastikan migrasi admin_audit sudah diterapkan dan akun Anda admin aktif.',
      );
    }
  }
}

class AdminAuditException implements Exception {
  final String message;
  const AdminAuditException(this.message);
  @override
  String toString() => message;
}
