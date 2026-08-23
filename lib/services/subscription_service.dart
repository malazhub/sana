import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // ADMIN: CONFIRM PAYMENT + ACTIVATE SUBSCRIPTION
  // ============================================================

  /// Confirms a customer's payment and activates the customer's
  /// subscription through the PostgreSQL RPC.
  ///
  /// IMPORTANT:
  /// Flutter does NOT calculate the subscription expiry date.
  ///
  /// PostgreSQL is responsible for:
  /// - creating/updating the subscription
  /// - setting activated_at
  /// - calculating expires_at
  /// - setting the subscription status
  /// - recording the payment
  ///
  /// RPC:
  ///
  ///   public.admin_confirm_payment(...)
  static Future<void> adminConfirmPayment({
    required String userId,
    required String transactionId,
    required double amount,
    String currency = 'USD',
    DateTime? paidAt,
    String? notes,
  }) async {
    final normalizedUserId = userId.trim();

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
      await _supabase.rpc(
        'admin_confirm_payment',
        params: {
          'target_user_id': normalizedUserId,
          'p_transaction_id':
              normalizedTransactionId,
          'p_amount': amount,
          'p_currency': normalizedCurrency,
          'p_paid_at': paidAt
              ?.toUtc()
              .toIso8601String(),
          'p_notes': normalizedNotes,
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

  /// Returns the authenticated user's subscription.
  ///
  /// Returns null when:
  /// - there is no authenticated user
  /// - the user has no subscription record
  static Future<Map<String, dynamic>?>
      getCurrentSubscription() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

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
  }

  // ============================================================
  // ACTIVE SUBSCRIPTION CHECK
  // ============================================================

  /// Returns true only when:
  ///
  /// 1. A subscription exists.
  /// 2. Its status is active.
  /// 3. expires_at is in the future.
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

  /// Returns the authenticated user's subscription expiry date.
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

  /// Returns the number of complete days remaining.
  ///
  /// Returns 0 when:
  /// - no subscription exists
  /// - expiry date is missing
  /// - subscription has expired
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
  // EXPIRY STATUS
  // ============================================================

  /// Returns true when an expiry date exists and is no longer
  /// in the future.
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
  // 20-DAY REMINDER WINDOW
  // ============================================================

  /// Returns true when an active subscription expires within
  /// the next 20 days.
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

    final difference =
        expiresAt.difference(now);

    return difference <=
        const Duration(days: 20);
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