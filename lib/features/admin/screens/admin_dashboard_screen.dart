import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../borrowing/providers/borrowing_provider.dart';
import '../../books/providers/books_provider.dart';
import '../../../core/services/sample_data_service.dart';

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
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BorrowingProvider>(context, listen: false).loadPendingRequests();
      Provider.of<BooksProvider>(context, listen: false).loadBooks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Requests', icon: Icon(Icons.approval)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Development Tools Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Development Tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final sampleDataService = SampleDataService();
                            await sampleDataService.insertSampleData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sample data inserted!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh books
                              Provider.of<BooksProvider>(context, listen: false).loadBooks();
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Add Sample Data'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final sampleDataService = SampleDataService();
                            await sampleDataService.clearAllData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All data cleared!'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              // Refresh books
                              Provider.of<BooksProvider>(context, listen: false).loadBooks();
                            }
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear Data'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Library Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Statistics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatCard(
                context,
                'Total Books',
                '0', // This would come from actual data
                Icons.book,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Active Loans',
                '0',
                Icons.library_books,
                Colors.green,
              ),
              _buildStatCard(
                context,
                'Pending Requests',
                '0',
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Overdue Books',
                '0',
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActivityItem(
                    'New book request from user',
                    '2 minutes ago',
                    Icons.book,
                    Colors.blue,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    'Book returned: "Sample Book"',
                    '1 hour ago',
                    Icons.assignment_return,
                    Colors.green,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    'System initialized',
                    '2 hours ago',
                    Icons.info,
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Requests management coming soon'),
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
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(book.title),
                  subtitle: Text('by ${book.author}'),
                  trailing: Text('${book.availableCopies}/${book.totalCopies}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('User management coming soon'),
    );
  }
}