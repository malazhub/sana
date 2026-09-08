class GuestIdentityService {
  GuestIdentityService._();

  /// One canonical shared scope for every Guest session.
  ///
  /// Guests must never receive a per-device/per-install ID.
  /// All Guest medical records therefore belong to the same
  /// shared workspace.
  static const String sharedGuestId = 'guest_shared_workspace';

  static Future<String> getGuestId() async {
    return sharedGuestId;
  }
}
