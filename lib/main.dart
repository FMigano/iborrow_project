import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/config/app_config.dart';
import 'core/services/sync_manager.dart';
import 'core/services/notification_service.dart';
import 'core/services/sample_data_service.dart';
import 'core/router/app_router.dart'; // Import your router
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/books/providers/books_provider.dart';
import 'features/borrowing/providers/borrowing_provider.dart';

// Import workmanager only on mobile platforms
import 'package:workmanager/workmanager.dart' if (dart.library.html) 'core/services/workmanager_stub.dart';

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

  // Initialize timezone
  tz.initializeTimeZones();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize Workmanager for background sync (skip on web)
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    } catch (e) {
      debugPrint('Workmanager initialization failed: $e');
    }
  } else {
    debugPrint('Skipping Workmanager initialization on web platform');
  }

  // Initialize services
  await NotificationService.initialize();
  await SyncManager.initialize();

  // Insert sample data
  final sampleDataService = SampleDataService();
  await sampleDataService.insertSampleData();

  runApp(const IBorrowApp());
}

class IBorrowApp extends StatelessWidget {
  const IBorrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BooksProvider()),
        ChangeNotifierProvider(create: (_) => BorrowingProvider()),
      ],
      child: MaterialApp.router(
        title: 'iBorrow',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router, // USE YOUR ACTUAL ROUTER HERE!
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
