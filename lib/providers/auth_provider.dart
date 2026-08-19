import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initialize();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  bool _isAuthenticated = false;
  bool _isGuest = true;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;

  User? get currentUser => _user;

  bool get isAuthenticated => _isAuthenticated;

  bool get isGuest => _isGuest;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get userId => _user?.id;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initialize() async {
    _setLoading(true);

    try {
      final session = _supabase.auth.currentSession;

      if (session != null) {
        _setAuthenticated(
          session.user,
          notify: false,
        );
      } else {
        _setGuest(
          notify: false,
        );
      }

      _authSubscription =
          _supabase.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            'Auth state listener error: '
            '$error\n$stackTrace',
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Authentication initialization failed: '
        '$error\n$stackTrace',
      );

      _setGuest(
        notify: false,
      );

      _errorMessage = 'Unable to restore your session.';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    final session = _supabase.auth.currentSession;

    if (session != null) {
      _setAuthenticated(session.user);
    } else {
      _setGuest();
    }
  }

  // ============================================================
  // AUTH STATE LISTENER
  // ============================================================

  void _handleAuthStateChange(
    AuthState authState,
  ) {
    final session = authState.session;

    switch (authState.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (session != null) {
          _setAuthenticated(session.user);
        }
        break;

      case AuthChangeEvent.signedOut:
        _setGuest();
        break;

      case AuthChangeEvent.passwordRecovery:
        if (session != null) {
          _setAuthenticated(session.user);
        }
        break;

      case AuthChangeEvent.initialSession:
        if (session != null) {
          _setAuthenticated(session.user);
        } else {
          _setGuest();
        }
        break;

      case AuthChangeEvent.mfaChallengeVerified:
        if (session != null) {
          _setAuthenticated(session.user);
        }
        break;

      case AuthChangeEvent.userDeleted:
        _setGuest();
        break;
    }
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      _setError('Please enter your email.');
      return false;
    }

    if (password.isEmpty) {
      _setError('Please enter your password.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response =
          await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        _setError(
          'Unable to sign in.',
        );
        return false;
      }

      _setAuthenticated(user);

      return true;
    } on AuthException catch (error) {
      debugPrint(
        'Supabase sign in error: '
        '${error.message}',
      );

      _setError(
        error.message,
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sign in failed: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to sign in. Please try again.',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<bool> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedPhone = phone.trim();
    final normalizedEmail = email.trim();

    if (normalizedName.isEmpty) {
      _setError('Please enter your name.');
      return false;
    }

    if (normalizedEmail.isEmpty) {
      _setError('Please enter your email.');
      return false;
    }

    if (password.isEmpty) {
      _setError('Please enter a password.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response =
          await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'name': normalizedName,
          'phone': normalizedPhone,
        },
      );

      final user = response.user;

      if (user == null) {
        _setError(
          'Unable to create your account.',
        );
        return false;
      }

      /*
       * Do not manually insert into the users table here.
       *
       * The Supabase database trigger/profile mechanism
       * should create the application profile.
       */

      final session = response.session;

      if (session != null) {
        _setAuthenticated(user);
      } else {
        /*
         * Email confirmation may be enabled.
         * The account exists, but there is no active session yet.
         */
        _setGuest();

        _setError(
          'Account created. Please confirm your email before signing in.',
        );
      }

      return true;
    } on AuthException catch (error) {
      debugPrint(
        'Supabase sign up error: '
        '${error.message}',
      );

      _setError(
        error.message,
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sign up failed: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to create your account. Please try again.',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.auth.signOut();

      /*
       * The auth-state listener normally calls _setGuest().
       * We also update immediately so the UI does not wait
       * for the stream event.
       */
      _setGuest();
    } on AuthException catch (error) {
      debugPrint(
        'Supabase sign out error: '
        '${error.message}',
      );

      _setError(
        error.message,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Sign out failed: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to sign out.',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // STATE
  // ============================================================

  void _setAuthenticated(
    User user, {
    bool notify = true,
  }) {
    final changed =
        _user?.id != user.id ||
        !_isAuthenticated ||
        _isGuest ||
        _errorMessage != null;

    _user = user;
    _isAuthenticated = true;
    _isGuest = false;
    _errorMessage = null;

    if (notify && changed) {
      notifyListeners();
    }
  }

  void _setGuest({
    bool notify = true,
  }) {
    final changed =
        _user != null ||
        _isAuthenticated ||
        !_isGuest;

    _user = null;
    _isAuthenticated = false;
    _isGuest = true;

    if (notify && changed) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
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

  void clearError() {
    _clearError();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}