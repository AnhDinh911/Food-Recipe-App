class Recipe {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final double rating;
  final String description;
  final int durationMinutes;
  final int calories;
  final String difficulty;
  final String origin;
  final List<String> ingredients;
  final List<String> steps;
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoUrl;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.description,
    required this.durationMinutes,
    required this.calories,
    required this.difficulty,
    required this.origin,
    required this.ingredients,
    required this.steps,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhotoUrl,
    this.createdAt,
  });

  factory Recipe.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Recipe(
      id: documentId ?? (map['id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      rating: _asDouble(map['rating']),
      description: (map['description'] ?? '') as String,
      durationMinutes: _asInt(map['durationMinutes']),
      calories: _asInt(map['calories']),
      difficulty: (map['difficulty'] ?? '') as String,
      origin: (map['origin'] ?? '') as String,
      ingredients: List<String>.from(map['ingredients'] ?? const []),
      steps: List<String>.from(map['steps'] ?? const []),
      creatorId: (map['creatorId'] ?? '') as String,
      creatorName: (map['creatorName'] ?? 'Chef') as String,
      creatorPhotoUrl: map['creatorPhotoUrl'] as String?,
      createdAt: _asDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'description': description,
      'durationMinutes': durationMinutes,
      'calories': calories,
      'difficulty': difficulty,
      'origin': origin,
      'ingredients': ingredients,
      'steps': steps,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'createdAt': createdAt,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? category,
    String? imageUrl,
    double? rating,
    String? description,
    int? durationMinutes,
    int? calories,
    String? difficulty,
    String? origin,
    List<String>? ingredients,
    List<String>? steps,
    String? creatorId,
    String? creatorName,
    String? creatorPhotoUrl,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      calories: calories ?? this.calories,
      difficulty: difficulty ?? this.difficulty,
      origin: origin ?? this.origin,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final milliseconds = value is Map<String, dynamic> ? value['_seconds'] : null;
    if (milliseconds is int) {
      return DateTime.fromMillisecondsSinceEpoch(milliseconds * 1000);
    }
    try {
      final result = (value as dynamic).toDate();
      if (result is DateTime) return result;
    } catch (_) {
      // Fall back to string parsing below.
    }
    return DateTime.tryParse('$value');
  }

}
