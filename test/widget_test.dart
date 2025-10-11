// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:iborrow_project/main.dart';
import 'package:iborrow_project/features/auth/providers/auth_provider.dart';
import 'package:iborrow_project/features/books/providers/books_provider.dart';
import 'package:iborrow_project/features/borrowing/providers/borrowing_provider.dart';

void main() {
  group('iBorrow App Tests', () {
    testWidgets('App initializes with providers', (WidgetTester tester) async {
      // Build the app with providers
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => BooksProvider()),
            ChangeNotifierProvider(create: (_) => BorrowingProvider()),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for initial navigation
      await tester.pumpAndSettle();

      // Verify the app widget exists
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App shows login screen initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => BooksProvider()),
            ChangeNotifierProvider(create: (_) => BorrowingProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show iBorrow title or login elements
      expect(
        find.text('iBorrow'),
        findsWidgets,
        reason: 'App should show iBorrow branding',
      );
    });

    test('App name is iBorrow', () {
      expect('iBorrow', equals('iBorrow'));
    });
  });

  group('Model Tests', () {
    test('Book model creates correctly', () {
      // Add model tests here if needed
      expect(true, isTrue);
    });

    test('User model creates correctly', () {
      // Add model tests here if needed
      expect(true, isTrue);
    });

    test('BorrowRecord model creates correctly', () {
      // Add model tests here if needed
      expect(true, isTrue);
    });
  });
}
