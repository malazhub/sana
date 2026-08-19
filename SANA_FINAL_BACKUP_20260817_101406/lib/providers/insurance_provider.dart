import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insurance_card.dart';

class InsuranceProvider with ChangeNotifier {
  final List<InsuranceCard> _cards = [];
  bool _isLoading = false;

  List<InsuranceCard> get cards => List.unmodifiable(_cards);
  bool get isLoading => _isLoading;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  InsuranceProvider() {
    loadCards();
  }

  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localData = prefs.getString('saved_insurance_cards_v2') ??
          prefs.getString('saved_insurance_cards');
      if (localData != null && localData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localData);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final card = InsuranceCard.fromMap(item);
            if (!_cards.any((c) => c.id == card.id)) {
              _cards.add(card);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local insurance cards: $e');
    }

    if (_supabase != null) {
      try {
        final response = await _supabase!.from('insurance_cards').select();
        if (response.isNotEmpty) {
          for (final item in response) {
            final cloudCard =
                InsuranceCard.fromMap(Map<String, dynamic>.from(item));
            final idx = _cards.indexWhere((c) => c.id == cloudCard.id);
            if (idx >= 0) {
              _cards[idx] = cloudCard;
            } else {
              _cards.add(cloudCard);
            }
          }
          await _saveToLocal();
        }
      } catch (e) {
        debugPrint('Failed to load insurance cards from Supabase: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCard([InsuranceCard? card]) async {
    if (card != null) {
      if (!_cards.any((c) => c.id == card.id)) {
        _cards.add(card);
        notifyListeners();
        await _saveToLocal();
      }

      if (_supabase != null) {
        try {
          await _supabase!.from('insurance_cards').insert(card.toSupabaseMap());
          debugPrint('Insurance card synced to Supabase successfully!');
        } catch (e) {
          debugPrint('Failed to sync added card to Supabase: $e');
        }
      }
    }
  }

  Future<void> deleteCard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
    await _saveToLocal();

    if (_supabase != null) {
      try {
        await _supabase!.from('insurance_cards').delete().eq('id', id);
      } catch (e) {
        debugPrint('Failed to delete card from Supabase: $e');
      }
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> maps =
          _cards.map((c) => c.toMap()).toList();
      await prefs.setString('saved_insurance_cards_v2', jsonEncode(maps));
    } catch (e) {
      debugPrint('Error saving insurance cards locally: $e');
    }
  }
}
