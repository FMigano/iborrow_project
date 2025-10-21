import 'package:flutter/foundation.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/models/book.dart';
import 'package:uuid/uuid.dart';

/// Provider for browsing Google Books catalog
class GoogleBooksProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Map<String, dynamic>> _googleBooks = [];
  bool _isLoading = false;
  String? _error;
  String _currentGenre = 'Fiction';

  List<Map<String, dynamic>> get googleBooks => _googleBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentGenre => _currentGenre;

  /// Browse books by genre from Google Books
  Future<void> browseByGenre(String genre) async {
    _isLoading = true;
    _error = null;
    _currentGenre = genre;
    notifyListeners();

    try {
      _googleBooks =
          await GoogleBooksService.browseByGenre(genre, maxResults: 40);
      debugPrint('✅ Loaded ${_googleBooks.length} books for genre: $genre');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error browsing genre: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get new releases from Google Books
  Future<void> loadNewReleases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _googleBooks = await GoogleBooksService.getNewReleases(maxResults: 40);
      debugPrint('✅ Loaded ${_googleBooks.length} new releases');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading new releases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search Google Books
  Future<void> searchGoogleBooks(String query) async {
    if (query.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _googleBooks =
          await GoogleBooksService.searchBooks(query, maxResults: 40);
      debugPrint('✅ Found ${_googleBooks.length} books for: $query');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error searching: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convert Google Book to local Book model for saving
  Book convertToLocalBook(Map<String, dynamic> googleBook) {
    final imageLinks = googleBook['imageLinks'];
    String? imageUrl;

    if (imageLinks != null) {
      imageUrl = imageLinks['medium'] ??
          imageLinks['small'] ??
          imageLinks['thumbnail'] ??
          imageLinks['smallThumbnail'];
    }

    final authors = googleBook['authors'] as List?;
    final categories = googleBook['categories'] as List?;
    final publishedDate = googleBook['publishedDate']?.toString();

    return Book(
      id: _uuid.v4(),
      title: googleBook['title'] ?? 'Unknown Title',
      author: authors?.join(', ') ?? 'Unknown Author',
      genre: categories?.first ?? 'General',
      description: googleBook['description'],
      imageUrl: imageUrl,
      publisher: googleBook['publisher'],
      yearPublished: publishedDate != null && publishedDate.length >= 4
          ? int.tryParse(publishedDate.substring(0, 4))
          : null,
      averageRating: (googleBook['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: googleBook['ratingsCount'] ?? 0,
      totalCopies: 1,
      availableCopies: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
