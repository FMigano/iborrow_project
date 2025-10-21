import 'package:flutter/material.dart';
import 'core/database/database_helper.dart';
import 'core/models/book.dart';
import 'core/models/user.dart' as app_models; // Add alias
import 'core/models/borrow_record.dart';

class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _db = DatabaseHelper();

  List<app_models.User> users = []; // Use alias here
  List<Book> books = [];
  List<BorrowRecord> borrowings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);

    try {
      final loadedUsers = await _db.getAllUsers();
      final loadedBooks = await _db.getAllBooks();
      final loadedBorrowings =
          await _db.getAllBorrowRecords(); // Changed method name

      setState(() {
        users = loadedUsers;
        books = loadedBooks;
        borrowings = loadedBorrowings;
        isLoading = false;
      });

      debugPrint('=== DATABASE CONTENT ===');
      debugPrint('Users: ${users.length}');
      debugPrint('Books: ${books.length}');
      debugPrint('Borrowings: ${borrowings.length}');
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DATABASE VIEWER'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'USERS (${users.length})'),
            Tab(text: 'BOOKS (${books.length})'),
            Tab(text: 'BORROWINGS (${borrowings.length})'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildBooksTab(),
                _buildBorrowingsTab(),
              ],
            ),
    );
  }

  Widget _buildUsersTab() {
    if (users.isEmpty) {
      return const Center(
        child: Text('NO USERS FOUND',
            style: TextStyle(fontSize: 20, color: Colors.red)),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user.email}'),
                Text('Admin: ${user.isAdmin ? "YES" : "NO"}'),
                Text('ID: ${user.id}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooksTab() {
    if (books.isEmpty) {
      return const Center(
        child: Text('NO BOOKS FOUND',
            style: TextStyle(fontSize: 20, color: Colors.red)),
      );
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(book.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Author: ${book.author}'),
                Text('Genre: ${book.genre}'),
                Text('Available: ${book.availableCopies}/${book.totalCopies}'),
                Text('ID: ${book.id}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBorrowingsTab() {
    if (borrowings.isEmpty) {
      return const Center(
        child: Text('NO BORROWINGS FOUND',
            style: TextStyle(fontSize: 20, color: Colors.red)),
      );
    }

    return ListView.builder(
      itemCount: borrowings.length,
      itemBuilder: (context, index) {
        final borrowing = borrowings[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(
              'STATUS: ${borrowing.status.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: borrowing.status == 'pending'
                    ? Colors.orange
                    : borrowing.status == 'borrowed'
                        ? Colors.green
                        : Colors.blue,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: ${borrowing.userId}'),
                Text('Book ID: ${borrowing.bookId}'),
                Text('Request Date: ${borrowing.requestDate}'),
                if (borrowing.dueDate != null)
                  Text('Due Date: ${borrowing.dueDate}'),
                if (borrowing.notes != null) Text('Notes: ${borrowing.notes}'),
                Text('Record ID: ${borrowing.id}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
