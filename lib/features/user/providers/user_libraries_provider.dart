import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_library.dart';
import 'package:uuid/uuid.dart';

class UserLibrariesProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  List<UserLibrary> _libraries = [];
  bool _isLoading = false;
  String? _error;

  List<UserLibrary> get libraries => _libraries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load user's libraries
  Future<void> loadUserLibraries(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('user_libraries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _libraries =
          (response as List).map((json) => UserLibrary.fromMap(json)).toList();

      debugPrint('✅ Loaded ${_libraries.length} libraries for user $userId');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading libraries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new library
  Future<bool> createLibrary({
    required String userId,
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final library = UserLibrary(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        description: description,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('user_libraries').insert(library.toMap());

      // Reload libraries
      await loadUserLibraries(userId);

      debugPrint('✅ Library created successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating library: $e');
      return false;
    }
  }

  /// Delete a library
  Future<bool> deleteLibrary(String libraryId, String userId) async {
    try {
      await _supabase.from('user_libraries').delete().eq('id', libraryId);

      // Reload libraries
      await loadUserLibraries(userId);

      debugPrint('✅ Library deleted successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting library: $e');
      return false;
    }
  }
}
