//import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION
  // ---------------------------------------------------------------------------

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
          'role': 'user',
          'is_active': false,
        },
      );

      return response;
    } catch (e) {
      debugPrint('Supabase signUp error: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Supabase signIn error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
      rethrow;
    }
  }

  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  static String? get currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  static bool get isSignedIn {
    return _supabase.auth.currentSession != null;
  }

  // ---------------------------------------------------------------------------
  // USER DATA
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> getUserData(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Get user data error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final userId = currentUserId;

    if (userId == null) {
      return null;
    }

    return getUserData(userId);
  }

  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select(
            'id, name, email, phone, created_at, is_active, '
            'expiry_date, role',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch all users error: $e');
      rethrow;
    }
  }

  static Future<void> updateUserActivation({
    required String userId,
    required bool isActive,
    DateTime? expiryDate,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_active': isActive,
            'expiry_date': expiryDate?.toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Update user activation error: $e');
      rethrow;
    }
  }

  static Future<bool> isAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      return response['role']?.toString().toLowerCase() == 'admin';
    } catch (e) {
      debugPrint('isAdmin error: $e');
      return false;
    }
  }

  static Future<bool> isSubscriptionExpired(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('users')
          .select('expiry_date, is_active')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return true;
      }

      final isActive = response['is_active'] == true;

      if (!isActive) {
        return true;
      }

      final rawExpiry = response['expiry_date'];

      if (rawExpiry == null) {
        return true;
      }

      final expiryDate = DateTime.tryParse(
        rawExpiry.toString(),
      );

      if (expiryDate == null) {
        return true;
      }

      return expiryDate.isBefore(DateTime.now());
    } catch (e) {
      debugPrint('Subscription check error: $e');
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // GENERIC DATABASE OPERATIONS
  // ---------------------------------------------------------------------------

  static Future<void> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final cleanData = Map<String, dynamic>.from(data);

      await _supabase
          .from(table)
          .insert(cleanData);
    } catch (e) {
      debugPrint('Insert error [$table]: $e');
      rethrow;
    }
  }

  static Future<void> update(
    String table,
    Map<String, dynamic> data,
    String id,
  ) async {
    try {
      final cleanData = Map<String, dynamic>.from(data);

      await _supabase
          .from(table)
          .update(cleanData)
          .eq('id', id);
    } catch (e) {
      debugPrint('Update error [$table/$id]: $e');
      rethrow;
    }
  }

  static Future<void> delete(
    String table,
    String id,
  ) async {
    try {
      await _supabase
          .from(table)
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Delete error [$table/$id]: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAll(
    String table,
  ) async {
    try {
      final response = await _supabase
          .from(table)
          .select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch all error [$table]: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFiltered(
    String table,
    String column,
    String value,
  ) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq(column, value);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint(
        'Fetch filtered error [$table/$column=$value]: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // FILE / PHOTO STORAGE
  // ---------------------------------------------------------------------------

  static Future<String> uploadPhoto(
    Uint8List bytes,
    String path,
  ) async {
    try {
      final storage = _supabase.storage.from('photos');

      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
        ),
      );

      return storage.getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload photo error: $e');
      rethrow;
    }
  }

  static Future<String> uploadFile(
    Uint8List bytes,
    String path,
    String fileType,
  ) async {
    try {
      final storage = _supabase.storage.from('documents');

      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: fileType,
        ),
      );

      return storage.getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload file error: $e');
      rethrow;
    }
  }

  static Future<Uint8List?> downloadFile(
    String url,
  ) async {
    try {
      final uri = Uri.tryParse(url);

      if (uri == null) {
        return null;
      }

      final path = _extractStoragePath(uri);

      if (path == null || path.isEmpty) {
        return null;
      }

      try {
        return await _supabase.storage
            .from('photos')
            .download(path);
      } catch (_) {
        try {
          return await _supabase.storage
              .from('documents')
              .download(path);
        } catch (e) {
          debugPrint('Storage download error: $e');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Download file error: $e');
      return null;
    }
  }

  static String? _extractStoragePath(
    Uri uri,
  ) {
    final segments = uri.pathSegments;

    final objectIndex = segments.indexOf('object');

    if (objectIndex >= 0 &&
        objectIndex + 2 < segments.length) {
      final remaining = segments.sublist(
        objectIndex + 2,
      );

      if (remaining.isNotEmpty) {
        return remaining.join('/');
      }
    }

    final publicIndex = segments.indexOf('public');

    if (publicIndex >= 0 &&
        publicIndex + 2 < segments.length) {
      final remaining = segments.sublist(
        publicIndex + 2,
      );

      if (remaining.isNotEmpty) {
        return remaining.join('/');
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // ACTIVATION / EXPIRY NOTIFICATION SUPPORT
  // ---------------------------------------------------------------------------

  static Future<void> sendActivationNotifications({
    required String userId,
    required String email,
    required String? phone,
    required DateTime expiryDate,
  }) async {
    try {
      final userName = await _getUserName(userId);

      final formattedDate =
          '${expiryDate.day.toString().padLeft(2, '0')}/'
          '${expiryDate.month.toString().padLeft(2, '0')}/'
          '${expiryDate.year}';

      final subject =
          'SANA Account Activated';

      final body = '''
Dear $userName,

Your SANA account has been activated.

Subscription:
Status: Active
Expiry date: $formattedDate
Duration: 1 year

You can now use your SANA medical records and medication reminder features.

SANA
''';

      // These methods are intentionally kept as service hooks.
      // The actual email/SMS provider can be connected later
      // without changing the admin/user code.
      await _sendEmail(
        email,
        subject,
        body,
      );

      if (phone != null && phone.trim().isNotEmpty) {
        await _sendSms(
          phone.trim(),
          'SANA: Your account is active until $formattedDate.',
        );
      }
    } catch (e) {
      debugPrint(
        'Activation notification error: $e',
      );
      rethrow;
    }
  }

  static Future<String> _getUserName(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('users')
          .select('name')
          .eq('id', userId)
          .maybeSingle();

      return response?['name']?.toString() ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  static Future<void> _sendEmail(
    String to,
    String subject,
    String body,
  ) async {
    // Email delivery requires a Supabase Edge Function
    // or another configured email provider.
    //
    // Keep this method here so the application has one
    // central notification interface.
    debugPrint(
      'EMAIL -> $to | $subject\n$body',
    );
  }

  static Future<void> _sendSms(
    String phone,
    String message,
  ) async {
    // SMS delivery requires a configured SMS provider.
    debugPrint(
      'SMS -> $phone | $message',
    );
  }

  // ---------------------------------------------------------------------------
  // EXPIRY HELPERS
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>>
      fetchUsersExpiringWithin(
    int days,
  ) async {
    try {
      final now = DateTime.now();
      final limit = now.add(
        Duration(days: days),
      );

      final response = await _supabase
          .from('users')
          .select(
            'id, name, email, phone, created_at, '
            'is_active, expiry_date, role',
          )
          .eq('is_active', true)
          .gte(
            'expiry_date',
            now.toIso8601String(),
          )
          .lte(
            'expiry_date',
            limit.toIso8601String(),
          )
          .order(
            'expiry_date',
            ascending: true,
          );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint(
        'Fetch expiring users error: $e',
      );
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>>
      fetchExpiredActiveUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select(
            'id, name, email, phone, created_at, '
            'is_active, expiry_date, role',
          )
          .eq('is_active', true)
          .lt(
            'expiry_date',
            DateTime.now().toIso8601String(),
          )
          .order(
            'expiry_date',
            ascending: true,
          );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint(
        'Fetch expired users error: $e',
      );
      rethrow;
    }
  }

  static Future<void> deactivateExpiredUsers() async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_active': false,
          })
          .eq('is_active', true)
          .lt(
            'expiry_date',
            DateTime.now().toIso8601String(),
          );
    } catch (e) {
      debugPrint(
        'Deactivate expired users error: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // RAW CLIENT ACCESS
  // ---------------------------------------------------------------------------

  static SupabaseClient get client {
    return _supabase;
  }
}