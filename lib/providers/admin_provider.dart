import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider extends ChangeNotifier {
  static const String adminEmail = 'malazjanbeih@gmail.com';

  bool _isAdmin = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _users = [];

  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get users =>
      List.unmodifiable(_users);

  SupabaseClient get _supabase =>
      Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // ADMIN CHECK
  // ---------------------------------------------------------------------------

  Future<bool> checkAdminStatus(String userId) async {
    try {
      final currentUser =
          _supabase.auth.currentUser;

      if (currentUser == null ||
          currentUser.id != userId) {
        _isAdmin = false;
        notifyListeners();
        return false;
      }

      final email =
          currentUser.email?.trim().toLowerCase();

      _isAdmin = email == adminEmail;

      notifyListeners();

      return _isAdmin;
    } catch (e) {
      debugPrint(
        'Admin status check error: $e',
      );

      _isAdmin = false;
      notifyListeners();

      return false;
    }
  }

  bool checkCurrentUserIsAdmin() {
    final email =
        _supabase.auth.currentUser?.email
            ?.trim()
            .toLowerCase();

    _isAdmin = email == adminEmail;

    notifyListeners();

    return _isAdmin;
  }

  // ---------------------------------------------------------------------------
  // LOAD USERS
  // ---------------------------------------------------------------------------

  Future<void> loadUsers() async {
    if (!checkCurrentUserIsAdmin()) {
      _users = [];
      _errorMessage =
          'Administrator access required.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select('*')
          .order(
            'created_at',
            ascending: false,
          );

      _users = List<Map<String, dynamic>>.from(
        response,
      );
    } catch (e) {
      _errorMessage =
          'Unable to load users: $e';

      debugPrint(
        'Admin loadUsers error: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVATE USER FOR ONE YEAR
  // ---------------------------------------------------------------------------

  Future<bool> activateUser(
    String userId,
    String email,
    String phone,
  ) async {
    if (!checkCurrentUserIsAdmin()) {
      return false;
    }

    if (userId.trim().isEmpty) {
      _errorMessage =
          'Invalid user ID.';
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;

      await _supabase.rpc(
        'activate_annual_subscription',
        params: {
          'target_user_id': userId,
        },
      );

      await loadUsers();

      return true;
    } catch (e) {
      _errorMessage =
          'Unable to activate user: $e';

      debugPrint(
        'Admin activateUser error: $e',
      );

      notifyListeners();

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // DEACTIVATE USER
  // ---------------------------------------------------------------------------

  Future<bool> deactivateUser(
    String userId,
  ) async {
    if (!checkCurrentUserIsAdmin()) {
      return false;
    }

    if (userId.trim().isEmpty) {
      _errorMessage =
          'Invalid user ID.';
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;

      await _supabase
          .from('user_subscriptions')
          .update({
            'status': 'inactive',
          })
          .eq(
            'user_id',
            userId,
          );

      await loadUsers();

      return true;
    } catch (e) {
      _errorMessage =
          'Unable to deactivate user: $e';

      debugPrint(
        'Admin deactivateUser error: $e',
      );

      notifyListeners();

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVE USER CHECK
  // ---------------------------------------------------------------------------

  Future<bool> isUserActive(
    String userId,
  ) async {
    if (userId.trim().isEmpty) {
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
            userId,
          )
          .maybeSingle();

      if (response == null) {
        return false;
      }

      final status =
          response['status']
              ?.toString()
              .toLowerCase();

      if (status != 'active') {
        return false;
      }

      final rawExpiry =
          response['expires_at'];

      if (rawExpiry == null) {
        return false;
      }

      final expiresAt =
          DateTime.tryParse(
        rawExpiry.toString(),
      );

      if (expiresAt == null) {
        return false;
      }

      return expiresAt.isAfter(
        DateTime.now(),
      );
    } catch (e) {
      debugPrint(
        'isUserActive error: $e',
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // EXPIRY / WARNING HELPERS
  // ---------------------------------------------------------------------------

  bool isExpired(
    Map<String, dynamic> user,
  ) {
    final status =
        user['status']?.toString().toLowerCase();

    if (status != 'active') {
      return true;
    }

    final rawExpiry =
        user['expires_at'];

    if (rawExpiry == null) {
      return true;
    }

    final expiry =
        DateTime.tryParse(
      rawExpiry.toString(),
    );

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
        user['status']?.toString().toLowerCase();

    if (status != 'active') {
      return false;
    }

    final rawExpiry =
        user['expires_at'];

    if (rawExpiry == null) {
      return false;
    }

    final expiry =
        DateTime.tryParse(
      rawExpiry.toString(),
    );

    if (expiry == null) {
      return false;
    }

    final now = DateTime.now();

    final difference =
        expiry.difference(now);

    return !difference.isNegative &&
        difference.inDays <= 20;
  }

  // ---------------------------------------------------------------------------
  // CLEAR ERROR
  // ---------------------------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------

  void reset() {
    _isAdmin = false;
    _isLoading = false;
    _errorMessage = null;
    _users = [];
    notifyListeners();
  }
}