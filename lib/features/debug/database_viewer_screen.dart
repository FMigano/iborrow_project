import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import for kIsWeb
import '../../core/database/database_helper.dart';
import '../../core/models/book.dart';
import '../../core/models/user.dart' as app_models;
import '../../core/models/borrow_record.dart';
import '../../core/models/penalty.dart';
import 'package:intl/intl.dart';
// Import for SampleDataService

class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Book> _books = [];
  List<app_models.User> _users = [];
  List<BorrowRecord> _borrowRecords = [];
  List<Penalty> _penalties = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final books = await _databaseHelper.getAllBooks();
      final users = await _databaseHelper.getAllUsers();
      final borrowRecords = await _databaseHelper.getAllBorrowRecords();
      final penalties = await _databaseHelper.getAllPenalties();

      setState(() {
        _books = books;
        _users = users;
        _borrowRecords = borrowRecords;
        _penalties = penalties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Database Viewer & Manager',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Bulk Delete Options',
            onSelected: _handleBulkDelete,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_books',
                child: Row(
                  children: [
                    Icon(Icons.library_books, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clear All Books'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_users',
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clear All Users'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_borrowings',
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clear All Borrowings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Books (${_books.length})'),
            Tab(text: 'Users (${_users.length})'),
            Tab(text: 'Borrowings (${_borrowRecords.length})'),
            Tab(text: 'Penalties (${_penalties.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBooksTab(),
                _buildUsersTab(),
                _buildBorrowRecordsTab(),
                _buildPenaltiesTab(),
              ],
            ),
    );
  }

  Widget _buildBooksTab() {
    if (_books.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No books in database', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            // Change from Row to Column to prevent overflow
            children: [
              // First row with wrapped buttons
              Row(
                children: [
                  Expanded(
                    // Wrap buttons in Expanded to prevent overflow
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteByGenreDialog,
                      icon: const Icon(Icons.category, size: 18),
                      label: const Text(
                        'Delete by Genre',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    // Wrap buttons in Expanded to prevent overflow
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteByAuthorDialog,
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text(
                        'Delete by Author',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Additional info row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total: ${_books.length} books | Available: ${_books.where((b) => b.isAvailable).length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Books list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _books.length,
            itemBuilder: (context, index) {
              final book = _books[index];
              return Dismissible(
                key: Key(book.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      Text('Delete', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                confirmDismiss: (direction) => _confirmDeleteBook(book),
                onDismissed: (direction) => _deleteBook(book),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('by ${book.author} • ${book.genre}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: book.isAvailable ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${book.availableCopies}/${book.totalCopies}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _confirmDeleteSingleBook(book),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete Book',
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDataRow('ID', book.id),
                            _buildDataRow('ISBN', book.isbn),
                            _buildDataRow('Description', book.description),
                            _buildDataRow(
                                'Total Copies', '${book.totalCopies}'),
                            _buildDataRow(
                                'Available Copies', '${book.availableCopies}'),
                            _buildDataRow(
                                'Created At', _formatDate(book.createdAt)),
                            _buildDataRow(
                                'Updated At', _formatDate(book.updatedAt)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users in database', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Dismissible(
          key: Key(user.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.white),
                Text('Delete', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          confirmDismiss: (direction) => _confirmDeleteUser(user),
          onDismissed: (direction) => _deleteUser(user),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
                  Text('${user.email} • ${user.isAdmin ? 'Admin' : 'User'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isAdmin ? Colors.purple : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isAdmin ? 'ADMIN' : 'USER',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDeleteSingleUser(user),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete User',
                  ),
                  const Icon(Icons.expand_more),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRow('ID', user.id),
                      _buildDataRow('Student ID', user.studentId),
                      _buildDataRow('Phone', user.phoneNumber),
                      _buildDataRow('Role',
                          user.isAdmin ? 'Administrator' : 'Regular User'),
                      _buildDataRow('Created At', _formatDate(user.createdAt)),
                      _buildDataRow('Updated At', _formatDate(user.updatedAt)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBorrowRecordsTab() {
    if (_borrowRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No borrow records in database',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _borrowRecords.length,
      itemBuilder: (context, index) {
        final record = _borrowRecords[index];
        return Dismissible(
          key: Key(record.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.white),
                Text('Delete', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          confirmDismiss: (direction) => _confirmDeleteBorrowRecord(record),
          onDismissed: (direction) => _deleteBorrowRecord(record),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                'Record ${record.id.substring(0, 8)}...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  '${record.status.toUpperCase()} • User: ${record.userId.substring(0, 8)}...'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(record.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDeleteSingleBorrowRecord(record),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Record',
                  ),
                  const Icon(Icons.expand_more),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRow('ID', record.id),
                      _buildDataRow('User ID', record.userId),
                      _buildDataRow('Book ID', record.bookId),
                      _buildDataRow('Status', record.status),
                      _buildDataRow(
                          'Request Date', _formatDate(record.requestDate)),
                      _buildDataRow(
                          'Approved Date',
                          record.approvedDate != null
                              ? _formatDate(record.approvedDate!)
                              : 'N/A'),
                      _buildDataRow(
                          'Borrow Date',
                          record.borrowDate != null
                              ? _formatDate(record.borrowDate!)
                              : 'N/A'),
                      _buildDataRow(
                          'Due Date',
                          record.dueDate != null
                              ? _formatDate(record.dueDate!)
                              : 'N/A'),
                      _buildDataRow(
                          'Return Date',
                          record.returnDate != null
                              ? _formatDate(record.returnDate!)
                              : 'N/A'),
                      _buildDataRow('Approved By', record.approvedBy ?? 'N/A'),
                      _buildDataRow('Notes', record.notes ?? 'N/A'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPenaltiesTab() {
    if (_penalties.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No penalties in database', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _penalties.length,
      itemBuilder: (context, index) {
        final penalty = _penalties[index];
        return Dismissible(
          key: Key(penalty.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.white),
                Text('Delete', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          confirmDismiss: (direction) => _confirmDeletePenalty(penalty),
          onDismissed: (direction) => _deletePenalty(penalty),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                'Penalty \$${penalty.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
                  Text('${penalty.status.toUpperCase()} • ${penalty.reason}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          penalty.status == 'paid' ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      penalty.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDeleteSinglePenalty(penalty),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Penalty',
                  ),
                  const Icon(Icons.expand_more),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRow('ID', penalty.id),
                      _buildDataRow('User ID', penalty.userId),
                      _buildDataRow('Borrow Record ID', penalty.borrowRecordId),
                      _buildDataRow(
                          'Amount', '\$${penalty.amount.toStringAsFixed(2)}'),
                      _buildDataRow('Reason', penalty.reason),
                      _buildDataRow('Status', penalty.status),
                      _buildDataRow(
                          'Paid Date',
                          penalty.paidDate != null
                              ? _formatDate(penalty.paidDate!)
                              : 'N/A'),
                      _buildDataRow(
                          'Created At', _formatDate(penalty.createdAt)),
                      _buildDataRow(
                          'Updated At', _formatDate(penalty.updatedAt)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value ?? 'N/A',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'borrowed':
        return Colors.green;
      case 'returned':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  // Delete confirmation dialogs
  Future<bool> _confirmDeleteBook(Book book) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Book'),
            content: Text('Are you sure you want to delete "${book.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmDeleteUser(app_models.User user) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
                'Are you sure you want to delete "${user.fullName}"?\n\nThis will also delete all their borrow records and penalties.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmDeleteBorrowRecord(BorrowRecord record) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Borrow Record'),
            content: Text(
                'Are you sure you want to delete this borrow record?\n\nID: ${record.id.substring(0, 8)}...'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmDeletePenalty(Penalty penalty) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Penalty'),
            content: Text(
                'Are you sure you want to delete this penalty?\n\nAmount: \$${penalty.amount.toStringAsFixed(2)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Individual delete confirmations
  void _confirmDeleteSingleBook(Book book) async {
    final confirmed = await _confirmDeleteBook(book);
    if (confirmed) {
      _deleteBook(book);
    }
  }

  void _confirmDeleteSingleUser(app_models.User user) async {
    final confirmed = await _confirmDeleteUser(user);
    if (confirmed) {
      _deleteUser(user);
    }
  }

  void _confirmDeleteSingleBorrowRecord(BorrowRecord record) async {
    final confirmed = await _confirmDeleteBorrowRecord(record);
    if (confirmed) {
      _deleteBorrowRecord(record);
    }
  }

  void _confirmDeleteSinglePenalty(Penalty penalty) async {
    final confirmed = await _confirmDeletePenalty(penalty);
    if (confirmed) {
      _deletePenalty(penalty);
    }
  }

  // Delete operations
  Future<void> _deleteBook(Book book) async {
    try {
      await _databaseHelper.deleteBook(book.id);
      setState(() {
        _books.removeWhere((b) => b.id == book.id);
      });
      _showSuccessSnackBar('Book "${book.title}" deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete book: $e');
    }
  }

  Future<void> _deleteUser(app_models.User user) async {
    try {
      await _databaseHelper.deleteUser(user.id);
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
        _borrowRecords.removeWhere((r) => r.userId == user.id);
        _penalties.removeWhere((p) => p.userId == user.id);
      });
      _showSuccessSnackBar('User "${user.fullName}" deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete user: $e');
    }
  }

  Future<void> _deleteBorrowRecord(BorrowRecord record) async {
    try {
      await _databaseHelper.deleteBorrowRecord(record.id);
      setState(() {
        _borrowRecords.removeWhere((r) => r.id == record.id);
        _penalties.removeWhere((p) => p.borrowRecordId == record.id);
      });
      _showSuccessSnackBar('Borrow record deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete borrow record: $e');
    }
  }

  Future<void> _deletePenalty(Penalty penalty) async {
    try {
      await _databaseHelper.deletePenalty(penalty.id);
      setState(() {
        _penalties.removeWhere((p) => p.id == penalty.id);
      });
      _showSuccessSnackBar('Penalty deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete penalty: $e');
    }
  }

  // Bulk delete operations
  void _handleBulkDelete(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'clear_books':
        _showClearBooksDialog();
        break;
      case 'clear_users':
        _showClearUsersDialog();
        break;
      case 'clear_borrowings':
        _showClearBorrowingsDialog();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'Are you sure you want to delete ALL data from the database? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Clearing all data...'),
                    ],
                  ),
                ),
              );

              try {
                await _databaseHelper.clearAllData();
                if (!mounted || !context.mounted) return;
                Navigator.pop(context); // Close loading dialog
                await _loadAllData(); // Reload data
                _showSuccessSnackBar('All data cleared successfully');
              } catch (e) {
                if (!mounted || !context.mounted) return;
                Navigator.pop(context); // Close loading dialog
                _showErrorSnackBar('Error clearing data: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showClearBooksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Books'),
        content: const Text(
            'Are you sure you want to delete ALL books from the database?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _databaseHelper.clearBooksTable();
              _loadAllData();
              _showSuccessSnackBar('All books cleared successfully');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showClearUsersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Users'),
        content: const Text(
            'Are you sure you want to delete ALL users? This will also delete all borrowing records and penalties.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _databaseHelper.clearUsersTable();
              _loadAllData();
              _showSuccessSnackBar('All users cleared successfully');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showClearBorrowingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Borrowings'),
        content: const Text(
            'This will:\n• Delete all borrow records\n• Delete all penalties\n• Reset all books to full availability\n\nUsers and books will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Clearing borrowing data...'),
                    ],
                  ),
                ),
              );

              try {
                // Reset book availability first
                await _databaseHelper.resetAllBookAvailability();
                // Then clear borrowing data
                await _databaseHelper.clearBorrowRecordsTable();

                if (!mounted || !context.mounted) return;
                Navigator.pop(context); // Close loading dialog
                await _loadAllData(); // Reload data
                _showSuccessSnackBar(
                    'All borrowing data cleared and books reset to full availability');
              } catch (e) {
                if (!mounted || !context.mounted) return;
                Navigator.pop(context); // Close loading dialog
                _showErrorSnackBar('Error clearing borrowing data: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Clear Borrowings'),
          ),
        ],
      ),
    );
  }

  void _showDeleteByGenreDialog() {
    final controller = TextEditingController();
    final availableGenres = _books.map((b) => b.genre).toSet().toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Books by Genre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Genre',
                border: OutlineInputBorder(),
              ),
              value: availableGenres.isNotEmpty ? availableGenres.first : null,
              onChanged: (value) => controller.text = value ?? '',
              items: availableGenres.map((genre) {
                final count = _books.where((b) => b.genre == genre).length;
                return DropdownMenuItem(
                  value: genre,
                  child: Text('$genre ($count books)'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final selectedGenre =
                  availableGenres.isNotEmpty ? availableGenres.first : null;
              if (selectedGenre != null) {
                Navigator.pop(context);

                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Deleting books...'),
                        ],
                      ),
                    ),
                  );

                  await _databaseHelper.deleteBooksByGenre(selectedGenre);

                  if (!mounted || !context.mounted) return;
                  Navigator.pop(context); // Close loading dialog
                  _loadAllData();
                  _showSuccessSnackBar(
                      'Books in "$selectedGenre" genre deleted');
                } catch (e) {
                  if (!mounted || !context.mounted) return;
                  Navigator.pop(context); // Close loading dialog
                  _showErrorSnackBar('Error deleting books by genre: $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteByAuthorDialog() {
    final availableAuthors = _books.map((b) => b.author).toSet().toList();
    String? selectedAuthor =
        availableAuthors.isNotEmpty ? availableAuthors.first : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete Books by Author'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Author',
                  border: OutlineInputBorder(),
                ),
                value: selectedAuthor,
                onChanged: (value) => setState(() => selectedAuthor = value),
                items: availableAuthors.map((author) {
                  final count = _books.where((b) => b.author == author).length;
                  return DropdownMenuItem(
                    value: author,
                    child: Text('$author ($count books)'),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedAuthor != null) {
                  Navigator.pop(context);

                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Deleting books...'),
                          ],
                        ),
                      ),
                    );

                    await _databaseHelper.deleteBooksByAuthor(selectedAuthor!);

                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context); // Close loading dialog
                    _loadAllData();
                    _showSuccessSnackBar('Books by "$selectedAuthor" deleted');
                  } catch (e) {
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context); // Close loading dialog
                    _showErrorSnackBar('Error deleting books by author: $e');
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
