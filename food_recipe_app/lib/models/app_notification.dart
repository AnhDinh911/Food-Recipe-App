class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    this.recipeId,
    this.recipeTitle,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final String? recipeId;
  final String? recipeTitle;
  final DateTime? createdAt;
  final bool isRead;

  factory AppNotification.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AppNotification(
      id: id,
      type: (map['type'] ?? 'general') as String,
      title: (map['title'] ?? 'Notification') as String,
      body: (map['body'] ?? '') as String,
      actorId: (map['actorId'] ?? '') as String,
      actorName: (map['actorName'] ?? 'Chef') as String,
      actorPhotoUrl: map['actorPhotoUrl'] as String?,
      recipeId: map['recipeId'] as String?,
      recipeTitle: map['recipeTitle'] as String?,
      createdAt: _asDateTime(map['createdAt']),
      isRead: (map['isRead'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'actorId': actorId,
      'actorName': actorName,
      'actorPhotoUrl': actorPhotoUrl,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      final result = (value as dynamic).toDate();
      if (result is DateTime) return result;
    } catch (_) {
      // Fall back to string parsing below.
    }
    return DateTime.tryParse('$value');
  }
}
