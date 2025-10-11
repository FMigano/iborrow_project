import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/user.dart' as app_models;
import '../models/borrow_record.dart';
import '../models/penalty.dart';
import 'web_storage_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final _supabase = Supabase.instance.client;
  final webStorage = WebStorageHelper();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    
    if (_database != null) return _database;
    
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    // ✅ FIX: Use getDatabasesPath() for persistent storage
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'iborrow.db');
    
    debugPrint('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🔧 Creating database tables...');
    
    // Create tables
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        student_id TEXT,
        phone_number TEXT,
        is_admin INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE books(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        isbn TEXT,
        genre TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        total_copies INTEGER NOT NULL,
        available_copies INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE borrow_records(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        status TEXT NOT NULL,
        request_date TEXT NOT NULL,
        approved_date TEXT,
        borrow_date TEXT,
        due_date TEXT,
        return_request_date TEXT,
        return_date TEXT,
        approved_by TEXT,
        return_approved_by TEXT,
        notes TEXT,
        return_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE penalties(
        id TEXT PRIMARY KEY,
        borrow_record_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        amount REAL NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (borrow_record_id) REFERENCES borrow_records (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    debugPrint('✅ Database tables created successfully');
  }

  // Add method to check if database exists and has data
  Future<bool> databaseHasData() async {
    if (kIsWeb) {
      final books = await webStorage.getAllBooks();
      return books.isNotEmpty;
    }
    
    final db = await database;
    if (db == null) return false;
    
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM books');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  // ✅ Add method to ensure database is initialized
  Future<void> ensureInitialized() async {
    if (kIsWeb) {
      debugPrint('📱 Running on Web - using WebStorage');
      return;
    }
    
    final db = await database;
    if (db != null) {
      debugPrint('✅ Database initialized at: ${db.path}');
      
      // Check if we have data
      final hasData = await databaseHasData();
      debugPrint('📊 Database has data: $hasData');
    }
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
    // ✅ SAVE TO SUPABASE FIRST (source of truth)
    try {
      await _supabase.from('books').upsert(book.toMap());
      debugPrint('✅ Saved book to Supabase: ${book.title}');
    } catch (e) {
      debugPrint('❌ Failed to save book to Supabase: $e');
      throw Exception('Failed to save book to cloud: $e');
    }

    // Then save locally for offline access
    if (kIsWeb) {
      await webStorage.insertBook(book);
    } else {
      final db = await database;
      await db?.insert(
        'books',
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Book>> getAllBooks() async {
    // ✅ LOAD FROM SUPABASE FIRST
    try {
      final response = await _supabase
          .from('books')
          .select()
          .order('title', ascending: true);
    
      final books = (response as List)
          .map((json) => Book.fromMap(json))
          .toList();
    
      debugPrint('✅ Loaded ${books.length} books from Supabase');
    
      // Cache locally
      if (kIsWeb) {
        for (final book in books) {
          await webStorage.insertBook(book);
        }
      } else {
        final db = await database;
        for (final book in books) {
          await db?.insert(
            'books',
            book.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    
      return books;
    } catch (e) {
      debugPrint('⚠️ Failed to load from Supabase, using local cache: $e');
    
      // Fallback to local cache if Supabase fails
      if (kIsWeb) {
        return await webStorage.getAllBooks();
      } else {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db!.query('books');
        return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
      }
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
    // ✅ UPDATE SUPABASE FIRST
    try {
      await _supabase
          .from('books')
          .update(book.toMap())
          .eq('id', book.id);
      debugPrint('✅ Updated book in Supabase: ${book.title}');
    } catch (e) {
      debugPrint('❌ Failed to update book in Supabase: $e');
      throw Exception('Failed to update book in cloud: $e');
    }

    // Then update locally
    if (kIsWeb) {
      await webStorage.updateBook(book);
    } else {
      final db = await database;
      await db?.update(
        'books',
        book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
      );
    }
  }

  Future<void> deleteBook(String bookId) async {
    if (kIsWeb) {
      await webStorage.deleteBook(bookId);
    } else {
      final db = await database;
      
      // Delete related data first (due to foreign keys)
      await db!.delete('penalties', where: 'book_id = ?', whereArgs: [bookId]);
      await db.delete('borrow_records', where: 'book_id = ?', whereArgs: [bookId]);
      
      // Then delete the book
      await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
    }
    
    // Delete from Supabase
    try {
      final supabaseClient = Supabase.instance.client;
      if (supabaseClient.auth.currentUser != null) {
        await supabaseClient.from('penalties').delete().eq('book_id', bookId);
        await supabaseClient.from('borrow_records').delete().eq('book_id', bookId);
        await supabaseClient.from('books').delete().eq('id', bookId);
      }
    } catch (e) {
      debugPrint('Failed to delete book from Supabase: $e');
    }
    
    debugPrint('Book $bookId deleted successfully');
  }

  // Borrow record methods
  Future<void> insertBorrowRecord(BorrowRecord record) async {
    // ✅ Helper function to check if string is valid UUID
    bool isValidUuid(String? value) {
      if (value == null || value.isEmpty) return false;
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      return uuidPattern.hasMatch(value);
    }

    // ✅ SAVE TO SUPABASE FIRST
    try {
      final supabaseData = Map<String, dynamic>.from(record.toMap());
    
      // Remove invalid UUIDs
      if (!isValidUuid(supabaseData['approved_by'])) {
        supabaseData.remove('approved_by');
      }
    
      if (!isValidUuid(supabaseData['return_approved_by'])) {
        supabaseData.remove('return_approved_by');
      }

      await _supabase.from('borrow_records').upsert(supabaseData);
      debugPrint('✅ Saved borrow record to Supabase: ${record.id}');
    } catch (e) {
      debugPrint('❌ Failed to save borrow record to Supabase: $e');
      throw Exception('Failed to save borrow record to cloud: $e');
    }

    // Then save locally
    if (kIsWeb) {
      await webStorage.insertBorrowRecord(record);
    } else {
      final db = await database;
      await db?.insert(
        'borrow_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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

  // Add these methods if they don't exist:
  Future<List<BorrowRecord>> getAllActiveBorrowings() async {
    if (kIsWeb) {
      return await webStorage.getAllActiveBorrowings();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'borrow_records',
        where: 'status IN (?, ?, ?)',
        whereArgs: ['borrowed', 'return_requested', 'approved'],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => BorrowRecord.fromMap(maps[i]));
    }
  }

  Future<List<BorrowRecord>> getBorrowRecordsByStatus(String status) async {
    if (kIsWeb) {
      return await webStorage.getBorrowRecordsByStatus(status);
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
    // ✅ SAVE TO SUPABASE FIRST
    try {
      await _supabase.from('penalties').insert(penalty.toMap());
      debugPrint('✅ Saved penalty to Supabase: ${penalty.id}');
    } catch (e) {
      debugPrint('❌ Failed to save penalty to Supabase: $e');
      throw Exception('Failed to save penalty to cloud: $e');
    }

    // Then save locally
    if (kIsWeb) {
      await webStorage.insertPenalty(penalty);
    } else {
      final db = await database;
      await db?.insert(
        'penalties',
        penalty.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
    
    // Sync to Supabase
    try {
      await _syncPenaltyToSupabase(penalty);
    } catch (e) {
      debugPrint('Failed to sync penalty to Supabase: $e');
    }
  }

  // Add these methods to your DatabaseHelper class:

  Future<List<app_models.User>> getAllUsers() async {
    if (kIsWeb) {
      return await webStorage.getAllUsers();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'users',
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => app_models.User.fromMap(maps[i]));
    }
  }

  Future<List<BorrowRecord>> getAllBorrowRecords() async {
    // ✅ LOAD FROM SUPABASE FIRST
    try {
      final response = await _supabase
          .from('borrow_records')
          .select()
          .order('created_at', ascending: false);
    
      final records = (response as List)
          .map((json) => BorrowRecord.fromMap(json))
          .toList();
    
      debugPrint('✅ Loaded ${records.length} borrow records from Supabase');
    
      // Cache locally
      if (kIsWeb) {
        for (final record in records) {
          await webStorage.insertBorrowRecord(record);
        }
      } else {
        final db = await database;
        for (final record in records) {
          await db?.insert(
            'borrow_records',
            record.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    
      return records;
    } catch (e) {
      debugPrint('⚠️ Failed to load from Supabase, using local cache: $e');
    
      // Fallback to local cache
      if (kIsWeb) {
        return await webStorage.getAllBorrowRecords();
      } else {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db!.query('borrow_records');
        return List.generate(maps.length, (i) => BorrowRecord.fromMap(maps[i]));
      }
    }
  }

  Future<List<Penalty>> getAllPenalties() async {
    if (kIsWeb) {
      return await webStorage.getAllPenalties();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db!.query(
        'penalties',
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => Penalty.fromMap(maps[i]));
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
      final supabaseClient = Supabase.instance.client;
      if (supabaseClient.auth.currentUser != null) {
        await supabaseClient.from('penalties').upsert(penalty.toMap());
        debugPrint('Penalty synced to Supabase: ${penalty.id}');
      }
    } catch (e) {
      debugPrint('Error syncing penalty to Supabase: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      await webStorage.clearAllTables();
    } else {
      final db = await database;
      await db?.delete('users');
      await db?.delete('books');
      await db?.delete('borrow_records');
      await db?.delete('penalties');
      await db?.delete('sync_log');
    }
  }

  Future<void> clearBooksTable() async {
    if (kIsWeb) {
      await webStorage.clearBooksTable();
    } else {
      final db = await database;
      await db?.delete('books');
    }
  }

  Future<void> clearUsersTable() async {
    if (kIsWeb) {
      await webStorage.clearUsersTable();
    } else {
      final db = await database;
      await db?.delete('users');
      await db?.delete('borrow_records');
      await db?.delete('penalties');
    }
  }

  Future<void> clearBorrowRecordsTable() async {
    if (kIsWeb) {
      await webStorage.clearBorrowRecordsTable();
    } else {
      final db = await database;
      await db?.delete('borrow_records');
    }
  }

  Future<void> resetAllBookAvailability() async {
    if (kIsWeb) {
      // For web, get all books and update them individually
      final books = await webStorage.getAllBooks();
      for (var book in books) {
        final updatedBook = Book(
          id: book.id,
          title: book.title,
          author: book.author,
          isbn: book.isbn,
          genre: book.genre,
          description: book.description,
          imageUrl: book.imageUrl,
          totalCopies: book.totalCopies,
          availableCopies: book.totalCopies,
          createdAt: book.createdAt,
          updatedAt: DateTime.now(),
        );
        await webStorage.updateBook(updatedBook);
      }
    } else {
      final db = await database;
      await db?.rawUpdate('UPDATE books SET available_copies = total_copies');
    }
  }

  Future<void> deleteBooksByGenre(String genre) async {
    final db = await database;
    await db?.delete('books', where: 'genre = ?', whereArgs: [genre]);
  }

  Future<void> deleteBooksByAuthor(String author) async {
    final db = await database;
    await db?.delete('books', where: 'author = ?', whereArgs: [author]);
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db?.delete('users', where: 'id = ?', whereArgs: [id]);
    await db?.delete('borrow_records', where: 'user_id = ?', whereArgs: [id]);
    await db?.delete('penalties', where: 'user_id = ?', whereArgs: [id]);
  }

  Future<void> deleteBorrowRecord(String id) async {
    final db = await database;
    await db?.delete('borrow_records', where: 'id = ?', whereArgs: [id]);
    await db?.delete('penalties', where: 'borrow_record_id = ?', whereArgs: [id]);
  }

  Future<void> deletePenalty(String id) async {
    final db = await database;
    await db?.delete('penalties', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
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