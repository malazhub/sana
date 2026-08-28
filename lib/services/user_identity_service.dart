import 'package:shared_preferences/shared_preferences.dart';

class GuestIdentityService {
  static const String _key = 'sana_guest_user_id';

  /// Shared guest ID used by DataScopeService.
  static Future<String?> get sharedGuestId async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  /// Returns the existing guest ID or creates one.
  static Future<String> getGuestId() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getString(_key);

    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final id = 'guest_${DateTime.now().microsecondsSinceEpoch}';

    await prefs.setString(_key, id);

    return id;
  }

  /// Compatibility alias.
  static Future<String> getGuestUserId() async {
    return getGuestId();
  }

  /// Compatibility alias.
  static Future<String> ensureGuestUserId() async {
    return getGuestId();
  }

  /// Compatibility alias.
  static Future<String> getUserId() async {
    return getGuestId();
  }

  /// Compatibility alias.
  static Future<String> currentUserId() async {
    return getGuestId();
  }

  /// Compatibility alias.
  static Future<String> getIdentity() async {
    return getGuestId();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
