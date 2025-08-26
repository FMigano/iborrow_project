import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/book.dart';

class BooksProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedGenre;
  String _searchQuery = '';

  List<Book> get books => _searchQuery.isEmpty && _selectedGenre == null
      ? _books
      : _filteredBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedGenre => _selectedGenre;

  List<Book> get availableBooks => books.where((book) => book.availableCopies > 0).toList();

  List<String> get genres {
    final genreSet = _books.map((book) => book.genre).toSet();
    return ['All', ...genreSet.toList()..sort()];
  }

  Future<void> loadBooks() async {
    try {
      _setLoading(true);
      _books = await _databaseHelper.getAllBooks();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void searchBooks(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByGenre(String? genre) {
    _selectedGenre = genre == 'All' ? null : genre;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredBooks = _books.where((book) {
      final matchesSearch = _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery) ||
          book.author.toLowerCase().contains(_searchQuery) ||
          book.genre.toLowerCase().contains(_searchQuery);

      final matchesGenre = _selectedGenre == null || book.genre == _selectedGenre;

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
}