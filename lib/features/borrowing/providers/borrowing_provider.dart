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
  List<Penalty> _userPenalties = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BorrowRecord> get userBorrowings => _userBorrowings;
  List<BorrowRecord> get pendingRequests => _pendingRequests;
  List<Penalty> get userPenalties => _userPenalties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get canBorrowBooks => _userPenalties.where((p) => p.status == 'pending').isEmpty;
  
  double get totalPendingPenalties {
    return _userPenalties
        .where((p) => p.status == 'pending')
        .fold(0.0, (sum, penalty) => sum + penalty.amount);
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

  Future<void> loadPendingRequests() async {
    try {
      _setLoading(true);
      _pendingRequests = await _databaseHelper.getPendingRequests();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
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
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> approveBorrowRequest(String recordId, String adminId) async {
    try {
      // Get the borrow record
      final records = await _databaseHelper.getPendingRequests();
      final record = records.firstWhere((r) => r.id == recordId);
      
      // Create approved record
      final approvedRecord = BorrowRecord(
        id: record.id,
        userId: record.userId,
        bookId: record.bookId,
        status: 'approved',
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
}