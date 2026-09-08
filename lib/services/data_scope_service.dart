import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_identity_service.dart';

enum DataScopeMode {
  guest,
  activeUser,
  admin,
}

class DataScopeService {
  DataScopeService._();

  static final SupabaseClient _db = Supabase.instance.client;

  static DataScopeMode get mode {
    final user = _db.auth.currentUser;

    if (user == null) {
      return DataScopeMode.guest;
    }

    final role = user.userMetadata?['role']?.toString().trim().toLowerCase();

    if (role == 'admin') {
      return DataScopeMode.admin;
    }

    return DataScopeMode.activeUser;
  }

  static bool get isGuest => mode == DataScopeMode.guest;

  static bool get isActiveUser => mode == DataScopeMode.activeUser;

  static bool get isAdmin => mode == DataScopeMode.admin;

  static String? get userId => _db.auth.currentUser?.id;

  static Future<String> ownerId() async {
    final currentUser = _db.auth.currentUser;

    if (currentUser == null) {
      return GuestIdentityService.getGuestId();
    }

    return currentUser.id;
  }

  static Future<String?> guestId() async {
    if (!isGuest) {
      return null;
    }

    return GuestIdentityService.getGuestId();
  }

  static Future<Map<String, dynamic>> scope() async {
    final currentUser = _db.auth.currentUser;

    if (currentUser == null) {
      return {
        'mode': DataScopeMode.guest.name,
        'user_id': GuestIdentityService.sharedGuestId,
      };
    }

    return {
      'mode':
          isAdmin ? DataScopeMode.admin.name : DataScopeMode.activeUser.name,
      'user_id': currentUser.id,
    };
  }

  static Future<void> reset() async {
    // Scope is resolved directly from the current Supabase
    // authentication session, so no persistent scope state
    // needs to be cleared here.
  }
}
