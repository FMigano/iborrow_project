import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/app_config.dart';
import 'core/database/database_helper.dart';
import 'core/services/sync_manager.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/books/providers/books_provider.dart';
import 'features/books/providers/reviews_provider.dart';
import 'features/books/providers/google_books_provider.dart';
import 'features/borrowing/providers/borrowing_provider.dart';
import 'features/user/providers/user_libraries_provider.dart';
import 'features/user/providers/feed_provider.dart';
import 'features/user/providers/feed_likes_provider.dart';
import 'features/user/providers/feed_comments_provider.dart';

import 'package:workmanager/workmanager.dart'
    if (dart.library.html) 'core/services/workmanager_stub.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  if (!kIsWeb) {
    Workmanager().executeTask((task, inputData) async {
      switch (task) {
        case SyncManager.syncTaskName:
          await SyncManager.syncData();
          break;
      }
      return Future.value(true);
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment variables loaded');
  } catch (e) {
    debugPrint('⚠️ Using fallback config (no .env file): $e');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // ✅ Pre-initialize database
  await DatabaseHelper().database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
            create: (_) => BooksProvider()), // ✅ Auto-loads books
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => GoogleBooksProvider()),
        ChangeNotifierProvider(
            create: (_) => BorrowingProvider()), // ✅ Auto-loads borrowings
        ChangeNotifierProvider(create: (_) => UserLibrariesProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => FeedLikesProvider()),
        ChangeNotifierProvider(create: (_) => FeedCommentsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iBorrow',
      theme: AppTheme.lightTheme,
      darkTheme:
          AppTheme.lightTheme, // Use light theme for dark mode too (all white)
      themeMode: ThemeMode.light, // Force light mode for white backgrounds
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
