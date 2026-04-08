import 'package:flutter/material.dart';
import 'package:food_recipe_app/core/app_theme.dart';
import 'package:food_recipe_app/data/recipe_repository.dart';
import 'package:food_recipe_app/models/recipe.dart';
import 'package:food_recipe_app/widgets/common_widgets.dart';

class PostRecipeScreen extends StatefulWidget {
  const PostRecipeScreen({super.key});

  @override
  State<PostRecipeScreen> createState() => _PostRecipeScreenState();
}

class _PostRecipeScreenState extends State<PostRecipeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();

  bool _isPopular = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _difficultyController.dispose();
    _originController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _submitRecipe() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final rating = double.tryParse(_ratingController.text.trim());
    final description = _descriptionController.text.trim();
    final durationMinutes = int.tryParse(_durationController.text.trim());
    final calories = int.tryParse(_caloriesController.text.trim());
    final difficulty = _difficultyController.text.trim();
    final origin = _originController.text.trim();
    final ingredients = _ingredientsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final steps = _stepsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (title.isEmpty ||
        category.isEmpty ||
        imageUrl.isEmpty ||
        rating == null ||
        description.isEmpty ||
        durationMinutes == null ||
        calories == null ||
        difficulty.isEmpty ||
        origin.isEmpty ||
        ingredients.isEmpty ||
        steps.isEmpty) {
      _showMessage('Please fill all fields with valid values.');
      return;
    }

    if (rating < 0 || rating > 5) {
      _showMessage('Rating must be between 0 and 5.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final recipe = Recipe(
        id: '',
        title: title,
        category: category,
        imageUrl: imageUrl,
        rating: rating,
        description: description,
        durationMinutes: durationMinutes,
        calories: calories,
        difficulty: difficulty,
        origin: origin,
        ingredients: ingredients,
        steps: steps,
      );

      await RecipeRepository.instance.createRecipe(recipe, isPopular: _isPopular);
      _showMessage('Recipe posted successfully.');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showMessage('Failed to post recipe: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.primaryGreen,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: 6),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFDDEFCB),
                      ),
                      child: const Icon(
                        Icons.post_add_rounded,
                        size: 82,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Post Recipe',
                      style: TextStyle(
                        fontSize: 44,
                        color: AppColors.primaryGreen,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your recipe with everyone',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryGreen.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              RoundedInput(
                hint: 'Recipe Title',
                icon: Icons.restaurant_menu_rounded,
                controller: _titleController,
              ),
              const SizedBox(height: 14),
              RoundedInput(
                hint: 'Category (e.g. Breakfast)',
                icon: Icons.category_outlined,
                controller: _categoryController,
              ),
              const SizedBox(height: 14),
              RoundedInput(
                hint: 'Image URL',
                icon: Icons.image_outlined,
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              RoundedInput(
                hint: 'Rating (0 - 5)',
                icon: Icons.star_outline_rounded,
                controller: _ratingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),
              RoundedInput(
                hint: 'Duration (minutes)',
                icon: Icons.access_time_rounded,
                controller: _durationController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              RoundedInput(
                hint: 'Calories',
                icon: Icons.local_fire_department_outlined,
                controller: _caloriesController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              RoundedInput(
                hint: 'Difficulty (e.g. Easy)',
                icon: Icons.bar_chart_rounded,
                controller: _difficultyController,
              ),
              const SizedBox(height: 14),
              RoundedInput(
                hint: 'Origin (e.g. Italy)',
                icon: Icons.place_outlined,
                controller: _originController,
              ),
              const SizedBox(height: 14),
              _MultiLineInput(
                hint: 'Description',
                icon: Icons.notes_rounded,
                controller: _descriptionController,
              ),
              const SizedBox(height: 14),
              _MultiLineInput(
                hint: 'Ingredients (one per line)',
                icon: Icons.checklist_rounded,
                controller: _ingredientsController,
              ),
              const SizedBox(height: 14),
              _MultiLineInput(
                hint: 'Steps (one per line)',
                icon: Icons.format_list_numbered_rounded,
                controller: _stepsController,
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                title: const Text(
                  'Mark as Popular Recipe',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: _isPopular,
                activeColor: AppColors.primaryGreen,
                onChanged: (value) => setState(() => _isPopular = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: _isLoading ? 'Posting...' : 'Post Recipe',
                onTap: _isLoading ? () {} : _submitRecipe,
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiLineInput extends StatelessWidget {
  const _MultiLineInput({
    required this.hint,
    required this.icon,
    required this.controller,
  });

  final String hint;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.primaryGreen.withValues(alpha: 0.75)),
        prefixIcon: Icon(icon, color: AppColors.mutedBeige),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
