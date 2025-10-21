import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/book_review.dart';
import 'package:uuid/uuid.dart';

class ReviewsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  List<BookReview> _reviews = [];
  bool _isLoading = false;
  String? _error;

  List<BookReview> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load reviews for a specific book
  Future<void> loadBookReviews(String bookId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('book_reviews')
          .select()
          .eq('book_id', bookId)
          .order('created_at', ascending: false);

      _reviews =
          (response as List).map((json) => BookReview.fromMap(json)).toList();

      debugPrint('✅ Loaded ${_reviews.length} reviews for book $bookId');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new review
  Future<bool> addReview({
    required String bookId,
    required String userId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      final review = BookReview(
        id: _uuid.v4(),
        bookId: bookId,
        userId: userId,
        rating: rating,
        reviewText: reviewText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('book_reviews').insert(review.toMap());

      // Reload reviews
      await loadBookReviews(bookId);

      debugPrint('✅ Review added successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding review: $e');
      return false;
    }
  }

  /// Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      await _supabase.from('book_reviews').update({
        'rating': rating,
        'review_text': reviewText,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);

      debugPrint('✅ Review updated successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _supabase.from('book_reviews').delete().eq('id', reviewId);

      _reviews.removeWhere((r) => r.id == reviewId);
      notifyListeners();

      debugPrint('✅ Review deleted successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting review: $e');
      return false;
    }
  }

  /// Check if user has already reviewed a book
  Future<BookReview?> getUserReview(String bookId, String userId) async {
    try {
      final response = await _supabase
          .from('book_reviews')
          .select()
          .eq('book_id', bookId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return BookReview.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error checking user review: $e');
      return null;
    }
  }
}
