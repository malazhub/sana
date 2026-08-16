import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  static final SupabaseClient _db = Supabase.instance.client;

  static Future<Map<String, dynamic>?> current() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;

    return await _db
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> request() async {
    final result = await _db.rpc('request_private_subscription');

    if (result == null) return null;
    if (result is Map<String, dynamic>) return result;
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<bool> active() async {
    final row = await current();
    if (row == null) return false;

    if (row['status'] != 'active') return false;

    final raw = row['expires_at'];
    if (raw == null) return false;

    final expiry = DateTime.tryParse(raw.toString());
    if (expiry == null) return false;

    return DateTime.now().toUtc().isBefore(expiry.toUtc());
  }

  static Future<Map<String, dynamic>> adminConfirmPayment({
    required String userId,
    required String transactionId,
    required double amount,
    String currency = 'USD',
    DateTime? paidAt,
    String? notes,
  }) async {
    final result = await _db.rpc(
      'admin_confirm_payment',
      params: {
        'p_user_id': userId,
        'p_transaction_id': transactionId.trim(),
        'p_amount': amount,
        'p_currency': currency,
        'p_paid_at': (paidAt ?? DateTime.now()).toUtc().toIso8601String(),
        'p_notes': notes,
      },
    );

    return Map<String, dynamic>.from(result as Map);
  }
}
