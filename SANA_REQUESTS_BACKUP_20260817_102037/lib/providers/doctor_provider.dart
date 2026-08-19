import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor.dart';

class DoctorProvider with ChangeNotifier {
  final List<Doctor> _doctors = [];
  bool _isLoading = false;

  List<Doctor> get doctors => List.unmodifiable(_doctors);
  bool get isLoading => _isLoading;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  DoctorProvider() {
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localData = prefs.getString('saved_doctors');
      if (localData != null && localData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localData);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final doc = Doctor.fromMap(item);
            if (!_doctors.any((d) => d.id == doc.id)) {
              _doctors.add(doc);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local doctors: ');
    }

    if (_supabase != null) {
      try {
        final response = await _supabase!.from('doctors').select();
        if (response.isNotEmpty) {
          for (final item in response) {
            final cloudDoc = Doctor.fromMap(Map<String, dynamic>.from(item));
            final idx = _doctors.indexWhere((d) => d.id == cloudDoc.id);
            if (idx >= 0) {
              _doctors[idx] = cloudDoc;
            } else {
              _doctors.add(cloudDoc);
            }
          }
          await _saveToLocal();
        }
      } catch (e) {
        debugPrint('Failed to load doctors from Supabase: ');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDoctor(Doctor doc) async {
    if (!_doctors.any((d) => d.id == doc.id)) {
      _doctors.add(doc);
      notifyListeners();
      await _saveToLocal();
    }

    if (_supabase != null) {
      try {
        await _supabase!.from('doctors').insert(doc.toMap());
      } catch (e) {
        debugPrint('Failed to sync added doctor to Supabase: ');
      }
    }
  }

  Future<void> deleteDoctor(String id) async {
    _doctors.removeWhere((d) => d.id == id);
    notifyListeners();
    await _saveToLocal();

    if (_supabase != null) {
      try {
        await _supabase!.from('doctors').delete().eq('id', id);
      } catch (e) {
        debugPrint('Failed to delete doctor from Supabase: ');
      }
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> maps =
          _doctors.map((d) => d.toMap()).toList();
      await prefs.setString('saved_doctors', jsonEncode(maps));
    } catch (e) {
      debugPrint('Error saving doctors locally: ');
    }
  }
}
