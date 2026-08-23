import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

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
  // ============================================================

  Future<bool> loadUsers() async {
    _setLoading(true);
    _clearError();

    try {
      /*
       * The admin screen works with the subscription-aware
       * fields below.
       *
       * We read the user profile together with the current
       * subscription so the UI always receives one normalized
       * user record.
       */

      final response = await _supabase
          .from('users')
          .select('''
            id,
            name,
            email,
            phone,
            role,
            is_active,
            expiry_date,
            created_at,
            subscriptions (
              id,
              status,
              expires_at,
              started_at,
              transaction_id,
              amount,
              currency,
              paid_at,
              notes
            )
          ''')
          .order(
            'created_at',
            ascending: false,
          );

      final result = <Map<String, dynamic>>[];

      for (final raw in response) {
        final row =
            Map<String, dynamic>.from(raw as Map);

        final subscriptionRaw =
            row['subscriptions'];

        Map<String, dynamic>? subscription;

        if (subscriptionRaw is List &&
            subscriptionRaw.isNotEmpty) {
          final first =
              subscriptionRaw.first;

          if (first is Map) {
            subscription =
                Map<String, dynamic>.from(first);
          }
        } else if (subscriptionRaw is Map) {
          subscription =
              Map<String, dynamic>.from(
            subscriptionRaw,
          );
        }

        /*
         * Normalize the record to the exact keys consumed
         * by AdminScreen.
         */

        final user = <String, dynamic>{
          'user_id': row['id'],
          'user_name': row['name'],
          'user_email': row['email'],
          'user_phone': row['phone'],
          'role': row['role'],
          'created_at': row['created_at'],

          'is_active':
              subscription?['status']
                      ?.toString()
                      .trim()
                      .toLowerCase() ==
                  'active'
                  ? true
                  : row['is_active'] == true,

          'expiry_date':
              subscription?['expires_at'] ??
                  row['expiry_date'],

          'subscription_status':
              subscription?['status'],

          'subscription_id':
              subscription?['id'],

          'transaction_id':
              subscription?['transaction_id'],

          'amount':
              subscription?['amount'],

          'currency':
              subscription?['currency'],

          'paid_at':
              subscription?['paid_at'],

          'started_at':
              subscription?['started_at'],

          'notes':
              subscription?['notes'],
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

      /*
       * Fallback query.
       *
       * This keeps the admin panel usable if the
       * subscriptions relationship is not exposed through
       * Supabase's generated relationship query.
       */
      try {
        final response = await _supabase
            .from('users')
            .select('''
              id,
              name,
              email,
              phone,
              role,
              is_active,
              expiry_date,
              created_at
            ''')
            .order(
              'created_at',
              ascending: false,
            );

        _users = response.map<Map<String, dynamic>>(
          (raw) {
            final row =
                Map<String, dynamic>.from(
              raw as Map,
            );

            return {
              'user_id': row['id'],
              'user_name': row['name'],
              'user_email': row['email'],
              'user_phone': row['phone'],
              'role': row['role'],
              'created_at': row['created_at'],
              'is_active': row['is_active'] == true,
              'expiry_date': row['expiry_date'],
              'subscription_status': null,
              'subscription_id': null,
              'transaction_id': null,
              'amount': null,
              'currency': null,
              'paid_at': null,
              'started_at': null,
              'notes': null,
            };
          },
        ).toList();

        _setError(
          'Subscription details could not be loaded. '
          'Showing user profile data.',
        );

        return true;
      } catch (fallbackError, fallbackStack) {
        debugPrint(
          'AdminProvider fallback load failed: '
          '$fallbackError\n$fallbackStack',
        );

        _setError(
          _cleanErrorMessage(
            fallbackError,
            fallback:
                'Unable to load users.',
          ),
        );

        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool isActive(
    Map<String, dynamic> user,
  ) {
    final status =
        user['subscription_status']
            ?.toString()
            .trim()
            .toLowerCase();

    if (status == 'active') {
      final expiry =
          _parseDate(user['expiry_date']);

      if (expiry == null) {
        return true;
      }

      return expiry.isAfter(
        DateTime.now().toUtc(),
      );
    }

    final value = user['is_active'];

    if (value is bool && !value) {
      return false;
    }

    final expiry =
        _parseDate(user['expiry_date']);

    if (expiry == null) {
      return value == true;
    }

    return expiry.isAfter(
      DateTime.now().toUtc(),
    );
  }

  bool isExpired(
    Map<String, dynamic> user,
  ) {
    final expiry =
        _parseDate(user['expiry_date']);

    if (expiry == null) {
      return false;
    }

    return !expiry.isAfter(
      DateTime.now().toUtc(),
    );
  }

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
        _parseDate(user['expiry_date']);

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

  bool expiresWithin20Days(
    Map<String, dynamic> user,
  ) {
    if (!isActive(user)) {
      return false;
    }

    final remaining =
        daysRemaining(user);

    if (remaining == null) {
      return false;
    }

    return remaining >= 0 &&
        remaining <= 20;
  }

  // ============================================================
  // ACTIVATE USER
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
      /*
       * IMPORTANT:
       *
       * The expiry date is NOT calculated by Flutter.
       * The protected Supabase RPC is responsible for creating
       * the one-year subscription.
       *
       * Expected RPC:
       *
       *   admin_activate_user
       *
       * Parameters:
       *   p_user_id
       *   p_transaction_id
       *   p_amount
       *   p_currency
       *   p_paid_at
       *   p_notes
       */

      await _supabase.rpc(
        'admin_activate_user',
        params: {
          'p_user_id': userId,
          'p_transaction_id': transactionId,
          'p_amount': amount,
          'p_currency': currency,
          'p_paid_at':
              paidAt.toUtc().toIso8601String(),
          'p_notes': notes,
        },
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
  // ============================================================

  Future<bool> deactivateUser(
    String userId,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      /*
       * Deactivation is intentionally non-destructive.
       *
       * The backend RPC changes the subscription state and
       * does NOT delete the user's data.
       */

      await _supabase.rpc(
        'admin_deactivate_user',
        params: {
          'p_user_id': userId,
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
    for (final user in _users) {
      if (user['user_id']?.toString() ==
          userId) {
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
    _users = [];
    _clearError();
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

    return DateTime.tryParse(text)?.toUtc();
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