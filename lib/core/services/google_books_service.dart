import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Service for fetching book information from Google Books API
/// Documentation: https://developers.google.com/books/docs/v1/using
class GoogleBooksService {
  static const String _baseUrl = AppConfig.googleBooksApiUrl;
  static String get _apiKey => AppConfig.googleBooksApiKey;

  /// Fetch complete book data from Google Books API
  /// Uses intitle: and inauthor: search operators for precise results
  static Future<Map<String, dynamic>?> fetchBookData({
    required String title,
    required String author,
  }) async {
    try {
      final query = 'intitle:$title inauthor:$author';
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
          '$_baseUrl/volumes?q=$encodedQuery&maxResults=1&key=$_apiKey');

      debugPrint('📚 Fetching: $title by $author');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['totalItems'] != null && data['totalItems'] > 0) {
          final book = data['items'][0];
          final volumeInfo = book['volumeInfo'];

          // Fix CORS: Force HTTPS on all image URLs
          Map<String, dynamic>? imageLinks = volumeInfo['imageLinks'];
          if (imageLinks != null) {
            imageLinks = Map<String, dynamic>.from(imageLinks);
            imageLinks.forEach((key, value) {
              if (value is String) {
                imageLinks![key] = value.replaceFirst('http://', 'https://');
              }
            });
          }

          return {
            'title': volumeInfo['title'],
            'authors': volumeInfo['authors'],
            'publisher': volumeInfo['publisher'],
            'publishedDate': volumeInfo['publishedDate'],
            'description': volumeInfo['description'],
            'imageLinks': imageLinks,
            'categories': volumeInfo['categories'],
            'averageRating': volumeInfo['averageRating'],
            'ratingsCount': volumeInfo['ratingsCount'],
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching book: $e');
      return null;
    }
  }

  /// Fetch book cover URL (with HTTPS fix for CORS)
  static Future<String?> fetchBookCoverUrl({
    required String title,
    required String author,
  }) async {
    try {
      final bookData = await fetchBookData(title: title, author: author);

      if (bookData != null && bookData['imageLinks'] != null) {
        final imageLinks = bookData['imageLinks'];
        return imageLinks['medium'] ??
            imageLinks['small'] ??
            imageLinks['thumbnail'] ??
            imageLinks['smallThumbnail'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search Google Books catalog
  static Future<List<Map<String, dynamic>>> searchBooks(String query,
      {int maxResults = 40}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
          '$_baseUrl/volumes?q=$encodedQuery&maxResults=$maxResults&key=$_apiKey');

      debugPrint('🔍 Searching: $query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['totalItems'] != null && data['totalItems'] > 0) {
          return (data['items'] as List).map((item) {
            final volumeInfo = Map<String, dynamic>.from(item['volumeInfo']);

            // Fix CORS: Force HTTPS
            if (volumeInfo['imageLinks'] != null) {
              final imageLinks =
                  Map<String, dynamic>.from(volumeInfo['imageLinks']);
              imageLinks.forEach((key, value) {
                if (value is String) {
                  imageLinks[key] = value.replaceFirst('http://', 'https://');
                }
              });
              volumeInfo['imageLinks'] = imageLinks;
            }

            return volumeInfo;
          }).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error searching: $e');
      return [];
    }
  }

  /// Browse by subject/genre
  static Future<List<Map<String, dynamic>>> browseByGenre(String genre,
      {int maxResults = 40}) async {
    return searchBooks('subject:$genre', maxResults: maxResults);
  }

  /// Get new releases (newest published)
  static Future<List<Map<String, dynamic>>> getNewReleases(
      {int maxResults = 40}) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/volumes?q=subject:fiction&orderBy=newest&maxResults=$maxResults&key=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['totalItems'] != null && data['totalItems'] > 0) {
          return (data['items'] as List).map((item) {
            final volumeInfo = Map<String, dynamic>.from(item['volumeInfo']);

            // Fix CORS: Force HTTPS
            if (volumeInfo['imageLinks'] != null) {
              final imageLinks =
                  Map<String, dynamic>.from(volumeInfo['imageLinks']);
              imageLinks.forEach((key, value) {
                if (value is String) {
                  imageLinks[key] = value.replaceFirst('http://', 'https://');
                }
              });
              volumeInfo['imageLinks'] = imageLinks;
            }

            return volumeInfo;
          }).toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get popular genres
  static List<String> getPopularGenres() {
    return [
      'Fiction',
      'Science',
      'History',
      'Biography',
      'Technology',
      'Business',
      'Self-Help',
      'Romance',
      'Mystery',
      'Fantasy',
      'Science Fiction',
      'Horror',
      'Poetry',
      'Art',
      'Philosophy',
      'Psychology',
      'Health',
      'Travel',
    ];
  }
}
