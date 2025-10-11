import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/borrow_record.dart';
import '../models/user.dart' as app_models;
import '../models/penalty.dart';

class WebStorageHelper {
  static const String _userKey = 'iborrow_users';
  static const String _booksKey = 'iborrow_books';
  static const String _borrowRecordsKey = 'iborrow_borrow_records';
  static const String _penaltiesKey = 'iborrow_penalties';

  // User methods - FIX: Use app_models.User instead of User
  Future<void> insertUser(app_models.User user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getUsers();
    users[user.id] = user.toMap();
    await prefs.setString(_userKey, jsonEncode(users));
  }

  Future<app_models.User?> getUserById(String id) async {
    final users = await _getUsers();
    final userData = users[id];
    if (userData != null) {
      return app_models.User.fromMap(userData);
    }
    return null;
  }

  // Book methods
  Future<void> insertBook(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final books = await _getBooks();
    books[book.id] = book.toMap();
    await prefs.setString(_booksKey, jsonEncode(books));
  }

  Future<List<Book>> getAllBooks() async {
    final books = await _getBooks();
    return books.values.map((data) => Book.fromMap(data)).toList();
  }

  Future<Book?> getBookById(String id) async {
    final books = await _getBooks();
    final bookData = books[id];
    if (bookData != null) {
      return Book.fromMap(bookData);
    }
    return null;
  }

  Future<void> updateBook(Book book) async {
    final books = await _getBooks();
    books[book.id] = book.toMap();
    await _saveBooks(books);
  }

  Future<void> deleteBook(String bookId) async {
    final books = await _getBooks();
    books.remove(bookId);
    await _saveBooks(books);
    
    // Also remove related borrowing records and penalties
    final borrowRecords = await _getBorrowRecords();
    final penaltiesToRemove = <String>[];
    final recordsToRemove = <String>[];
    
    // Find related records to remove
    borrowRecords.forEach((id, recordData) {
      if (recordData['book_id'] == bookId) {
        recordsToRemove.add(id);
      }
    });
    
    for (final id in recordsToRemove) {
      borrowRecords.remove(id);
    }
    
    await _saveBorrowRecords(borrowRecords);
    
    // Remove related penalties
    final penalties = await _getPenalties();
    penalties.forEach((id, penaltyData) {
      if (penaltyData['book_id'] == bookId) {
        penaltiesToRemove.add(id);
      }
    });
    
    for (final id in penaltiesToRemove) {
      penalties.remove(id);
    }
    
    await _savePenalties(penalties);
    
    debugPrint('Book $bookId deleted from web storage');
  }

  // Borrow record methods
  Future<void> insertBorrowRecord(BorrowRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _getBorrowRecords();
    records[record.id] = record.toMap();
    await prefs.setString(_borrowRecordsKey, jsonEncode(records));
  }

  Future<List<BorrowRecord>> getUserBorrowings(String userId) async {
    final records = await _getBorrowRecords();
    return records.values
        .map((data) => BorrowRecord.fromMap(data))
        .where((record) => record.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<BorrowRecord>> getPendingRequests() async {
    final records = await _getBorrowRecords();
    return records.values
        .map((data) => BorrowRecord.fromMap(data))
        .where((record) => record.status == 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> updateBorrowRecord(BorrowRecord record) async {
    await insertBorrowRecord(record); // Same as insert for shared preferences
  }

  // Penalty methods
  Future<void> insertPenalty(Penalty penalty) async {
    final prefs = await SharedPreferences.getInstance();
    final penalties = await _getPenalties();
    penalties[penalty.id] = penalty.toMap();
    await prefs.setString(_penaltiesKey, jsonEncode(penalties));
  }

  Future<List<Penalty>> getUserPenalties(String userId) async {
    final penalties = await _getPenalties();
    return penalties.values
        .map((data) => Penalty.fromMap(data))
        .where((penalty) => penalty.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<BorrowRecord>> getAllBorrowRecords() async {
    final records = await _getBorrowRecords();
    return records.values
        .map((data) => BorrowRecord.fromMap(data))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<app_models.User>> getAllUsers() async {
    final users = await _getUsers();
    return users.values
        .map((data) => app_models.User.fromMap(data))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Penalty>> getAllPenalties() async {
    final penalties = await _getPenalties();
    return penalties.values
        .map((data) => Penalty.fromMap(data))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> updatePenalty(Penalty penalty) async {
    final penalties = await _getPenalties();
    penalties[penalty.id] = penalty.toMap();
    await _savePenalties(penalties);
  }

  // Sync methods (no-op for web)
  Future<List<SyncLogData>> getPendingSyncs() async {
    return [];
  }

  Future<void> markSyncComplete(String syncId) async {
    // No-op for web
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_booksKey);
    await prefs.remove(_borrowRecordsKey);
    await prefs.remove(_penaltiesKey);
    debugPrint('All data cleared from web storage');
  }

  Future<void> clearUserDataOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_penaltiesKey);
    await prefs.remove(_borrowRecordsKey);
    await prefs.remove(_userKey);
    // Keep books in storage
    debugPrint('User data cleared from web storage, books preserved');
  }

  Future<void> clearBorrowingDataOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_penaltiesKey);
    await prefs.remove(_borrowRecordsKey);
    // Keep books and users in storage
    debugPrint('Borrowing data cleared from web storage, books and users preserved');
  }

  Future<void> close() async {
    // No-op for shared preferences
  }

  // Private helper methods
  Future<Map<String, Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    }
    return {};
  }

  Future<Map<String, Map<String, dynamic>>> _getBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_booksKey);
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    }
    return {};
  }

  Future<Map<String, Map<String, dynamic>>> _getBorrowRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_borrowRecordsKey);
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    }
    return {};
  }

  // FIX: Replace localStorage with SharedPreferences
  Future<Map<String, Map<String, dynamic>>> _getPenalties() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_penaltiesKey);
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    }
    return {};
  }

  Future<void> _saveBooks(Map<String, Map<String, dynamic>> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_booksKey, jsonEncode(books));
  }

  Future<void> _savePenalties(Map<String, Map<String, dynamic>> penalties) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_penaltiesKey, jsonEncode(penalties));
  }

  Future<List<BorrowRecord>> getAllActiveBorrowings() async {
    final records = await _getBorrowRecords();
    return records.values
        .map((data) => BorrowRecord.fromMap(data))
        .where((record) => ['borrowed', 'return_requested', 'approved'].contains(record.status))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<BorrowRecord>> getBorrowRecordsByStatus(String status) async {
    final records = await _getBorrowRecords();
    return records.values
        .map((data) => BorrowRecord.fromMap(data))
        .where((record) => record.status == status)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deleteBooksByGenre(String genre) async {
    final books = await _getBooks();
    final booksToRemove = <String>[];
    
    books.forEach((id, bookData) {
      if (bookData['genre'] == genre) {
        booksToRemove.add(id);
      }
    });
    
    for (final id in booksToRemove) {
      books.remove(id);
    }
    
    await _saveBooks(books);
    debugPrint('Deleted ${booksToRemove.length} books with genre: $genre');
  }

  Future<void> deleteBooksByAuthor(String author) async {
    final books = await _getBooks();
    final booksToRemove = <String>[];
    
    books.forEach((id, bookData) {
      if (bookData['author'] == author) {
        booksToRemove.add(id);
      }
    });
    
    for (final id in booksToRemove) {
      books.remove(id);
    }
    
    await _saveBooks(books);
    debugPrint('Deleted ${booksToRemove.length} books by author: $author');
  }

  Future<void> clearBooksTable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_booksKey);
    debugPrint('All books cleared from web storage');
  }

  Future<void> clearUsersTable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> clearBorrowRecordsTable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_borrowRecordsKey);
  }

  Future<void> clearPenaltiesTable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_penaltiesKey);
  }

  Future<void> clearAllTables() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_booksKey);
    await prefs.remove(_borrowRecordsKey);
    await prefs.remove(_penaltiesKey);
  }

  Future<void> deleteUser(String userId) async {
    // Delete user's penalties first
    final penalties = await _getPenalties();
    final penaltiesToRemove = <String>[];
    penalties.forEach((id, penaltyData) {
      if (penaltyData['user_id'] == userId) {
        penaltiesToRemove.add(id);
      }
    });
    for (final id in penaltiesToRemove) {
      penalties.remove(id);
    }
    await _savePenalties(penalties);

    // Delete user's borrow records
    final borrowRecords = await _getBorrowRecords();
    final recordsToRemove = <String>[];
    borrowRecords.forEach((id, recordData) {
      if (recordData['user_id'] == userId) {
        recordsToRemove.add(id);
      }
    });
    for (final id in recordsToRemove) {
      borrowRecords.remove(id);
    }
    await _saveBorrowRecords(borrowRecords);

    // Delete the user
    final users = await _getUsers();
    users.remove(userId);
    await _saveUsers(users);
    
    debugPrint('User $userId and all related data deleted');
  }

  Future<void> deleteBorrowRecord(String recordId) async {
    // Delete related penalties first
    final penalties = await _getPenalties();
    final penaltiesToRemove = <String>[];
    penalties.forEach((id, penaltyData) {
      if (penaltyData['borrow_record_id'] == recordId) {
        penaltiesToRemove.add(id);
      }
    });
    for (final id in penaltiesToRemove) {
      penalties.remove(id);
    }
    await _savePenalties(penalties);

    // Delete the borrow record
    final borrowRecords = await _getBorrowRecords();
    borrowRecords.remove(recordId);
    await _saveBorrowRecords(borrowRecords);
    
    debugPrint('Borrow record $recordId and related penalties deleted');
  }

  Future<void> deletePenalty(String penaltyId) async {
    final penalties = await _getPenalties();
    penalties.remove(penaltyId);
    await _savePenalties(penalties);
    debugPrint('Penalty $penaltyId deleted');
  }

  // Helper methods for saving data
  Future<void> _saveUsers(Map<String, Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(users));
  }

  Future<void> _saveBorrowRecords(Map<String, Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_borrowRecordsKey, jsonEncode(records));
  }
}

class SyncLogData {
  final String id;
  final String tableName;
  final String recordId;
  final String operation;
  final bool synced;
  final DateTime createdAt;

  SyncLogData({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    this.synced = false,
    required this.createdAt,
  });

  factory SyncLogData.fromMap(Map<String, dynamic> map) {
    return SyncLogData(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      operation: map['operation'],
      synced: (map['synced'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'synced': synced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}