import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static late SupabaseClient client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      publishableKey: 'YOUR_SUPABASE_ANON_KEY',
    );

    client = Supabase.instance.client;
  }

  static User? get currentUser {
    return client.auth.currentUser;
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> logout() async {
    await client.auth.signOut();
  }
}
