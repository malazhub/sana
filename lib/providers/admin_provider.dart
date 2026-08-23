import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/subscription_service.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];

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
  // LOAD CUSTOMERS
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
          .neq('role', 'admin')
          .order(
            'created_at',
            ascending: false,
          );

      final subscriptionsResponse = await _supabase
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

      for (final rawSubscription in subscriptionsResponse) {
        final subscription =
            Map<String, dynamic>.from(rawSubscription);

        final userId =
            subscription['user_id']?.toString().trim() ?? '';

        if (userId.isEmpty) {
          continue;
        }

        subscriptionsByUserId[userId] = subscription;
      }

      final result = <Map<String, dynamic>>[];

      for (final rawUser in usersResponse) {
        final user =
            Map<String, dynamic>.from(rawUser);

        final userId =
            user['id']?.toString().trim() ?? '';

        if (userId.isEmpty) {
          continue;
        }

        final subscription =
            subscriptionsByUserId[userId];

        result.add({
          'user_id': user['id'],
          'user_name': user['name'],
          'user_email': user['email'],
          'user_phone': user['phone'],
          'role': user['role'],
          'created_at': user['created_at'],

          'is_active': user['is_active'],
          'expiry_date': user['expiry_date'],

          'subscription_id':
              subscription?['id'],
          'subscription_status':
              subscription?['status'],
          'activated_at':
              subscription?['activated_at'],
          'expires_at':
              subscription?['expires_at'],
          'reminder_20day_sent':
              subscription?['reminder_20day_sent'],
          'subscription_created_at':
              subscription?['created_at'],
        });
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
          fallback: 'Unable to load customers.',
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
    final status = user['subscription_status']
        ?.toString()
        .trim()
        .toLowerCase();

    final expiry = _parseDate(
      user['expires_at'] ??
          user['expiry_date'],
    );

    if (status != null && status.isNotEmpty) {
      if (status != 'active') {
        return false;
      }

      if (expiry == null) {
        return false;
      }

      return expiry.isAfter(
        DateTime.now().toUtc(),
      );
    }

    final legacyActive = user['is_active'];

    if (legacyActive is! bool || !legacyActive) {
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
    final status = user['subscription_status']
        ?.toString()
        .trim()
        .toLowerCase();

    final expiry = _parseDate(
      user['expires_at'] ??
          user['expiry_date'],
    );

    if (status == 'expired') {
      return true;
    }

    if (expiry == null) {
      return false;
    }

    return !expiry.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // STATUS
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
    final expiry = _parseDate(
      user['expires_at'] ??
          user['expiry_date'],
    );

    if (expiry == null) {
      return null;
    }

    final now = DateTime.now().toUtc();

    if (!expiry.isAfter(now)) {
      return 0;
    }

    return expiry.difference(now).inDays;
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

    final expiry = _parseDate(
      user['expires_at'] ??
          user['expiry_date'],
    );

    if (expiry == null) {
      return false;
    }

    final now = DateTime.now().toUtc();

    if (!expiry.isAfter(now)) {
      return false;
    }

    return expiry.difference(now) <=
        const Duration(days: 20);
  }

  // ============================================================
  // ACTIVATE USER
  //
  // Payment confirmation and subscription activation are
  // performed by the protected PostgreSQL RPC.
  //
  // Flutter NEVER calculates expires_at.
  // ============================================================

  Future<bool> activateUser(
    String userId, {
    required String transactionId,
    required double amount,
    required String currency,
    required DateTime paidAt,
    String? notes,
  }) async {
    final cleanUserId = userId.trim();
    final cleanTransactionId = transactionId.trim();
    final cleanCurrency = currency.trim();

    if (cleanUserId.isEmpty) {
      _setError('Customer is required.');
      return false;
    }

    if (cleanTransactionId.length < 3) {
      _setError('Transaction ID is required.');
      return false;
    }

    if (amount <= 0) {
      _setError(
        'Payment amount must be greater than zero.',
      );
      return false;
    }

    if (cleanCurrency.isEmpty) {
      _setError('Currency is required.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await SubscriptionService.adminConfirmPayment(
        userId: cleanUserId,
        transactionId: cleanTransactionId,
        amount: amount,
        currency: cleanCurrency,
        paidAt: paidAt,
        notes: notes,
      );

      return await loadUsers();
    } catch (error, stackTrace) {
      debugPrint(
        'AdminProvider.activateUser failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback: 'Unable to activate customer.',
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
  // The protected PostgreSQL RPC performs the actual change.
  //
  // No customer/application data is deleted.
  // ============================================================

  Future<bool> deactivateUser(
    String userId,
  ) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      _setError('Customer is required.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _supabase.rpc(
        'admin_deactivate_user',
        params: {
          // IMPORTANT:
          // This must exactly match the SQL RPC parameter:
          // admin_deactivate_user(target_user_id uuid)
          'target_user_id': cleanUserId,
        },
      );

      return await loadUsers();
    } catch (error, stackTrace) {
      debugPrint(
        'AdminProvider.deactivateUser failed: '
        '$error\n$stackTrace',
      );

      _setError(
        _cleanErrorMessage(
          error,
          fallback: 'Unable to deactivate customer.',
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
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return null;
    }

    for (final user in _users) {
      final currentId =
          user['user_id']?.toString().trim();

      if (currentId == cleanUserId) {
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
  // CLEAR
  // ============================================================

  void clear() {
    _users = <Map<String, dynamic>>[];
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

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(text);

    if (parsed == null) {
      return null;
    }

    return parsed.toUtc();
  }

  // ============================================================
  // ERROR CLEANING
  // ============================================================

  String _cleanErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return fallback;
    }

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }
}