class FeedPost {
  final String id;
  final String userId;
  final String? bookId;
  final String content;
  final String postType; // general, review, recommendation
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional data (not from database, loaded separately)
  int likeCount;
  int commentCount;
  bool isLikedByCurrentUser;

  FeedPost({
    required this.id,
    required this.userId,
    this.bookId,
    required this.content,
    this.postType = 'general',
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
  });

  factory FeedPost.fromMap(Map<String, dynamic> map) {
    return FeedPost(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      bookId: map['book_id'],
      content: map['content'] ?? '',
      postType: map['post_type'] ?? 'general',
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'content': content,
      'post_type': postType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class FeedComment {
  final String id;
  final String postId;
  final String userId;
  final String commentText;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedComment.fromMap(Map<String, dynamic> map) {
    return FeedComment(
      id: map['id'] ?? '',
      postId: map['post_id'] ?? '',
      userId: map['user_id'] ?? '',
      commentText: map['comment_text'] ?? '',
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
