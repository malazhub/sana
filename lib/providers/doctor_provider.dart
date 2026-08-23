import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor.dart';

class DoctorProvider extends ChangeNotifier {
  final List<Doctor> _doctors = [];
  bool _isLoading = false;
  String? _userId;
  StreamSubscription<AuthState>? _authSubscription;
  int _loadGeneration = 0;

  List<Doctor> get doctors => List.unmodifiable(_doctors);
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  SupabaseClient get _client => Supabase.instance.client;

  DoctorProvider() {
    _userId = _client.auth.currentUser?.id;
    _authSubscription = _client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Doctor auth listener error: $error\n$stackTrace');
      },
    );
    if (_userId != null) {
      loadDoctors();
    }
  }

  void _handleAuthStateChange(AuthState authState) {
    final newUserId = authState.session?.user.id;
    if (_userId == newUserId) return;

    _loadGeneration++;
    _userId = newUserId;
    _doctors.clear();
    notifyListeners();

    if (newUserId != null) {
      loadDoctors();
    }
  }

  Future<void> loadDoctors() async {
    final currentGen = _loadGeneration;
    final user = _client.auth.currentUser;
    if (user == null) {
      _doctors.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client
          .from('doctors')
          .select()
          .eq('user_id', user.id)
          .order('name', ascending: true);

      if (currentGen != _loadGeneration) return;

      _doctors.clear();
      for (final item in response) {
        try {
          _doctors.add(Doctor.fromMap(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('Error parsing doctor: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
    } finally {
      if (currentGen == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addDoctor(Doctor doctor) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final docMap = doctor.toMap()..['user_id'] = user.id;
      final response = await _client.from('doctors').insert(docMap).select().single();
      final newDoctor = Doctor.fromMap(Map<String, dynamic>.from(response));
      _doctors.insert(0, newDoctor);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding doctor: $e');
      return false;
    }
  }

  Future<bool> deleteDoctor(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('doctors').delete().eq('id', id).eq('user_id', user.id);
      _doctors.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting doctor: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}