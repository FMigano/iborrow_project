import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../database/database_helper.dart';
import '../models/book.dart';
import 'package:uuid/uuid.dart';

class SampleDataService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();

  List<Book> getSampleBooks() {
    return [
      Book(
        id: _uuid.v4(),
        title: 'The Psychology of Computer Programming',
        author: 'Gerald M. Weinberg',
        isbn: '978-0932633422',
        genre: 'Technology',
        description: 'Classic book on software engineering psychology.',
        totalCopies: 2,
        availableCopies: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'Atomic Habits',
        author: 'James Clear',
        isbn: '978-0735211292',
        genre: 'Self-Help',
        description: 'An easy and proven way to build good habits and break bad ones.',
        totalCopies: 4,
        availableCopies: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'The Lean Startup',
        author: 'Eric Ries',
        isbn: '978-0307887894',
        genre: 'Business',
        description: 'How Today\'s Entrepreneurs Use Continuous Innovation to Create Radically Successful Businesses.',
        totalCopies: 2,
        availableCopies: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '978-0132350884',
        genre: 'Technology',
        description: 'A Handbook of Agile Software Craftsmanship.',
        totalCopies: 3,
        availableCopies: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        isbn: '978-0062316097',
        genre: 'History',
        description: 'A Brief History of Humankind.',
        totalCopies: 5,
        availableCopies: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'Thinking, Fast and Slow',
        author: 'Daniel Kahneman',
        isbn: '978-0374533557',
        genre: 'Psychology',
        description: 'The groundbreaking tour of the mind explaining the two systems that drive the way we think.',
        totalCopies: 3,
        availableCopies: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'The Pragmatic Programmer',
        author: 'Andrew Hunt & David Thomas',
        isbn: '978-0135957059',
        genre: 'Technology',
        description: 'Your Journey To Mastery, 20th Anniversary Edition.',
        totalCopies: 2,
        availableCopies: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'Deep Work',
        author: 'Cal Newport',
        isbn: '978-1455586691',
        genre: 'Self-Help',
        description: 'Rules for Focused Success in a Distracted World.',
        totalCopies: 4,
        availableCopies: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'The Innovator\'s Dilemma',
        author: 'Clayton M. Christensen',
        isbn: '978-1633691780',
        genre: 'Business',
        description: 'When New Technologies Cause Great Firms to Fail.',
        totalCopies: 2,
        availableCopies: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: _uuid.v4(),
        title: 'The Art of Computer Programming',
        author: 'Donald E. Knuth',
        isbn: '978-0201896831',
        genre: 'Technology',
        description: 'Volume 1: Fundamental Algorithms.',
        totalCopies: 1,
        availableCopies: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<void> insertSampleData() async {
    try {
      debugPrint('📚 Checking if sample data already exists...');

      // Check if books exist in Supabase
      final supabase = Supabase.instance.client;
      final existingBooks = await supabase.from('books').select().limit(1);
      
      if (existingBooks.isNotEmpty) {
        debugPrint('✅ Sample data already exists in Supabase');
        // Load from Supabase to local database
        await _databaseHelper.getAllBooks();
        return;
      }

      debugPrint('📝 Inserting fresh sample data to Supabase...');

      // Generate fresh sample books
      final books = getSampleBooks();

      // Insert books to Supabase
      for (final book in books) {
        await supabase.from('books').insert(book.toMap());
        debugPrint('✅ Inserted book: ${book.title}');
      }

      // Now sync to local database
      await _databaseHelper.getAllBooks();
      
      debugPrint('✅ Sample data inserted successfully! (${books.length} books)');
    } catch (e) {
      debugPrint('❌ Error inserting sample data: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Clear Supabase data (keep users since they sign up themselves)
      await supabase.from('penalties').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('borrow_records').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('books').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      
      // Clear local data (keep users)
      await _databaseHelper.clearAllData();
      
      debugPrint('🗑️ All data cleared from Supabase and local storage (users preserved)!');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
    }
  }

  Future<void> clearBorrowingDataOnly() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Clear borrowing data from Supabase
      await supabase.from('penalties').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('borrow_records').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      
      // Reset book availability in Supabase
      final books = await _databaseHelper.getAllBooks();
      for (final book in books) {
        await supabase.from('books').update({
          'available_copies': book.totalCopies,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', book.id);
      }
      
      // Clear local borrowing data
      await _databaseHelper.clearBorrowRecordsTable();
      await _databaseHelper.resetAllBookAvailability();
      
      debugPrint('✅ Borrowing data cleared, books reset!');
    } catch (e) {
      debugPrint('❌ Error clearing borrowing data: $e');
    }
  }
}