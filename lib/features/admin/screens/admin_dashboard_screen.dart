import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../borrowing/providers/borrowing_provider.dart';
import '../../books/providers/books_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/sample_data_service.dart';
import '../../../core/models/borrow_record.dart';
import '../../../core/models/book.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Increase to 5 tabs
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final borrowingProvider = Provider.of<BorrowingProvider>(context, listen: false);
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    
    await Future.wait([
      borrowingProvider.loadPendingRequests(),
      borrowingProvider.loadReturnRequests(), // This should now work
      borrowingProvider.loadAllActiveBorrowings(),
      booksProvider.loadBooks(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Requests', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Returns', icon: Icon(Icons.assignment_return)), // NEW TAB
            Tab(text: 'Books', icon: Icon(Icons.library_books)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _RequestsTab(),
          _ReturnsTab(), // NEW TAB
          _BooksTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadData(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer2<BooksProvider, BorrowingProvider>(
              builder: (context, books, borrowing, child) {
                final totalBooks = books.books.length;
                
                // Use allActiveBorrowings instead of userBorrowings
                final activeLoans = borrowing.allActiveBorrowings
                    .where((b) => b.status == 'borrowed').length;
                
                final pendingRequests = borrowing.pendingRequests.length;
                
                // Calculate overdue books from all active borrowings
                final overdueBooks = borrowing.allActiveBorrowings
                    .where((b) => b.status == 'borrowed' && 
                          b.dueDate != null && 
                          DateTime.now().isAfter(b.dueDate!))
                    .length;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Books',
                      totalBooks.toString(),
                      Icons.book,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Active Loans',
                      activeLoans.toString(),
                      Icons.library_books,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Pending Requests',
                      pendingRequests.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Overdue Books',
                      overdueBooks.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _insertSampleData(context),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Add Sample Data'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _clearAllData(context),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/debug'),
                icon: const Icon(Icons.storage, color: Colors.white),
                label: const Text('VIEW DATABASE DATA', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData(BuildContext context) async {
    final borrowingProvider = Provider.of<BorrowingProvider>(context, listen: false);
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    
    await Future.wait([
      borrowingProvider.loadPendingRequests(), // This now also loads active borrowings
      booksProvider.loadBooks(),
    ]);
  }

  Widget _buildStatCard(BuildContext context, String title, String value, 
      IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _insertSampleData(BuildContext context) async {
    try {
      final sampleDataService = SampleDataService();
      await sampleDataService.insertSampleData();
      
      // Refresh data
      await _loadData(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data inserted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final sampleDataService = SampleDataService();
        await sampleDataService.clearAllData();
        
        await _loadData(context);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BorrowingProvider>(
      builder: (context, borrowing, child) {
        if (borrowing.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (borrowing.pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pending_actions,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pending Requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All requests have been processed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => borrowing.loadPendingRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: borrowing.pendingRequests.length,
            itemBuilder: (context, index) {
              final request = borrowing.pendingRequests[index];
              return _buildRequestCard(context, request, borrowing);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, BorrowRecord request, BorrowingProvider borrowing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ID: ${request.bookId}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${request.userId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested: ${DateFormat('MMM dd, yyyy').format(request.requestDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            if (request.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${request.notes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(context, request.id, borrowing),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(context, request.id, borrowing),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, String requestId, BorrowingProvider borrowing) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.currentUser?.id ?? 'admin';
    
    final success = await borrowing.approveBorrowRequest(requestId, adminId);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Request approved successfully!' : 'Failed to approve request'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requestId, BorrowingProvider borrowing) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Reason for rejection (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Request rejected by admin'),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && context.mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final adminId = auth.currentUser?.id ?? 'admin';
      
      final success = await borrowing.rejectBorrowRequest(requestId, adminId, reason: reason);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Request rejected successfully!' : 'Failed to reject request'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _ReturnsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BorrowingProvider>(
      builder: (context, borrowing, child) {
        if (borrowing.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (borrowing.returnRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_return,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Return Requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All returns have been processed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => borrowing.loadReturnRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: borrowing.returnRequests.length,
            itemBuilder: (context, index) {
              final request = borrowing.returnRequests[index];
              return _buildReturnRequestCard(context, request, borrowing);
            },
          ),
        );
      },
    );
  }

  Widget _buildReturnRequestCard(BuildContext context, BorrowRecord request, BorrowingProvider borrowing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ID: ${request.bookId}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${request.userId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Borrowed: ${DateFormat('MMM dd, yyyy').format(request.borrowDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (request.returnRequestDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Return Requested: ${DateFormat('MMM dd, yyyy').format(request.returnRequestDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Text(
                    'Return Requested',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            if (request.returnNotes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Return Notes: ${request.returnNotes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectReturn(context, request.id, borrowing),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject Return'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveReturn(context, request.id, borrowing),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve Return'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveReturn(BuildContext context, String requestId, BorrowingProvider borrowing) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.currentUser?.id ?? 'admin';
    
    final success = await borrowing.approveBookReturn(requestId, adminId);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Return approved successfully!' : 'Failed to approve return'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectReturn(BuildContext context, String requestId, BorrowingProvider borrowing) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Return'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty && context.mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final adminId = auth.currentUser?.id ?? 'admin';
      
      final success = await borrowing.rejectBookReturn(requestId, adminId, reason: reason);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Return rejected successfully!' : 'Failed to reject return'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _BooksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, books, child) {
        if (books.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => books.loadBooks(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.books.length,
            itemBuilder: (context, index) {
              final book = books.books[index];
              return _buildBookCard(context, book);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 70,
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
                        const Icon(Icons.book),
                  ),
                )
              : const Icon(Icons.book),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('by ${book.author}'),
            Text('Available: ${book.availableCopies}/${book.totalCopies}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: book.isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: book.isAvailable ? Colors.green : Colors.red),
          ),
          child: Text(
            book.isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              color: book.isAvailable ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BorrowingProvider>(
      builder: (context, borrowing, child) {
        // Use the cached allActiveBorrowings instead of future
        final activeBorrowings = borrowing.allActiveBorrowings;
        
        if (borrowing.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (activeBorrowings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Users',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No users have borrowed books',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => borrowing.loadAllActiveBorrowings(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeBorrowings.length,
            itemBuilder: (context, index) {
              final borrowingRecord = activeBorrowings[index];
              return _buildUserBorrowingCard(context, borrowingRecord);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserBorrowingCard(BuildContext context, BorrowRecord borrowing) {
    final isOverdue = borrowing.dueDate != null && 
        DateTime.now().isAfter(borrowing.dueDate!) && 
        borrowing.status == 'borrowed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ID: ${borrowing.userId}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Book ID: ${borrowing.bookId}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (borrowing.borrowDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Borrowed: ${DateFormat('MMM dd, yyyy').format(borrowing.borrowDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (borrowing.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${DateFormat('MMM dd, yyyy').format(borrowing.dueDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(borrowing.status, isOverdue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getStatusColor(borrowing.status, isOverdue)),
                  ),
                  child: Text(
                    _getStatusText(borrowing.status, isOverdue),
                    style: TextStyle(
                      color: _getStatusColor(borrowing.status, isOverdue),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            if (isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'OVERDUE - ${DateTime.now().difference(borrowing.dueDate!).inDays} days late',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isOverdue) {
    if (isOverdue) return Colors.red;
    
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'borrowed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, bool isOverdue) {
    if (isOverdue) return 'Overdue';
    
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'borrowed':
        return 'Borrowed';
      default:
        return status;
    }
  }
}