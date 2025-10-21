class Reservation {
  final String id;
  final String userId;
  final String bookId;
  final String status; // 'active', 'fulfilled', 'cancelled'
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? fulfilledAt;
  final DateTime? notifiedAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.bookId,
    this.status = 'active',
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.fulfilledAt,
    this.notifiedAt,
  });

  bool get isActive => status == 'active';
  bool get isFulfilled => status == 'fulfilled';
  bool get isCancelled => status == 'cancelled';

  Reservation copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? status,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? fulfilledAt,
    DateTime? notifiedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
    );
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      bookId: map['book_id'] ?? '',
      status: map['status'] ?? 'active',
      position: map['position'] ?? 0,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      fulfilledAt: map['fulfilled_at'] != null
          ? DateTime.parse(map['fulfilled_at'])
          : null,
      notifiedAt: map['notified_at'] != null
          ? DateTime.parse(map['notified_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'status': status,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'fulfilled_at': fulfilledAt?.toIso8601String(),
      'notified_at': notifiedAt?.toIso8601String(),
    };
  }

  factory Reservation.fromSupabaseMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      bookId: map['book_id'] ?? '',
      status: map['status'] ?? 'active',
      position: map['position'] ?? 0,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      fulfilledAt: map['fulfilled_at'] != null
          ? DateTime.parse(map['fulfilled_at'])
          : null,
      notifiedAt: map['notified_at'] != null
          ? DateTime.parse(map['notified_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'status': status,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'fulfilled_at': fulfilledAt?.toIso8601String(),
      'notified_at': notifiedAt?.toIso8601String(),
    };
  }
}
