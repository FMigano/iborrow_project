import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/book.dart';
import '../../../core/models/book_review.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/books_provider.dart';
import '../providers/reviews_provider.dart';
import '../../borrowing/providers/borrowing_provider.dart';
import '../../auth/providers/auth_provider.dart';

class EnhancedBookDetailScreen extends StatefulWidget {
  final String? bookId;
  final Book? book;

  const EnhancedBookDetailScreen({
    super.key,
    this.bookId,
    this.book,
  });

  @override
  State<EnhancedBookDetailScreen> createState() =>
      _EnhancedBookDetailScreenState();
}

class _EnhancedBookDetailScreenState extends State<EnhancedBookDetailScreen> {
  Book? _book;
  bool _isLoading = true;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _book = widget.book;
      _isLoading = false;
      _loadReviews();
    } else if (widget.bookId != null) {
      _loadBook();
    }
  }

  Future<void> _loadBook() async {
    try {
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      await booksProvider.loadBooks();

      final book = booksProvider.books.firstWhere(
        (b) => b.id == widget.bookId,
        orElse: () => throw Exception('Book not found'),
      );

      setState(() {
        _book = book;
        _isLoading = false;
      });
      _loadReviews();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading book: $e')),
        );
        context.pop();
      }
    }
  }

  Future<void> _loadReviews() async {
    if (_book != null) {
      context.read<ReviewsProvider>().loadBookReviews(_book!.id);
    }
  }

  Future<void> _borrowBook() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final borrowing = Provider.of<BorrowingProvider>(context, listen: false);

    if (auth.currentUser == null) {
      _showMessage('Please log in to borrow books', Colors.red);
      return;
    }

    if (!borrowing.canBorrowBooks) {
      _showMessage(
          'You have pending penalties. Please pay them first.', Colors.red);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await borrowing.requestBook(
        auth.currentUser!.id,
        _book!.id,
        notes: 'Book request from mobile app',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog

        _showMessage(
          success
              ? 'Book request submitted successfully!'
              : 'Failed to request book. Please try again.',
          success ? Colors.green : Colors.red,
        );

        if (success) {
          // Reload book data
          await Provider.of<BooksProvider>(context, listen: false).loadBooks();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        _showMessage('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showReviewDialog({BookReview? existingReview}) {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) {
      _showMessage('Please log in to write a review', Colors.orange);
      return;
    }

    int rating = existingReview?.rating ?? 5;
    final textController =
        TextEditingController(text: existingReview?.reviewText ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existingReview == null ? 'Write a Review' : 'Edit Review',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rating',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber[700],
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Review',
                    hintText: 'Share your thoughts about this book...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final reviewsProvider = context.read<ReviewsProvider>();

                bool success;
                if (existingReview == null) {
                  success = await reviewsProvider.addReview(
                    bookId: _book!.id,
                    userId: auth.currentUser!.id,
                    rating: rating,
                    reviewText: textController.text.trim().isEmpty
                        ? null
                        : textController.text.trim(),
                  );
                } else {
                  success = await reviewsProvider.updateReview(
                    reviewId: existingReview.id,
                    rating: rating,
                    reviewText: textController.text.trim().isEmpty
                        ? null
                        : textController.text.trim(),
                  );
                }

                if (!mounted) return;
                _showMessage(
                  success
                      ? 'Review ${existingReview == null ? "added" : "updated"} successfully!'
                      : 'Failed to save review. Please try again.',
                  success ? Colors.green : Colors.red,
                );

                // Reload book to update average rating
                if (success && mounted) {
                  await context.read<BooksProvider>().loadBooks();
                }
              },
              child: Text(existingReview == null ? 'Submit' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Book Cover
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_book!.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: _book!.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.cardGrey,
                        child: const Icon(Icons.book, size: 80),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.cardGrey,
                      child: const Icon(Icons.book, size: 80),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isBookmarked = !_isBookmarked;
                  });
                  _showMessage(
                    _isBookmarked
                        ? 'Added to bookmarks'
                        : 'Removed from bookmarks',
                    Colors.green,
                  );
                },
              ),
            ],
          ),

          // Book Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Author
                  Text(
                    _book!.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${_book!.author}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating & Availability
                  Row(
                    children: [
                      if (_book!.hasRatings) ...[
                        Icon(Icons.star, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _book!.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${_book!.reviewCount} ${_book!.reviewCount == 1 ? "review" : "reviews"})',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _book!.isAvailable
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _book!.isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          _book!.isAvailable
                              ? '${_book!.availableCopies}/${_book!.totalCopies} Available'
                              : 'Unavailable',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: _book!.isAvailable
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Book Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Genre',
                          _book!.genre,
                          Icons.category,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_book!.publisher != null)
                        Expanded(
                          child: _buildInfoCard(
                            'Publisher',
                            _book!.publisher!,
                            Icons.business,
                          ),
                        ),
                    ],
                  ),
                  if (_book!.yearPublished != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Published',
                      _book!.yearPublished.toString(),
                      Icons.calendar_today,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Description
                  if (_book!.description != null &&
                      _book!.description!.isNotEmpty) ...[
                    Text(
                      'About this book',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _book!.description!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reviews Section
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _book!.isAvailable ? _borrowBook : null,
            icon: const Icon(Icons.book),
            label: Text(_book!.isAvailable ? 'Borrow' : 'Unavailable'),
            backgroundColor: _book!.isAvailable ? Colors.blue : Colors.grey,
            heroTag: 'borrow',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Consumer<ReviewsProvider>(
      builder: (context, reviewsProvider, child) {
        if (reviewsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = reviewsProvider.reviews;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews (${reviews.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showReviewDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Review'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No reviews yet',
                          style: GoogleFonts.inter(color: AppTheme.textGrey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to review this book!',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...reviews.map((review) => _buildReviewCard(review)),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(BookReview review) {
    final auth = context.read<AuthProvider>();
    final isOwnReview = auth.currentUser?.id == review.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwnReview ? 'You' : 'User',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnReview)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showReviewDialog(existingReview: review);
                      } else if (value == 'delete') {
                        context.read<ReviewsProvider>().deleteReview(review.id);
                      }
                    },
                  ),
              ],
            ),
            if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.reviewText!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(review.createdAt),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? "s" : ""} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? "s" : ""} ago';
    } else {
      return 'Just now';
    }
  }
}
