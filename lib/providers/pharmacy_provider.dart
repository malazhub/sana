import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pharmacy.dart';

class PharmacyProvider with ChangeNotifier {
  final List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;

  List<Pharmacy> get pharmacies => List.unmodifiable(_pharmacies);
  bool get isLoading => _isLoading;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  PharmacyProvider() {
    loadPharmacies();
  }

  Future<void> loadPharmacies() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localData = prefs.getString('saved_pharmacies');
      if (localData != null && localData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localData);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final pharm = Pharmacy.fromMap(item);
            if (!_pharmacies.any((p) => p.id == pharm.id)) {
              _pharmacies.add(pharm);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local pharmacies: ');
    }

    if (_supabase != null) {
      try {
        final response = await _supabase!.from('pharmacies').select();
        if (response.isNotEmpty) {
          for (final item in response) {
            final cloudPharm = Pharmacy.fromMap(Map<String, dynamic>.from(item));
            final idx = _pharmacies.indexWhere((p) => p.id == cloudPharm.id);
            if (idx >= 0) {
              _pharmacies[idx] = cloudPharm;
            } else {
              _pharmacies.add(cloudPharm);
            }
          }
          await _saveToLocal();
        }
      } catch (e) {
        debugPrint('Failed to load pharmacies from Supabase: ');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPharmacy(Pharmacy pharm) async {
    if (!_pharmacies.any((p) => p.id == pharm.id)) {
      _pharmacies.add(pharm);
      notifyListeners();
      await _saveToLocal();
    }

    if (_supabase != null) {
      try {
        await _supabase!.from('pharmacies').insert(pharm.toMap());
      } catch (e) {
        debugPrint('Failed to sync added pharmacy to Supabase: ');
      }
    }
  }

  Future<void> deletePharmacy(String id) async {
    _pharmacies.removeWhere((p) => p.id == id);
    notifyListeners();
    await _saveToLocal();

    if (_supabase != null) {
      try {
        await _supabase!.from('pharmacies').delete().eq('id', id);
      } catch (e) {
        debugPrint('Failed to delete pharmacy from Supabase: ');
      }
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> maps = _pharmacies.map((p) => p.toMap()).toList();
      await prefs.setString('saved_pharmacies', jsonEncode(maps));
    } catch (e) {
      debugPrint('Error saving pharmacies locally: ');
    }
  }
}
