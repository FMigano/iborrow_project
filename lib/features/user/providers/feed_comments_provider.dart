import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FeedCommentsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Add a comment to a post
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String commentText,
  }) async {
    try {
      await _supabase.from('feed_comments').insert({
        'id': _uuid.v4(),
        'post_id': postId,
        'user_id': userId,
        'comment_text': commentText,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('💬 Comment added to post $postId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      return false;
    }
  }

  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('feed_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error getting comments: $e');
      return [];
    }
  }

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final response =
          await _supabase.from('feed_comments').select().eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting comment count: $e');
      return 0;
    }
  }
}
