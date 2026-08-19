import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pharmacy.dart';
import '../services/supabase_service.dart';

class PharmacyProvider extends ChangeNotifier {
  final List<Pharmacy> _pharmacies = [];

  bool _isLoading = false;
  String? _userId;

  StreamSubscription<AuthState>? _authSubscription;

  List<Pharmacy> get pharmacies =>
      List.unmodifiable(_pharmacies);

  bool get isLoading => _isLoading;

  String? get userId => _userId;

  SupabaseClient get _client => Supabase.instance.client;

  PharmacyProvider() {
    _userId = _client.auth.currentUser?.id;

    _authSubscription = _client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Pharmacy auth listener error: '
          '$error\n$stackTrace',
        );
      },
    );

    if (_userId != null) {
      loadPharmacies();
    }
  }

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  void _handleAuthStateChange(
    AuthState authState,
  ) {
    final newUserId = authState.session?.user.id;

    if (_userId == newUserId) {
      return;
    }

    _userId = newUserId;

    // Never expose another user's pharmacies.
    _pharmacies.clear();

    notifyListeners();

    if (newUserId != null) {
      loadPharmacies();
    }
  }

  String? _authenticatedUserId() {
    final currentUserId =
        _client.auth.currentUser?.id;

    if (currentUserId == null ||
        currentUserId.isEmpty) {
      _userId = null;
      return null;
    }

    _userId = currentUserId;
    return currentUserId;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadPharmacies() async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      _pharmacies.clear();
      notifyListeners();
      return;
    }

    if (_isLoading) {
      return;
    }

    _setLoading(true);

    try {
      final data = await SupabaseService.fetchFiltered(
        'pharmacies',
        'user_id',
        uid,
      );

      final loadedPharmacies = <Pharmacy>[];

      for (final map in data) {
        try {
          final pharmacy = Pharmacy.fromMap(
            Map<String, dynamic>.from(map),
          );

          if (pharmacy.id.isEmpty) {
            continue;
          }

          loadedPharmacies.add(pharmacy);
        } catch (error) {
          debugPrint(
            'Invalid pharmacy record: $error',
          );
        }
      }

      _pharmacies
        ..clear()
        ..addAll(loadedPharmacies);
    } catch (error, stackTrace) {
      debugPrint(
        'Load pharmacies error: '
        '$error\n$stackTrace',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> addPharmacy(
    Pharmacy pharmacy,
  ) async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to save a pharmacy.',
      );
    }

    try {
      final map = pharmacy.toMap();

      // Never trust a user ID supplied by the UI.
      map['user_id'] = uid;

      await SupabaseService.insert(
        'pharmacies',
        map,
      );

      // Reload so the local state matches Supabase.
      await loadPharmacies();
    } catch (error, stackTrace) {
      debugPrint(
        'Add pharmacy error: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updatePharmacy(
    Pharmacy pharmacy,
  ) async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to update a pharmacy.',
      );
    }

    final existingIndex = _pharmacies.indexWhere(
      (item) => item.id == pharmacy.id,
    );

    if (existingIndex < 0) {
      throw StateError(
        'Pharmacy not found.',
      );
    }

    try {
      final map = pharmacy.toMap();

      // Always bind the record to the current user.
      map['user_id'] = uid;

      await SupabaseService.update(
        'pharmacies',
        map,
        pharmacy.id,
      );

      await loadPharmacies();
    } catch (error, stackTrace) {
      debugPrint(
        'Update pharmacy error: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deletePharmacy(
    String id,
  ) async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to delete a pharmacy.',
      );
    }

    final pharmacyIndex = _pharmacies.indexWhere(
      (pharmacy) => pharmacy.id == id,
    );

    if (pharmacyIndex < 0) {
      return;
    }

    try {
      await SupabaseService.delete(
        'pharmacies',
        id,
      );

      _pharmacies.removeAt(pharmacyIndex);

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Delete pharmacy error: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _pharmacies.clear();
    notifyListeners();
  }

  // ============================================================
  // STATE
  // ============================================================

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}