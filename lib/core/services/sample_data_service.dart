import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/book.dart';

class SampleDataService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  Future<void> insertSampleData() async {
    // Check if data already exists
    final existingBooks = await _databaseHelper.getAllBooks();
    if (existingBooks.isNotEmpty) {
      debugPrint('Sample data already exists');
      return;
    }

    debugPrint('Inserting sample data...');

    // Sample books
    final sampleBooks = [
      {
        'title': 'The Great Gatsby',
        'author': 'F. Scott Fitzgerald',
        'genre': 'Fiction',
        'isbn': '9780743273565',
        'description': 'A classic American novel set in the Jazz Age.',
        'totalCopies': 3,
      },
      {
        'title': 'To Kill a Mockingbird',
        'author': 'Harper Lee',
        'genre': 'Fiction',
        'isbn': '9780061120084',
        'description': 'A gripping tale of racial injustice and childhood innocence.',
        'totalCopies': 2,
      },
      {
        'title': 'Introduction to Algorithms',
        'author': 'Thomas H. Cormen',
        'genre': 'Technology',
        'isbn': '9780262033848',
        'description': 'Comprehensive guide to algorithms and data structures.',
        'totalCopies': 5,
      },
      {
        'title': 'Clean Code',
        'author': 'Robert C. Martin',
        'genre': 'Technology',
        'isbn': '9780132350884',
        'description': 'A handbook of agile software craftsmanship.',
        'totalCopies': 4,
      },
      {
        'title': 'Sapiens',
        'author': 'Yuval Noah Harari',
        'genre': 'History',
        'isbn': '9780062316097',
        'description': 'A brief history of humankind.',
        'totalCopies': 3,
      },
      {
        'title': 'The Lean Startup',
        'author': 'Eric Ries',
        'genre': 'Business',
        'isbn': '9780307887894',
        'description': 'How constant innovation creates radically successful businesses.',
        'totalCopies': 2,
      },
      {
        'title': 'Atomic Habits',
        'author': 'James Clear',
        'genre': 'Self-Help',
        'isbn': '9780735211292',
        'description': 'An easy and proven way to build good habits and break bad ones.',
        'totalCopies': 4,
      },
      {
        'title': 'The Psychology of Computer Programming',
        'author': 'Gerald M. Weinberg',
        'genre': 'Technology',
        'isbn': '9780932633422',
        'description': 'Classic book on software engineering psychology.',
        'totalCopies': 2,
      },
    ];

    // Insert sample books
    for (final bookData in sampleBooks) {
      final book = Book(
        id: _uuid.v4(),
        title: bookData['title'] as String,
        author: bookData['author'] as String,
        genre: bookData['genre'] as String,
        isbn: bookData['isbn'] as String?,
        description: bookData['description'] as String?,
        totalCopies: bookData['totalCopies'] as int,
        availableCopies: bookData['totalCopies'] as int,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _databaseHelper.insertBook(book);
    }

    debugPrint('Sample data inserted successfully!');
  }

  Future<void> clearAllData() async {
    await _databaseHelper.clearAllData();
    debugPrint('All data cleared!');
  }
}