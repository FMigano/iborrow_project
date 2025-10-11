import 'package:uuid/uuid.dart';

class BorrowRecord {
  final String id;
  final String userId;
  final String bookId;
  final String status;
  final DateTime requestDate;
  final DateTime? approvedDate;
  final DateTime? borrowDate;
  final DateTime? dueDate;
  final DateTime? returnRequestDate;
  final DateTime? returnDate;
  final String? approvedBy;
  final String? returnApprovedBy;
  final String? notes;
  final String? returnNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const _uuid = Uuid();

  BorrowRecord({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.requestDate,
    this.approvedDate,
    this.borrowDate,
    this.dueDate,
    this.returnRequestDate,
    this.returnDate,
    this.approvedBy,
    this.returnApprovedBy,
    this.notes,
    this.returnNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    return dueDate != null && 
           DateTime.now().isAfter(dueDate!) && 
           status == 'borrowed';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'status': status,
      'request_date': requestDate.toIso8601String(),
      'approved_date': approvedDate?.toIso8601String(),
      'borrow_date': borrowDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'return_request_date': returnRequestDate?.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'approved_by': approvedBy,
      'return_approved_by': returnApprovedBy,
      'notes': notes,
      'return_notes': returnNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BorrowRecord.fromMap(Map<String, dynamic> map) {
    return BorrowRecord(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      bookId: map['book_id'] ?? '',
      status: map['status'] ?? 'pending',
      requestDate: DateTime.parse(map['request_date'] ?? DateTime.now().toIso8601String()),
      approvedDate: map['approved_date'] != null ? DateTime.parse(map['approved_date']) : null,
      borrowDate: map['borrow_date'] != null ? DateTime.parse(map['borrow_date']) : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      returnRequestDate: map['return_request_date'] != null ? DateTime.parse(map['return_request_date']) : null,
      returnDate: map['return_date'] != null ? DateTime.parse(map['return_date']) : null,
      approvedBy: map['approved_by'],
      returnApprovedBy: map['return_approved_by'],
      notes: map['notes'],
      returnNotes: map['return_notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  BorrowRecord copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? status,
    DateTime? requestDate,
    DateTime? approvedDate,
    DateTime? borrowDate,
    DateTime? dueDate,
    DateTime? returnRequestDate,
    DateTime? returnDate,
    String? approvedBy,
    String? returnApprovedBy,
    String? notes,
    String? returnNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BorrowRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      approvedDate: approvedDate ?? this.approvedDate,
      borrowDate: borrowDate ?? this.borrowDate,
      dueDate: dueDate ?? this.dueDate,
      returnRequestDate: returnRequestDate ?? this.returnRequestDate,
      returnDate: returnDate ?? this.returnDate,
      approvedBy: approvedBy ?? this.approvedBy,
      returnApprovedBy: returnApprovedBy ?? this.returnApprovedBy,
      notes: notes ?? this.notes,
      returnNotes: returnNotes ?? this.returnNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}