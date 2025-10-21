import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/book.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  bool _isLoading = true;
  int _totalBooks = 0;
  int _totalUsers = 0;
  int _activeBorrowings = 0;
  int _overdueBooks = 0;
  List<Book> _popularBooks = [];
  List<Map<String, dynamic>> _genreStats = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final books = await _db.getAllBooks();
      final users = await _db.getAllUsers();
      final borrowRecords = await _db.getAllBorrowRecords();

      _totalBooks = books.length;
      _totalUsers = users.length;
      _activeBorrowings = borrowRecords
          .where((r) =>
              r.status == 'borrowed' ||
              r.status == 'approved' ||
              r.status == 'return_requested')
          .length;
      _overdueBooks = borrowRecords.where((r) => r.isOverdue).length;

      // Calculate popular books (most borrowed)
      final borrowCounts = <String, int>{};
      for (var record in borrowRecords) {
        borrowCounts[record.bookId] = (borrowCounts[record.bookId] ?? 0) + 1;
      }

      final popularBookIds = borrowCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _popularBooks = popularBookIds
          .take(5)
          .map((entry) => books.firstWhere((b) => b.id == entry.key))
          .toList();

      // Genre statistics
      final genreCounts = <String, int>{};
      for (var book in books) {
        genreCounts[book.genre] = (genreCounts[book.genre] ?? 0) + 1;
      }

      _genreStats = genreCounts.entries
          .map((e) => {'genre': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Analytics Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsOverview(),
                  const SizedBox(height: 24),
                  _buildPopularBooks(),
                  const SizedBox(height: 24),
                  _buildGenreDistribution(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Books',
              _totalBooks.toString(),
              Icons.book,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Users',
              _totalUsers.toString(),
              Icons.people,
              Colors.green,
            ),
            _buildStatCard(
              'Active Loans',
              _activeBorrowings.toString(),
              Icons.library_books,
              Colors.orange,
            ),
            _buildStatCard(
              'Overdue',
              _overdueBooks.toString(),
              Icons.warning,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBooks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Borrowed Books',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_popularBooks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No borrowing data yet',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._popularBooks.map((book) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(
                    book.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(book.author),
                  trailing: Chip(
                    label: Text(book.genre),
                    backgroundColor: Colors.blue[100],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildGenreDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Books by Genre',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._genreStats.map((stat) {
          final total = _totalBooks;
          final percentage = total > 0 ? (stat['count'] as int) / total : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stat['genre'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${stat['count']} books',
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.blue[400]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
