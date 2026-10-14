import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class AdminAuditService {
  static final List<Map<String, dynamic>> _localAuditLogs = [];

  static Future<void> record({
    required String action,
    required String module,
    required String description,
    String? userIdentifier,
    String? userName,
    Map<String, dynamic> metadata = const {},
  }) async {
    final effectiveUid = userIdentifier ?? 'admin';
    final effectiveName = userName ?? 'Administrator';

    _localAuditLogs.insert(0, {
      'id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
      'user_identifier': effectiveUid,
      'user_name': effectiveName,
      'action_type': action.toUpperCase(),
      'target_module': module.toUpperCase(),
      'description': description,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });

    try {
      final client = SupabaseService.client;
      if (client == null) return;
      try {
        await client.rpc('log_admin_activity', params: {
          'p_action_type': action,
          'p_target_module': module,
          'p_description': description,
          'p_metadata': metadata,
        });
      } catch (_) {
        // Fallback langsung ke tabel audit_logs jika RPC belum ada
        await client.from('audit_logs').insert({
          'user_identifier': effectiveUid,
          'user_name': effectiveName,
          'action_type': action.toUpperCase(),
          'target_module': module.toUpperCase(),
          'description': description,
          'metadata': metadata,
        });
      }
    } catch (error) {
      debugPrint('Aktivitas dicatat secara lokal (Supabase write note: $error)');
    }
  }

  static Future<List<Map<String, dynamic>>> list({int limit = 200}) async {
    final client = SupabaseService.client;
    if (client == null) return List.from(_localAuditLogs);

    try {
      final rows = await client
          .from('audit_logs')
          .select('id,user_identifier,user_name,action_type,target_module,description,metadata,created_at')
          .order('created_at', ascending: false)
          .limit(limit);
      final list = List<Map<String, dynamic>>.from(rows);
      return list;
    } catch (error) {
      debugPrint('Gagal memuat log aktivitas admin dari Supabase ($error), menggunakan log lokal.');
      return List.from(_localAuditLogs);
    }
  }
}

class AdminAuditException implements Exception {
  final String message;
  const AdminAuditException(this.message);
  @override
  String toString() => message;
}
