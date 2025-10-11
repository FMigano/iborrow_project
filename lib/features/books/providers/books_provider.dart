import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/book.dart';
import '../../../core/services/sample_data_service.dart';

class BooksProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();
  
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? selectedGenre;

  List<Book> get books => _filteredBooks.isEmpty && _searchQuery.isEmpty && selectedGenre == null ? _books : _filteredBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ ADD: Auto-load on provider creation
  BooksProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    debugPrint('📚 BooksProvider: Initializing data...');
    await loadBooks();
    
    // If no books found, insert sample data
    if (_books.isEmpty) {
      debugPrint('📚 No books found, inserting sample data...');
      try {
        await SampleDataService().insertSampleData();
        await loadBooks();
      } catch (e) {
        debugPrint('❌ Error inserting sample data: $e');
      }
    }
  }

  Future<void> loadBooks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('📚 Loading books from Supabase...');
      _books = await _databaseHelper.getAllBooks();
      
      debugPrint('✅ Loaded ${_books.length} books');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading books: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);
      
      debugPrint('📥 Found ${response.length} books in Supabase');
      
      for (final bookMap in response) {
        final book = Book.fromMap(bookMap);
        await _databaseHelper.insertBook(book);
        debugPrint('➕ Added book: ${book.title}');
      }
      
      // Reload books
      _books = await _databaseHelper.getAllBooks();
      notifyListeners();
      
      debugPrint('✅ Books synced from Supabase');
    } catch (e) {
      debugPrint('❌ Error syncing books from Supabase: $e');
    }
  }

  void searchBooks(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByGenre(String genre) {
    if (selectedGenre == genre) {
      selectedGenre = null; // Deselect if already selected
    } else {
      selectedGenre = genre;
    }
    // Implement genre filtering logic
    notifyListeners();
  }

  void _applyFilters() {
    _filteredBooks = _books.where((book) {
      final matchesSearch = _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery) ||
          book.author.toLowerCase().contains(_searchQuery) ||
          book.genre.toLowerCase().contains(_searchQuery);

      final matchesGenre = selectedGenre == null || book.genre == selectedGenre;

      return matchesSearch && matchesGenre;
    }).toList();
  }

  Future<bool> addBook({
    required String title,
    required String author,
    required String genre,
    String? isbn,
    String? description,
    String? imageUrl,
    int totalCopies = 1,
  }) async {
    try {
      final book = Book(
        id: _uuid.v4(),
        title: title,
        author: author,
        genre: genre,
        isbn: isbn,
        description: description,
        imageUrl: imageUrl,
        totalCopies: totalCopies,
        availableCopies: totalCopies,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.insertBook(book);
      await loadBooks();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<Book?> getBookById(String id) async {
    try {
      return await _databaseHelper.getBookById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
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

  List<String> get genres {
    final genreSet = <String>{};
    for (var book in _books) {
      genreSet.add(book.genre);
    }
    return genreSet.toList()..sort();
  }
}