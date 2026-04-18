import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_recipe_app/core/app_theme.dart';
import 'package:food_recipe_app/data/recipe_repository.dart';
import 'package:food_recipe_app/models/recipe.dart';
import 'package:food_recipe_app/screens/recipe_detail_screen.dart';
import 'package:food_recipe_app/widgets/common_widgets.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  late Future<List<Recipe>> _savedRecipesFuture;

  @override
  void initState() {
    super.initState();
    _savedRecipesFuture = _loadSavedRecipes();
  }

  Future<List<Recipe>> _loadSavedRecipes() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Future.value(const []);
    return RecipeRepository.instance.fetchSavedRecipes(userId);
  }

  Future<void> _refresh() async {
    final future = _loadSavedRecipes();
    setState(() {
      _savedRecipesFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Saved Recipes',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: currentUser == null
          ? const _EmptyState(
              title: 'Sign in to save recipes',
              subtitle: 'Your personal saved list will appear here.',
            )
          : RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: _refresh,
              child: FutureBuilder<List<Recipe>>(
                future: _savedRecipesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const _EmptyState(
                      title: 'Could not load saved recipes',
                      subtitle: 'Please try again in a moment.',
                    );
                  }

                  final recipes = snapshot.data ?? const [];
                  if (recipes.isEmpty) {
                    return const _EmptyState(
                      title: 'No saved recipes yet',
                      subtitle: 'Tap the save button on any recipe to keep it here.',
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return _SavedRecipeTile(
                        recipe: recipe,
                        onOpen: _refresh,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _SavedRecipeTile extends StatelessWidget {
  const _SavedRecipeTile({
    required this.recipe,
    required this.onOpen,
  });

  final Recipe recipe;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
            ),
          );
          await onOpen();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: RecipeNetworkImage(imageUrl: recipe.imageUrl, height: 92),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.category,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'By ${recipe.creatorName}',
                      style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text('${recipe.durationMinutes} Min'),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text('${recipe.calories} Cal'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.bookmark_outline_rounded,
                size: 54,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.65),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
