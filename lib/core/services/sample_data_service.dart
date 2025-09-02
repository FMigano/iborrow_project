import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/book.dart';
import '../models/user.dart';
import '../models/borrow_record.dart';
import 'package:uuid/uuid.dart';

class SampleDataService {
  static const _uuid = Uuid();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> insertSampleData() async {
    // Check if data already exists
    final existingBooks = await _databaseHelper.getAllBooks();
    if (existingBooks.isNotEmpty) {
      debugPrint('Sample data already exists');
      return;
    }

    debugPrint('Inserting sample data...');

    // Sample books (your existing code)
    final now = DateTime.now();
    final sampleBooks = [
      Book(
        id: _uuid.v4(),
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        isbn: '978-0-7432-7356-5',
        genre: 'Fiction',
        description: 'A classic American novel set in the Jazz Age.',
        totalCopies: 3,
        availableCopies: 3, // Changed to simulate borrowed books
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: _uuid.v4(),
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        isbn: '978-0-06-112008-4',
        genre: 'Fiction',
        description: 'A gripping tale of racial injustice and childhood innocence.',
        totalCopies: 3,
        availableCopies: 3,
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: _uuid.v4(),
        title: '1984',
        author: 'George Orwell',
        isbn: '978-0-452-28423-4',
        genre: 'Dystopian Fiction',
        description: 'A dystopian social science fiction novel.',
        totalCopies: 2,
        availableCopies: 2, // Changed to simulate borrowed books
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: _uuid.v4(),
        title: 'Introduction to Algorithms',
        author: 'Thomas H. Cormen',
        isbn: '978-0-262-03384-8',
        genre: 'Technology',
        description: 'Comprehensive guide to algorithms and data structures.',
        totalCopies: 5,
        availableCopies: 5,
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: _uuid.v4(),
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '978-0-132-35088-4',
        genre: 'Technology',
        description: 'A handbook of agile software craftsmanship.',
        totalCopies: 4,
        availableCopies: 4,
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: _uuid.v4(),
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        isbn: '978-0-06-231609-7',
        genre: 'History',
        description: 'A brief history of humankind.',
        totalCopies: 3,
        availableCopies: 3,
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: _uuid.v4(),
        title: 'The Lean Startup',
        author: 'Eric Ries',
        isbn: '978-0-307-88789-4',
        genre: 'Business',
        description: 'How constant innovation creates radically successful businesses.',
        totalCopies: 2,
        availableCopies: 2,
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: _uuid.v4(),
        title: 'Atomic Habits',
        author: 'James Clear',
        isbn: '978-0-735-21129-2',
        genre: 'Self-Help',
        description: 'An easy and proven way to build good habits and break bad ones.',
        totalCopies: 4,
        availableCopies: 4,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // Insert sample books
    for (final book in sampleBooks) {
      await _databaseHelper.insertBook(book);
    }

    // Create sample users
    final sampleUsers = [
      User(
        id: _uuid.v4(),
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        studentId: 'STU001',
        phoneNumber: '+1234567890',
        isAdmin: false,
        createdAt: now,
        updatedAt: now,
      ),
      User(
        id: _uuid.v4(),
        email: 'jane.smith@example.com',
        fullName: 'Jane Smith',
        studentId: 'STU002',
        phoneNumber: '+1234567891',
        isAdmin: false,
        createdAt: now,
        updatedAt: now,
      ),
      User(
        id: _uuid.v4(),
        email: 'admin@example.com',
        fullName: 'Admin User',
        studentId: 'ADM001',
        phoneNumber: '+1234567892',
        isAdmin: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // Insert sample users
    for (final user in sampleUsers) {
      await _databaseHelper.insertUser(user);
    }

    // Create sample borrow records
    final sampleBorrowRecords = [
      // Pending request
      BorrowRecord(
        id: _uuid.v4(),
        userId: sampleUsers[0].id, // John Doe
        bookId: sampleBooks[1].id,  // To Kill a Mockingbird
        status: 'pending',
        requestDate: now.subtract(const Duration(hours: 2)),
        notes: 'Need this for literature class',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      // Active borrowing
      BorrowRecord(
        id: _uuid.v4(),
        userId: sampleUsers[0].id, // John Doe
        bookId: sampleBooks[0].id,  // The Great Gatsby
        status: 'borrowed',
        requestDate: now.subtract(const Duration(days: 5)),
        approvedDate: now.subtract(const Duration(days: 4)),
        borrowDate: now.subtract(const Duration(days: 4)),
        dueDate: now.add(const Duration(days: 10)),
        approvedBy: sampleUsers[2].id, // Admin
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      // Overdue book
      BorrowRecord(
        id: _uuid.v4(),
        userId: sampleUsers[1].id, // Jane Smith
        bookId: sampleBooks[2].id,  // 1984
        status: 'borrowed',
        requestDate: now.subtract(const Duration(days: 20)),
        approvedDate: now.subtract(const Duration(days: 19)),
        borrowDate: now.subtract(const Duration(days: 19)),
        dueDate: now.subtract(const Duration(days: 5)), // Overdue!
        approvedBy: sampleUsers[2].id, // Admin
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 19)),
      ),
    ];

    // Insert sample borrow records
    for (final record in sampleBorrowRecords) {
      await _databaseHelper.insertBorrowRecord(record);
    }

    debugPrint('Sample data inserted successfully!');
    debugPrint('Created ${sampleBooks.length} books, ${sampleUsers.length} users, and ${sampleBorrowRecords.length} borrow records');
  }

  Future<void> clearAllData() async {
    await _databaseHelper.clearAllData();
    debugPrint('All data cleared!');
  }
}