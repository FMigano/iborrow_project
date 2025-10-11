class Penalty {
  final String id;
  final String userId;
  final String bookId; // ✅ Add this field
  final String borrowRecordId;
  final double amount;
  final String reason;
  final String status;
  final DateTime? paidDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Penalty({
    required this.id,
    required this.userId,
    required this.bookId, // ✅ Add this parameter
    required this.borrowRecordId,
    required this.amount,
    required this.reason,
    required this.status,
    this.paidDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Penalty.fromMap(Map<String, dynamic> map) {
    return Penalty(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      bookId: map['book_id'] ?? '', // ✅ Add this
      borrowRecordId: map['borrow_record_id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? '',
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId, // ✅ Add this
      'borrow_record_id': borrowRecordId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'paid_date': paidDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId, // ✅ Add this
      'borrow_record_id': borrowRecordId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'paid_at': paidDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Penalty.fromSupabaseMap(Map<String, dynamic> map) {
    return Penalty(
      id: map['id'],
      userId: map['user_id'],
      bookId: map['book_id'], // ✅ Add this
      borrowRecordId: map['borrow_record_id'],
      amount: map['amount'].toDouble(),
      reason: map['reason'],
      status: map['status'],
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Penalty copyWith({
    String? id,
    String? userId,
    String? bookId, // ✅ Add this
    String? borrowRecordId,
    double? amount,
    String? reason,
    String? status,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Penalty(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId, // ✅ Add this
      borrowRecordId: borrowRecordId ?? this.borrowRecordId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}