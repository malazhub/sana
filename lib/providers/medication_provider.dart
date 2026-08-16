import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';

class MedicationProvider with ChangeNotifier {
  final List<Medication> _medications = [];
  final List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  List<Medication> get medications => List.unmodifiable(_medications);
  List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  MedicationProvider() {
    loadMedications();
  }

  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localData = prefs.getString('saved_medications');
      if (localData != null && localData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localData);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final med = Medication.fromMap(item);
            if (!_medications.any((m) => m.id == med.id)) {
              _medications.add(med);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local medications: ');
    }

    if (_supabase != null) {
      try {
        final response = await _supabase!.from('medications').select();
        if (response.isNotEmpty) {
          for (final item in response) {
            final cloudMed = Medication.fromMap(Map<String, dynamic>.from(item));
            final idx = _medications.indexWhere((m) => m.id == cloudMed.id);
            if (idx >= 0) {
              _medications[idx] = cloudMed;
            } else {
              _medications.add(cloudMed);
            }
          }
          await _saveToLocal();
        }
      } catch (e) {
        debugPrint('Failed to load medications from Supabase: ');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMedication(Medication med) async {
    if (!_medications.any((m) => m.id == med.id)) {
      _medications.add(med);
      notifyListeners();
      await _saveToLocal();
    }

    if (_supabase != null) {
      try {
        await _supabase!.from('medications').insert(med.toSupabaseMap());
        debugPrint('Medication synced to Supabase successfully!');
      } catch (e) {
        debugPrint('Failed to sync added medication to Supabase: ');
      }
    }
  }

  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((m) => m.id == id);
    notifyListeners();
    await _saveToLocal();

    if (_supabase != null) {
      try {
        await _supabase!.from('medications').delete().eq('id', id);
      } catch (e) {
        debugPrint('Failed to delete medication from Supabase: ');
      }
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> maps = _medications.map((m) => m.toMap()).toList();
      await prefs.setString('saved_medications', jsonEncode(maps));
    } catch (e) {
      debugPrint('Error saving medications locally: ');
    }
  }
}
