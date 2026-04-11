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
}
