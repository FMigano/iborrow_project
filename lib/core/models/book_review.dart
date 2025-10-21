class BookReview {
  final String id;
  final String bookId;
  final String userId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookReview({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookReview.fromMap(Map<String, dynamic> map) {
    return BookReview(
      id: map['id'] ?? '',
      bookId: map['book_id'] ?? '',
      userId: map['user_id'] ?? '',
      rating: map['rating'] ?? 0,
      reviewText: map['review_text'],
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
      'rating': rating,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
