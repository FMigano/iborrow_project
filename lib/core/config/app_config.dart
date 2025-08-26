class AppConfig {
  // Supabase Configuration
  // Replace these with your actual Supabase project credentials
  static const String supabaseUrl = 'https://xumzpeenrfgyznlmzuva.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1bXpwZWVucmZneXpubG16dXZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNzg2MjMsImV4cCI6MjA3MDc1NDYyM30.gEoJ-H0CKEiAyQ2g_VgS4MR9kq7Me4pMtvF44zfBj2c';
  
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
