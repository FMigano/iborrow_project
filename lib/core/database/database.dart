import '../models/book.dart';
import '../models/borrow_record.dart';
import '../models/user.dart';
import 'database_helper.dart';

class AppDatabase {
  final DatabaseHelper _helper = DatabaseHelper();

  Future<void> insertUser(User user) async {
    await _helper.insertUser(user);
  }

  Future<User?> getUserById(String id) async {
    return await _helper.getUserById(id);
  }

  Future<void> insertBook(Book book) async {
    await _helper.insertBook(book);
  }

  Future<List<Book>> getAllBooks() async {
    return await _helper.getAllBooks();
  }

  Future<Book?> getBookById(String id) async {
    return await _helper.getBookById(id);
  }

  Future<void> insertBorrowRecord(BorrowRecord record) async {
    await _helper.insertBorrowRecord(record);
  }

  Future<List<BorrowRecord>> getUserBorrowings(String userId) async {
    return await _helper.getUserBorrowings(userId);
  }

  Future<List<BorrowRecord>> getPendingRequests() async {
    return await _helper.getPendingRequests();
  }

  Future<List<SyncLogData>> getPendingSyncs() async {
    return await _helper.getPendingSyncs();
  }

  Future<void> markSyncComplete(String syncId) async {
    await _helper.markSyncComplete(syncId);
  }

  Future<void> close() async {
    await _helper.close();
  }
}

// Compatibility classes for existing code
class UsersCompanion {
  final String id;
  final String email;
  final String fullName;
  final String? studentId;
  final String? phoneNumber;

  UsersCompanion.insert({
    required this.id,
    required this.email,
    required this.fullName,
    this.studentId,
    this.phoneNumber,
  });
}

class BooksCompanion {
  final String id;
  final String title;
  final String author;
  final String genre;

  BooksCompanion.insert({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
  });
}

class Value<T> {
  final T value;
  const Value(this.value);
}