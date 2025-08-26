import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/book.dart';
import '../providers/books_provider.dart';
import '../../borrowing/providers/borrowing_provider.dart';
import '../../auth/providers/auth_provider.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? book;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    final loadedBook = await booksProvider.getBookById(widget.bookId);
    
    if (mounted) {
      setState(() {
        book = loadedBook;
        isLoading = false;
      });
    }
  }

  Future<void> _requestBook() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final borrowingProvider = Provider.of<BorrowingProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || book == null) return;

    // Check if user can borrow books
    if (!borrowingProvider.canBorrowBooks) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have pending penalties. Please pay them before borrowing books.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final success = await borrowingProvider.requestBook(
      authProvider.currentUser!.id,
      book!.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Book request submitted successfully!' 
                : 'Failed to submit book request. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Not Found')),
        body: const Center(
          child: Text('Book not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book!.title),
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
              child: book!.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book!.imageUrl!,
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
                    book!.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Author
                  Text(
                    'by ${book!.author}',
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
                      book!.genre,
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
                        color: book!.availableCopies > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${book!.availableCopies} of ${book!.totalCopies} available',
                        style: TextStyle(
                          color: book!.availableCopies > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  if (book!.isbn != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'ISBN: ${book!.isbn}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  if (book!.description != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book!.description!,
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
                          book!.availableCopies > 0 && 
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
              onPressed: canBorrow ? _requestBook : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                book!.availableCopies > 0 
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