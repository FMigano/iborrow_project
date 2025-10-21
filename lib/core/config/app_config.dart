import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://dvvxyoyqltsnulhhsjni.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2dnh5b3lxbHRzbnVsaGhzam5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNjE2MDAsImV4cCI6MjA3NTkzNzYwMH0.MhQZLeuZHf33gkboHG85fFHOz_hM-knJpA0QiSVBu7Q';

  // Google Books API Configuration
  static String get googleBooksApiKey =>
      dotenv.env['GOOGLE_BOOKS_API_KEY'] ??
      'AIzaSyDl81z1C5vpL0gv9PgguKr9iLkXA2aII4k';
  static const String googleBooksApiUrl = 'https://www.googleapis.com/books/v1';

  // App Constants
  static const String appName = 'iBorrow';
  static const int defaultLoanDays = 14;
  static const double penaltyPerDay = 1.0;
  static const int maxBooksPerUser = 5;

  // Sync Settings
  static const Duration syncInterval = Duration(hours: 2);

  // Notification IDs
  static const int dueDateReminderId = 1000;
  static const int overdueReminderId = 2000;
}
