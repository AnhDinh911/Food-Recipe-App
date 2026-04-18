class RecipeComment {
  const RecipeComment({
    required this.id,
    required this.recipeId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.message,
    this.parentCommentId,
    this.createdAt,
  });

  final String id;
  final String recipeId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String message;
  final String? parentCommentId;
  final DateTime? createdAt;

  bool get isReply => parentCommentId != null && parentCommentId!.isNotEmpty;

  factory RecipeComment.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String recipeId,
  }) {
    return RecipeComment(
      id: id,
      recipeId: recipeId,
      authorId: (map['authorId'] ?? '') as String,
      authorName: (map['authorName'] ?? 'Chef') as String,
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      message: (map['message'] ?? '') as String,
      parentCommentId: map['parentCommentId'] as String?,
      createdAt: _asDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'message': message,
      'parentCommentId': parentCommentId,
      'createdAt': createdAt,
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    try {
      final result = (value as dynamic).toDate();
      if (result is DateTime) return result;
    } catch (_) {
      // Fall back to string parsing below.
    }
    return DateTime.tryParse('$value');
  }
}
