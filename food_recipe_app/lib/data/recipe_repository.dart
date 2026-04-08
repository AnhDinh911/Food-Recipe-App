import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_recipe_app/models/recipe.dart';

class RecipeRepository {
  RecipeRepository._();
  static final RecipeRepository instance = RecipeRepository._();
  static final Random _random = Random();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _firestore.collection('recipes');

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
    return snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data(), documentId: doc.id))
        .toList(growable: false);
  }

  Future<Recipe?> fetchRecipeById(String id) async {
    final doc = await _recipesRef.doc(id).get();
    if (!doc.exists) return null;
    return Recipe.fromMap(doc.data()!, documentId: doc.id);
  }

  Future<void> createRecipe(Recipe recipe, {bool isPopular = false}) async {
    final doc = _recipesRef.doc();
    final data = recipe.copyWith(id: doc.id).toMap()
      ..addAll({
        'isPopular': isPopular,
        'createdAt': FieldValue.serverTimestamp(),
      });

    await doc.set(data);
  }
}
