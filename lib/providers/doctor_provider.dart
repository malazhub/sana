import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/doctor.dart';
import '../services/supabase_service.dart';

class DoctorProvider extends ChangeNotifier {
  final List<Doctor> _doctors = [];

  bool _isLoading = false;
  String? _userId;

  StreamSubscription<AuthState>? _authSubscription;

  List<Doctor> get doctors => List.unmodifiable(_doctors);

  bool get isLoading => _isLoading;

  String? get userId => _userId;

  SupabaseClient get _client => Supabase.instance.client;

  DoctorProvider() {
    _userId = _client.auth.currentUser?.id;

    _authSubscription = _client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Doctor auth listener error: '
          '$error\n$stackTrace',
        );
      },
    );

    if (_userId != null) {
      loadDoctors();
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

    // Never expose another user's doctors.
    _doctors.clear();

    notifyListeners();

    if (newUserId != null) {
      loadDoctors();
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

  Future<void> loadDoctors() async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      _doctors.clear();
      notifyListeners();
      return;
    }

    if (_isLoading) {
      return;
    }

    _setLoading(true);

    try {
      final data = await SupabaseService.fetchFiltered(
        'doctors',
        'user_id',
        uid,
      );

      final loadedDoctors = <Doctor>[];

      for (final map in data) {
        try {
          final doctor = Doctor.fromMap(
            Map<String, dynamic>.from(map),
          );

          loadedDoctors.add(doctor);
        } catch (error) {
          debugPrint(
            'Invalid doctor record: $error',
          );
        }
      }

      _doctors
        ..clear()
        ..addAll(loadedDoctors);
    } catch (error, stackTrace) {
      debugPrint(
        'Load doctors error: '
        '$error\n$stackTrace',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> addDoctor(
    Doctor doctor,
  ) async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to save a doctor.',
      );
    }

    try {
      final map = doctor.toMap();

      // Never trust a user ID supplied by the UI.
      map['user_id'] = uid;

      await SupabaseService.insert(
        'doctors',
        map,
      );

      /*
       * Reload from Supabase so the local object contains
       * exactly what the database contains.
       */
      await loadDoctors();
    } catch (error, stackTrace) {
      debugPrint(
        'Add doctor error: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateDoctor(
    Doctor doctor,
  ) async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to update a doctor.',
      );
    }

    final existingIndex = _doctors.indexWhere(
      (item) => item.id == doctor.id,
    );

    if (existingIndex < 0) {
      throw StateError(
        'Doctor not found.',
      );
    }

    try {
      final map = doctor.toMap();

      // Always bind the record to the current user.
      map['user_id'] = uid;

      await SupabaseService.update(
        'doctors',
        map,
        doctor.id,
      );

      await loadDoctors();
    } catch (error, stackTrace) {
      debugPrint(
        'Update doctor error: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteDoctor(
    String id,
  ) async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to delete a doctor.',
      );
    }

    final doctorIndex = _doctors.indexWhere(
      (doctor) => doctor.id == id,
    );

    if (doctorIndex < 0) {
      return;
    }

    try {
      /*
       * The Supabase service must enforce the database/RLS
       * ownership rule. The provider also verifies that the
       * doctor belongs to the current user's loaded collection.
       */
      await SupabaseService.delete(
        'doctors',
        id,
      );

      _doctors.removeAt(doctorIndex);

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Delete doctor error: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _doctors.clear();
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