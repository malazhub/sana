import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final List<Map<String, dynamic>> _users = [];

  bool _isAdmin = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAdmin => _isAdmin;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get users =>
      List.unmodifiable(_users);

  // ============================================================
  // ADMIN AUTHORIZATION
  // ============================================================

  Future<bool> checkCurrentUserIsAdmin() async {
    final authUser =
        _supabase.auth.currentUser;

    if (authUser == null) {
      _setAdmin(false);
      return false;
    }

    final authUserId = authUser.id.trim();

    if (authUserId.isEmpty) {
      _setAdmin(false);
      return false;
    }

    try {
      /*
       * IMPORTANT:
       *
       * Supabase Auth user.id maps to users.user_id.
       *
       * Do NOT use users.id here.
       */
      final response = await _supabase
          .from('users')
          .select('role')
          .eq(
            'user_id',
            authUserId,
          )
          .maybeSingle();

      if (response == null) {
        _setAdmin(false);
        return false;
      }

      final role =
          response['role']
              ?.toString()
              .trim()
              .toLowerCase();

      final authorized =
          role == 'admin';

      _setAdmin(authorized);

      return authorized;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin authorization check failed: '
        '$error\n$stackTrace',
      );

      _setAdmin(false);

      return false;
    }
  }

  Future<bool> checkAdminStatus(
    String userId,
  ) async {
    final requestedUserId =
        userId.trim();

    if (requestedUserId.isEmpty) {
      _setAdmin(false);
      return false;
    }

    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      _setAdmin(false);
      return false;
    }

    if (currentUser.id != requestedUserId) {
      _setAdmin(false);
      return false;
    }

    return checkCurrentUserIsAdmin();
  }

  void _setAdmin(
    bool value,
  ) {
    if (_isAdmin == value) {
      return;
    }

    _isAdmin = value;
    notifyListeners();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<bool> loadUsers() async {
    if (_isLoading) {
      return false;
    }

    final authorized =
        await checkCurrentUserIsAdmin();

    if (!authorized) {
      _users.clear();

      _setError(
        'Administrator access required.',
      );

      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      /*
       * Use the SAME columns used everywhere else.
       */
      final response = await _supabase
          .from('users')
          .select(
            'user_id, name, user_email, user_phone, '
            'role, status, activated_at, expires_at',
          )
          .order(
            'user_email',
            ascending: true,
          );

      final loadedUsers =
          <Map<String, dynamic>>[];

      for (final item in response) {
        final user =
            Map<String, dynamic>.from(
          item,
        );

        final role =
            user['role']
                ?.toString()
                .trim()
                .toLowerCase();

        /*
         * Do not display administrator accounts
         * in the customer list.
         */
        if (role == 'admin') {
          continue;
        }

        loadedUsers.add(user);
      }

      _users
        ..clear()
        ..addAll(loadedUsers);

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin load users failed: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to load users.',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ACTIVATE USER
  // ============================================================

  Future<bool> activateUser(
    String userId,
  ) async {
    if (!await checkCurrentUserIsAdmin()) {
      _setError(
        'Administrator access required.',
      );

      return false;
    }

    final targetUserId =
        userId.trim();

    if (targetUserId.isEmpty) {
      _setError(
        'Invalid user ID.',
      );

      return false;
    }

    try {
      _clearError();

      final now =
          DateTime.now().toUtc();

      final expiresAt =
          DateTime(
        now.year + 1,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ).toUtc();

      await _supabase
          .from('users')
          .update({
        'status': 'active',
        'activated_at':
            now.toIso8601String(),
        'expires_at':
            expiresAt.toIso8601String(),
      })
          .eq(
        'user_id',
        targetUserId,
      );

      await loadUsers();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin activate user failed: '
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
    if (!await checkCurrentUserIsAdmin()) {
      _setError(
        'Administrator access required.',
      );

      return false;
    }

    final targetUserId =
        userId.trim();

    if (targetUserId.isEmpty) {
      _setError(
        'Invalid user ID.',
      );

      return false;
    }

    try {
      _clearError();

      await _supabase
          .from('users')
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
        'Admin deactivate user failed: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to deactivate user.',
      );

      return false;
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool isActive(
    Map<String, dynamic> user,
  ) {
    final status =
        user['status']
            ?.toString()
            .trim()
            .toLowerCase();

    return status == 'active';
  }

  bool isExpired(
    Map<String, dynamic> user,
  ) {
    final expiresAt =
        _parseDate(
      user['expires_at'],
    );

    if (expiresAt == null) {
      return false;
    }

    return !expiresAt.isAfter(
      DateTime.now().toUtc(),
    );
  }

  bool expiresWithin20Days(
    Map<String, dynamic> user,
  ) {
    if (!isActive(user)) {
      return false;
    }

    final expiresAt =
        _parseDate(
      user['expires_at'],
    );

    if (expiresAt == null) {
      return false;
    }

    final difference =
        expiresAt.difference(
      DateTime.now().toUtc(),
    );

    return !difference.isNegative &&
        difference <=
            const Duration(days: 20);
  }

  String statusText(
    Map<String, dynamic> user,
  ) {
    if (isExpired(user)) {
      return 'Expired';
    }

    if (isActive(user)) {
      return 'Active';
    }

    return 'Pending';
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