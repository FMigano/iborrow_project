class Penalty {
  final String id;
  final String userId;
  final String borrowRecordId;
  final double amount;
  final String? reason;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  Penalty({
    required this.id,
    required this.userId,
    required this.borrowRecordId,
    required this.amount,
    this.reason,
    this.status = 'pending',
    this.paidAt,
    required this.createdAt,
  });

  factory Penalty.fromMap(Map<String, dynamic> map) {
    return Penalty(
      id: map['id'],
      userId: map['user_id'],
      borrowRecordId: map['borrow_record_id'],
      amount: map['amount'].toDouble(),
      reason: map['reason'],
      status: map['status'] ?? 'pending',
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'borrow_record_id': borrowRecordId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'borrow_record_id': borrowRecordId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Penalty.fromSupabaseMap(Map<String, dynamic> map) {
    return Penalty(
      id: map['id'],
      userId: map['user_id'],
      borrowRecordId: map['borrow_record_id'],
      amount: map['amount'].toDouble(),
      reason: map['reason'],
      status: map['status'],
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}