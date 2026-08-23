import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/subscription_service.dart';

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

    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', authUser.id)
          .maybeSingle();

      final role = response?['role']
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

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
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      _setAdmin(false);
      return false;
    }

    if (currentUser.id.trim() !=
        userId.trim()) {
      _setAdmin(false);
      return false;
    }

    return checkCurrentUserIsAdmin();
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
       * Load users.
       *
       * Administrators are excluded from the customer list.
       */
      final response = await _supabase
          .from('users')
          .select(
            'id, name, email, phone, '
            'created_at, is_active, '
            'expiry_date, role',
          )
          .order(
            'created_at',
            ascending: false,
          );

      final loadedUsers =
          <Map<String, dynamic>>[];

      for (final item in response) {
        final user =
            Map<String, dynamic>.from(item);

        final role = user['role']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        if (role == 'admin') {
          continue;
        }

        final userId =
            user['id']?.toString().trim() ??
                '';

        if (userId.isEmpty) {
          continue;
        }

        /*
         * Normalize fields so the AdminScreen can use
         * consistent names.
         */
        user['user_id'] = userId;
        user['user_name'] =
            user['name']?.toString() ?? '';
        user['user_email'] =
            user['email']?.toString() ?? '';
        user['user_phone'] =
            user['phone']?.toString() ?? '';

        loadedUsers.add(user);
      }

      // ========================================================
      // LOAD SUBSCRIPTIONS
      // ========================================================

      final subscriptionResponse =
          await _supabase
              .from('user_subscriptions')
              .select(
                'id, user_id, user_email, '
                'user_phone, status, '
                'activated_at, expires_at, '
                'reminder_20day_sent, created_at',
              );

      /*
       * Map subscription data to the corresponding user.
       */
      for (final item
          in subscriptionResponse) {
        final subscription =
            Map<String, dynamic>.from(item);

        final subscriptionUserId =
            subscription['user_id']
                    ?.toString()
                    .trim() ??
                '';

        if (subscriptionUserId.isEmpty) {
          continue;
        }

        final index =
            loadedUsers.indexWhere(
          (user) =>
              user['id']?.toString() ==
              subscriptionUserId,
        );

        if (index == -1) {
          continue;
        }

        loadedUsers[index]
          ..['subscription_id'] =
              subscription['id']
          ..['subscription_status'] =
              subscription['status']
          ..['subscription_activated_at'] =
              subscription['activated_at']
          ..['subscription_expires_at'] =
              subscription['expires_at']
          ..['payment_user_email'] =
              subscription['user_email']
          ..['payment_user_phone'] =
              subscription['user_phone']
          ..['reminder_20day_sent'] =
              subscription[
                  'reminder_20day_sent'];
      }

      /*
       * Give users without a subscription a predictable
       * pending state.
       */
      for (final user in loadedUsers) {
        user['subscription_status'] ??=
            'pending';

        user['subscription_activated_at'] ??=
            null;

        user['subscription_expires_at'] ??=
            user['expiry_date'];

        user['payment_status'] =
            _paymentStatusForUser(user);
      }

      _users
        ..clear()
        ..addAll(loadedUsers);

      notifyListeners();

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
    String userId, {
    String transactionId = '',
    double amount = 0,
    String currency = 'USD',
    DateTime? paidAt,
    String? notes,
  }) async {
    final authorized =
        await checkCurrentUserIsAdmin();

    if (!authorized) {
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

    /*
     * Keep these validations because the AdminScreen currently
     * requires payment confirmation before activation.
     */
    if (transactionId.trim().isEmpty) {
      _setError(
        'Transaction ID is required.',
      );

      return false;
    }

    if (amount <= 0) {
      _setError(
        'Payment amount must be greater than zero.',
      );

      return false;
    }

    try {
      _clearError();

      /*
       * IMPORTANT:
       *
       * SubscriptionService calls:
       *
       * public.activate_annual_subscription(uuid)
       *
       * PostgreSQL calculates:
       *
       * now() + interval '1 year'
       *
       * Therefore Flutter never calculates the subscription
       * expiry date.
       */
      await SubscriptionService
          .adminConfirmPayment(
        userId: targetUserId,
        transactionId:
            transactionId.trim(),
        amount: amount,
        currency:
            currency.trim().isEmpty
                ? 'USD'
                : currency.trim(),
        paidAt: paidAt,
        notes: notes,
      );

      await loadUsers();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin activate user failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to activate user.',
        ),
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
    final authorized =
        await checkCurrentUserIsAdmin();

    if (!authorized) {
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

      /*
       * Deactivation is NON-DESTRUCTIVE.
       *
       * User data is not deleted.
       */
      await _supabase
          .from('user_subscriptions')
          .update({
        'status': 'expired',
        'reminder_20day_sent': false,
      }).eq(
        'user_id',
        targetUserId,
      );

      await _supabase
          .from('users')
          .update({
        'is_active': false,
      }).eq(
        'id',
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
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to deactivate user.',
        ),
      );

      return false;
    }
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool isActive(
    Map<String, dynamic> user,
  ) {
    final status =
        user['subscription_status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final expiresAt =
        expiryDate(user);

    if (status != 'active') {
      return false;
    }

    if (expiresAt == null) {
      return false;
    }

    return expiresAt.isAfter(
      DateTime.now().toUtc(),
    );
  }

  bool isExpired(
    Map<String, dynamic> user,
  ) {
    final expiresAt =
        expiryDate(user);

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
        expiryDate(user);

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
    final status =
        user['subscription_status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status == 'pending') {
      return 'Pending';
    }

    if (status == 'active' &&
        isActive(user)) {
      return 'Active';
    }

    if (status == 'expired' ||
        isExpired(user)) {
      return 'Expired';
    }

    if (isActive(user)) {
      return 'Active';
    }

    return 'Inactive';
  }

  String paymentText(
    Map<String, dynamic> user,
  ) {
    final status =
        user['subscription_status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status == 'active' &&
        isActive(user)) {
      return 'Paid';
    }

    return 'Pending';
  }

  DateTime? expiryDate(
    Map<String, dynamic> user,
  ) {
    return _parseDate(
      user['subscription_expires_at'] ??
          user['expiry_date'],
    );
  }

  DateTime? activatedDate(
    Map<String, dynamic> user,
  ) {
    return _parseDate(
      user['subscription_activated_at'],
    );
  }

  int? daysRemaining(
    Map<String, dynamic> user,
  ) {
    final expiry =
        expiryDate(user);

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
  // PAYMENT STATUS
  // ============================================================

  String _paymentStatusForUser(
    Map<String, dynamic> user,
  ) {
    final status =
        user['subscription_status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status == 'active' &&
        isActive(user)) {
      return 'paid';
    }

    return 'pending';
  }

  // ============================================================
  // DATE PARSING
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
  // ERROR HANDLING
  // ============================================================

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

  void _setAdmin(
    bool value,
  ) {
    if (_isAdmin == value) {
      return;
    }

    _isAdmin = value;

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