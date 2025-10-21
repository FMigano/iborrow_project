import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FeedLikesProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Toggle like on a post
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      // Check if already liked
      final existing = await _supabase
          .from('feed_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await _supabase
            .from('feed_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        debugPrint('❤️ Unliked post $postId');
        return false;
      } else {
        // Like
        await _supabase.from('feed_likes').insert({
          'id': _uuid.v4(),
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('❤️ Liked post $postId');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error toggling like: $e');
      return false;
    }
  }

  /// Get like count for a post
  Future<int> getLikeCount(String postId) async {
    try {
      final response =
          await _supabase.from('feed_likes').select().eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting like count: $e');
      return 0;
    }
  }

  /// Check if user liked a post
  Future<bool> hasUserLiked(String postId, String userId) async {
    try {
      final response = await _supabase
          .from('feed_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
