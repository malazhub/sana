import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // ADMIN
  // CONFIRM PAYMENT + ACTIVATE SUBSCRIPTION
  //
  // IMPORTANT:
  // Flutter NEVER calculates expires_at.
  //
  // PostgreSQL admin_confirm_payment() controls:
  //   - administrator authorization
  //   - payment recording
  //   - transaction uniqueness
  //   - activation time
  //   - one-year subscription period
  //   - subscription status
  //   - users.is_active
  //   - users.expiry_date
  // ============================================================

  static Future<void> adminConfirmPayment({
    required String userId,
    required String transactionId,
    required double amount,
    String currency = 'USD',
    DateTime? paidAt,
    String? notes,
  }) async {
    final cleanUserId = userId.trim();

    final cleanTransactionId = transactionId.trim();

    final cleanCurrency = currency.trim().toUpperCase();

    final cleanNotes = notes?.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (cleanUserId.isEmpty) {
      throw Exception(
        'Customer is required.',
      );
    }

    if (cleanTransactionId.length < 3) {
      throw Exception(
        'Transaction ID is required.',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Payment amount must be greater than zero.',
      );
    }

    if (cleanCurrency.isEmpty) {
      throw Exception(
        'Currency is required.',
      );
    }

    try {
      await _supabase.rpc(
        'admin_confirm_payment',
        params: {
          'target_user_id': cleanUserId,
          'p_transaction_id': cleanTransactionId,
          'p_amount': amount,
          'p_currency': cleanCurrency,
          'p_paid_at': paidAt?.toUtc().toIso8601String(),
          'p_notes': cleanNotes?.isEmpty == true ? null : cleanNotes,
        },
      );
    } on PostgrestException catch (error) {
      final message = error.message.trim();

      throw Exception(
        message.isNotEmpty ? message : 'Unable to confirm payment.',
      );
    } catch (error) {
      final message = error.toString().trim();

      if (message.isEmpty) {
        throw Exception(
          'Unable to confirm payment.',
        );
      }

      if (message.startsWith(
        'Exception: ',
      )) {
        throw Exception(
          message.substring(
            'Exception: '.length,
          ),
        );
      }

      rethrow;
    }
  }

  // ============================================================
  // CURRENT USER SUBSCRIPTION
  // ============================================================

  static Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final response = await _supabase
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
          )
          .eq(
            'user_id',
            user.id,
          )
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(
        response,
      );
    } on PostgrestException {
      rethrow;
    }
  }

  // ============================================================
  // CHECK ACTIVE SUBSCRIPTION
  // ============================================================

  static Future<bool> hasActiveSubscription() async {
    final subscription = await getCurrentSubscription();

    if (subscription == null) {
      return false;
    }

    final status =
        subscription['status']?.toString().trim().toLowerCase() ?? '';

    if (status != 'active') {
      return false;
    }

    final expiresAt = _parseDate(
      subscription['expires_at'],
    );

    if (expiresAt == null) {
      return false;
    }

    return expiresAt.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // GET EXPIRY DATE
  // ============================================================

  static Future<DateTime?> getCurrentSubscriptionExpiry() async {
    final subscription = await getCurrentSubscription();

    if (subscription == null) {
      return null;
    }

    return _parseDate(
      subscription['expires_at'],
    );
  }

  // ============================================================
  // GET REMAINING DAYS
  // ============================================================

  static Future<int> getRemainingDays() async {
    final expiresAt = await getCurrentSubscriptionExpiry();

    if (expiresAt == null) {
      return 0;
    }

    final now = DateTime.now().toUtc();

    if (!expiresAt.isAfter(now)) {
      return 0;
    }

    return expiresAt.difference(now).inDays;
  }

  // ============================================================
  // CHECK EXPIRED
  // ============================================================

  static Future<bool> hasExpiredSubscription() async {
    final expiresAt = await getCurrentSubscriptionExpiry();

    if (expiresAt == null) {
      return false;
    }

    return !expiresAt.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // CHECK EXPIRING WITHIN 20 DAYS
  // ============================================================

  static Future<bool> expiresWithin20Days() async {
    final subscription = await getCurrentSubscription();

    if (subscription == null) {
      return false;
    }

    final status =
        subscription['status']?.toString().trim().toLowerCase() ?? '';

    if (status != 'active') {
      return false;
    }

    final expiresAt = _parseDate(
      subscription['expires_at'],
    );

    if (expiresAt == null) {
      return false;
    }

    final now = DateTime.now().toUtc();

    if (!expiresAt.isAfter(now)) {
      return false;
    }

    final remaining = expiresAt.difference(now);

    return remaining <=
        const Duration(
          days: 20,
        );
  }

  // ============================================================
  // GET SUBSCRIPTION STATUS
  // ============================================================

  static Future<String?> getCurrentStatus() async {
    final subscription = await getCurrentSubscription();

    if (subscription == null) {
      return null;
    }

    final status = subscription['status']?.toString().trim().toLowerCase();

    if (status == null || status.isEmpty) {
      return null;
    }

    return status;
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  static DateTime? _parseDate(
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
}
