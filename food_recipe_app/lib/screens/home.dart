import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart'; // Flutter Material UI widgets
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_recipe_app/core/app_theme.dart'; // App colors and asset paths
import 'package:food_recipe_app/data/recipe_repository.dart';
import 'package:food_recipe_app/data/user_repository.dart';
import 'package:food_recipe_app/models/app_notification.dart';
import 'package:food_recipe_app/models/recipe.dart';
import 'package:food_recipe_app/screens/notifications_screen.dart';
import 'package:food_recipe_app/screens/post_recipe_screen.dart';
import 'package:food_recipe_app/screens/recipe_detail_screen.dart';
import 'package:food_recipe_app/screens/saved_recipes_screen.dart';
import 'package:food_recipe_app/screens/settings_screen.dart';
import 'package:food_recipe_app/screens/user_profile_screen.dart';
import 'package:food_recipe_app/widgets/common_widgets.dart';
import 'package:food_recipe_app/widgets/recipe_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isActionMenuOpen = false;
  int _selectedTabIndex = 0;
  String _selectedCuisine = _cuisines.first.firestoreCategory;
  late Future<List<Recipe>> _categoryRecipesFuture;
  late Future<List<Recipe>> _featuredRecipesFuture;
  late Future<List<Recipe>> _popularRecipesFuture;
  late final PageController _pageController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  final Set<String> _seenNotificationIds = <String>{};
  bool _hasPrimedNotifications = false;
  bool _isSearchLoading = true;
  List<Recipe> _searchRecipes = const [];

  static const List<_CuisineOption> _cuisines = [
    _CuisineOption(label: 'Vietnamese', firestoreCategory: 'Vietnamese Food'),
    _CuisineOption(label: 'Chinese', firestoreCategory: 'Chinese Food'),
    _CuisineOption(label: 'Japanese', firestoreCategory: 'Japanese Food'),
    _CuisineOption(label: 'Italian', firestoreCategory: 'Italian Food'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _loadCuisineSections();
    _loadSearchRecipes();
    _bindNotificationStream();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _loadCuisineSections() {
    _categoryRecipesFuture = RecipeRepository.instance.fetchRecipesByCategory(
      _selectedCuisine,
      randomized: true,
    );
    _featuredRecipesFuture = RecipeRepository.instance.fetchNewestRecipesByCategory(
      _selectedCuisine,
    );
    _popularRecipesFuture = RecipeRepository.instance.fetchPopularRecipesByCategory(
      _selectedCuisine,
    );
  }

  Future<void> _loadSearchRecipes() async {
    try {
      final recipes = await RecipeRepository.instance.fetchAllRecipes();
      if (!mounted) return;
      setState(() {
        _searchRecipes = recipes;
        _isSearchLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearchLoading = false);
    }
  }

  void _bindNotificationStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _notificationsSubscription?.cancel();
    _notificationsSubscription =
        UserRepository.instance.watchNotifications(userId).listen((notifications) {
      if (!_hasPrimedNotifications) {
        _seenNotificationIds
          ..clear()
          ..addAll(notifications.map((item) => item.id));
        _hasPrimedNotifications = true;
        return;
      }

      final unseen = notifications
          .where((item) => !_seenNotificationIds.contains(item.id))
          .toList(growable: false);

      if (unseen.isEmpty || !mounted) return;

      _seenNotificationIds.addAll(unseen.map((item) => item.id));
      final latest = unseen.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            '${latest.actorName} commented on ${latest.recipeTitle ?? 'your recipe'}',
          ),
        ),
      );
    }, onError: (_) {
      // Ignore notification stream permission issues so home stays usable.
    });
  }

  void _toggleActionMenu() {
    setState(() => _isActionMenuOpen = !_isActionMenuOpen);
  }

  void _closeActionMenu() {
    if (_isActionMenuOpen) {
      setState(() => _isActionMenuOpen = false);
    }
  }

  Future<void> _selectTab(int index, {bool focusSearch = false}) async {
    _closeActionMenu();
    if (_selectedTabIndex != index) {
      setState(() => _selectedTabIndex = index);
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    if (focusSearch) {
      Future.delayed(const Duration(milliseconds: 40), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _openPostRecipe() async {
    _closeActionMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostRecipeScreen()),
    );
    setState(_loadCuisineSections);
    _loadSearchRecipes();
  }

  Future<void> _openSavedRecipes() async {
    _closeActionMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SavedRecipesScreen()),
    );
  }

  Future<void> _openUserProfile() async {
    _closeActionMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  }

  Future<void> _openSettings() async {
    _closeActionMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openNotifications() async {
    _closeActionMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = _displayName(user);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopGreeting(username: username),
                      const SizedBox(height: 18),
                      _SearchTriggerBar(
                        onTap: () => _selectTab(1, focusSearch: true),
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(title: 'Category'),
                      const SizedBox(height: 12),
                      _CategoryRow(
                        cuisines: _cuisines,
                        selectedCuisine: _selectedCuisine,
                        onSelected: (cuisine) {
                          setState(() {
                            _selectedCuisine = cuisine;
                            _loadCuisineSections();
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _RecipeCarousel(
                        key: ValueKey('category-$_selectedCuisine'),
                        future: _categoryRecipesFuture,
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle(title: 'Featured'),
                      const SizedBox(height: 12),
                      _RecipeCarousel(
                        key: ValueKey('featured-$_selectedCuisine'),
                        future: _featuredRecipesFuture,
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(title: 'Popular Recipes'),
                      const SizedBox(height: 12),
                      _RecipeCarousel(
                        key: ValueKey('popular-$_selectedCuisine'),
                        future: _popularRecipesFuture,
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: _SearchTab(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  isLoading: _isSearchLoading,
                  recipes: _searchRecipes,
                  onBackToHome: () => _selectTab(0),
                ),
              ),
            ],
          ),
          if (_isActionMenuOpen)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 90,
              child: GestureDetector(
                onTap: _closeActionMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedTabIndex: _selectedTabIndex,
        isActionMenuOpen: _isActionMenuOpen,
        onHomeTap: () => _selectTab(0),
        onSearchTap: () => _selectTab(1, focusSearch: true),
        onCenterTap: _toggleActionMenu,
        onMiddleTap: _openPostRecipe,
        onRightTap: _openSavedRecipes,
        onProfileTap: _openUserProfile,
        onNotificationTap: _openNotifications,
        onSettingsTap: _openSettings,
      ),
    );
  }

  String _displayName(User? user) {
    final fromProfile = user?.displayName?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;

    final fromEmail = user?.email?.trim();
    if (fromEmail != null && fromEmail.contains('@')) {
      return fromEmail.split('@').first;
    }
    return 'Chef';
  }
}

class _CuisineOption {
  const _CuisineOption({
    required this.label,
    required this.firestoreCategory,
  });

  final String label;
  final String firestoreCategory;
}

class _TopGreeting extends StatelessWidget {
  const _TopGreeting({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                username,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchTriggerBar extends StatelessWidget {
  const _SearchTriggerBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
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
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              'Search recipes',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.recipes,
    required this.onBackToHome,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final List<Recipe> recipes;
  final VoidCallback onBackToHome;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  String _query = '';
  _SearchFilter _selectedFilter = _SearchFilter.title;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant _SearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
      _query = widget.controller.text.trim();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final nextQuery = widget.controller.text.trim();
    if (nextQuery == _query) return;
    setState(() => _query = nextQuery);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.toLowerCase();
    final filteredRecipes = normalizedQuery.isEmpty
        ? widget.recipes
        : widget.recipes.where((recipe) {
            switch (_selectedFilter) {
              case _SearchFilter.title:
                return recipe.title.toLowerCase().contains(normalizedQuery);
              case _SearchFilter.category:
                return recipe.category.toLowerCase().contains(normalizedQuery);
              case _SearchFilter.rating:
                final minRating = double.tryParse(normalizedQuery);
                if (minRating == null) return false;
                return recipe.rating >= minRating;
              case _SearchFilter.calories:
                final maxCalories = int.tryParse(normalizedQuery);
                if (maxCalories == null) return false;
                return recipe.calories <= maxCalories;
            }
          }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBackToHome,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _selectedFilter.hintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: PopupMenuButton<_SearchFilter>(
                    tooltip: 'Filter search',
                    initialValue: _selectedFilter,
                    onSelected: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) {
                      return _SearchFilter.values
                          .map(
                            (filter) => PopupMenuItem<_SearchFilter>(
                              value: filter,
                              child: Text(filter.label),
                            ),
                          )
                          .toList(growable: false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _selectedFilter == _SearchFilter.title
                            ? Colors.grey
                            : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredRecipes.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? _selectedFilter.emptyPrompt : 'No recipes found',
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: filteredRecipes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final recipe = filteredRecipes[index];
                    return _SearchRecipeTile(recipe: recipe);
                  },
                ),
        ),
      ],
    );
  }
}

enum _SearchFilter {
  title(
    label: 'Title',
    hintText: 'Search by food title',
    emptyPrompt: 'Start typing to search recipes',
  ),
  category(
    label: 'Category',
    hintText: 'Search by category',
    emptyPrompt: 'Type a cuisine like Vietnamese or Italian',
  ),
  rating(
    label: 'Rating',
    hintText: 'Enter minimum rating, e.g. 4.0',
    emptyPrompt: 'Enter a minimum rating to filter recipes',
  ),
  calories(
    label: 'Calories',
    hintText: 'Enter max calories, e.g. 500',
    emptyPrompt: 'Enter a max calorie target to filter recipes',
  );

  const _SearchFilter({
    required this.label,
    required this.hintText,
    required this.emptyPrompt,
  });

  final String label;
  final String hintText;
  final String emptyPrompt;
}

class _SearchRecipeTile extends StatelessWidget {
  const _SearchRecipeTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: RecipeNetworkImage(imageUrl: recipe.imageUrl, height: 84),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.cuisines,
    required this.selectedCuisine,
    required this.onSelected,
  });

  final List<_CuisineOption> cuisines;
  final String selectedCuisine;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip(_CuisineOption cuisine) {
      final active = cuisine.firestoreCategory == selectedCuisine;

      return GestureDetector(
        onTap: () => onSelected(cuisine.firestoreCategory),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: active ? AppColors.primaryGreen : Colors.white,
          ),
          child: Text(
            cuisine.label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cuisines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return chip(cuisines[index]);
        },
      ),
    );
  }
}

class _RecipeCarousel extends StatelessWidget {
  const _RecipeCarousel({
    super.key,
    required this.future,
  });

  final Future<List<Recipe>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 260,
            child: Center(
              child: Text(
                'Failed to load recipes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final recipes = snapshot.data ?? const [];
        if (recipes.isEmpty) {
          return SizedBox(
            height: 260,
            child: Center(
              child: Text(
                'No recipes for this cuisine yet',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                key: ValueKey('recipe-card-${recipe.id}'),
                recipe: recipe,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedTabIndex,
    required this.isActionMenuOpen,
    required this.onHomeTap,
    required this.onSearchTap,
    required this.onCenterTap,
    required this.onMiddleTap,
    required this.onRightTap,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.onSettingsTap,
  });

  final int selectedTabIndex;
  final bool isActionMenuOpen;
  final VoidCallback onHomeTap;
  final VoidCallback onSearchTap;
  final VoidCallback onCenterTap;
  final VoidCallback onMiddleTap;
  final VoidCallback onRightTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final navHeight = isActionMenuOpen ? 220.0 : 92.0;
    final barContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FooterIconButton(
            icon: Icons.home_filled,
            isActive: selectedTabIndex == 0,
            onTap: onHomeTap,
          ),
          _FooterIconButton(
            icon: Icons.search,
            isActive: selectedTabIndex == 1,
            onTap: onSearchTap,
          ),
          const SizedBox(width: 54, height: 54),
          _FooterIconButton(
            icon: Icons.notifications_none_outlined,
            isActive: false,
            onTap: onNotificationTap,
          ),
          _FooterIconButton(
            icon: Icons.person_outline,
            isActive: false,
            onTap: onProfileTap,
          ),
        ],
      ),
    );

    return SizedBox(
      height: navHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          if (isActionMenuOpen)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 92,
                  color: Colors.white.withValues(alpha: 0.6),
                  child: barContent,
                ),
              ),
            )
          else
            Container(
              height: 92,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: barContent,
            ),
          _ActionButtonsOverlay(
            isOpen: isActionMenuOpen,
            onPostTap: onMiddleTap,
            onSavedTap: onRightTap,
            onSettingsTap: onSettingsTap,
          ),
          _CenterActionButton(
            isOpen: isActionMenuOpen,
            onTap: onCenterTap,
          ),
        ],
      ),
    );
  }
}

class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          icon,
          color: isActive ? AppColors.primaryGreen : Colors.grey,
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 18,
      child: Material(
        color: AppColors.primaryGreen,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen,
            ),
            child: Icon(
              isOpen ? Icons.close_rounded : Icons.restaurant_menu,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtonsOverlay extends StatelessWidget {
  const _ActionButtonsOverlay({
    required this.isOpen,
    required this.onPostTap,
    required this.onSavedTap,
    required this.onSettingsTap,
  });

  final bool isOpen;
  final VoidCallback onPostTap;
  final VoidCallback onSavedTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    Widget actionButton({
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icon, color: AppColors.primaryGreen),
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isOpen ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          offset: isOpen ? Offset.zero : const Offset(0, 0.2),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 92),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                actionButton(
                  icon: Icons.bookmarks_rounded,
                  onTap: onSavedTap,
                ),
                const SizedBox(width: 26),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: actionButton(
                    icon: Icons.post_add_rounded,
                    onTap: onPostTap,
                  ),
                ),
                const SizedBox(width: 26),
                actionButton(
                  icon: Icons.settings_outlined,
                  onTap: onSettingsTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
