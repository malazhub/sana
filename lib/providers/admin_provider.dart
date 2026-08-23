import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/subscription_service.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  List<Map<String, dynamic>> _users = [];

  bool _isLoading = false;
  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  List<Map<String, dynamic>> get users =>
      List.unmodifiable(_users);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // LOAD USERS
  //
  // IMPORTANT:
  //
  // The current SANA schema uses:
  //
  //   users
  //   user_subscriptions
  //   payment_confirmations
  //
  // We do NOT use a "subscriptions" relationship here.
  // ============================================================

  Future<bool> loadUsers() async {
    _setLoading(true);
    _clearError();

    try {
      final usersResponse = await _supabase
          .from('users')
          .select(
            'id, '
            'name, '
            'email, '
            'phone, '
            'role, '
            'is_active, '
            'expiry_date, '
            'created_at',
          )
          .order(
            'created_at',
            ascending: false,
          );

      final subscriptionResponse = await _supabase
          .from('user_subscriptions')
          .select(
            'id, '
            'user_id, '
            'user_email, '
            'user_phone, '
            'status, '
            'activated_at, '
            'expires_at, '
            'reminder_20day_sent, '
            'created_at',
          );

      final subscriptionsByUserId =
          <String, Map<String, dynamic>>{};

      for (final raw in subscriptionResponse) {
        final subscription =
            Map<String, dynamic>.from(
          raw as Map,
        );

        final userId =
            subscription['user_id']
                ?.toString()
                .trim();

        if (userId == null ||
            userId.isEmpty) {
          continue;
        }

        subscriptionsByUserId[userId] =
            subscription;
      }

      final result =
          <Map<String, dynamic>>[];

      for (final raw in usersResponse) {
        final row =
            Map<String, dynamic>.from(
          raw as Map,
        );

        final userId =
            row['id']?.toString().trim() ?? '';

        final subscription =
            subscriptionsByUserId[userId];

        final subscriptionStatus =
            subscription?['status']
                ?.toString()
                .trim()
                .toLowerCase();

        final subscriptionExpiry =
            subscription?['expires_at'];

        final activeFromSubscription =
            subscriptionStatus == 'active' &&
            _isFutureDate(
              subscriptionExpiry,
            );

        final user = <String, dynamic>{
          // ------------------------------------------------------
          // Identity
          // ------------------------------------------------------

          'user_id':
              row['id'],

          'user_name':
              row['name'],

          'user_email':
              row['email'],

          'user_phone':
              row['phone'],

          'role':
              row['role'],

          'created_at':
              row['created_at'],

          // ------------------------------------------------------
          // Access state
          // ------------------------------------------------------

          'is_active':
              activeFromSubscription
                  ? true
                  : row['is_active'] == true,

          'expiry_date':
              subscriptionExpiry ??
                  row['expiry_date'],

          // ------------------------------------------------------
          // Subscription
          // ------------------------------------------------------

          'subscription_id':
              subscription?['id'],

          'subscription_status':
              subscription?['status'],

          'activated_at':
              subscription?['activated_at'],

          'expires_at':
              subscription?['expires_at'],

          'reminder_20day_sent':
              subscription?[
                  'reminder_20day_sent'],

          'subscription_created_at':
              subscription?['created_at'],
        };

        result.add(user);
      }

      _users = result;

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'AdminProvider.loadUsers failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback:
              'Unable to load users.',
        ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ACTIVE
  // ============================================================

  bool isActive(
    Map<String, dynamic> user,
  ) {
    final status =
        user['subscription_status']
            ?.toString()
            .trim()
            .toLowerCase();

    final expiry =
        _parseDate(
      user['expiry_date'] ??
          user['expires_at'],
    );

    if (status == 'active') {
      if (expiry == null) {
        return false;
      }

      return expiry.isAfter(
        DateTime.now().toUtc(),
      );
    }

    final legacyActive =
        user['is_active'];

    if (legacyActive is! bool ||
        !legacyActive) {
      return false;
    }

    if (expiry == null) {
      return true;
    }

    return expiry.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // EXPIRED
  // ============================================================

  bool isExpired(
    Map<String, dynamic> user,
  ) {
    final expiry =
        _parseDate(
      user['expiry_date'] ??
          user['expires_at'],
    );

    if (expiry == null) {
      return false;
    }

    return !expiry.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String statusText(
    Map<String, dynamic> user,
  ) {
    if (isActive(user)) {
      return 'Active';
    }

    if (isExpired(user)) {
      return 'Expired';
    }

    return 'Pending';
  }

  // ============================================================
  // DAYS REMAINING
  // ============================================================

  int? daysRemaining(
    Map<String, dynamic> user,
  ) {
    final expiry =
        _parseDate(
      user['expiry_date'] ??
          user['expires_at'],
    );

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
  // EXPIRING WITHIN 20 DAYS
  // ============================================================

  bool expiresWithin20Days(
    Map<String, dynamic> user,
  ) {
    if (!isActive(user)) {
      return false;
    }

    final expiry =
        _parseDate(
      user['expiry_date'] ??
          user['expires_at'],
    );

    if (expiry == null) {
      return false;
    }

    final now =
        DateTime.now().toUtc();

    if (!expiry.isAfter(now)) {
      return false;
    }

    return expiry.difference(now) <=
        const Duration(days: 20);
  }

  // ============================================================
  // ACTIVATE USER
  //
  // IMPORTANT:
  //
  // Do NOT call admin_activate_user().
  //
  // The actual backend RPC from the revised SQL migration is:
  //
  //   admin_confirm_payment()
  //
  // SubscriptionService owns the RPC call.
  //
  // PostgreSQL calculates the one-year expiry.
  // Flutter never calculates expires_at.
  // ============================================================

  Future<bool> activateUser(
    String userId, {
    required String transactionId,
    required double amount,
    required String currency,
    required DateTime paidAt,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await SubscriptionService.adminConfirmPayment(
        userId: userId,
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        paidAt: paidAt,
        notes: notes,
      );

      await loadUsers();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'AdminProvider.activateUser failed: '
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
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // DEACTIVATE USER
  //
  // Backend RPC:
  //
  //   admin_deactivate_user(p_user_id)
  //
  // This is non-destructive.
  // ============================================================

  Future<bool> deactivateUser(
    String userId,
  ) async {
    final cleanUserId =
        userId.trim();

    if (cleanUserId.isEmpty) {
      _setError(
        'Customer is required.',
      );
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase.rpc(
        'admin_deactivate_user',
        params: {
          'p_user_id':
              cleanUserId,
        },
      );

      await loadUsers();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'AdminProvider.deactivateUser failed: '
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
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // FIND USER
  // ============================================================

  Map<String, dynamic>? findUser(
    String userId,
  ) {
    final cleanUserId =
        userId.trim();

    if (cleanUserId.isEmpty) {
      return null;
    }

    for (final user in _users) {
      if (user['user_id']
              ?.toString()
              .trim() ==
          cleanUserId) {
        return user;
      }
    }

    return null;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<bool> refresh() {
    return loadUsers();
  }

  // ============================================================
  // CLEAR USERS
  // ============================================================

  void clear() {
    _users = [];
    _errorMessage = null;
    notifyListeners();
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

  bool _isFutureDate(
    dynamic value,
  ) {
    final date =
        _parseDate(value);

    if (date == null) {
      return false;
    }

    return date.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // ERROR CLEANING
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
}