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
  });
  factory Recipe.fromMap(Map<String, dynamic> map, {String? documentId}) {
  return Recipe(
    id: documentId ?? (map['id'] ?? '') as String,
    title: (map['title'] ?? '') as String,
    category: (map['category'] ?? '') as String,
    imageUrl: (map['imageUrl'] ?? '') as String,
    rating: (map['rating'] ?? 0).toDouble(),
    description: (map['description'] ?? '') as String,
    durationMinutes: (map['durationMinutes'] ?? 0) as int,
    calories: (map['calories'] ?? 0) as int,
    difficulty: (map['difficulty'] ?? '') as String,
    origin: (map['origin'] ?? '') as String,
    ingredients: List<String>.from(map['ingredients'] ?? const []),
    steps: List<String>.from(map['steps'] ?? const []),
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
  );
}

}
