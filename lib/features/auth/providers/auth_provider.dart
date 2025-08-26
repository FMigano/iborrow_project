import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/database/database.dart';
import '../../../core/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  final AppDatabase _database = AppDatabase();

  supabase.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  supabase.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = session.user;
      _loadUserFromDatabase();
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (event == supabase.AuthChangeEvent.signedIn && session != null) {
        _currentUser = session.user;
        _loadUserFromDatabase();
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserFromDatabase() async {
    if (_currentUser == null) return;
    
    final dbUser = await _database.getUserById(_currentUser!.id);
    if (dbUser == null) {
      await _createUserInDatabase();
    }
  }

  Future<void> _createUserInDatabase() async {
    if (_currentUser == null) return;

    final user = User(
      id: _currentUser!.id,
      email: _currentUser!.email ?? '',
      fullName: _currentUser!.userMetadata?['full_name'] ?? '',
      phoneNumber: _currentUser!.phone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _database.insertUser(user);
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? studentId,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'student_id': studentId,
          'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        _currentUser = response.user;
        await _createUserInDatabase();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response.user != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabase.auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}