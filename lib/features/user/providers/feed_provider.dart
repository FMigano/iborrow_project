import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/feed_post.dart';
import 'package:uuid/uuid.dart';

class FeedProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  List<FeedPost> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<FeedPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load feed posts
  Future<void> loadFeedPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('feed_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      _posts =
          (response as List).map((json) => FeedPost.fromMap(json)).toList();

      debugPrint('✅ Loaded ${_posts.length} feed posts');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading feed posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new post
  Future<bool> createPost({
    required String userId,
    required String content,
    String postType = 'general',
    String? bookId,
  }) async {
    try {
      final post = FeedPost(
        id: _uuid.v4(),
        userId: userId,
        bookId: bookId,
        content: content,
        postType: postType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('feed_posts').insert(post.toMap());

      // Reload posts
      await loadFeedPosts();

      debugPrint('✅ Post created successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating post: $e');
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _supabase.from('feed_posts').delete().eq('id', postId);

      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();

      debugPrint('✅ Post deleted successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting post: $e');
      return false;
    }
  }
}
