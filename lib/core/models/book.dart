class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String genre;
  final String? description;
  final String? imageUrl;
  final int totalCopies;
  final int availableCopies;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    required this.genre,
    this.description,
    this.imageUrl,
    this.totalCopies = 1,
    this.availableCopies = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => availableCopies > 0;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? genre,
    String? isbn,
    String? description,
    String? imageUrl,
    int? totalCopies,
    int? availableCopies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      isbn: isbn ?? this.isbn,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      genre: map['genre'] ?? '',
      isbn: map['isbn'],
      description: map['description'],
      imageUrl: map['image_url'],
      totalCopies: map['total_copies'] ?? 0,
      availableCopies: map['available_copies'] ?? 0,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'genre': genre,
      'description': description,
      'image_url': imageUrl,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Book.fromSupabaseMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      genre: map['genre'] ?? '',
      isbn: map['isbn'],
      description: map['description'],
      imageUrl: map['image_url'],
      totalCopies: map['total_copies'] ?? 0,
      availableCopies: map['available_copies'] ?? 0,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'genre': genre,
      'description': description,
      'image_url': imageUrl,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
