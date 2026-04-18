import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_recipe_app/models/app_notification.dart';
import 'package:food_recipe_app/models/user_profile.dart';

class UserRepository {
  UserRepository._();

  static final UserRepository instance = UserRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      _usersRef.doc(uid).collection('notifications');

  Future<UserProfile?> fetchUserProfile(String uid) async {
    try {
      final snapshot = await _usersRef.doc(uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(snapshot.data()!, uid: uid);
      }
    } catch (_) {
      // Fall back to auth data below when available.
    }

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      return _profileFromAuth(currentUser);
    }

    return null;
  }

  Future<UserProfile?> fetchCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    return fetchUserProfile(currentUser.uid);
  }

  Future<void> updateCurrentUserProfile({
    required String displayName,
    String? photoUrl,
    String? bio,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await currentUser.updateDisplayName(displayName);
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      await currentUser.updatePhotoURL(photoUrl.trim());
    }

    await _usersRef.doc(currentUser.uid).set({
      'uid': currentUser.uid,
      'email': currentUser.email,
      'displayName': displayName,
      'photoUrl': photoUrl?.trim().isNotEmpty == true
          ? photoUrl!.trim()
          : currentUser.photoURL,
      'bio': bio,
      'provider': currentUser.providerData.isNotEmpty
          ? currentUser.providerData.first.providerId
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _notificationsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  Future<List<AppNotification>> fetchNotifications(String uid) async {
    try {
      final snapshot = await _notificationsRef(uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), id: doc.id))
          .toList(growable: false);
    } catch (_) {
      final snapshot = await _notificationsRef(uid).get();
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), id: doc.id))
          .toList(growable: true);
      notifications.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return notifications.toList(growable: false);
    }
  }

  Future<void> createCommentNotification({
    required String recipientUserId,
    required String actorId,
    required String actorName,
    String? actorPhotoUrl,
    required String recipeId,
    required String recipeTitle,
    required String commentText,
  }) async {
    final trimmedComment = commentText.trim();
    await _notificationsRef(recipientUserId).add({
      'type': 'recipe_comment',
      'title': 'New comment on your recipe',
      'body': trimmedComment,
      'actorId': actorId,
      'actorName': actorName,
      'actorPhotoUrl': actorPhotoUrl,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationsAsRead(String uid) async {
    try {
      final notifications = await fetchNotifications(uid);
      final unread = notifications.where((item) => !item.isRead).toList(growable: false);
      if (unread.isEmpty) return;

      final batch = _firestore.batch();
      for (final notification in unread) {
        batch.update(_notificationsRef(uid).doc(notification.id), {'isRead': true});
      }
      await batch.commit();
    } catch (_) {
      // Keep notifications screen usable even if marking as read fails.
    }
  }

  UserProfile _profileFromAuth(User user) {
    final email = user.email ?? '';
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (email.contains('@') ? email.split('@').first : 'Chef');

    return UserProfile(
      uid: user.uid,
      displayName: displayName,
      email: email,
      photoUrl: user.photoURL,
      provider: user.providerData.isNotEmpty ? user.providerData.first.providerId : null,
    );
  }
}
