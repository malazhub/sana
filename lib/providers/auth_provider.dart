import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initialize();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  User? get currentUser => _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get userId => _user?.id;

  Future<void> _initialize() async {
    _setLoading(true);

    try {
      final session = _supabase.auth.currentSession;

      if (session != null) {
        _setAuthenticated(session.user);
      } else {
        _setGuest();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Authentication initialization failed: $error\n$stackTrace',
      );

      _setGuest();
      _errorMessage = 'Unable to restore your session.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAuthStatus() async {
    await _initialize();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;

      if (user == null) {
        _setError('Unable to sign in.');
        return false;
      }

      _setAuthenticated(user);
      return true;
    } on AuthException catch (error) {
      _setError(error.message);
      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sign in failed: $error\n$stackTrace',
      );

      _setError('Unable to sign in. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
        },
      );

      final user = response.user;

      if (user == null) {
        _setError('Unable to create your account.');
        return false;
      }

      /*
       * User-profile creation should preferably be handled by the
       * Supabase database trigger defined in the project schema.
       *
       * We therefore do not blindly insert another `users` row here.
       */

      _setAuthenticated(user);
      return true;
    } on AuthException catch (error) {
      _setError(error.message);
      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sign up failed: $error\n$stackTrace',
      );

      _setError('Unable to create your account. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.auth.signOut();
      _setGuest();
    } on AuthException catch (error) {
      _setError(error.message);
    } catch (error, stackTrace) {
      debugPrint(
        'Sign out failed: $error\n$stackTrace',
      );

      _setError('Unable to sign out.');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setAuthenticated(User user) {
    _user = user;
    _isAuthenticated = true;
    _isGuest = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _setGuest() {
    _user = null;
    _isAuthenticated = false;
    _isGuest = true;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }
}