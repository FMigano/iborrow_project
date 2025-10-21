import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/borrow_record.dart';
import '../../../core/models/penalty.dart';
import '../providers/borrowing_provider.dart';
import '../../auth/providers/auth_provider.dart';

class MyBorrowingsScreen extends StatefulWidget {
  const MyBorrowingsScreen({super.key});

  @override
  State<MyBorrowingsScreen> createState() => _MyBorrowingsScreenState();
}

class _MyBorrowingsScreenState extends State<MyBorrowingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ✅ Reload data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final borrowingProvider =
        Provider.of<BorrowingProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      debugPrint(
          '🔄 Refreshing borrowings for user: ${authProvider.currentUser!.id}');
      await borrowingProvider.loadUserBorrowings(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final borrowingProvider = Provider.of<BorrowingProvider>(context);

    if (authProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Borrowings')),
        body: const Center(
          child: Text('Please log in to view your borrowings'),
        ),
      );
    }

    // ✅ Use provider data (already loaded)
    final userBorrowings = borrowingProvider.userBorrowings
        .where((b) => b.userId == authProvider.currentUser!.id)
        .toList();

    final currentBorrowings =
        userBorrowings.where((b) => b.status == 'borrowed').toList();

    final historyBorrowings = userBorrowings
        .where((b) => b.status == 'returned' || b.status == 'rejected')
        .toList();

    final userPenalties = borrowingProvider.penalties
        .where((p) => p.userId == authProvider.currentUser!.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Borrowings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.bookmark),
              text: 'Current (${currentBorrowings.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'History (${historyBorrowings.length})',
            ),
            Tab(
              icon: const Icon(Icons.warning),
              text: 'Penalties (${userPenalties.length})',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCurrentTab(currentBorrowings),
            _buildHistoryTab(historyBorrowings),
            _buildPenaltiesTab(userPenalties),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab(List<BorrowRecord> currentBorrowings) {
    if (currentBorrowings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.library_books_outlined,
        title: 'No current borrowings',
        subtitle: 'Browse books to start borrowing',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentBorrowings.length,
      itemBuilder: (context, index) {
        final record = currentBorrowings[index];
        return _buildBorrowingCard(context, record);
      },
    );
  }

  Widget _buildHistoryTab(List<BorrowRecord> historyBorrowings) {
    if (historyBorrowings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No borrowing history',
        subtitle: 'Your past borrowings will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyBorrowings.length,
      itemBuilder: (context, index) {
        final record = historyBorrowings[index];
        return _buildHistoryCard(context, record);
      },
    );
  }

  Widget _buildPenaltiesTab(List<Penalty> userPenalties) {
    if (userPenalties.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payment_outlined,
        title: 'No penalties',
        subtitle: 'Keep returning books on time!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userPenalties.length,
      itemBuilder: (context, index) {
        final penalty = userPenalties[index];
        return _buildPenaltyCard(context, penalty);
      },
    );
  }

  Widget _buildBorrowingCard(BuildContext context, BorrowRecord record) {
    final isOverdue = record.dueDate != null &&
        DateTime.now().isAfter(record.dueDate!) &&
        record.status == 'borrowed';

    Color statusColor;
    String statusText;

    switch (record.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending Approval';
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusText = 'Ready for Pickup';
        break;
      case 'borrowed':
        statusColor = isOverdue ? Colors.red : Colors.green;
        statusText = isOverdue ? 'Overdue' : 'Borrowed';
        break;
      case 'return_requested':
        statusColor = Colors.blue;
        statusText = 'Return Requested';
        break;
      case 'returned':
        statusColor = Colors.grey;
        statusText = 'Returned';
        break;
      default:
        statusColor = Colors.grey;
        statusText = record.status;
    }

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
                        'Book ID: ${record.bookId}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Request Date: ${DateFormat('MMM dd, yyyy').format(record.requestDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (record.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Due Date: ${DateFormat('MMM dd, yyyy').format(record.dueDate!)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: isOverdue ? Colors.red : null,
                                fontWeight: isOverdue ? FontWeight.bold : null,
                              ),
                        ),
                      ],
                      if (record.returnRequestDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Return Requested: ${DateFormat('MMM dd, yyyy').format(record.returnRequestDate!)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            if (record.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${record.notes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],

            // Add Return Request Button
            if (record.status == 'borrowed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _requestReturn(context, record.id),
                  icon: const Icon(Icons.assignment_return),
                  label: const Text('Request Return'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Add this method to handle return requests:
  Future<void> _requestReturn(BuildContext context, String recordId) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Request Book Return'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide any notes about the book condition:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Return notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );

    if (notes != null && context.mounted) {
      final success =
          await Provider.of<BorrowingProvider>(context, listen: false)
              .requestBookReturn(recordId,
                  returnNotes: notes.isNotEmpty ? notes : null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Return request submitted successfully!'
                : 'Failed to submit return request'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHistoryCard(BuildContext context, BorrowRecord record) {
    final isReturned = record.status == 'returned';

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
                        'Book ID: ${record.bookId}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested: ${DateFormat('MMM dd, yyyy').format(record.requestDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (record.returnDate != null) ...[
                        Text(
                          'Returned: ${DateFormat('MMM dd, yyyy').format(record.returnDate!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isReturned
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isReturned ? Colors.green : Colors.red),
                  ),
                  child: Text(
                    isReturned ? 'Returned' : 'Rejected',
                    style: TextStyle(
                      color: isReturned ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (record.isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Returned late',
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

  Widget _buildPenaltyCard(BuildContext context, Penalty penalty) {
    final isPaid = penalty.status == 'paid';

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
                        '\$${penalty.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.green : Colors.red,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        penalty.reason,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy').format(penalty.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (penalty.paidDate != null) ...[
                        Text(
                          'Paid: ${DateFormat('MMM dd, yyyy').format(penalty.paidDate!)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Status: ${penalty.status.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: isPaid ? Colors.green : Colors.red),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (!isPaid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final success = await Provider.of<BorrowingProvider>(
                            context,
                            listen: false)
                        .payPenalty(penalty.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Penalty paid successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Builder(
    builder: (context) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    ),
  );
}
