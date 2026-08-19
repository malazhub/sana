import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider extends ChangeNotifier {
  static const String adminEmail =
      'malazjanbeih@gmail.com';

  final List<Map<String, dynamic>> _users = [];

  bool _isAdmin = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAdmin => _isAdmin;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get users =>
      List.unmodifiable(_users);

  SupabaseClient get _supabase =>
      Supabase.instance.client;

  // ============================================================
  // ADMIN CHECK
  // ============================================================

  bool checkCurrentUserIsAdmin() {
    final user =
        _supabase.auth.currentUser;

    final email =
        user?.email?.trim().toLowerCase();

    final result =
        user != null &&
        email == adminEmail.toLowerCase();

    if (_isAdmin != result) {
      _isAdmin = result;
      notifyListeners();
    }

    return result;
  }

  Future<bool> checkAdminStatus(
    String userId,
  ) async {
    final requestedUserId = userId.trim();

    if (requestedUserId.isEmpty) {
      _setAdmin(false);
      return false;
    }

    try {
      final currentUser =
          _supabase.auth.currentUser;

      if (currentUser == null ||
          currentUser.id != requestedUserId) {
        _setAdmin(false);
        return false;
      }

      final email =
          currentUser.email?.trim().toLowerCase();

      final result =
          email == adminEmail.toLowerCase();

      _setAdmin(result);

      return result;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin status check error: '
        '$error\n$stackTrace',
      );

      _setAdmin(false);

      return false;
    }
  }

  void _setAdmin(bool value) {
    if (_isAdmin == value) {
      return;
    }

    _isAdmin = value;
    notifyListeners();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> loadUsers() async {
    if (!checkCurrentUserIsAdmin()) {
      _users.clear();

      _setError(
        'Administrator access required.',
      );

      return;
    }

    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select('*')
          .order(
            'created_at',
            ascending: false,
          );

      final loadedUsers =
          <Map<String, dynamic>>[];

      for (final item in response) {
        try {
          loadedUsers.add(
            Map<String, dynamic>.from(item),
          );
        } catch (error) {
          debugPrint(
            'Invalid user subscription record: '
            '$error',
          );
        }
      }

      _users
        ..clear()
        ..addAll(loadedUsers);
    } catch (error, stackTrace) {
      debugPrint(
        'Admin loadUsers error: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to load users.',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ACTIVATE USER
  // ============================================================

  Future<bool> activateUser(
    String userId,
    String email,
    String phone,
  ) async {
    if (!checkCurrentUserIsAdmin()) {
      _setError(
        'Administrator access required.',
      );

      return false;
    }

    final targetUserId = userId.trim();

    if (targetUserId.isEmpty) {
      _setError(
        'Invalid user ID.',
      );

      return false;
    }

    try {
      _clearError();

      /*
       * The database RPC owns the annual subscription rule.
       * Flutter does not calculate or forge the expiry date.
       */
      await _supabase.rpc(
        'activate_annual_subscription',
        params: {
          'target_user_id': targetUserId,
        },
      );

      await loadUsers();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin activateUser error: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to activate user.',
      );

      return false;
    }
  }

  // ============================================================
  // DEACTIVATE USER
  // ============================================================

  Future<bool> deactivateUser(
    String userId,
  ) async {
    if (!checkCurrentUserIsAdmin()) {
      _setError(
        'Administrator access required.',
      );

      return false;
    }

    final targetUserId = userId.trim();

    if (targetUserId.isEmpty) {
      _setError(
        'Invalid user ID.',
      );

      return false;
    }

    try {
      _clearError();

      await _supabase
          .from('user_subscriptions')
          .update({
            'status': 'inactive',
          })
          .eq(
            'user_id',
            targetUserId,
          );

      await loadUsers();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin deactivateUser error: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to deactivate user.',
      );

      return false;
    }
  }

  // ============================================================
  // ACTIVE USER CHECK
  // ============================================================

  Future<bool> isUserActive(
    String userId,
  ) async {
    final targetUserId = userId.trim();

    if (targetUserId.isEmpty) {
      return false;
    }

    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select(
            'status, expires_at',
          )
          .eq(
            'user_id',
            targetUserId,
          )
          .maybeSingle();

      if (response == null) {
        return false;
      }

      final status =
          response['status']
              ?.toString()
              .trim()
              .toLowerCase();

      if (status != 'active') {
        return false;
      }

      final expiresAt =
          _parseDate(response['expires_at']);

      if (expiresAt == null) {
        return false;
      }

      return expiresAt.isAfter(
        DateTime.now(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'isUserActive error: '
        '$error\n$stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // EXPIRATION
  // ============================================================

  bool isExpired(
    Map<String, dynamic> user,
  ) {
    final status =
        user['status']
            ?.toString()
            .trim()
            .toLowerCase();

    if (status != 'active') {
      return true;
    }

    final expiry =
        _parseDate(user['expires_at']);

    if (expiry == null) {
      return true;
    }

    return !expiry.isAfter(
      DateTime.now(),
    );
  }

  bool expiresWithin20Days(
    Map<String, dynamic> user,
  ) {
    final status =
        user['status']
            ?.toString()
            .trim()
            .toLowerCase();

    if (status != 'active') {
      return false;
    }

    final expiry =
        _parseDate(user['expires_at']);

    if (expiry == null) {
      return false;
    }

    final now = DateTime.now();

    final difference =
        expiry.difference(now);

    return !difference.isNegative &&
        difference <=
            const Duration(days: 20);
  }

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

    return DateTime.tryParse(text);
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

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _isAdmin = false;
    _isLoading = false;
    _errorMessage = null;
    _users.clear();

    notifyListeners();
  }
}