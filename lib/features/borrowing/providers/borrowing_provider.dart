import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/borrow_record.dart';
import '../../../core/models/penalty.dart';

class BorrowingProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<BorrowRecord> _userBorrowings = [];
  List<BorrowRecord> _pendingRequests = [];
  List<BorrowRecord> _allActiveBorrowings = []; // Add this
  List<Penalty> _userPenalties = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BorrowRecord> get userBorrowings => _userBorrowings;
  List<BorrowRecord> get pendingRequests => _pendingRequests;
  List<BorrowRecord> get allActiveBorrowings => _allActiveBorrowings; // Add this
  List<Penalty> get userPenalties => _userPenalties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get canBorrowBooks => _userPenalties.where((p) => p.status == 'pending').isEmpty;
  
  double get totalPendingPenalties {
    return _userPenalties
        .where((p) => p.status == 'pending')
        .fold(0.0, (sum, penalty) => sum + penalty.amount);
  }

  // Add this method to load all active borrowings for admin
  Future<void> loadAllActiveBorrowings() async {
    try {
      _setLoading(true);
      _allActiveBorrowings = await _databaseHelper.getAllActiveBorrowings();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update loadPendingRequests to also load active borrowings
  Future<void> loadPendingRequests() async {
    try {
      _setLoading(true);
      _pendingRequests = await _databaseHelper.getPendingRequests();
      await loadAllActiveBorrowings(); // Load active borrowings too
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserData(String userId) async {
    await loadUserBorrowings(userId);
    await loadUserPenalties(userId);
  }

  Future<void> loadUserBorrowings(String userId) async {
    try {
      _setLoading(true);
      _userBorrowings = await _databaseHelper.getUserBorrowings(userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserPenalties(String userId) async {
    try {
      _userPenalties = await _databaseHelper.getUserPenalties(userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> requestBook(String userId, String bookId, {String? notes}) async {
    try {
      final borrowRecord = BorrowRecord(
        id: _uuid.v4(),
        userId: userId,
        bookId: bookId,
        status: 'pending',
        requestDate: DateTime.now(),
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.insertBorrowRecord(borrowRecord);
      await loadUserBorrowings(userId);
      await loadPendingRequests(); // This will also refresh admin data
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> approveBorrowRequest(String recordId, String adminId) async {
    try {
      // Get the borrow record
      final record = _pendingRequests.firstWhere((r) => r.id == recordId);
      
      // Create approved record
      final approvedRecord = BorrowRecord(
        id: record.id,
        userId: record.userId,
        bookId: record.bookId,
        status: 'borrowed', // Change to 'borrowed' instead of 'approved'
        requestDate: record.requestDate,
        approvedDate: DateTime.now(),
        borrowDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        approvedBy: adminId,
        notes: record.notes,
        createdAt: record.createdAt,
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.updateBorrowRecord(approvedRecord);
      
      // Update book availability
      final book = await _databaseHelper.getBookById(record.bookId);
      if (book != null && book.availableCopies > 0) {
        final updatedBook = book.copyWith(
          availableCopies: book.availableCopies - 1,
          updatedAt: DateTime.now(),
        );
        await _databaseHelper.updateBook(updatedBook);
      }

      await loadPendingRequests(); // This will refresh both pending and active
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> rejectBorrowRequest(String recordId, String adminId, {String? reason}) async {
    try {
      final record = _pendingRequests.firstWhere((r) => r.id == recordId);
      
      final rejectedRecord = BorrowRecord(
        id: record.id,
        userId: record.userId,
        bookId: record.bookId,
        status: 'rejected',
        requestDate: record.requestDate,
        approvedDate: DateTime.now(),
        approvedBy: adminId,
        notes: reason ?? 'Request rejected',
        createdAt: record.createdAt,
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.updateBorrowRecord(rejectedRecord);
      await loadPendingRequests();
      return true;
    } catch (e) {
      _setError(e.toString());
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
          availableCopies: book.availableCopies + 1,
          updatedAt: DateTime.now(),
        );
        await _databaseHelper.updateBook(updatedBook);
      }

      await loadUserBorrowings(record.userId);
      await loadAllActiveBorrowings(); // Refresh admin data
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> payPenalty(String penaltyId) async {
    try {
      // Find the penalty
      final penalty = _userPenalties.firstWhere((p) => p.id == penaltyId);
      
      // Create updated penalty
      final updatedPenalty = Penalty(
        id: penalty.id,
        userId: penalty.userId,
        borrowRecordId: penalty.borrowRecordId,
        amount: penalty.amount,
        reason: penalty.reason,
        status: 'paid',
        paidAt: DateTime.now(),
        createdAt: penalty.createdAt,
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
  Future<bool> approveBookReturn(String borrowRecordId, String adminId, {String? adminNotes}) async {
    try {
      final record = _returnRequests.firstWhere((b) => b.id == borrowRecordId);
      
      final updatedRecord = record.copyWith(
        status: 'returned',
        returnDate: DateTime.now(),
        returnApprovedBy: adminId,
        returnNotes: adminNotes ?? record.returnNotes,
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.updateBorrowRecord(updatedRecord);
      
      // Remove from return requests and refresh data
      _returnRequests.removeWhere((b) => b.id == borrowRecordId);
      await loadAllActiveBorrowings(); // Refresh all data
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error approving book return: $e');
      return false;
    }
  }

  // Reject book return (admin action)
  Future<bool> rejectBookReturn(String borrowRecordId, String adminId, {String? reason}) async {
    try {
      final record = _returnRequests.firstWhere((b) => b.id == borrowRecordId);
      
      final updatedRecord = record.copyWith(
        status: 'borrowed', // Back to borrowed status
        returnNotes: reason,
        returnRequestDate: null, // Clear the return request date
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.updateBorrowRecord(updatedRecord);
      
      // Remove from return requests and refresh data
      _returnRequests.removeWhere((b) => b.id == borrowRecordId);
      await loadAllActiveBorrowings(); // Refresh all data
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error rejecting book return: $e');
      return false;
    }
  }

  // Get statistics for returned books
  List<BorrowRecord> get returnedBooks {
    return _allActiveBorrowings.where((b) => b.status == 'returned').toList();
  }

  int get totalBorrowedCount {
    return _allActiveBorrowings.where((b) => b.status == 'borrowed' || b.status == 'returned').length;
  }

  int get returnedCount {
    return returnedBooks.length;
  }

  int get currentlyBorrowedCount {
    return _allActiveBorrowings.where((b) => b.status == 'borrowed' || b.status == 'return_requested').length;
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
}