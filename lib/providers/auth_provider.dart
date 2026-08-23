import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/subscription_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;

  User? _currentUser;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _subscription;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  User? get currentUser => _currentUser;

  Map<String, dynamic>? get profile => _profile;

  Map<String, dynamic>? get subscription =>
      _subscription;

  bool get isLoading => _isLoading;

  bool get isInitialized => _isInitialized;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _currentUser != null;

  String get userId =>
      _currentUser?.id ?? '';

  String get email =>
      _currentUser?.email ?? '';

  String get role =>
      _profile?['role']
          ?.toString()
          .trim()
          .toLowerCase() ??
      'user';

  bool get isAdmin =>
      isAuthenticated &&
      role == 'admin';

  bool get isActive {
    final value =
        _profile?['is_active'];

    return value is bool && value;
  }

  // ============================================================
  // SUBSCRIPTION STATE
  // ============================================================

  DateTime? get expiryDate {
    final value =
        _subscription?['expires_at'] ??
        _profile?['expiry_date'];

    return _parseDate(value);
  }

  bool get hasValidSubscription {
    if (!isAuthenticated) {
      return false;
    }

    // Administrators do not require
    // a customer subscription.
    if (isAdmin) {
      return true;
    }

    final status =
        _subscription?['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';

    if (status != 'active') {
      return false;
    }

    final expiry = expiryDate;

    if (expiry == null) {
      return false;
    }

    return expiry.isAfter(
      DateTime.now().toUtc(),
    );
  }

  bool get subscriptionExpired {
    final expiry = expiryDate;

    if (expiry == null) {
      return false;
    }

    return !expiry.isAfter(
      DateTime.now().toUtc(),
    );
  }

  int? get daysRemaining {
    final expiry = expiryDate;

    if (expiry == null) {
      return null;
    }

    final now =
        DateTime.now().toUtc();

    if (!expiry.isAfter(now)) {
      return 0;
    }

    return expiry
        .difference(now)
        .inDays;
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _currentUser =
          _supabase.auth.currentUser;

      _authSubscription ??=
          _supabase.auth.onAuthStateChange.listen(
        (AuthState state) {
          unawaited(
            _handleAuthStateChange(state),
          );
        },
        onError: (Object error) {
          debugPrint(
            'Auth state listener error: $error',
          );
        },
      );

      if (_currentUser != null) {
        await _loadAuthenticatedState();
      } else {
        _profile = null;
        _subscription = null;
      }

      _isInitialized = true;
    } catch (error, stackTrace) {
      debugPrint(
        'Auth initialization failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to initialize authentication.',
        ),
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // AUTH STATE CHANGES
  // ============================================================

  Future<void> _handleAuthStateChange(
    AuthState state,
  ) async {
    try {
      _currentUser =
          state.session?.user;

      if (_currentUser == null) {
        _profile = null;
        _subscription = null;
        notifyListeners();
        return;
      }

      await _loadAuthenticatedState();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Auth state handling failed: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _loadAuthenticatedState() async {
    await loadProfile();
    await loadSubscription();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<bool> loadProfile() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      _currentUser = null;
      _profile = null;
      _subscription = null;
      notifyListeners();
      return false;
    }

    try {
      final response =
          await _supabase
              .from('users')
              .select(
                'id, name, email, phone, '
                'created_at, is_active, '
                'expiry_date, role',
              )
              .eq(
                'id',
                user.id,
              )
              .maybeSingle();

      if (response == null) {
        _currentUser = user;
        _profile = null;
        notifyListeners();
        return false;
      }

      _currentUser = user;

      _profile =
          Map<String, dynamic>.from(
        response,
      );

      notifyListeners();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Load user profile failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to load user profile.',
        ),
      );

      return false;
    }
  }

  // ============================================================
  // LOAD SUBSCRIPTION
  // ============================================================

  Future<bool> loadSubscription() async {
    if (!isAuthenticated) {
      _subscription = null;
      return false;
    }

    try {
      _subscription =
          await SubscriptionService
              .getCurrentSubscription();

      /*
       * Keep the legacy users table fields synchronized
       * in memory so existing screens that read profile
       * continue to work.
       */
      if (_profile != null &&
          _subscription != null) {
        _profile!['is_active'] =
            _subscription!['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ==
                'active';

        _profile!['expiry_date'] =
            _subscription!['expires_at'];
      }

      notifyListeners();

      return _subscription != null;
    } catch (error, stackTrace) {
      debugPrint(
        'Load subscription failed: '
        '$error\n$stackTrace',
      );

      _subscription = null;

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to load subscription.',
        ),
      );

      return false;
    }
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail =
        email.trim();

    if (cleanEmail.isEmpty) {
      _setError(
        'Email is required.',
      );
      return false;
    }

    if (password.isEmpty) {
      _setError(
        'Password is required.',
      );
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response =
          await _supabase.auth
              .signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      _currentUser =
          response.user;

      if (_currentUser == null) {
        _setError(
          'Unable to sign in.',
        );
        return false;
      }

      await _loadAuthenticatedState();

      return true;
    } on AuthException catch (error) {
      _setError(
        error.message.isNotEmpty
            ? error.message
            : 'Unable to sign in.',
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sign in failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to sign in.',
        ),
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
    required String email,
    required String password,
    String name = '',
    String phone = '',
  }) async {
    final cleanEmail =
        email.trim();

    final cleanName =
        name.trim();

    final cleanPhone =
        phone.trim();

    if (cleanEmail.isEmpty) {
      _setError(
        'Email is required.',
      );
      return false;
    }

    if (password.isEmpty) {
      _setError(
        'Password is required.',
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
    _clearError();

    try {
      final response =
          await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'name': cleanName,
          'phone': cleanPhone,
        },
      );

      _currentUser =
          response.user;

      if (_currentUser != null) {
        await _ensureUserProfile(
          user: _currentUser!,
          name: cleanName,
          phone: cleanPhone,
        );

        await _loadAuthenticatedState();
      }

      return true;
    } on AuthException catch (error) {
      _setError(
        error.message.isNotEmpty
            ? error.message
            : 'Unable to create account.',
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sign up failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to create account.',
        ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ENSURE PROFILE
  // ============================================================

  Future<void> _ensureUserProfile({
    required User user,
    required String name,
    required String phone,
  }) async {
    final existing =
        await _supabase
            .from('users')
            .select('id')
            .eq(
              'id',
              user.id,
            )
            .maybeSingle();

    if (existing != null) {
      return;
    }

    await _supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': user.email ?? '',
      'phone': phone,
      'created_at': DateTime.now()
          .toUtc()
          .toIso8601String(),
      'is_active': false,
      'expiry_date': null,
      'role': 'user',
    });
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.auth.signOut();

      _currentUser = null;
      _profile = null;
      _subscription = null;
    } on AuthException catch (error) {
      _setError(
        error.message.isNotEmpty
            ? error.message
            : 'Unable to sign out.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Sign out failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to sign out.',
        ),
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<bool> refresh() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      _currentUser = null;
      _profile = null;
      _subscription = null;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _currentUser = user;

      await _loadAuthenticatedState();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Auth refresh failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to refresh account status.',
        ),
      );

      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // ADMIN STATUS
  // ============================================================

  Future<bool> refreshAdminStatus() async {
    if (!isAuthenticated) {
      return false;
    }

    await loadProfile();

    return isAdmin;
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<bool> resetPassword(
    String email,
  ) async {
    final cleanEmail =
        email.trim();

    if (cleanEmail.isEmpty) {
      _setError(
        'Email is required.',
      );
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase.auth
          .resetPasswordForEmail(
        cleanEmail,
      );

      return true;
    } on AuthException catch (error) {
      _setError(
        error.message.isNotEmpty
            ? error.message
            : 'Unable to send password reset email.',
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Password reset failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to send password reset email.',
        ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void clearError() {
    _clearError();
  }

  void _clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setError(
    String message,
  ) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setLoading(
    bool value,
  ) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  String _cleanErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final message =
        error.toString().trim();

    if (message.isEmpty) {
      return fallback;
    }

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    )?.toUtc();
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _currentUser = null;
    _profile = null;
    _subscription = null;
    _isLoading = false;
    _isInitialized = false;
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;

    super.dispose();
  }
}