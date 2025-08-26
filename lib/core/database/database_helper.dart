import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/borrow_record.dart';
import '../models/user.dart';
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
        email TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        student_id TEXT,
        phone_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create books table
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        genre TEXT NOT NULL,
        isbn TEXT,
        description TEXT,
        image_url TEXT,
        total_copies INTEGER NOT NULL DEFAULT 1,
        available_copies INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create borrow_records table
    await db.execute('''
      CREATE TABLE borrow_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        status TEXT NOT NULL,
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
        reason TEXT,
        status TEXT DEFAULT 'pending',
        paid_at TEXT,
        created_at TEXT NOT NULL,
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
  Future<void> insertUser(User user) async {
    if (kIsWeb) {
      await webStorage.insertUser(user);
    } else {
      final db = await database;
      await db!.insert('users', user.toMap());
    }
  }

  Future<User?> getUserById(String id) async {
    if (kIsWeb) {
      return await webStorage.getUserById(id);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    }
  }

  // Book methods
  Future<void> insertBook(Book book) async {
    if (kIsWeb) {
      await webStorage.insertBook(book);
    } else {
      final db = await database;
      await db!.insert('books', book.toMap());
    }
  }

  Future<List<Book>> getAllBooks() async {
    if (kIsWeb) {
      return await webStorage.getAllBooks();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query('books');
      return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
    }
  }

  Future<Book?> getBookById(String id) async {
    if (kIsWeb) {
      return await webStorage.getBookById(id);
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
      return null;
    }
  }

  Future<void> updateBook(Book book) async {
    if (kIsWeb) {
      await webStorage.updateBook(book);
    } else {
      final db = await database;
      await db!.update(
        'books',
        book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
      );
    }
  }

  // Borrow record methods
  Future<void> insertBorrowRecord(BorrowRecord record) async {
    if (kIsWeb) {
      await webStorage.insertBorrowRecord(record);
    } else {
      final db = await database;
      await db!.insert('borrow_records', record.toMap());
    }
  }

  Future<List<BorrowRecord>> getUserBorrowings(String userId) async {
    if (kIsWeb) {
      return await webStorage.getUserBorrowings(userId);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
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
      return await webStorage.getPendingRequests();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'borrow_records',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => BorrowRecord.fromMap(maps[i]));
    }
  }

  Future<void> updateBorrowRecord(BorrowRecord record) async {
    if (kIsWeb) {
      await webStorage.updateBorrowRecord(record);
    } else {
      final db = await database;
      await db!.update(
        'borrow_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
    }
  }

  // Penalty methods
  Future<void> insertPenalty(Penalty penalty) async {
    if (kIsWeb) {
      await webStorage.insertPenalty(penalty);
    } else {
      final db = await database;
      await db!.insert('penalties', penalty.toMap());
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
    } else {
      final db = await database;
      await db!.update(
        'penalties',
        penalty.toMap(),
        where: 'id = ?',
        whereArgs: [penalty.id],
      );
    }
  }

  // Sync methods
  Future<List<SyncLogData>> getPendingSyncs() async {
    if (kIsWeb) {
      final webSyncs = await webStorage.getPendingSyncs();
      return webSyncs.map((sync) => SyncLogData(
        id: sync.id,
        tableName: sync.tableName,
        recordId: sync.recordId,
        operation: sync.operation,
        synced: sync.synced,
        createdAt: sync.createdAt,
      )).toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'sync_log',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
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

  Future<void> clearAllData() async {
    if (kIsWeb) {
      await webStorage.clearAllData();
    } else {
      final db = await database;
      if (db != null) {
        await db.delete('penalties');
        await db.delete('borrow_records');
        await db.delete('books');
        await db.delete('users');
        await db.delete('sync_log');
      }
    }
  }

  Future<void> close() async {
    if (kIsWeb) {
      await webStorage.close();
    } else {
      final db = await database;
      if (db != null) {
        await db.close();
        _database = null;
      }
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