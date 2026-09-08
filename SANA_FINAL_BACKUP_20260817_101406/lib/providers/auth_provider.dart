import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _user;
  User? get user => _user;

  final supabase = Supabase.instance.client;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final session = supabase.auth.currentSession;

    if (session != null) {
      _isAuthenticated = true;
      _user = session.user;
      _isGuest = false;
    } else {
      _isAuthenticated = false;
      _user = null;
      _isGuest = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      _user = response.user;
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );

      await supabase.from('users').insert({
        'id': response.user?.id,
        'name': name,
        'phone': phone,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

      _isAuthenticated = true;
      _user = response.user;
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      throw Exception('Sign up failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    _isAuthenticated = false;
    _user = null;
    _isGuest = true;
    notifyListeners();
  }
}
