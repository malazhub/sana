
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LoginResult {
  admin,
  activeUser,
  notActivated,
  userNotFound,
  failed,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initialize();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  Map<String, dynamic>? _profile;

  bool _isAuthenticated = false;
  bool _isGuest = true;
  bool _isLoading = true;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  User? get user => _user;

  User? get currentUser => _user;

  Map<String, dynamic>? get profile => _profile;

  bool get isAuthenticated => _isAuthenticated;

  bool get isGuest => _isGuest;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get userId => _user?.id;

  bool get isAdmin {
    final role = _profile?['role']
        ?.toString()
        .trim()
        .toLowerCase();

    return role == 'admin';
  }

  bool get isActiveUser {
    final role = _profile?['role']
        ?.toString()
        .trim()
        .toLowerCase();

    final status = _profile?['status']
        ?.toString()
        .trim()
        .toLowerCase();

    return role != 'admin' && status == 'active';
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        _setGuest(notify: false);
      } else {
        await _restoreSessionUser(
          session.user,
          notify: false,
        );
      }

      _authSubscription =
          _supabase.auth.onAuthStateChange.listen(
        (AuthState state) async {
          await _handleAuthStateChange(state);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            'AUTH LISTENER ERROR:\n$error\n$stackTrace',
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        'AUTH INITIALIZATION ERROR:\n$error\n$stackTrace',
      );

      _setGuest(notify: false);

      _errorMessage =
          'Unable to restore your session.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHECK AUTH STATUS
  // ============================================================

  Future<void> checkAuthStatus() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        _setGuest();
        return;
      }

      await _restoreSessionUser(session.user);
    } catch (error, stackTrace) {
      debugPrint(
        'CHECK AUTH STATUS ERROR:\n$error\n$stackTrace',
      );

      _setGuest();

      _setError(
        'Unable to load user.',
      );
    }
  }

  // ============================================================
  // AUTH STATE LISTENER
  // ============================================================

  Future<void> _handleAuthStateChange(
    AuthState authState,
  ) async {
    final session = authState.session;

    debugPrint(
      'AUTH EVENT: ${authState.event}',
    );

    switch (authState.event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.mfaChallengeVerified:
        if (session == null) {
          _setGuest();
        } else {
          await _restoreSessionUser(session.user);
        }
        break;

      case AuthChangeEvent.signedOut:
      case AuthChangeEvent.userDeleted:
        _setGuest();
        break;
    }
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> _loadProfile(
    String authUserId,
  ) async {
    try {
      debugPrint(
        'Loading application profile for user: $authUserId',
      );

      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', authUserId)
          .maybeSingle();

      if (response == null) {
        debugPrint(
          'No application profile found for: $authUserId',
        );

        return null;
      }

      final profile =
          Map<String, dynamic>.from(response);

      debugPrint(
        'Application profile loaded: '
        'role=${profile['role']}, '
        'status=${profile['status']}',
      );

      return profile;
    } catch (error, stackTrace) {
      debugPrint(
        'LOAD PROFILE ERROR:\n$error\n$stackTrace',
      );

      /*
       * IMPORTANT:
       *
       * Do NOT silently convert a database/RLS error into
       * "user not found".
       *
       * Rethrow the error so signIn/checkAuthStatus can
       * distinguish a database failure from a missing profile.
       */
      rethrow;
    }
  }

  // ============================================================
  // RESTORE AUTHENTICATED USER
  // ============================================================

  Future<void> _restoreSessionUser(
    User authenticatedUser, {
    bool notify = true,
  }) async {
    _user = authenticatedUser;
    _isAuthenticated = true;
    _isGuest = false;
    _errorMessage = null;

    try {
      final loadedProfile =
          await _loadProfile(authenticatedUser.id);

      _profile = loadedProfile;

      if (loadedProfile == null) {
        /*
         * Supabase session exists but application profile
         * does not exist.
         *
         * We keep the Auth user available but do not claim
         * that the user is an active application user.
         */
        debugPrint(
          'Authenticated user has no application profile.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'RESTORE USER PROFILE ERROR:\n$error\n$stackTrace',
      );

      _profile = null;
      _errorMessage = 'Unable to load user.';
    }

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Future<LoginResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      _setError(
        'Please enter your email.',
      );

      return LoginResult.failed;
    }

    if (password.isEmpty) {
      _setError(
        'Please enter your password.',
      );

      return LoginResult.failed;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      debugPrint(
        'Signing in: $normalizedEmail',
      );

      final response =
          await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final authenticatedUser = response.user;

      if (authenticatedUser == null) {
        _setError(
          'Unable to sign in.',
        );

        return LoginResult.failed;
      }

      debugPrint(
        'Supabase Auth login successful: '
        '${authenticatedUser.id}',
      );

      Map<String, dynamic>? loadedProfile;

      try {
        loadedProfile =
            await _loadProfile(
          authenticatedUser.id,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'PROFILE QUERY FAILED:\n$error\n$stackTrace',
        );

        /*
         * This is a real database/RLS/configuration error,
         * NOT "user not found".
         */
        await _safeSignOut();

        _setGuest(notify: false);

        _setError(
          'Unable to load user.',
        );

        return LoginResult.failed;
      }

      if (loadedProfile == null) {
        debugPrint(
          'User authenticated but no users-table record exists.',
        );

        await _safeSignOut();

        _setGuest(notify: false);

        _setError(
          'Get your own copy.',
        );

        return LoginResult.userNotFound;
      }

      _user = authenticatedUser;
      _profile = loadedProfile;
      _isAuthenticated = true;
      _isGuest = false;
      _errorMessage = null;

      final role = loadedProfile['role']
          ?.toString()
          .trim()
          .toLowerCase();

      final status = loadedProfile['status']
          ?.toString()
          .trim()
          .toLowerCase();

      debugPrint(
        'LOGIN PROFILE: role=$role status=$status',
      );

      // ========================================================
      // ADMIN
      // ========================================================

      if (role == 'admin') {
        notifyListeners();

        return LoginResult.admin;
      }

      // ========================================================
      // NORMAL USER
      // ========================================================

      if (status != 'active') {
        await _safeSignOut();

        _setGuest(notify: false);

        _setError(
          'Get your own copy.',
        );

        return LoginResult.notActivated;
      }

      // ========================================================
      // ACTIVE USER
      // ========================================================

      notifyListeners();

      return LoginResult.activeUser;
    } on AuthException catch (error, stackTrace) {
      debugPrint(
        'SUPABASE AUTH ERROR:\n'
        '${error.message}\n'
        '$stackTrace',
      );

      _setGuest(notify: false);

      _setError(
        error.message,
      );

      return LoginResult.failed;
    } catch (error, stackTrace) {
      debugPrint(
        'SIGN IN ERROR:\n$error\n$stackTrace',
      );

      _setGuest(notify: false);

      _setError(
        'Unable to sign in. Please try again.',
      );

      return LoginResult.failed;
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
      _setError(
        'Please enter your name.',
      );

      return false;
    }

    if (normalizedPhone.isEmpty) {
      _setError(
        'Please enter your phone number.',
      );

      return false;
    }

    if (normalizedEmail.isEmpty) {
      _setError(
        'Please enter your email.',
      );

      return false;
    }

    if (password.isEmpty) {
      _setError(
        'Please enter a password.',
      );

      return false;
    }

    if (password.length < 6) {
      _setError(
        'Password must contain at least 6 characters.',
      );

      return false;
    }

    _setLoading(true);
    _clearError(notify: false);

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

      final createdUser = response.user;

      if (createdUser == null) {
        _setError(
          'Unable to create your account.',
        );

        return false;
      }

      debugPrint(
        'ACCOUNT CREATED: ${createdUser.id}',
      );

      final session = response.session;

      /*
       * Email confirmation enabled:
       *
       * Supabase creates the Auth account but gives us
       * no session until the email is confirmed.
       */
      if (session == null) {
        _setGuest(notify: false);

        _setError(
          'Account created. Please confirm your email before signing in.',
        );

        return true;
      }

      /*
       * If Supabase immediately creates a session,
       * load the application profile.
       */
      Map<String, dynamic>? loadedProfile;

      try {
        loadedProfile =
            await _loadProfile(createdUser.id);
      } catch (error, stackTrace) {
        debugPrint(
          'SIGN UP PROFILE ERROR:\n$error\n$stackTrace',
        );

        await _safeSignOut();

        _setGuest(notify: false);

        _setError(
          'Unable to load user.',
        );

        return false;
      }

      if (loadedProfile == null) {
        /*
         * The Auth account exists but the application
         * users record has not been created.
         *
         * This is normally a database-trigger/profile
         * configuration problem.
         */
        await _safeSignOut();

        _setGuest(notify: false);

        _setError(
          'Account created, but your application profile could not be loaded.',
        );

        return true;
      }

      _user = createdUser;
      _profile = loadedProfile;
      _isAuthenticated = true;
      _isGuest = false;
      _errorMessage = null;

      notifyListeners();

      return true;
    } on AuthException catch (error, stackTrace) {
      debugPrint(
        'SUPABASE SIGN UP ERROR:\n'
        '${error.message}\n'
        '$stackTrace',
      );

      _setGuest(notify: false);

      _setError(
        error.message,
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'SIGN UP ERROR:\n$error\n$stackTrace',
      );

      _setGuest(notify: false);

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
    _clearError(notify: false);

    try {
      await _supabase.auth.signOut();

      _setGuest(notify: false);
    } on AuthException catch (error, stackTrace) {
      debugPrint(
        'SIGN OUT AUTH ERROR:\n'
        '${error.message}\n'
        '$stackTrace',
      );

      _setError(
        error.message,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'SIGN OUT ERROR:\n$error\n$stackTrace',
      );

      _setError(
        'Unable to sign out.',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SAFE SIGN OUT
  // ============================================================

  Future<void> _safeSignOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error, stackTrace) {
      debugPrint(
        'SAFE SIGN OUT ERROR:\n$error\n$stackTrace',
      );
    }
  }

  // ============================================================
  // STATE
  // ============================================================

  void _setGuest({
    bool notify = true,
  }) {
    final changed =
        _user != null ||
        _profile != null ||
        _isAuthenticated ||
        !_isGuest;

    _user = null;
    _profile = null;
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

  void _setError(
    String message, {
    bool notify = true,
  }) {
    _errorMessage = message;

    if (notify) {
      notifyListeners();
    }
  }

  void _clearError({
    bool notify = true,
  }) {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    if (notify) {
      notifyListeners();
    }
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

