import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/book.dart';
import '../providers/books_provider.dart';
import '../../borrowing/providers/borrowing_provider.dart';
import '../../auth/providers/auth_provider.dart';

class BookDetailScreen extends StatefulWidget {
  final String? bookId;
  final Book? book;

  const BookDetailScreen({
    super.key,
    this.bookId,
    this.book,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _book = widget.book;
      _isLoading = false;
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

  Future<void> _borrowBook() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final borrowing = Provider.of<BorrowingProvider>(context, listen: false);
    
    if (auth.currentUser == null) {
      _showMessage('Please log in to borrow books', Colors.red);
      return;
    }

    if (!borrowing.canBorrowBooks) {
      _showMessage('You have pending penalties. Please pay them first.', Colors.red);
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
          // Wait for message to show
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            // Use proper navigation that maintains the bottom nav
            if (GoRouter.of(context).canPop()) {
              context.pop(); // This goes back to the books list with bottom nav
            } else {
              // Fallback - navigate to home with bottom nav
              context.go('/home');
            }
          }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Not Found')),
        body: const Center(
          child: Text('Book not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_book!.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: _book!.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _book!.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.book,
                        size: 100,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.book,
                      size: 100,
                      color: Colors.grey,
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _book!.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Author
                  Text(
                    'by ${_book!.author}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Genre
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _book!.genre,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Availability
                  Row(
                    children: [
                      Icon(
                        Icons.library_books,
                        color: _book!.availableCopies > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_book!.availableCopies} of ${_book!.totalCopies} available',
                        style: TextStyle(
                          color: _book!.availableCopies > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_book!.isbn != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'ISBN: ${_book!.isbn}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  if (_book!.description != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _book!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer2<AuthProvider, BorrowingProvider>(
        builder: (context, authProvider, borrowingProvider, child) {
          final isAuthenticated = authProvider.isAuthenticated;
          final canBorrow = isAuthenticated && 
                          _book!.availableCopies > 0 && 
                          borrowingProvider.canBorrowBooks;
          
          if (!isAuthenticated) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login to Borrow'),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: canBorrow ? _borrowBook : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _book!.availableCopies > 0 
                    ? (borrowingProvider.canBorrowBooks 
                        ? 'Request Book' 
                        : 'Pay Penalties to Borrow')
                    : 'Not Available',
              ),
            ),
          );
        },
      ),
    );
  }
}