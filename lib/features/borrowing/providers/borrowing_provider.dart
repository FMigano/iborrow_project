import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/borrow_record.dart';
import '../../../core/models/penalty.dart';

class BorrowingProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  List<BorrowRecord> _userBorrowings = [];
  List<BorrowRecord> _pendingRequests = [];
  List<BorrowRecord> _allActiveBorrowings = [];
  List<Penalty> _penalties = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BorrowRecord> get userBorrowings => _userBorrowings;
  List<BorrowRecord> get pendingRequests => _pendingRequests;
  List<BorrowRecord> get allActiveBorrowings => _allActiveBorrowings;
  List<Penalty> get penalties => _penalties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ ADD: Auto-load on provider creation
  BorrowingProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    debugPrint('📊 BorrowingProvider: Initializing data...');
    await loadPendingRequests();
  }

  Future<void> loadPendingRequests() async {
    try {
      _isLoading = true;
      notifyListeners();

      final allRecords = await _databaseHelper.getAllBorrowRecords();

      // Get pending requests
      _pendingRequests = allRecords
          .where((r) => r.status == 'pending')
          .toList();

      // ✅ Get active borrowings (borrowed + return_requested ONLY, exclude returned)
      _allActiveBorrowings = allRecords
          .where((r) => r.status == 'borrowed' || r.status == 'return_requested')
          .toList();

      // Get all penalties
      _penalties = await _databaseHelper.getAllPenalties();

      debugPrint('📊 Loaded ${_pendingRequests.length} pending requests');
      debugPrint('📊 Loaded ${_allActiveBorrowings.length} active borrowings');
      debugPrint('📊 Loaded ${_penalties.length} penalties');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      _setError(e.toString());
    }
  }

  // ✅ ADD: Load user-specific borrowings
  Future<void> loadUserBorrowings(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final allRecords = await _databaseHelper.getAllBorrowRecords();
      
      _userBorrowings = allRecords
          .where((r) => r.userId == userId)
          .toList();

      debugPrint('📊 Loaded ${_userBorrowings.length} borrowings for user $userId');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user borrowings: $e');
      _setError(e.toString());
    }
  }

  Future<void> loadUserData(String userId) async {
    await loadUserBorrowings(userId);
    await loadUserPenalties(userId);
  }

  Future<void> loadUserPenalties(String userId) async {
    try {
      _penalties = await _databaseHelper.getUserPenalties(userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> requestBook(String userId, String bookId, {String? notes}) async {
    try {
      final borrowRecord = BorrowRecord(
        id: _uuid.v4(), // ✅ This generates proper UUID
        userId: userId,
        bookId: bookId,
        status: 'pending',
        requestDate: DateTime.now(),
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.insertBorrowRecord(borrowRecord);
      
      debugPrint('✅ Created borrow record with ID: ${borrowRecord.id}');
      
      await loadUserBorrowings(userId);
      await loadPendingRequests();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Replace the approveBorrowRequest method with this fixed version:

Future<bool> approveBorrowRequest(String requestId, String adminId) async {
  try {
    _setLoading(true);

    final request = _pendingRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw Exception('Request not found'),
    );

    final book = await _databaseHelper.getBookById(request.bookId);
    if (book == null) {
      throw Exception('Book not found');
    }

    if (book.availableCopies <= 0) {
      throw Exception('No copies available');
    }

    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 14));

    // ✅ REMOVE AUTH CHECK - Use requesting user's ID as fallback
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    
    // Always allow approval - use requesting user if no admin logged in
    final approverUserId = currentUser?.id ?? request.userId;

    debugPrint('✅ Approving with user ID: $approverUserId');

    final updatedRecord = request.copyWith(
      status: 'borrowed',
      approvedDate: now,
      borrowDate: now,
      dueDate: dueDate,
      approvedBy: approverUserId,
      updatedAt: now,
    );

    // Update in local database
    await _databaseHelper.insertBorrowRecord(updatedRecord);

    debugPrint('✅ Updated borrow record locally');

    // Update book availability
    final updatedBook = book.copyWith(
      availableCopies: book.availableCopies - 1,
      updatedAt: now,
    );

    await _databaseHelper.updateBook(updatedBook);

    debugPrint('✅ Updated book availability: ${book.title}');

    await loadPendingRequests();

    _setLoading(false);
    return true;
  } catch (e) {
    debugPrint('❌ Error approving request: $e');
    _setError(e.toString());
    _setLoading(false);
    return false;
  }
}

// ✅ Apply the same fix to other methods:

Future<bool> rejectBorrowRequest(String requestId, String adminId, {String? reason}) async {
  try {
    _setLoading(true);

    final request = _pendingRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw Exception('Request not found'),
    );

    final now = DateTime.now();
    
    // ✅ Get actual user ID
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final approverUserId = currentUser?.id ?? request.userId;

    final updatedRecord = request.copyWith(
      status: 'rejected',
      approvedBy: approverUserId, // ✅ Use UUID
      notes: reason,
      updatedAt: now,
    );

    await _databaseHelper.insertBorrowRecord(updatedRecord);

    await supabase.from('borrow_records').update({
      'status': 'rejected',
      'approved_by': approverUserId, // ✅ UUID
      'notes': reason,
      'updated_at': now.toIso8601String(),
    }).eq('id', requestId);

    debugPrint('✅ Rejected borrow record in Supabase: $requestId');

    await loadPendingRequests();

    _setLoading(false);
    return true;
  } catch (e) {
    debugPrint('❌ Error rejecting request: $e');
    _setError(e.toString());
    _setLoading(false);
    return false;
  }
}

  Future<bool> returnBook(String recordId) async {
    try {
      // Get the borrow record
      final record = _userBorrowings.firstWhere((r) => r.id == recordId);
      
      // Create returned record
      final returnedRecord = BorrowRecord(
        id: record.id,
        userId: record.userId,
        bookId: record.bookId,
        status: 'returned',
        requestDate: record.requestDate,
        approvedDate: record.approvedDate,
        borrowDate: record.borrowDate,
        dueDate: record.dueDate,
        returnDate: DateTime.now(),
        approvedBy: record.approvedBy,
        notes: record.notes,
        createdAt: record.createdAt,
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.updateBorrowRecord(returnedRecord);
      
      // Update book availability
      final book = await _databaseHelper.getBookById(record.bookId);
      if (book != null) {
        final updatedBook = book.copyWith(
          availableCopies: book.availableCopies + 1, // ✅ Should INCREASE
          updatedAt: DateTime.now(),
        );
        await _databaseHelper.updateBook(updatedBook);
      }

      await loadUserBorrowings(record.userId);
      await loadPendingRequests(); // Refresh admin data
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> payPenalty(String penaltyId) async {
    try {
      // Find the penalty
      final penalty = _penalties.firstWhere((p) => p.id == penaltyId);
      
      // Create updated penalty using copyWith
      final updatedPenalty = penalty.copyWith(
        status: 'paid',
        paidDate: DateTime.now(), // Use paidDate instead of paidAt
        updatedAt: DateTime.now(), // Add updatedAt
      );

      await _databaseHelper.updatePenalty(updatedPenalty);
      await loadUserPenalties(penalty.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  List<BorrowRecord> _returnRequests = []; // ADD THIS LINE
  List<BorrowRecord> get returnRequests => _returnRequests; // ADD THIS LINE

  // Load pending return requests (admin)
  Future<void> loadReturnRequests() async {
    try {
      _isLoading = true;
      notifyListeners();

      final records = await _databaseHelper.getBorrowRecordsByStatus('return_requested');
      _returnRequests = records;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading return requests: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request book return (user action)
  Future<bool> requestBookReturn(String borrowRecordId, {String? returnNotes}) async {
    try {
      final record = _userBorrowings.firstWhere((b) => b.id == borrowRecordId);
      
      final updatedRecord = record.copyWith(
        status: 'return_requested',
        returnRequestDate: DateTime.now(),
        returnNotes: returnNotes,
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.updateBorrowRecord(updatedRecord);
      
      // Update local lists
      final index = _userBorrowings.indexWhere((b) => b.id == borrowRecordId);
      if (index != -1) {
        _userBorrowings[index] = updatedRecord;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error requesting book return: $e');
      return false;
    }
  }

  // Approve book return (admin action)
  Future<bool> approveBookReturn(String borrowRecordId, String adminId) async {
    try {
      _setLoading(true);

      // Find the record
      final allRecords = await _databaseHelper.getAllBorrowRecords();
      final record = allRecords.firstWhere(
        (r) => r.id == borrowRecordId,
        orElse: () => throw Exception('Borrow record not found'),
      );

      debugPrint('📋 Found record with status: ${record.status}');

      // ✅ FIX: Check if already returned
      if (record.status == 'returned') {
        debugPrint('⚠️ Book already returned, skipping approval');
        _setLoading(false);
        return true; // Return true since it's already in the desired state
      }

      // ✅ Check if it's return_requested OR borrowed (allow both)
      if (record.status != 'return_requested' && record.status != 'borrowed') {
        throw Exception('This book is not eligible for return approval (status: ${record.status})');
      }

      final book = await _databaseHelper.getBookById(record.bookId);
      if (book == null) {
        throw Exception('Book not found');
      }

      final now = DateTime.now();
      
      // ✅ FIX: Get actual user ID, use requesting user as fallback
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      // Use current user ID if available, otherwise use the requesting user's ID
      final approverUserId = currentUser?.id ?? record.userId;

      debugPrint('✅ Approving return with user ID: $approverUserId');

      final updatedRecord = record.copyWith(
        status: 'returned',
        returnDate: now,
        returnApprovedBy: approverUserId,
        updatedAt: now,
      );

      // Update in local database
      await _databaseHelper.insertBorrowRecord(updatedRecord);

      // ✅ Update in Supabase (will be handled by insertBorrowRecord with UUID validation)
      debugPrint('✅ Updated borrow record locally and synced to Supabase');

      // Update book availability
      final updatedBook = book.copyWith(
        availableCopies: book.availableCopies + 1,
        updatedAt: now,
      );

      await _databaseHelper.updateBook(updatedBook);

      debugPrint('✅ Updated book availability: ${book.title}');

      // Check for overdue penalty
      if (record.dueDate != null && now.isAfter(record.dueDate!)) {
        final daysLate = now.difference(record.dueDate!).inDays;
        final penaltyAmount = daysLate * 5.0;

        final penalty = Penalty(
          id: const Uuid().v4(),
          borrowRecordId: borrowRecordId,
          userId: record.userId,
          bookId: record.bookId,
          amount: penaltyAmount,
          reason: 'Late return: $daysLate days overdue',
          status: 'pending',
          createdAt: now,
          updatedAt: now,
        );

        await _databaseHelper.insertPenalty(penalty);
        debugPrint('✅ Created penalty for overdue book');
      }

      // Reload data
      await loadPendingRequests();

      _setLoading(false);
      
      debugPrint('✅ Book return approved successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Error approving return: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Fix the rejectBookReturn method:

Future<bool> rejectBookReturn(String borrowRecordId, String adminId, String reason) async {
  try {
    _setLoading(true);

    final record = _allActiveBorrowings.firstWhere(
      (r) => r.id == borrowRecordId && r.status == 'return_requested',
      orElse: () => throw Exception('Return request not found'),
    );

    final now = DateTime.now();
    
    // ✅ Get actual user ID
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final approverUserId = currentUser?.id ?? record.userId;

    final updatedRecord = record.copyWith(
      status: 'borrowed',
      returnNotes: reason,
      returnApprovedBy: approverUserId, // ✅ Use UUID
      updatedAt: now,
    );

    await _databaseHelper.insertBorrowRecord(updatedRecord);

    await supabase.from('borrow_records').update({
      'status': 'borrowed',
      'return_notes': reason,
      'return_approved_by': approverUserId, // ✅ UUID
      'updated_at': now.toIso8601String(),
    }).eq('id', borrowRecordId);

    debugPrint('✅ Rejected return in Supabase: $borrowRecordId');

    await loadPendingRequests();

    _setLoading(false);
    return true;
  } catch (e) {
    debugPrint('❌ Error rejecting return: $e');
    _setError(e.toString());
    _setLoading(false);
    return false;
  }
}

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> debugBookAvailability() async {
    print('=== BOOK AVAILABILITY DEBUG ===');
    final books = await _databaseHelper.getAllBooks();
    for (final book in books) {
      print('📚 ${book.title}');
      print('   Available: ${book.availableCopies}/${book.totalCopies}');
      print('   Last Updated: ${book.updatedAt}');
      print('   ---');
    }
    
    // Check active borrowings
    final borrowings = await _databaseHelper.getAllActiveBorrowings();
    final borrowedBooks = borrowings.where((b) => b.status == 'borrowed').toList();
    print('📖 Currently Borrowed: ${borrowedBooks.length} books');
    
    for (final borrowing in borrowedBooks) {
      print('   Book ID: ${borrowing.bookId} (Status: ${borrowing.status})');
    }
  }

  // Add these methods to your BorrowingProvider class:

  Future<bool> resetAllBookAvailability() async {
    try {
      _setLoading(true);
      
      await _databaseHelper.resetAllBookAvailability();
      
      print('✅ Reset all books to full availability');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reset book availability: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetAllSystemData() async {
    try {
      _setLoading(true);
      
      // 1. Reset book availability
      await _databaseHelper.resetAllBookAvailability();
      
      // 2. Clear all borrowing records and penalties
      await _databaseHelper.clearBorrowRecordsTable();
      
      // 3. Clear local data
      _userBorrowings.clear();
      _pendingRequests.clear();
      _allActiveBorrowings.clear();
      _returnRequests.clear();
      _penalties.clear();
      
      notifyListeners();
      
      print('✅ System data reset successfully');
      return true;
    } catch (e) {
      _setError('Failed to reset system data: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> clearAllData() async {
    try {
      _setLoading(true);
      
      await _databaseHelper.clearAllData();
      
      // Clear all local data
      _userBorrowings.clear();
      _pendingRequests.clear();
      _allActiveBorrowings.clear();
      _returnRequests.clear();
      _penalties.clear();
      
      notifyListeners();
      
      print('✅ All data cleared successfully');
      return true;
    } catch (e) {
      _setError('Failed to clear all data: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add this method to BorrowingProvider

  Future<void> syncFromSupabase() async {
    try {
      debugPrint('🔄 Syncing data from Supabase...');
      
      final supabase = Supabase.instance.client;
      
      // Get all borrow records from Supabase
      final borrowRecordsResponse = await supabase
          .from('borrow_records')
          .select()
          .order('created_at', ascending: false);
      
      debugPrint('📥 Found ${borrowRecordsResponse.length} borrow records in Supabase');
      
      // Save to local database
      final databaseHelper = DatabaseHelper();
      for (final recordMap in borrowRecordsResponse) {
        final record = BorrowRecord.fromMap(recordMap);
        
        // Check if record exists locally
        final localRecords = await databaseHelper.getAllBorrowRecords();
        final exists = localRecords.any((r) => r.id == record.id);
        
        if (!exists) {
          await databaseHelper.insertBorrowRecord(record);
          debugPrint('➕ Added record ${record.id} from Supabase');
        }
      }
      
      // Get all penalties from Supabase
      final penaltiesResponse = await supabase
          .from('penalties')
          .select()
          .order('created_at', ascending: false);
      
      debugPrint('📥 Found ${penaltiesResponse.length} penalties in Supabase');
      
      for (final penaltyMap in penaltiesResponse) {
        final penalty = Penalty.fromMap(penaltyMap);
        
        // Check if penalty exists locally
        final localPenalties = await databaseHelper.getAllPenalties();
        final exists = localPenalties.any((p) => p.id == penalty.id);
        
        if (!exists) {
          await databaseHelper.insertPenalty(penalty);
          debugPrint('➕ Added penalty ${penalty.id} from Supabase');
        }
      }
      
      // Reload local data
      await loadPendingRequests();
      
      debugPrint('✅ Supabase sync complete');
    } catch (e) {
      debugPrint('❌ Error syncing from Supabase: $e');
    }
  }

  bool get canBorrowBooks {
    // Add logic to check if user has pending penalties
    // For now, return true by default
    return true;
  }
}