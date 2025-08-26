class BorrowRecord {
  final String id;
  final String userId;
  final String bookId;
  final String status;
  final DateTime requestDate;
  final DateTime? approvedDate;
  final DateTime? borrowDate;
  final DateTime? dueDate;
  final DateTime? returnDate;
  final String? approvedBy;
  final String? notes;
  final bool isOverdue;
  final DateTime createdAt;
  final DateTime updatedAt;

  BorrowRecord({
    required this.id,
    required this.userId,
    required this.bookId,
    this.status = 'pending',
    required this.requestDate,
    this.approvedDate,
    this.borrowDate,
    this.dueDate,
    this.returnDate,
    this.approvedBy,
    this.notes,
    this.isOverdue = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BorrowRecord.fromMap(Map<String, dynamic> map) {
    return BorrowRecord(
      id: map['id'],
      userId: map['user_id'],
      bookId: map['book_id'],
      status: map['status'] ?? 'pending',
      requestDate: DateTime.parse(map['request_date']),
      approvedDate: map['approved_date'] != null ? DateTime.parse(map['approved_date']) : null,
      borrowDate: map['borrow_date'] != null ? DateTime.parse(map['borrow_date']) : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      returnDate: map['return_date'] != null ? DateTime.parse(map['return_date']) : null,
      approvedBy: map['approved_by'],
      notes: map['notes'],
      isOverdue: (map['is_overdue'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
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
      'return_date': returnDate?.toIso8601String(),
      'approved_by': approvedBy,
      'notes': notes,
      'is_overdue': isOverdue ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}