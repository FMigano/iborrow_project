import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/books/screens/book_list_screen.dart';
import '../../features/books/screens/book_detail_screen.dart';
import '../../features/borrowing/screens/my_borrowings_screen.dart' as borrowing;
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isAuthenticated = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup' ||
                          state.matchedLocation == '/';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated && (state.matchedLocation == '/login' || state.matchedLocation == '/signup')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
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
      ),
      GoRoute(
        path: '/book/:id',
        builder: (context, state) => BookDetailScreen(
          bookId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/my-borrowings',
        builder: (context, state) => const borrowing.MyBorrowingsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}