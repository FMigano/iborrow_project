# iBorrow

iBorrow is a Flutter library-management and book-sharing application. It lets users discover books, request and manage borrowings, organize personal libraries, and participate in a community feed. Administrators can manage catalog and borrowing workflows from the admin dashboard.

## Features

- Email/password authentication through Supabase
- Browse, search, and filter the local book catalog
- Search and browse books from the Google Books API
- View book details, ratings, reviews, availability, and copy counts
- Request books, approve or reject requests, request returns, and approve returns
- Track due dates, overdue items, and penalties
- Local notifications for due dates, overdue books, availability, and request updates
- Personal user libraries, including public libraries
- Community feed with posts, likes, comments, reviews, and recommendations
- Admin dashboard for borrowing requests, returns, books, users, and analytics
- SQLite-backed local data with Supabase integration and sync scaffolding
- Light theme with responsive Flutter UI for Android, iOS, web, Linux, macOS, and Windows

## Tech stack

- **Flutter/Dart** for the application and UI
- **Provider** for state management
- **GoRouter** for navigation and authentication redirects
- **Supabase** for authentication and cloud data
- **SQLite (`sqflite`)** for local persistence
- **Google Books API** for external book discovery
- **Workmanager** and `flutter_local_notifications` for background and reminder workflows

## Requirements

- Flutter SDK with Dart 3 (`>=3.0.0 <4.0.0`)
- A Supabase project configured for the tables and policies used by the app
- A Google Books API key for external catalog search
- Platform tooling for the target device (Android Studio, Xcode, or desktop toolchain as applicable)

## Getting started

1. Clone the repository and enter the project directory:

   ```bash
   git clone https://github.com/FMigano/iborrow_project.git
   cd iborrow_project
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Create the environment file:

   ```bash
   cp .env.example .env
   ```

4. Set the values in `.env`:

   ```dotenv
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   GOOGLE_BOOKS_API_KEY=your-google-books-api-key
   ```

5. Check available devices and run the app:

   ```bash
   flutter devices
   flutter run
   ```

The app initializes Supabase and the local database before rendering the application. Keep `.env` private; it is intended for local development and is listed as an application asset in `pubspec.yaml`.

## Running on specific platforms

```bash
flutter run -d chrome       # Web
flutter run -d android     # Android
flutter run -d ios         # iOS (macOS required)
flutter run -d windows     # Windows
flutter run -d macos       # macOS (macOS required)
flutter run -d linux       # Linux
```

## Project structure

```text
lib/
├── core/
│   ├── config/       # Environment-backed configuration and app constants
│   ├── database/     # SQLite helpers and local persistence
│   ├── models/       # Books, users, borrowings, penalties, reviews, and feed models
│   ├── router/       # GoRouter routes and auth redirects
│   ├── services/     # Google Books, notifications, storage, and sync services
│   └── theme/        # Application theme
├── features/
│   ├── admin/        # Admin dashboard, catalog management, and analytics
│   ├── auth/         # Login, signup, and authentication state
│   ├── books/        # Catalog, search, details, and reviews
│   ├── borrowing/    # Borrow and return workflows
│   ├── home/         # Main authenticated home screen
│   ├── splash/       # Startup screen
│   └── user/         # Profiles, libraries, community feed, likes, and comments
└── main.dart         # App initialization and Provider wiring
```

## Important application rules

The current app configuration defines a default loan period of 14 days, a maximum of 5 books per user, and a default penalty value of 1.0 per day. Return approval also calculates late penalties in the borrowing workflow. These values live in `lib/core/config/app_config.dart` and the borrowing provider, so review them before changing production policy.

## Development commands

```bash
flutter analyze
flutter test
flutter build apk       # Android release build
flutter build web       # Web release build
```

## Notes

- Supabase is initialized from `lib/core/config/app_config.dart` and `.env` values.
- Google Books results can be converted into the app's local `Book` model for use in the borrowing flow.
- Background synchronization is currently platform-aware and includes sync scaffolding; web does not support background sync.
- Platform-specific notification permissions may be required before reminders can be delivered.

## License

No license file is currently included in this repository.
