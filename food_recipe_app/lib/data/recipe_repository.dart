import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_recipe_app/models/recipe_comment.dart';
import 'package:food_recipe_app/models/recipe.dart';
import 'package:food_recipe_app/models/user_profile.dart';
import 'package:food_recipe_app/data/user_repository.dart';

class RecipeRepository {
  RecipeRepository._();
  static final RecipeRepository instance = RecipeRepository._();
  static final Random _random = Random();
  static final Map<String, Set<String>> _sessionSavedRecipeIdsByUser = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _firestore.collection('recipes');
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<List<Recipe>> fetchPopularRecipes({int limit = 10}) async {
    final snapshot = await _recipesRef
        .where('isPopular', isEqualTo: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
        .toList(growable: false);
  }

  Future<List<Recipe>> fetchRecipesByCategory(
    String category, {
    int limit = 10,
    bool randomized = false,
  }) async {
    final snapshot = await _recipesRef.where('category', isEqualTo: category).get();
    final recipes = snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
        .toList(growable: true);

    if (randomized) {
      recipes.shuffle(_random);
    }

    if (recipes.length > limit) {
      return recipes.take(limit).toList(growable: false);
    }

    return recipes.toList(growable: false);
  }

  Future<List<Recipe>> fetchNewestRecipesByCategory(
    String category, {
    int limit = 5,
  }) async {
    try {
      final snapshot = await _recipesRef
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final recipes = snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
          .toList(growable: false);

      if (recipes.isNotEmpty) return recipes;
    } catch (_) {
      // Fall back for older seeded docs that may not have createdAt or indexes.
    }

    return fetchRecipesByCategory(category, limit: limit);
  }

  Future<List<Recipe>> fetchPopularRecipesByCategory(
    String category, {
    int limit = 10,
  }) async {
    final snapshot = await _recipesRef
        .where('category', isEqualTo: category)
        .where('isPopular', isEqualTo: true)
        .get();

    final recipes = snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
        .toList(growable: true);

    recipes.shuffle(_random);

    if (recipes.length > limit) {
      return recipes.take(limit).toList(growable: false);
    }

    return recipes.toList(growable: false);
  }

  Future<List<Recipe>> fetchAllRecipes() async {
    final snapshot = await _recipesRef.get();
    final recipes = snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
        .toList(growable: true);
    recipes.sort(_sortRecipesByNewest);
    return recipes.toList(growable: false);
  }

  Future<Recipe?> fetchRecipeById(String id) async {
    final doc = await _recipesRef.doc(id).get();
    if (!doc.exists) return null;
    return Recipe.fromMap(doc.data()!, documentId: doc.id);
  }

  Future<List<Recipe>> fetchRecipesByCreator(String creatorId) async {
    try {
      final snapshot = await _recipesRef
          .where('creatorId', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
          .toList(growable: false);
    } catch (_) {
      final snapshot = await _recipesRef.where('creatorId', isEqualTo: creatorId).get();
      final recipes = snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
          .toList(growable: true);
      recipes.sort(_sortRecipesByNewest);
      return recipes.toList(growable: false);
    }
  }

  Future<List<Recipe>> fetchSavedRecipes(String userId) async {
    try {
      final savedSnapshot = await _usersRef
          .doc(userId)
          .collection('savedRecipes')
          .orderBy('savedAt', descending: true)
          .get();
      final recipes = await _mergeWithSessionSavedRecipes(
        userId,
        await _recipesFromSavedSnapshot(savedSnapshot),
      );
      return recipes;
    } catch (_) {
      try {
        final savedSnapshot = await _usersRef.doc(userId).collection('savedRecipes').get();
        final recipes = await _mergeWithSessionSavedRecipes(
          userId,
          await _recipesFromSavedSnapshot(savedSnapshot),
        );
        return recipes;
      } catch (_) {
        return _fetchSessionSavedRecipes(userId);
      }
    }
  }

  Future<bool> isRecipeSaved({
    required String userId,
    required String recipeId,
  }) async {
    try {
      final doc = await _usersRef.doc(userId).collection('savedRecipes').doc(recipeId).get();
      final exists = doc.exists;
      if (exists) {
        _sessionSavedRecipeIdsByUser.putIfAbsent(userId, () => <String>{}).add(recipeId);
      } else {
        _sessionSavedRecipeIdsByUser[userId]?.remove(recipeId);
      }
      return exists;
    } catch (_) {
      return _sessionSavedRecipeIdsByUser[userId]?.contains(recipeId) ?? false;
    }
  }

  Future<void> toggleSavedRecipe({
    required String userId,
    required Recipe recipe,
  }) async {
    final sessionSavedIds = _sessionSavedRecipeIdsByUser.putIfAbsent(
      userId,
      () => <String>{},
    );

    try {
      final ref = _usersRef.doc(userId).collection('savedRecipes').doc(recipe.id);
      final existing = await ref.get();
      if (existing.exists) {
        await ref.delete();
        sessionSavedIds.remove(recipe.id);
        return;
      }

      await ref.set({
        'recipeId': recipe.id,
        'title': recipe.title,
        'imageUrl': recipe.imageUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });
      sessionSavedIds.add(recipe.id);
    } catch (_) {
      if (sessionSavedIds.contains(recipe.id)) {
        sessionSavedIds.remove(recipe.id);
      } else {
        sessionSavedIds.add(recipe.id);
      }
    }
  }

  Stream<List<RecipeComment>> watchComments(String recipeId) {
    return _recipesRef
        .doc(recipeId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RecipeComment.fromMap(
                  doc.data(),
                  id: doc.id,
                  recipeId: recipeId,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<void> addComment({
    required String recipeId,
    required String message,
    String? parentCommentId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Please sign in to comment.');
    }

    final profile = await _resolveCurrentUserProfile(currentUser);
    final recipe = await fetchRecipeById(recipeId);

    await _recipesRef.doc(recipeId).collection('comments').add({
      'recipeId': recipeId,
      'authorId': profile.uid,
      'authorName': profile.displayName,
      'authorPhotoUrl': profile.photoUrl,
      'message': message,
      'parentCommentId': parentCommentId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final creatorId = recipe?.creatorId.trim() ?? '';
    if (recipe != null && creatorId.isNotEmpty && creatorId != profile.uid) {
      try {
        await UserRepository.instance.createCommentNotification(
          recipientUserId: creatorId,
          actorId: profile.uid,
          actorName: profile.displayName,
          actorPhotoUrl: profile.photoUrl,
          recipeId: recipe.id,
          recipeTitle: recipe.title,
          commentText: message,
        );
      } catch (_) {
        // Keep comments working even if notifications fail to save.
      }
    }
  }

  Future<void> createRecipe(Recipe recipe, {bool isPopular = false}) async {
    final doc = _recipesRef.doc();
    final creator = await _resolveCurrentUserProfile(_auth.currentUser);
    final data = recipe
        .copyWith(
          id: doc.id,
          creatorId: creator.uid,
          creatorName: creator.displayName,
          creatorPhotoUrl: creator.photoUrl,
        )
        .toMap()
      ..addAll({
        'isPopular': isPopular,
        'createdAt': FieldValue.serverTimestamp(),
      });

    await doc.set(data);
  }

  Future<UserProfile> _resolveCurrentUserProfile(User? user) async {
    if (user == null) {
      return const UserProfile(
        uid: '',
        displayName: 'Chef',
        email: '',
      );
    }

    try {
      final snapshot = await _usersRef.doc(user.uid).get();
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          return UserProfile.fromMap(data, uid: user.uid);
        }
      }
    } catch (_) {
      // Use auth fallback below when Firestore is unavailable.
    }

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

  int _sortRecipesByNewest(Recipe a, Recipe b) {
    final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bCreated.compareTo(aCreated);
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

  Future<List<Recipe>> _recipesFromSavedSnapshot(
    QuerySnapshot<Map<String, dynamic>> savedSnapshot,
  ) async {
    if (savedSnapshot.docs.isEmpty) return const [];

    final savedDocs = savedSnapshot.docs.toList(growable: true)
      ..sort((a, b) {
        final aDate = _asDateTime(a.data()['savedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = _asDateTime(b.data()['savedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final savedRecipeIds = savedDocs.map((doc) => doc.id).toList(growable: false);
    final recipes = await Future.wait(savedRecipeIds.map(fetchRecipeById));
    return recipes.whereType<Recipe>().toList(growable: false);
  }

  Future<List<Recipe>> _fetchSessionSavedRecipes(String userId) async {
    final savedRecipeIds =
        _sessionSavedRecipeIdsByUser[userId]?.toList(growable: false) ?? const [];
    if (savedRecipeIds.isEmpty) return const [];

    final recipes = await Future.wait(savedRecipeIds.map(fetchRecipeById));
    return recipes.whereType<Recipe>().toList(growable: false);
  }

  Future<List<Recipe>> _mergeWithSessionSavedRecipes(
    String userId,
    List<Recipe> firestoreRecipes,
  ) async {
    final sessionSavedIds = _sessionSavedRecipeIdsByUser[userId] ?? const <String>{};
    final mergedIds = <String>{
      ...firestoreRecipes.map((recipe) => recipe.id),
      ...sessionSavedIds,
    };

    if (mergedIds.isEmpty) {
      _sessionSavedRecipeIdsByUser[userId] = <String>{};
      return const [];
    }

    final missingIds = mergedIds.difference(
      firestoreRecipes.map((recipe) => recipe.id).toSet(),
    );

    final missingRecipes = await Future.wait(missingIds.map(fetchRecipeById));
    final mergedRecipes = <Recipe>[
      ...firestoreRecipes,
      ...missingRecipes.whereType<Recipe>(),
    ];

    _sessionSavedRecipeIdsByUser[userId] =
        mergedRecipes.map((recipe) => recipe.id).toSet();

    return mergedRecipes;
  }
}
