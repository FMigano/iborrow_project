import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // Add this import
import '../../auth/providers/auth_provider.dart';
import '../../books/providers/books_provider.dart';
import '../../borrowing/providers/borrowing_provider.dart';
import '../../books/screens/book_list_screen.dart';
import '../../borrowing/screens/my_borrowings_screen.dart' as borrowing_screens;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    BooksScreen(),
    MyBorrowingsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // ✅ Load data when home screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    debugPrint('🏠 Loading initial data for home screen...');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final borrowingProvider =
        Provider.of<BorrowingProvider>(context, listen: false);
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);

    // Load books (already auto-loads, but refresh to be sure)
    await booksProvider.loadBooks();

    // Load user-specific borrowings if logged in
    if (authProvider.currentUser != null) {
      debugPrint('👤 Loading data for user: ${authProvider.currentUser!.id}');
      await borrowingProvider.loadUserBorrowings(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Books',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'My Books',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookListScreen();
  }
}

class MyBorrowingsScreen extends StatelessWidget {
  const MyBorrowingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const borrowing_screens.MyBorrowingsScreen();
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.book,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'About iBorrow',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'iBorrow Library Management System',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mission',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'To revolutionize library management with modern digital solutions, making book borrowing and library administration seamless and efficient.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Features',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...[
                '📚 Digital book catalog',
                '📱 Mobile-first design',
                '🔄 Real-time borrowing status',
                '📊 Borrowing history tracking',
                '🔔 Due date notifications',
                '👨‍💼 Admin management tools',
                '🌐 Cross-platform support',
              ].map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      feature,
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  )),
              const SizedBox(height: 16),
              Text(
                'Contact',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Email: support@iborrow.com\nWebsite: www.iborrow.com',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2025 iBorrow. All rights reserved.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Help & Support',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use iBorrow:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...[
                '1. Browse books in the Books tab',
                '2. Tap on a book to view details',
                '3. Tap "Borrow" to request the book',
                '4. Wait for approval from librarian',
                '5. Check "My Books" for borrowing status',
                '6. Return books before due date',
              ].map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      step,
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need more help?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact us at: support@iborrow.com\nOr visit the library front desk',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Consumer2<AuthProvider, BorrowingProvider>(
        builder: (context, auth, borrowing, child) {
          final user = auth.currentUser;
          final borrowings = borrowing.userBorrowings;

          // Calculate statistics
          final totalBorrowed = borrowings.length;
          final returned =
              borrowings.where((b) => b.status == 'returned').length;
          final active = borrowings.where((b) => b.status == 'borrowed').length;
          final overdue = borrowings.where((b) => b.isOverdue).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // User Profile Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName.substring(0, 1).toUpperCase()
                                : user?.email.substring(0, 1).toUpperCase() ??
                                    'U',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.fullName ?? 'User Name',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (user?.studentId != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'ID: ${user!.studentId}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Borrowing Statistics
                Text(
                  'Borrowing Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Borrowed',
                        totalBorrowed.toString(),
                        Icons.library_books,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Returned',
                        returned.toString(),
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
                        'Currently Borrowed',
                        active.toString(),
                        Icons.book,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Overdue',
                        overdue.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // User Information
                Text(
                  'Account Information',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          'Full Name',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          user?.fullName ?? 'Not provided',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(
                          'Email',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                      if (user?.studentId != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.badge),
                          title: Text(
                            'Student ID',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            user!.studentId!,
                            style: GoogleFonts.inter(),
                          ),
                        ),
                      ],
                      if (user?.phoneNumber != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text(
                            'Phone Number',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            user!.phoneNumber!,
                            style: GoogleFonts.inter(),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          'Member Since',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          user?.createdAt != null
                              ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                              : 'Unknown',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings & Actions
                Text(
                  'Settings & Support',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: Text(
                          'Help & Support',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showHelpDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: Text(
                          'About iBorrow',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content:
                              const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await auth.signOut();
                        // Add navigation to login screen after sign out
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
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
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
