import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/borrow_record.dart';
import '../models/user.dart' as app_models;
import '../models/penalty.dart';

// Import for mobile (SQLite)
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Import for web (SharedPreferences)  
import 'web_storage_helper.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  static WebStorageHelper? _webStorage;
  static const String _databaseName = 'iborrow.db';
  static const int _databaseVersion = 1;

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  factory DatabaseHelper() => instance;

  Future<Database?> get database async {
    if (kIsWeb) return null; // Web doesn't use SQLite
    _database ??= await _initDatabase();
    return _database!;
  }

  WebStorageHelper get webStorage {
    if (!kIsWeb) throw Exception('WebStorage only available on web platform');
    _webStorage ??= WebStorageHelper();
    return _webStorage!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) throw Exception('SQLite not available on web platform');
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        student_id TEXT,
        phone_number TEXT,
        is_admin INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create books table
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        isbn TEXT,
        genre TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        total_copies INTEGER DEFAULT 1,
        available_copies INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create borrow_records table
    await db.execute('''
      CREATE TABLE borrow_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        request_date TEXT NOT NULL,
        approved_date TEXT,
        borrow_date TEXT,
        due_date TEXT,
        return_date TEXT,
        approved_by TEXT,
        notes TEXT,
        is_overdue INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (book_id) REFERENCES books (id)
      )
    ''');

    // Create penalties table
    await db.execute('''
      CREATE TABLE penalties (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        borrow_record_id TEXT NOT NULL,
        amount REAL NOT NULL,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        paid_at TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (borrow_record_id) REFERENCES borrow_records (id)
      )
    ''');

    // Create sync_log table for offline sync
    await db.execute('''
      CREATE TABLE sync_log (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // User methods
  Future<void> insertUser(app_models.User user) async {
    if (kIsWeb) {
      await webStorage.insertUser(user);
      // Also sync to Supabase
      await _syncUserToSupabase(user);
    } else {
      final db = await database;
      await db!.insert('users', user.toMap());
      await _logSync('users', user.id, 'insert');
      // Try to sync to Supabase immediately
      await _syncUserToSupabase(user);
    }
  }

  Future<app_models.User?> getUserById(String id) async {
    if (kIsWeb) {
      // First try to get from web storage
      app_models.User? user = await webStorage.getUserById(id);
      if (user == null) {
        // If not found locally, try Supabase
        user = await _getUserFromSupabase(id);
        if (user != null) {
          await webStorage.insertUser(user);
        }
      }
      return user;
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return app_models.User.fromMap(maps.first);
      }
      
      // If not found locally, try Supabase
      final user = await _getUserFromSupabase(id);
      if (user != null) {
        await insertUser(user);
      }
      return user;
    }
  }

  // Book methods
  Future<void> insertBook(Book book) async {
    if (kIsWeb) {
      await webStorage.insertBook(book);
      await _syncBookToSupabase(book);
    } else {
      final db = await database;
      await db!.insert('books', book.toMap());
      await _logSync('books', book.id, 'insert');
      await _syncBookToSupabase(book);
    }
  }

  Future<List<Book>> getAllBooks() async {
    if (kIsWeb) {
      // Get from web storage and sync with Supabase
      List<Book> localBooks = await webStorage.getAllBooks();
      List<Book> supabaseBooks = await _getAllBooksFromSupabase();
      
      // Merge and update local storage
      Map<String, Book> mergedBooks = {};
      for (var book in localBooks) {
        mergedBooks[book.id] = book;
      }
      for (var book in supabaseBooks) {
        if (!mergedBooks.containsKey(book.id) || 
            book.updatedAt.isAfter(mergedBooks[book.id]!.updatedAt)) {
          mergedBooks[book.id] = book;
          await webStorage.insertBook(book);
        }
      }
      return mergedBooks.values.toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query('books');
      List<Book> localBooks = List.generate(maps.length, (i) => Book.fromMap(maps[i]));
      
      // Also get from Supabase and merge
      List<Book> supabaseBooks = await _getAllBooksFromSupabase();
      Map<String, Book> mergedBooks = {};
      for (var book in localBooks) {
        mergedBooks[book.id] = book;
      }
      for (var book in supabaseBooks) {
        if (!mergedBooks.containsKey(book.id) || 
            book.updatedAt.isAfter(mergedBooks[book.id]!.updatedAt)) {
          mergedBooks[book.id] = book;
          await updateBook(book);
        }
      }
      return mergedBooks.values.toList();
    }
  }

  Future<Book?> getBookById(String id) async {
    if (kIsWeb) {
      Book? book = await webStorage.getBookById(id);
      if (book == null) {
        book = await _getBookFromSupabase(id);
        if (book != null) {
          await webStorage.insertBook(book);
        }
      }
      return book;
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'books',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Book.fromMap(maps.first);
      }
      
      // Try Supabase
      final book = await _getBookFromSupabase(id);
      if (book != null) {
        await insertBook(book);
      }
      return book;
    }
  }

  Future<void> updateBook(Book book) async {
    if (kIsWeb) {
      await webStorage.updateBook(book);
      await _syncBookToSupabase(book);
    } else {
      final db = await database;
      await db!.update(
        'books',
        book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
      );
      await _logSync('books', book.id, 'update');
      await _syncBookToSupabase(book);
    }
  }

  // Borrow record methods
  Future<void> insertBorrowRecord(BorrowRecord record) async {
    if (kIsWeb) {
      await webStorage.insertBorrowRecord(record);
      await _syncBorrowRecordToSupabase(record);
    } else {
      final db = await database;
      await db!.insert('borrow_records', record.toMap());
      await _logSync('borrow_records', record.id, 'insert');
      await _syncBorrowRecordToSupabase(record);
    }
  }

  Future<List<BorrowRecord>> getUserBorrowings(String userId) async {
    if (kIsWeb) {
      final records = await webStorage.getAllBorrowRecords();
      return records.where((record) => record.userId == userId).toList();
    } else {
      final db = await database;
      if (db == null) return []; // Return empty list instead of null
      
      final List<Map<String, dynamic>> maps = await db.query(
        'borrow_records',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => BorrowRecord.fromMap(maps[i]));
    }
  }

  Future<List<BorrowRecord>> getPendingRequests() async {
    if (kIsWeb) {
      final records = await webStorage.getAllBorrowRecords();
      return records.where((record) => record.status == 'pending').toList();
    } else {
      final db = await database;
      if (db == null) return []; // Return empty list instead of null
      
      final List<Map<String, dynamic>> maps = await db.query(
        'borrow_records',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'request_date DESC',
      );
      return List.generate(maps.length, (i) => BorrowRecord.fromMap(maps[i]));
    }
  }

  Future<void> updateBorrowRecord(BorrowRecord record) async {
    if (kIsWeb) {
      await webStorage.updateBorrowRecord(record);
      await _syncBorrowRecordToSupabase(record);
    } else {
      final db = await database;
      await db!.update(
        'borrow_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
      await _logSync('borrow_records', record.id, 'update');
      await _syncBorrowRecordToSupabase(record);
    }
  }

  // Add this method after the existing borrow record methods
  Future<List<BorrowRecord>> getAllActiveBorrowings() async {
    if (kIsWeb) {
      final records = await webStorage.getAllBorrowRecords();
      return records.where((record) => 
          record.status == 'borrowed' || 
          record.status == 'pending' || 
          record.status == 'approved').toList();
    } else {
      final db = await database;
      if (db == null) return []; // Return empty list instead of null
      
      final List<Map<String, dynamic>> maps = await db.query(
        'borrow_records',
        where: 'status IN (?, ?, ?)',
        whereArgs: ['borrowed', 'pending', 'approved'],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => BorrowRecord.fromMap(maps[i]));
    }
  }

  // Add this method to DatabaseHelper class:
  Future<List<BorrowRecord>> getBorrowRecordsByStatus(String status) async {
    if (kIsWeb) {
      final allRecords = await webStorage.getAllBorrowRecords();
      return allRecords.where((record) => record.status == status).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'borrow_records',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => BorrowRecord.fromMap(maps[i]));
    }
  }

  // Penalty methods
  Future<void> insertPenalty(Penalty penalty) async {
    if (kIsWeb) {
      await webStorage.insertPenalty(penalty);
      await _syncPenaltyToSupabase(penalty);
    } else {
      final db = await database;
      await db!.insert('penalties', penalty.toMap());
      await _logSync('penalties', penalty.id, 'insert');
      await _syncPenaltyToSupabase(penalty);
    }
  }

  Future<List<Penalty>> getUserPenalties(String userId) async {
    if (kIsWeb) {
      return await webStorage.getUserPenalties(userId);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'penalties',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => Penalty.fromMap(maps[i]));
    }
  }

  Future<void> updatePenalty(Penalty penalty) async {
    if (kIsWeb) {
      await webStorage.updatePenalty(penalty);
      await _syncPenaltyToSupabase(penalty);
    } else {
      final db = await database;
      await db!.update(
        'penalties',
        penalty.toMap(),
        where: 'id = ?',
        whereArgs: [penalty.id],
      );
      await _logSync('penalties', penalty.id, 'update');
      await _syncPenaltyToSupabase(penalty);
    }
  }

  // Add this method to get all users
  Future<List<app_models.User>> getAllUsers() async {
    if (kIsWeb) {
      return await webStorage.getAllUsers();
    } else {
      final db = await database;
      if (db == null) return []; // Return empty list instead of null
      
      final List<Map<String, dynamic>> maps = await db.query('users');
      return List.generate(maps.length, (i) => app_models.User.fromMap(maps[i]));
    }
  }

  // Sync methods
  Future<List<SyncLogData>> getPendingSyncs() async {
    if (kIsWeb) {
      final webSyncLogs = await webStorage.getPendingSyncs();
      return webSyncLogs.map((webSyncLog) => SyncLogData(
        id: webSyncLog.id,
        tableName: webSyncLog.tableName,
        recordId: webSyncLog.recordId,
        operation: webSyncLog.operation,
        synced: webSyncLog.synced,
        createdAt: webSyncLog.createdAt,
      )).toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'sync_log',
        where: 'synced = ?',
        whereArgs: [0],
      );
      return List.generate(maps.length, (i) => SyncLogData.fromMap(maps[i]));
    }
  }

  Future<void> markSyncComplete(String syncId) async {
    if (kIsWeb) {
      await webStorage.markSyncComplete(syncId);
    } else {
      final db = await database;
      await db!.update(
        'sync_log',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [syncId],
      );
    }
  }

  Future<void> _logSync(String tableName, String recordId, String operation) async {
    if (kIsWeb) return;
    
    final db = await database;
    await db!.insert('sync_log', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Supabase sync methods
  Future<void> _syncUserToSupabase(app_models.User user) async {
    try {
      await _supabase.from('users').upsert(user.toSupabaseMap());
      print('User synced to Supabase successfully');
    } catch (e) {
      print('Failed to sync user to Supabase: $e');
      // Don't throw error - just log it
    }
  }

  Future<app_models.User?> _getUserFromSupabase(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .single();
      return app_models.User.fromSupabaseMap(response);
    } catch (e) {
      debugPrint('Failed to get user from Supabase: $e');
      return null;
    }
  }

  Future<void> _syncBookToSupabase(Book book) async {
    try {
      print('Syncing book to Supabase: ${book.title} with ID: ${book.id}');
      await _supabase.from('books').upsert(book.toSupabaseMap());
      print('Supabase sync successful for book: ${book.title}');
    } catch (e) {
      print('Failed to sync book to Supabase: $e');
      // Don't throw error - just log it
    }
  }

  Future<Book?> _getBookFromSupabase(String id) async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .eq('id', id)
          .single();
      return Book.fromSupabaseMap(response);
    } catch (e) {
      debugPrint('Failed to get book from Supabase: $e');
      return null;
    }
  }

  Future<List<Book>> _getAllBooksFromSupabase() async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((book) => Book.fromSupabaseMap(book)).toList();
    } catch (e) {
      debugPrint('Failed to get books from Supabase: $e');
      return [];
    }
  }

  Future<void> _syncBorrowRecordToSupabase(BorrowRecord record) async {
    try {
      await _supabase.from('borrow_records').upsert(record.toMap());
      print('Borrow record synced to Supabase successfully');
    } catch (e) {
      print('Failed to sync borrow record to Supabase: $e');
      // Don't throw error - just log it
    }
  }

  Future<void> _syncPenaltyToSupabase(Penalty penalty) async {
    try {
      await _supabase.from('penalties').upsert(penalty.toSupabaseMap());
    } catch (e) {
      debugPrint('Failed to sync penalty to Supabase: $e');
    }
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      await webStorage.clearAllData();
    } else {
      final db = await database;
      await db?.delete('users');
      await db?.delete('books');
      await db?.delete('borrow_records');
      await db?.delete('penalties');
      await db?.delete('sync_log');
    }
  }

  Future<void> close() async {
    if (kIsWeb) {
      await webStorage.close();
    } else {
      await _database?.close();
      _database = null;
    }
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