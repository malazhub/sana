import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/insurance_card.dart';

class InsuranceProvider extends ChangeNotifier {
  static const String _storageKey =
      'saved_insurance_cards_v2';

  static const String _legacyStorageKey =
      'saved_insurance_cards';

  final List<InsuranceCard> _cards = [];

  bool _isLoading = false;
  String? _userId;

  StreamSubscription<AuthState>? _authSubscription;

  List<InsuranceCard> get cards =>
      List.unmodifiable(_cards);

  bool get isLoading => _isLoading;

  String? get userId => _userId;

  SupabaseClient get _client =>
      Supabase.instance.client;

  User? get _currentUser =>
      _client.auth.currentUser;

  InsuranceProvider() {
    _userId = _currentUser?.id;

    _authSubscription =
        _client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Insurance auth listener error: '
          '$error\n$stackTrace',
        );
      },
    );

    if (_userId != null) {
      loadCards();
    }
  }

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  void _handleAuthStateChange(
    AuthState authState,
  ) {
    final newUserId =
        authState.session?.user.id;

    if (_userId == newUserId) {
      return;
    }

    _userId = newUserId;

    // Never keep another user's cards in memory.
    _cards.clear();

    notifyListeners();

    if (newUserId != null) {
      loadCards();
    }
  }

  String? _authenticatedUserId() {
    final currentUserId =
        _currentUser?.id;

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

  Future<void> loadCards() async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      _cards.clear();
      notifyListeners();
      return;
    }

    if (_isLoading) {
      return;
    }

    _setLoading(true);

    try {
      // Always start with a clean collection.
      _cards.clear();

      // --------------------------------------------------------
      // LOCAL CACHE
      // --------------------------------------------------------

      await _loadLocalCards(uid);

      // --------------------------------------------------------
      // SUPABASE
      // --------------------------------------------------------

      try {
        final response = await _client
            .from('insurance_cards')
            .select()
            .eq('user_id', uid)
            .order(
              'created_at',
              ascending: false,
            );

        final cloudCards = <InsuranceCard>[];

        for (final item in response) {
          try {
            final card = InsuranceCard.fromMap(
              Map<String, dynamic>.from(item),
            );

            // Extra protection against malformed/incorrect
            // records returned by the backend.
            if (card.userId != null &&
                card.userId!.isNotEmpty &&
                card.userId != uid) {
              continue;
            }

            cloudCards.add(card);
          } catch (error) {
            debugPrint(
              'Invalid insurance card: $error',
            );
          }
        }

        _cards
          ..clear()
          ..addAll(cloudCards);

        await _saveToLocal(uid);
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to load insurance cards from Supabase: '
          '$error\n$stackTrace',
        );

        // Keep the authenticated user's local cache
        // when Supabase is temporarily unavailable.
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Insurance card loading error: '
        '$error\n$stackTrace',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ADD / SAVE
  // ============================================================

  Future<void> addCard([
    InsuranceCard? card,
  ]) async {
    if (card == null) {
      return;
    }

    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to save an insurance card.',
      );
    }

    try {
      /*
       * Never trust the user ID supplied by the UI/model.
       * Always replace it with the authenticated Supabase ID.
       */
      final cardToSave = InsuranceCard(
        id: card.id,
        providerName: card.providerName,
        policyNumber: card.policyNumber,
        frontImageUrl: card.frontImageUrl,
        backImageUrl: card.backImageUrl,
        userId: uid,
        createdAt: card.createdAt,
      );

      final map = cardToSave.toSupabaseMap();

      map['user_id'] = uid;

      final response = await _client
          .from('insurance_cards')
          .upsert(
            map,
            onConflict: 'id',
          )
          .select()
          .single();

      final savedCard = InsuranceCard.fromMap(
        Map<String, dynamic>.from(response),
      );

      // Extra ownership check.
      if (savedCard.userId != null &&
          savedCard.userId!.isNotEmpty &&
          savedCard.userId != uid) {
        throw StateError(
          'The saved insurance card belongs to another user.',
        );
      }

      final index = _cards.indexWhere(
        (item) => item.id == savedCard.id,
      );

      if (index >= 0) {
        _cards[index] = savedCard;
      } else {
        _cards.insert(
          0,
          savedCard,
        );
      }

      await _saveToLocal(uid);

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to save insurance card: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteCard(
    String id,
  ) async {
    final uid = _authenticatedUserId();

    if (uid == null) {
      throw StateError(
        'You must be signed in to delete an insurance card.',
      );
    }

    final cardIndex = _cards.indexWhere(
      (card) => card.id == id,
    );

    if (cardIndex < 0) {
      return;
    }

    try {
      /*
       * Both ID and user_id are checked.
       * This prevents deleting another user's card.
       */
      await _client
          .from('insurance_cards')
          .delete()
          .eq('id', id)
          .eq('user_id', uid);

      _cards.removeAt(cardIndex);

      await _saveToLocal(uid);

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to delete insurance card: '
        '$error\n$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // LOCAL CACHE
  // ============================================================

  Future<void> _loadLocalCards(
    String uid,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final data =
          prefs.getString(_storageKey) ??
          prefs.getString(_legacyStorageKey);

      if (data == null ||
          data.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(data);

      if (decoded is! List) {
        return;
      }

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final card = InsuranceCard.fromMap(
            Map<String, dynamic>.from(item),
          );

          final cardUserId = card.userId;

          /*
           * Only load cards belonging to the current
           * authenticated user.
           */
          if (cardUserId == null ||
              cardUserId.isEmpty) {
            continue;
          }

          if (cardUserId == 'guest') {
            continue;
          }

          if (cardUserId != uid) {
            continue;
          }

          final exists = _cards.any(
            (existing) =>
                existing.id == card.id,
          );

          if (!exists) {
            _cards.add(card);
          }
        } catch (error) {
          debugPrint(
            'Invalid cached insurance card: '
            '$error',
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load local insurance cards: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _saveToLocal(
    String uid,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final maps = _cards
          .where(
            (card) =>
                card.userId == uid,
          )
          .map(
            (card) => card.toMap(),
          )
          .toList();

      await prefs.setString(
        _storageKey,
        jsonEncode(maps),
      );
    } catch (error) {
      debugPrint(
        'Error saving insurance cards locally: '
        '$error',
      );
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _cards.clear();
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