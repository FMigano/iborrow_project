import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/book.dart';
import '../../../core/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();
  List<Book> _books = [];
  bool _isLoading = false;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Books',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showAddBookDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add New Book',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? _buildEmptyState()
              : _buildBooksList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Books Added',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add books to your library catalog',
            style: GoogleFonts.inter(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddBookDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withValues(alpha: 0.1),
              child: Text(
                book.title.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            title: Text(
              book.title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('by ${book.author}'),
                Text(
                  '${book.availableCopies}/${book.totalCopies} available',
                  style: TextStyle(
                    color: book.availableCopies > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditBookDialog(book);
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog(book);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddBookDialog() {
    _showBookDialog();
  }

  void _showEditBookDialog(Book book) {
    _showBookDialog(book: book);
  }

  void _showBookDialog({Book? book}) {
    final isEditing = book != null;
    final titleController = TextEditingController(text: book?.title ?? '');
    final authorController = TextEditingController(text: book?.author ?? '');
    final genreController = TextEditingController(text: book?.genre ?? '');
    final isbnController = TextEditingController(text: book?.isbn ?? '');
    final descriptionController = TextEditingController(text: book?.description ?? '');
    final totalCopiesController = TextEditingController(
      text: book?.totalCopies.toString() ?? '1',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing ? 'Edit Book' : 'Add New Book',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(
                  labelText: 'Author *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: isbnController,
                decoration: const InputDecoration(
                  labelText: 'ISBN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: totalCopiesController,
                decoration: const InputDecoration(
                  labelText: 'Total Copies *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveBook(
              context,
              isEditing: isEditing,
              bookId: book?.id,
              title: titleController.text,
              author: authorController.text,
              genre: genreController.text,
              isbn: isbnController.text,
              description: descriptionController.text,
              totalCopies: int.tryParse(totalCopiesController.text) ?? 1,
              currentAvailableCopies: book?.availableCopies,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBook(
    BuildContext context, {
    required bool isEditing,
    String? bookId,
    required String title,
    required String author,
    required String genre,
    String? isbn,
    String? description,
    required int totalCopies,
    int? currentAvailableCopies,
  }) async {
    if (title.trim().isEmpty || author.trim().isEmpty || genre.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    try {
      final now = DateTime.now();
      
      if (isEditing && bookId != null) {
        // Update existing book
        final updatedBook = Book(
          id: bookId,
          title: title.trim(),
          author: author.trim(),
          genre: genre.trim(),
          isbn: isbn?.trim(),
          description: description?.trim(),
          totalCopies: totalCopies,
          availableCopies: currentAvailableCopies ?? totalCopies,
          createdAt: _books.firstWhere((b) => b.id == bookId).createdAt,
          updatedAt: now,
        );
        
        await _databaseHelper.updateBook(updatedBook);
        _showSuccessSnackBar('Book updated successfully');
      } else {
        // Add new book
        final newBook = Book(
          id: _uuid.v4(),
          title: title.trim(),
          author: author.trim(),
          genre: genre.trim(),
          isbn: isbn?.trim(),
          description: description?.trim(),
          totalCopies: totalCopies,
          availableCopies: totalCopies,
          createdAt: now,
          updatedAt: now,
        );
        
        await _databaseHelper.insertBook(newBook);
        _showSuccessSnackBar('Book added successfully');
      }
      
      Navigator.pop(context);
      _loadBooks(); // Refresh the list
      
    } catch (e) {
      _showErrorSnackBar('Error saving book: $e');
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
      Navigator.pop(context);
      _loadBooks();
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

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Books'),
              Tab(text: 'Users'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBooksTab(context),
            const Center(child: Text('User Management')),
            const Center(child: Text('Settings')),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookManagementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.library_books),
            label: const Text('Manage Books'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          // Add other book-related admin functions here
        ],
      ),
    );
  }
}