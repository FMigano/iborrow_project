// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/feed_post.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../providers/feed_provider.dart';
import '../providers/feed_likes_provider.dart';
import '../providers/feed_comments_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadFeedPosts();
    });
  }

  void _showCreatePostDialog() {
    final contentController = TextEditingController();
    String selectedType = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Create Post',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Post Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'review', child: Text('Book Review')),
                  DropdownMenuItem(
                      value: 'recommendation', child: Text('Recommendation')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedType = value ?? 'general';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'What\'s on your mind?',
                  border: OutlineInputBorder(),
                  hintText: 'Share your thoughts about books...',
                ),
                maxLines: 4,
                maxLength: 500,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter some content')),
                  );
                  return;
                }

                final userId = context.read<AuthProvider>().currentUser?.id;
                if (userId != null) {
                  final success = await context.read<FeedProvider>().createPost(
                        userId: userId,
                        content: contentController.text.trim(),
                        postType: selectedType,
                      );

                  if (!mounted) return;
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Feed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePostDialog,
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<FeedProvider>().loadFeedPosts(),
        child: Consumer<FeedProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Posts Yet',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share something with the community!',
                      style: GoogleFonts.inter(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _showCreatePostDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Post'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(provider.posts[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(FeedPost post) {
    return FutureBuilder<String>(
      future: _getUserName(post.userId),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'User';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child:
                          const Icon(Icons.person, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _formatDate(post.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPostTypeColor(post.postType)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPostTypeLabel(post.postType),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getPostTypeColor(post.postType),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Post content
                Text(
                  post.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleLike(post),
                      icon: Icon(
                        post.isLikedByCurrentUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: post.isLikedByCurrentUser
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                      label: Text(
                        '${post.likeCount}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCommentsDialog(post),
                      icon: Icon(Icons.comment_outlined,
                          size: 18, color: Colors.grey[600]),
                      label: Text(
                        '${post.commentCount}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final user = await DatabaseHelper().getUserById(userId);
      return user?.fullName ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  Future<void> _toggleLike(FeedPost post) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final likesProvider = context.read<FeedLikesProvider>();
    final isLiked = await likesProvider.toggleLike(post.id, userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLiked ? 'Liked!' : 'Like removed'),
          duration: const Duration(seconds: 1),
        ),
      );
      // Reload feed to update counts
      await context.read<FeedProvider>().loadFeedPosts();
    }
  }

  void _showCommentsDialog(FeedPost post) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Comments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future:
                      context.read<FeedCommentsProvider>().getComments(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet. Be the first!',
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person, size: 20),
                          ),
                          title: Text(
                            comment['comment_text'],
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          subtitle: Text(
                            'Just now',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;

                      final userId =
                          context.read<AuthProvider>().currentUser?.id;
                      if (userId == null) return;

                      final success =
                          await context.read<FeedCommentsProvider>().addComment(
                                postId: post.id,
                                userId: userId,
                                commentText: commentController.text.trim(),
                              );

                      if (success && mounted) {
                        commentController.clear();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Comment posted!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Reload feed
                        await context.read<FeedProvider>().loadFeedPosts();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  Color _getPostTypeColor(String type) {
    switch (type) {
      case 'review':
        return Colors.orange;
      case 'recommendation':
        return Colors.green;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _getPostTypeLabel(String type) {
    switch (type) {
      case 'review':
        return 'Review';
      case 'recommendation':
        return 'Recommendation';
      default:
        return 'General';
    }
  }
}
