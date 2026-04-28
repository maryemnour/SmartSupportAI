import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final _sb = SupabaseService.instance;

  Future<AuthResponse> signIn({required String email, required String password}) =>
      _sb.client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp({required String email, required String password}) =>
      _sb.client.auth.signUp(email: email, password: password);

  Future<void> signOut() => _sb.client.auth.signOut();

  // Smart getCompanyId — 4-step fallback, never shows onboarding if company exists
  Future<String?> getCompanyId() async {
    final user = _sb.client.auth.currentUser;
    if (user == null) return null;
    try {
      // Step 1: fast path
      final userRow = await _sb.client
          .from('users').select('company_id')
          .eq('id', user.id).maybeSingle();
      final id = userRow?['company_id'] as String?;
      if (id != null && id.isNotEmpty) return id;

      // Step 2: race condition fix — search by email
      final email = user.email;
      if (email == null) return null;
      final found = await _sb.client
          .from('users').select('company_id')
          .eq('email', email).not('company_id', 'is', null).maybeSingle();
      final foundId = found?['company_id'] as String?;

      if (foundId != null && foundId.isNotEmpty) {
        // Step 3: fix broken row silently
        try {
          await _sb.client.from('users')
              .update({'company_id': foundId}).eq('id', user.id);
        } catch (_) {}
        return foundId;
      }

      // Step 4: truly no company → onboarding
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isSuperAdmin() async {
    final user = _sb.client.auth.currentUser;
    if (user == null) return false;
    try {
      final row = await _sb.client
          .from('users').select('role')
          .eq('id', user.id).maybeSingle();
      return row?['role'] == 'superadmin';
    } catch (_) {
      return false;
    }
  }
}
