import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/database/database_helper.dart';
import '../../../core/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _loadUserFromDatabase(session.user);
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (event == supabase.AuthChangeEvent.signedIn && session != null) {
        _loadUserFromDatabase(session.user);
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserFromDatabase(supabase.User supabaseUser) async {
    final dbUser = await _databaseHelper.getUserById(supabaseUser.id);
    if (dbUser == null) {
      await _createUserInDatabase(supabaseUser);
    } else {
      _currentUser = dbUser;
      notifyListeners();
    }
  }

  Future<void> _createUserInDatabase(supabase.User supabaseUser) async {
    final user = User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: supabaseUser.userMetadata?['full_name'] ?? '',
      studentId: supabaseUser.userMetadata?['student_id'],
      phoneNumber: supabaseUser.phone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _databaseHelper.insertUser(user);
    _currentUser = user;
    notifyListeners();
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
        await _createUserInDatabase(response.user!);
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

      if (response.user != null) {
        await _loadUserFromDatabase(response.user!);
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
}