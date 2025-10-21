import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/book.dart'; // Add this import
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/books/screens/book_list_screen.dart';
import '../../features/books/screens/enhanced_book_detail_screen.dart';
import '../../features/borrowing/screens/my_borrowings_screen.dart'
    as borrowing;
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../debug_viewer.dart'; // Add this
import '../../features/user/screens/edit_profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash', // Start with splash
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isAuthenticated = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/splash';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/signup')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/books',
        builder: (context, state) => const BookListScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) {
              final bookId = state.pathParameters['id']!;
              final book = state.extra as Book?;
              if (book != null) {
                return EnhancedBookDetailScreen(book: book);
              } else {
                return EnhancedBookDetailScreen(bookId: bookId);
              }
            },
          ),
        ],
      ),
      GoRoute(
        path: '/my-borrowings',
        builder: (context, state) => const borrowing.MyBorrowingsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/debug',
        builder: (context, state) => const DatabaseViewerScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}
