import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // ADMIN: CONFIRM PAYMENT + ACTIVATE SUBSCRIPTION
  // ============================================================

  static Future<void> adminConfirmPayment({
    required String userId,
    required String transactionId,
    required double amount,
    String currency = 'USD',
    DateTime? paidAt,
    String? notes,
  }) async {
    final normalizedUserId =
        userId.trim();

    final normalizedTransactionId =
        transactionId.trim();

    final normalizedCurrency =
        currency.trim().isEmpty
            ? 'USD'
            : currency.trim().toUpperCase();

    final normalizedNotes =
        notes?.trim();

    if (normalizedUserId.isEmpty) {
      throw Exception(
        'User ID is required.',
      );
    }

    if (normalizedTransactionId.isEmpty) {
      throw Exception(
        'Transaction ID is required.',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Payment amount must be greater than zero.',
      );
    }

    try {
      /*
       * IMPORTANT:
       *
       * Flutter deliberately does NOT calculate:
       *
       *     expires_at
       *
       * The protected PostgreSQL RPC is responsible for:
       *
       * - authorization
       * - payment recording
       * - activation
       * - activated_at
       * - expires_at
       * - subscription status
       *
       * This prevents the client from choosing its own
       * subscription expiry date.
       */
      await _supabase.rpc(
        'admin_confirm_payment',
        params: {
          'target_user_id':
              normalizedUserId,
          'p_transaction_id':
              normalizedTransactionId,
          'p_amount':
              amount,
          'p_currency':
              normalizedCurrency,
          'p_paid_at':
              paidAt
                  ?.toUtc()
                  .toIso8601String(),
          'p_notes':
              normalizedNotes,
        },
      );
    } on PostgrestException catch (error) {
      final message =
          error.message.trim();

      if (message.isNotEmpty) {
        throw Exception(message);
      }

      throw Exception(
        'Unable to confirm payment.',
      );
    } catch (error) {
      final message =
          error.toString().trim();

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

  static Future<Map<String, dynamic>?>
      getCurrentSubscription() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final response =
          await _supabase
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
  // ACTIVE SUBSCRIPTION
  // ============================================================

  static Future<bool>
      hasActiveSubscription() async {
    final subscription =
        await getCurrentSubscription();

    if (subscription == null) {
      return false;
    }

    final status =
        subscription['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status != 'active') {
      return false;
    }

    final expiresAt =
        _parseDate(
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
  // EXPIRY DATE
  // ============================================================

  static Future<DateTime?>
      getCurrentSubscriptionExpiry() async {
    final subscription =
        await getCurrentSubscription();

    if (subscription == null) {
      return null;
    }

    return _parseDate(
      subscription['expires_at'],
    );
  }

  // ============================================================
  // REMAINING DAYS
  // ============================================================

  static Future<int>
      getRemainingDays() async {
    final expiresAt =
        await getCurrentSubscriptionExpiry();

    if (expiresAt == null) {
      return 0;
    }

    final now =
        DateTime.now().toUtc();

    if (!expiresAt.isAfter(now)) {
      return 0;
    }

    return expiresAt
        .difference(now)
        .inDays;
  }

  // ============================================================
  // EXPIRED
  // ============================================================

  static Future<bool>
      hasExpiredSubscription() async {
    final expiresAt =
        await getCurrentSubscriptionExpiry();

    if (expiresAt == null) {
      return false;
    }

    return !expiresAt.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // 20-DAY REMINDER
  // ============================================================

  static Future<bool>
      expiresWithin20Days() async {
    final subscription =
        await getCurrentSubscription();

    if (subscription == null) {
      return false;
    }

    final status =
        subscription['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status != 'active') {
      return false;
    }

    final expiresAt =
        _parseDate(
      subscription['expires_at'],
    );

    if (expiresAt == null) {
      return false;
    }

    final now =
        DateTime.now().toUtc();

    if (!expiresAt.isAfter(now)) {
      return false;
    }

    return expiresAt
            .difference(now) <=
        const Duration(
          days: 20,
        );
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

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final parsed =
        DateTime.tryParse(text);

    if (parsed == null) {
      return null;
    }

    return parsed.toUtc();
  }
}