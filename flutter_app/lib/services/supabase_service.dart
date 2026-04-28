import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();
  SupabaseClient get client        => Supabase.instance.client;
  bool           get isAuthenticated => client.auth.currentUser != null;
  User?          get currentUser   => client.auth.currentUser;
}
