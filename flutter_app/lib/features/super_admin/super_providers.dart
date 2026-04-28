// Shared Riverpod providers for the super-admin feature.
// One source of truth so every super-admin sub-screen can subscribe and
// invalidate after mutations.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

/// Single row of platform-wide aggregates from the `platform_analytics` view.
final platformStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await _sb.from('platform_analytics').select().single();
  return Map<String, dynamic>.from(res);
});

/// Every tenant on the platform.
final allCompaniesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb
      .from('companies')
      .select('id, name, slug, plan, is_active, created_at, support_email')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

/// Every user across every tenant.
final allUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb
      .from('users')
      .select('id, email, full_name, role, is_active, created_at, company_id')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

/// Last 200 audit log entries across the platform.
final auditLogsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb
      .from('audit_logs')
      .select('id, company_id, user_id, action, target_type, target_id, metadata, created_at')
      .order('created_at', ascending: false)
      .limit(200);
  return List<Map<String, dynamic>>.from(res);
});
