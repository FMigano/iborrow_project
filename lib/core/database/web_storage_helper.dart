import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/borrow_record.dart';
import '../models/user.dart';
import '../models/penalty.dart';

class WebStorageHelper {
  static const String _userKey = 'iborrow_users';
  static const String _booksKey = 'iborrow_books';
  static const String _borrowRecordsKey = 'iborrow_borrow_records';
  static const String _penaltiesKey = 'iborrow_penalties';

  // User methods
  Future<void> insertUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getUsers();
    users[user.id] = user.toMap();
    await prefs.setString(_userKey, jsonEncode(users));
  }

  Future<User?> getUserById(String id) async {
    final users = await _getUsers();
    final userData = users[id];
    if (userData != null) {
      return User.fromMap(userData);
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
    await insertBook(book); // Same as insert for shared preferences
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

  Future<void> updatePenalty(Penalty penalty) async {
    await insertPenalty(penalty); // Same as insert for shared preferences
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

  Future<Map<String, Map<String, dynamic>>> _getPenalties() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_penaltiesKey);
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    }
    return {};
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