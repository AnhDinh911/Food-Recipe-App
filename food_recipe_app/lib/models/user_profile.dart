class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.provider,
    this.bio,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? provider;
  final String? bio;

  factory UserProfile.fromMap(Map<String, dynamic> map, {required String uid}) {
    final email = (map['email'] ?? '') as String;
    final displayName = (map['displayName'] ?? '') as String;

    return UserProfile(
      uid: uid,
      displayName: displayName.trim().isNotEmpty
          ? displayName.trim()
          : _displayNameFromEmail(email),
      email: email,
      photoUrl: map['photoUrl'] as String?,
      provider: map['provider'] as String?,
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'bio': bio,
    };
  }

  String get initials {
    final parts = displayName
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);

    if (parts.isEmpty) return 'C';
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  static String _displayNameFromEmail(String email) {
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Chef';
  }
}
