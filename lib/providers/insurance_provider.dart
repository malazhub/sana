import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insurance_card.dart';

class InsuranceProvider extends ChangeNotifier {
  final List<InsuranceCard> _cards = [];
  bool _isLoading = false;
  String? _userId;
  StreamSubscription<AuthState>? _authSubscription;
  int _loadGeneration = 0;

  List<InsuranceCard> get cards => List.unmodifiable(_cards);
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  SupabaseClient get _client => Supabase.instance.client;

  InsuranceProvider() {
    _userId = _client.auth.currentUser?.id;
    _authSubscription = _client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Insurance auth listener error: $error\n$stackTrace');
      },
    );
    if (_userId != null) {
      loadCards();
    }
  }

  void _handleAuthStateChange(AuthState authState) {
    final newUserId = authState.session?.user.id;
    if (_userId == newUserId) return;

    _loadGeneration++;
    _userId = newUserId;
    _cards.clear();
    notifyListeners();

    if (newUserId != null) {
      loadCards();
    }
  }

  Future<void> loadCards() async {
    final currentGen = _loadGeneration;
    final user = _client.auth.currentUser;
    if (user == null) {
      _cards.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client
          .from('insurance_cards')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (currentGen != _loadGeneration) return;

      _cards.clear();
      for (final item in response) {
        try {
          _cards.add(InsuranceCard.fromMap(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('Error parsing insurance card: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading insurance cards: $e');
    } finally {
      if (currentGen == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addCard(InsuranceCard card) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final cardMap = card.toMap()..['user_id'] = user.id;
      final response = await _client
          .from('insurance_cards')
          .insert(cardMap)
          .select()
          .single();
      final newCard =
          InsuranceCard.fromMap(Map<String, dynamic>.from(response));
      _cards.insert(0, newCard);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding insurance card: $e');
      return false;
    }
  }

  Future<bool> deleteCard(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('insurance_cards')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
      _cards.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting insurance card: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
