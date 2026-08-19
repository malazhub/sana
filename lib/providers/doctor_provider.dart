import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/supabase_service.dart';

class DoctorProvider extends ChangeNotifier {
  List<Doctor> _doctors = [];
  bool _isLoading = false;
  String _userId = '';

  List<Doctor> get doctors => _doctors;
  bool get isLoading => _isLoading;

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<void> loadDoctors() async {
    if (_userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final data = await SupabaseService.fetchFiltered('doctors', 'user_id', _userId);
      _doctors = data.map((map) => Doctor.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Load doctors error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDoctor(Doctor doctor) async {
    try {
      final map = doctor.toMap();
      map['user_id'] = _userId;
      await SupabaseService.insert('doctors', map);
      _doctors.add(doctor);
      notifyListeners();
    } catch (e) {
      debugPrint('Add doctor error: $e');
      rethrow;
    }
  }

  Future<void> updateDoctor(Doctor doctor) async {
    try {
      final map = doctor.toMap();
      map['user_id'] = _userId;
      await SupabaseService.update('doctors', map, doctor.id);
      final index = _doctors.indexWhere((d) => d.id == doctor.id);
      if (index != -1) {
        _doctors[index] = doctor;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update doctor error: $e');
      rethrow;
    }
  }

  Future<void> deleteDoctor(String id) async {
    try {
      await SupabaseService.delete('doctors', id);
      _doctors.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete doctor error: $e');
      rethrow;
    }
  }
}