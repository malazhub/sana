import 'package:flutter/material.dart';
import '../models/pharmacy.dart';
import '../services/supabase_service.dart';

class PharmacyProvider extends ChangeNotifier {
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  String _userId = '';

  List<Pharmacy> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<void> loadPharmacies() async {
    if (_userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final data = await SupabaseService.fetchFiltered('pharmacies', 'user_id', _userId);
      _pharmacies = data.map((map) => Pharmacy.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Load pharmacies error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPharmacy(Pharmacy pharmacy) async {
    try {
      final map = pharmacy.toMap();
      map['user_id'] = _userId;
      await SupabaseService.insert('pharmacies', map);
      _pharmacies.add(pharmacy);
      notifyListeners();
    } catch (e) {
      debugPrint('Add pharmacy error: $e');
      rethrow;
    }
  }

  Future<void> updatePharmacy(Pharmacy pharmacy) async {
    try {
      final map = pharmacy.toMap();
      map['user_id'] = _userId;
      await SupabaseService.update('pharmacies', map, pharmacy.id);
      final index = _pharmacies.indexWhere((p) => p.id == pharmacy.id);
      if (index != -1) {
        _pharmacies[index] = pharmacy;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update pharmacy error: $e');
      rethrow;
    }
  }

  Future<void> deletePharmacy(String id) async {
    try {
      await SupabaseService.delete('pharmacies', id);
      _pharmacies.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete pharmacy error: $e');
      rethrow;
    }
  }
}