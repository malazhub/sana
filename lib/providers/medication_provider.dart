import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medication.dart';
import '../models/medication_log.dart';

class MedicationProvider extends ChangeNotifier {
  static const String _medicationsStorageKey =
      'saved_medications_v2';

  static const String _logsStorageKey =
      'saved_medication_logs_v2';

  final List<Medication> _medications = [];
  final List<MedicationLog> _logs = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Medication> get medications =>
      List.unmodifiable(_medications);

  List<MedicationLog> get logs =>
      List.unmodifiable(_logs);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser => _supabase?.auth.currentUser;

  MedicationProvider() {
    loadMedications();
  }

  // ============================================================
  // MEDICATIONS
  // ============================================================

  Future<void> loadMedications() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _clearError();

    _medications.clear();
    _logs.clear();

    try {
      final user = _currentUser;

      if (user == null) {
        await _loadLocalMedications();
        await _loadLocalLogs();
        return;
      }

      final client = _supabase;

      if (client == null) {
        await _loadLocalMedications();
        await _loadLocalLogs();
        return;
      }

      // ----------------------------------------------------------
      // Load only this user's medications.
      // ----------------------------------------------------------

      final medicationResponse = await client
          .from('medications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      for (final item in medicationResponse) {
        try {
          final medication = Medication.fromMap(
            Map<String, dynamic>.from(item),
          );

          if (medication.id.isEmpty) {
            continue;
          }

          _medications.add(medication);
        } catch (error) {
          debugPrint(
            'Invalid medication record: $error',
          );
        }
      }

      // ----------------------------------------------------------
      // Load history belonging to this user's medications.
      //
      // medication_logs does not currently have a user_id column,
      // so history is safely obtained through the medication IDs.
      // ----------------------------------------------------------

      await _loadCloudLogs(
        client,
        user.id,
      );

      await _saveMedicationsToLocal();
      await _saveLogsToLocal();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load medications: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to load your medications.',
      );

      // Offline/cache fallback.
      await _loadLocalMedications();
      await _loadLocalLogs();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMedication(
    Medication medication,
  ) async {
    final user = _currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to save a medication.',
      );
    }

    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    // Always force the authenticated user's ID.
    final medicationToSave = medication.copyWith(
      userId: user.id,
    );

    _clearError();

    try {
      await client
          .from('medications')
          .upsert(
            medicationToSave.toSupabaseMap(),
            onConflict: 'id',
          );

      final index = _medications.indexWhere(
        (item) => item.id == medicationToSave.id,
      );

      if (index >= 0) {
        _medications[index] = medicationToSave;
      } else {
        _medications.insert(
          0,
          medicationToSave,
        );
      }

      await _saveMedicationsToLocal();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to add medication: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to save the medication.',
      );

      rethrow;
    }
  }

  Future<void> updateMedication(
    Medication medication,
  ) async {
    final user = _currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to update a medication.',
      );
    }

    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    final medicationToSave = medication.copyWith(
      userId: user.id,
    );

    _clearError();

    try {
      await client
          .from('medications')
          .update(
            medicationToSave.toSupabaseMap(),
          )
          .eq(
            'id',
            medicationToSave.id,
          )
          .eq(
            'user_id',
            user.id,
          );

      final index = _medications.indexWhere(
        (item) => item.id == medicationToSave.id,
      );

      if (index >= 0) {
        _medications[index] = medicationToSave;
      } else {
        _medications.insert(
          0,
          medicationToSave,
        );
      }

      await _saveMedicationsToLocal();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to update medication: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to update the medication.',
      );

      rethrow;
    }
  }

  Future<void> deleteMedication(
    String id,
  ) async {
    final user = _currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to delete a medication.',
      );
    }

    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    final index = _medications.indexWhere(
      (medication) => medication.id == id,
    );

    if (index < 0) {
      return;
    }

    final medication = _medications[index];

    if (medication.userId != user.id) {
      throw StateError(
        'You cannot delete another user\'s medication.',
      );
    }

    _clearError();

    try {
      await client
          .from('medications')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      _medications.removeAt(index);

      // The database schema uses ON DELETE SET NULL for
      // medication_logs, so history remains permanent.
      //
      // Remove the medication from the active list only.
      await _saveMedicationsToLocal();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to delete medication: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to delete the medication.',
      );

      rethrow;
    }
  }

  // ============================================================
  // MEDICATION HISTORY
  // ============================================================

  Future<void> loadMedicationHistory() async {
    final user = _currentUser;

    if (user == null) {
      await _loadLocalLogs();
      return;
    }

    final client = _supabase;

    if (client == null) {
      await _loadLocalLogs();
      return;
    }

    try {
      await _loadCloudLogs(
        client,
        user.id,
      );

      await _saveLogsToLocal();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load medication history: '
        '$error\n$stackTrace',
      );

      await _loadLocalLogs();
      notifyListeners();
    }
  }

  Future<void> recordMedicationStatus({
    required Medication medication,
    required String status,
    DateTime? takenAt,
  }) async {
    final user = _currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to record medication history.',
      );
    }

    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    final normalizedStatus =
        status.trim().toLowerCase();

    if (normalizedStatus != 'taken' &&
        normalizedStatus != 'not_taken') {
      throw ArgumentError(
        'Status must be "taken" or "not_taken".',
      );
    }

    if (medication.userId != user.id) {
      throw StateError(
        'This medication does not belong to the current user.',
      );
    }

    final log = MedicationLog(
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: medication.dosage,
      status: normalizedStatus,
      takenAt: takenAt ?? DateTime.now(),
    );

    try {
      final response = await client
          .from('medication_logs')
          .insert(
            log.toMap(),
          )
          .select()
          .single();

      final savedLog = MedicationLog.fromMap(
        Map<String, dynamic>.from(response),
      );

      _logs.insert(
        0,
        savedLog,
      );

      await _saveLogsToLocal();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to record medication status: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  Future<void> markTaken(
    Medication medication, {
    DateTime? takenAt,
  }) async {
    await recordMedicationStatus(
      medication: medication,
      status: 'taken',
      takenAt: takenAt,
    );
  }

  Future<void> markNotTaken(
    Medication medication, {
    DateTime? takenAt,
  }) async {
    await recordMedicationStatus(
      medication: medication,
      status: 'not_taken',
      takenAt: takenAt,
    );
  }

  // ============================================================
  // CLOUD LOG LOADING
  // ============================================================

  Future<void> _loadCloudLogs(
    SupabaseClient client,
    String userId,
  ) async {
    _logs.clear();

    final medicationIds = _medications
        .where(
          (medication) =>
              medication.userId == userId &&
              medication.id.isNotEmpty,
        )
        .map(
          (medication) => medication.id,
        )
        .toList();

    // If the user has no medications, there cannot be
    // any history belonging to active medications.
    //
    // Older logs for deleted medications intentionally remain
    // permanent in the database because medication deletion uses
    // ON DELETE SET NULL.
    if (medicationIds.isEmpty) {
      return;
    }

    // Supabase/PostgREST supports filtering an ID against
    // multiple values with the "in" operator.
    final response = await client
        .from('medication_logs')
        .select()
        .inFilter(
          'medication_id',
          medicationIds,
        )
        .order(
          'taken_at',
          ascending: false,
        );

    for (final item in response) {
      try {
        final log = MedicationLog.fromMap(
          Map<String, dynamic>.from(item),
        );

        _logs.add(log);
      } catch (error) {
        debugPrint(
          'Invalid medication log: $error',
        );
      }
    }
  }

  // ============================================================
  // LOCAL CACHE
  // ============================================================

  Future<void> _loadLocalMedications() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final data =
          prefs.getString(
            _medicationsStorageKey,
          ) ??
          prefs.getString(
            'saved_medications',
          );

      if (data == null || data.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(data);

      if (decoded is! List) {
        return;
      }

      final user = _currentUser;

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final medication =
              Medication.fromMap(
            Map<String, dynamic>.from(item),
          );

          if (medication.id.isEmpty) {
            continue;
          }

          // Never show another user's cached medication.
          if (user != null &&
              medication.userId.isNotEmpty &&
              medication.userId != user.id) {
            continue;
          }

          final exists =
              _medications.any(
            (existing) =>
                existing.id == medication.id,
          );

          if (!exists) {
            _medications.add(
              medication,
            );
          }
        } catch (error) {
          debugPrint(
            'Invalid cached medication: $error',
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load local medications: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _loadLocalLogs() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final data =
          prefs.getString(
            _logsStorageKey,
          );

      if (data == null || data.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(data);

      if (decoded is! List) {
        return;
      }

      _logs.clear();

      final medicationIds =
          _medications
              .map(
                (medication) =>
                    medication.id,
              )
              .toSet();

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final log =
              MedicationLog.fromMap(
            Map<String, dynamic>.from(item),
          );

          // Only load cached history associated with
          // medications currently known to this user.
          if (medicationIds.isNotEmpty &&
              !medicationIds.contains(
                log.medicationId,
              )) {
            continue;
          }

          _logs.add(log);
        } catch (error) {
          debugPrint(
            'Invalid cached medication log: $error',
          );
        }
      }

      _logs.sort(
        (a, b) => b.takenAt.compareTo(
          a.takenAt,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load local medication logs: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _saveMedicationsToLocal() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final data = _medications
          .map(
            (medication) =>
                medication.toMap(),
          )
          .toList();

      await prefs.setString(
        _medicationsStorageKey,
        jsonEncode(data),
      );
    } catch (error) {
      debugPrint(
        'Failed to cache medications: $error',
      );
    }
  }

  Future<void> _saveLogsToLocal() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final data = _logs
          .map(
            (log) => log.toMap(),
          )
          .toList();

      await prefs.setString(
        _logsStorageKey,
        jsonEncode(data),
      );
    } catch (error) {
      debugPrint(
        'Failed to cache medication logs: $error',
      );
    }
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

  void _clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  Future<void> clearLocalData() async {
    _medications.clear();
    _logs.clear();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _medicationsStorageKey,
    );

    await prefs.remove(
      _logsStorageKey,
    );

    await prefs.remove(
      'saved_medications',
    );

    notifyListeners();
  }
}