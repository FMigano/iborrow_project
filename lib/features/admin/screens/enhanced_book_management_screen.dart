// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/book.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/google_books_service.dart';
import '../../books/providers/books_provider.dart';
import 'package:uuid/uuid.dart';

class EnhancedBookManagementScreen extends StatefulWidget {
  const EnhancedBookManagementScreen({super.key});

  @override
  State<EnhancedBookManagementScreen> createState() =>
      _EnhancedBookManagementScreenState();
}

class _EnhancedBookManagementScreenState
    extends State<EnhancedBookManagementScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Book> _books = [];
  bool _isLoading = false;
  String _filterGenre = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await _databaseHelper.getAllBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading books: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _getFilteredBooks();
    final genres = _getUniqueGenres();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Books',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _loadSampleBooks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Load Sample Books',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search books...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: genres.map((genre) {
                      final isSelected = _filterGenre == genre;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(genre),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _filterGenre = genre;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Books list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBooks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(filteredBooks[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Book> _getFilteredBooks() {
    var filtered = _books;

    if (_filterGenre != 'All') {
      filtered = filtered.where((book) => book.genre == _filterGenre).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((book) {
        return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  List<String> _getUniqueGenres() {
    final genres = _books.map((book) => book.genre).toSet().toList()..sort();
    return ['All', ...genres];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Books Found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Books from Google Books will appear automatically',
            style: GoogleFonts.inter(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Users browse and select books from the dashboard',
            style: GoogleFonts.inter(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadSampleBooks,
            icon: const Icon(Icons.refresh),
            label: const Text('Load Sample Books'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Book cover placeholder
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: book.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        book.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.book, size: 32),
                      ),
                    )
                  : const Icon(Icons.book, size: 32),
            ),
            const SizedBox(width: 16),
            // Book details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${book.author}',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.genre,
                    style: GoogleFonts.inter(
                      color: Colors.blue[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: book.isAvailable
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: book.isAvailable
                                ? Colors.green[200]!
                                : Colors.red[200]!,
                          ),
                        ),
                        child: Text(
                          '${book.availableCopies}/${book.totalCopies} available',
                          style: TextStyle(
                            color: book.isAvailable
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmDialog(book);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSampleBooks() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Loading sample books...', style: GoogleFonts.inter()),
          ],
        ),
      ),
    );

    try {
      final sampleBooks = [
        {
          'title': 'The Great Gatsby',
          'author': 'F. Scott Fitzgerald',
          'genre': 'Fiction',
          'description': 'A classic American novel set in the Jazz Age.',
        },
        {
          'title': 'To Kill a Mockingbird',
          'author': 'Harper Lee',
          'genre': 'Fiction',
          'description':
              'A gripping tale of racial injustice and childhood innocence.',
        },
        {
          'title': '1984',
          'author': 'George Orwell',
          'genre': 'Dystopian Fiction',
          'description': 'A chilling vision of a totalitarian future.',
        },
        {
          'title': 'Pride and Prejudice',
          'author': 'Jane Austen',
          'genre': 'Romance',
          'description':
              'A witty and romantic tale of love and social conventions.',
        },
        {
          'title': 'The Catcher in the Rye',
          'author': 'J.D. Salinger',
          'genre': 'Fiction',
          'description': 'A coming-of-age story following Holden Caulfield.',
        },
      ];

      for (final bookData in sampleBooks) {
        // Fetch book data from Google Books API
        debugPrint(
            '📚 Fetching: ${bookData['title']} by ${bookData['author']}');

        final googleBookData = await GoogleBooksService.fetchBookData(
          title: bookData['title']!,
          author: bookData['author']!,
        );

        String? imageUrl;
        String? publisher;
        int? yearPublished;

        if (googleBookData != null) {
          final imageLinks = googleBookData['imageLinks'];
          if (imageLinks != null) {
            imageUrl = imageLinks['medium'] ??
                imageLinks['small'] ??
                imageLinks['thumbnail'] ??
                imageLinks['smallThumbnail'];
          }
          publisher = googleBookData['publisher'];
          final publishedDate = googleBookData['publishedDate'];
          if (publishedDate != null) {
            yearPublished =
                int.tryParse(publishedDate.toString().substring(0, 4));
          }

          debugPrint('✅ Image URL: $imageUrl');
        }

        final book = Book(
          id: const Uuid().v4(),
          title: bookData['title']!,
          author: bookData['author']!,
          genre: bookData['genre']!,
          description: bookData['description'],
          imageUrl: imageUrl,
          publisher: publisher,
          yearPublished: yearPublished,
          totalCopies: 3,
          availableCopies: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseHelper.insertBook(book);
      }

      // Refresh books provider
      if (mounted) {
        await context.read<BooksProvider>().loadBooks();
      }

      // Reload local list
      await _loadBooks();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample books loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Error loading sample books: $e');
      }
    }
  }

  void _showDeleteConfirmDialog(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteBook(book),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(Book book) async {
    try {
      await _databaseHelper.deleteBook(book.id);
      if (!mounted) return;
      Navigator.pop(context);

      await _loadBooks();
      if (!mounted) return;

      await context.read<BooksProvider>().loadBooks();
      if (!mounted) return;
      _showSuccessSnackBar('Book deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error deleting book: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
