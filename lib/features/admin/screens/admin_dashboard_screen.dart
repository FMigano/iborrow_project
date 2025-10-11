import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../borrowing/providers/borrowing_provider.dart';
import '../../books/providers/books_provider.dart';
import '../../../core/models/borrow_record.dart';
import '../../../core/models/book.dart';
import '../../../core/models/user.dart' as app_models;
import '../../debug/database_viewer_screen.dart'; // Import the DatabaseViewerScreen
import '../../../core/database/database_helper.dart';

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
          isScrollable: false,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          labelStyle: const TextStyle(
            fontSize: 11, // Smaller to fit 5 tabs evenly
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.normal,
          ),
          labelPadding: EdgeInsets.zero, // Removes extra padding
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 4), // Better indicator spacing
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard, size: 16),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.pending_actions, size: 16),
              text: 'Requests',
            ),
            Tab(
              icon: Icon(Icons.assignment_return, size: 16),
              text: 'Returns',
            ),
            Tab(
              icon: Icon(Icons.library_books, size: 16),
              text: 'Books',
            ),
            Tab(
              icon: Icon(Icons.people, size: 16),
              text: 'Users',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _RequestsTab(),
          const _ReturnsTab(), // NEW TAB
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
            // Statistics Cards
            Consumer2<BorrowingProvider, BooksProvider>(
              builder: (context, borrowing, books, child) {
                final totalBooks = books.books.length;
                final availableBooks = books.books.where((b) => b.availableCopies > 0).length;
                final pendingRequests = borrowing.pendingRequests.length;
                final activeBorrowings = borrowing.allActiveBorrowings.length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Books',
                            totalBooks.toString(),
                            Icons.book,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Available',
                            availableBooks.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Pending',
                            pendingRequests.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Active',
                            activeBorrowings.toString(),
                            Icons.bookmark,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ✅ ADD THIS SECTION: Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Reset & Reload Button
            Card(
              child: ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: Text(
                  'Reset & Reload Sample Data',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Clear all data and reload sample books',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showResetDialog(context),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Database Viewer Button
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage, color: Colors.purple),
                title: Text(
                  'View Database',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Inspect all tables and records',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DatabaseViewerScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ADD THIS METHOD
  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Reset Data',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('• Delete all borrow records', style: GoogleFonts.inter()),
            Text('• Delete all penalties', style: GoogleFonts.inter()),
            Text('• Reset book availability', style: GoogleFonts.inter()),
            Text('• Reload sample books from Supabase', style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            Text(
              'Continue?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading
      try {
        // Show loading
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Clear all data
        final sampleDataService = SampleDataService();
        await sampleDataService.clearAllData();
        
        // Insert fresh sample data
        await sampleDataService.insertSampleData();

        // Reload data in providers
        if (context.mounted) {
          final booksProvider = Provider.of<BooksProvider>(context, listen: false);
          final borrowingProvider = Provider.of<BorrowingProvider>(context, listen: false);
          
          await Future.wait([
            booksProvider.loadBooks(),
            borrowingProvider.loadPendingRequests(),
          ]);
        }

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Data reset and reloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error resetting data: $e');
        
        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadData(BuildContext context) async {
    final borrowingProvider = Provider.of<BorrowingProvider>(context, listen: false);
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    
    await Future.wait([
      borrowingProvider.loadPendingRequests(),
      booksProvider.loadBooks(),
    ]);
  }

  Widget _buildStatCard(BuildContext context, String title, String value, 
      IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.grey[600],
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
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Book ID: ${request.bookId.substring(0, 8)}...',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'Pending',
                    style: GoogleFonts.inter(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'User ID: ${request.userId.substring(0, 8)}...',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            Text(
              'Requested: ${DateFormat('MMM dd, yyyy').format(request.requestDate)}',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${request.notes}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(context, request.id, borrowing),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    // ✅ FIX: Remove ALL auth checks - just call approve directly
                    onPressed: () => _approveRequest(context, request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ COMPLETELY REWRITE: Remove auth check
  Future<void> _approveRequest(BuildContext context, BorrowRecord request) async {
    final borrowingProvider = Provider.of<BorrowingProvider>(context, listen: false);

    final success = await borrowingProvider.approveBorrowRequest(
      request.id,
      'system-admin',
    );

    if (success && context.mounted) {
      // ✅ Show quick success animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Request approved!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requestId, BorrowingProvider borrowing) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(
            'Reject Request',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty && context.mounted) {
      final success = await borrowing.rejectBorrowRequest(
        requestId,
        'system-admin',
        reason: reason,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

class _ReturnsTab extends StatelessWidget {
  const _ReturnsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<BorrowingProvider>(
      builder: (context, borrowingProvider, child) {
        if (borrowingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ FIX: Only show return_requested, not already returned books
        final returnRequests = borrowingProvider.allActiveBorrowings
            .where((r) => r.status == 'return_requested')
            .toList();

        if (returnRequests.isEmpty) {
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
                  'No return requests',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: returnRequests.length,
          itemBuilder: (context, index) {
            final request = returnRequests[index];
            return _ReturnRequestCard(request: request);
          },
        );
      },
    );
  }
}

class _ReturnRequestCard extends StatelessWidget {
  final BorrowRecord request;

  const _ReturnRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final borrowingProvider = Provider.of<BorrowingProvider>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadRequestData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text('Loading...', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final book = data['book'] as Book?;
        final user = data['user'] as app_models.User?;
        final isOverdue = request.dueDate != null && 
                         DateTime.now().isAfter(request.dueDate!);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ FIX: Wrap long text with Flexible
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book ID: ${request.bookId.substring(0, 8)}...',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (book != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              book.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        'Return Requested',
                        style: GoogleFonts.inter(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (user != null) ...[
                  Text(
                    'User: ${user.fullName}',
                    style: GoogleFonts.inter(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (request.returnRequestDate != null)
                  Text(
                    'Requested: ${DateFormat('MMM dd, yyyy').format(request.returnRequestDate!)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.blue[700],
                    ),
                  ),
                if (isOverdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'OVERDUE',
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // ✅ FIX: Use Column for buttons on small screens
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await _showRejectDialog(context);
                          if (result != null && result.isNotEmpty && context.mounted) {
                            final supabase = Supabase.instance.client;
                            final currentUser = supabase.auth.currentUser;
                            final adminId = currentUser?.id ?? request.userId;

                            final success = await borrowingProvider.rejectBookReturn(
                              request.id,
                              adminId,
                              result,
                            );

                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Return request rejected'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final supabase = Supabase.instance.client;
                          final currentUser = supabase.auth.currentUser;
                          final adminId = currentUser?.id ?? request.userId;

                          final success = await borrowingProvider.approveBookReturn(
                            request.id,
                            adminId,
                          );

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Return approved'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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

  Future<Map<String, dynamic>> _loadRequestData() async {
    final book = await DatabaseHelper().getBookById(request.bookId);
    final user = await DatabaseHelper().getUserById(request.userId);
    
    return {
      'book': book,
      'user': user,
    };
  }

  Future<String?> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Return', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
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
          onRefresh: () => borrowing.loadPendingRequests(),
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

class SampleDataService {
  Future<void> insertSampleData() async {
    // Add implementation for inserting sample data
    // This is a placeholder - implement based on your actual SampleDataService
    final sampleDataService = SampleDataService();
    // Add your sample data insertion logic here
  }
  
  Future<void> resetSystemForTesting() async {
    // Clear all borrow records and penalties
    final db = await DatabaseHelper().database;
    await db?.delete('borrow_records');
    await db?.delete('penalties');
    
    // Reset all books to full availability
    final books = await db?.query('books') ?? [];
    for (final book in books) {
      await db?.update(
        'books',
        {
          'available_copies': book['total_copies'],
        },
        where: 'id = ?',
        whereArgs: [book['id']],
      );
    }
  }

  Future<void> clearAllData() async {
    final db = await DatabaseHelper().database;
    
    // Clear all borrow records
    await db?.execute('DELETE FROM borrow_records');
    await db?.execute('DELETE FROM penalties');

    // Reset book availability
    await DatabaseHelper().resetAllBookAvailability();
    await DatabaseHelper().resetAllBookAvailability();
  }
}