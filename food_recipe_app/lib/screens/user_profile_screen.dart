import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_recipe_app/core/app_theme.dart';
import 'package:food_recipe_app/data/recipe_repository.dart';
import 'package:food_recipe_app/data/user_repository.dart';
import 'package:food_recipe_app/models/recipe.dart';
import 'package:food_recipe_app/models/user_profile.dart';
import 'package:food_recipe_app/screens/recipe_detail_screen.dart';
import 'package:food_recipe_app/widgets/common_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const Duration _loadTimeout = Duration(seconds: 12);

  _UserProfileViewData? _viewData;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile(initialLoad: true);
  }

  Future<void> _loadProfile({bool initialLoad = false}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? currentUser?.uid;

    if (targetUserId == null) {
      if (!mounted) return;
      setState(() {
        _viewData = null;
        _isInitialLoading = false;
      });
      return;
    }

    if (initialLoad && mounted) {
      setState(() => _isInitialLoading = true);
    }

    UserProfile? profile;
    List<Recipe> recipes = const [];

    try {
      profile = await UserRepository.instance
          .fetchUserProfile(targetUserId)
          .timeout(_loadTimeout);
    } catch (_) {
      profile = null;
    }

    try {
      recipes = await RecipeRepository.instance
          .fetchRecipesByCreator(targetUserId)
          .timeout(_loadTimeout);
    } catch (_) {
      recipes = const [];
    }

    if (!mounted) return;
    setState(() {
      _viewData = _UserProfileViewData(
        profile: profile,
        recipes: recipes,
        isCurrentUser: currentUser?.uid == targetUserId,
      );
      _isInitialLoading = false;
    });
  }

  Future<void> _refresh() async {
    try {
      await _loadProfile();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh profile right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _viewData;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _refresh,
        child: _buildBody(data),
      ),
    );
  }

  Widget _buildBody(_UserProfileViewData? data) {
    if (_isInitialLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (data == null || data.profile == null) {
      return const _ProfileMessage(
        title: 'No profile available',
        subtitle: 'Sign in to see your cooking profile.',
      );
    }

    final profile = data.profile!;
    final recipeCount = data.recipes.length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              UserAvatar(
                name: profile.displayName,
                photoUrl: profile.photoUrl,
                radius: 44,
              ),
              const SizedBox(height: 16),
              Text(
                profile.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.65),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DetailPill(
                    icon: Icons.restaurant_menu_rounded,
                    label: '$recipeCount recipes shared',
                  ),
                  _DetailPill(
                    icon: Icons.verified_user_outlined,
                    label: _providerLabel(profile.provider),
                  ),
                  _DetailPill(
                    icon: Icons.info_outline_rounded,
                    label: profile.bio?.trim().isNotEmpty == true
                        ? profile.bio!.trim()
                        : 'Sharing favorite home-cooked meals',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          data.isCurrentUser ? 'Your Recipe Feed' : 'Recipe Feed',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        if (data.recipes.isEmpty)
          const _InlineProfileMessage(
            title: 'No recipes posted yet',
            subtitle: 'Recipes shared by this cook will appear here.',
          )
        else
          ...data.recipes.map(
            (recipe) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ProfileRecipeTile(recipe: recipe),
            ),
          ),
      ],
    );
  }

  String _providerLabel(String? provider) {
    switch (provider) {
      case 'google':
      case 'google.com':
        return 'Google member';
      case 'password':
        return 'Email member';
      default:
        return 'Community cook';
    }
  }
}

class _UserProfileViewData {
  const _UserProfileViewData({
    required this.profile,
    required this.recipes,
    required this.isCurrentUser,
  });

  final UserProfile? profile;
  final List<Recipe> recipes;
  final bool isCurrentUser;
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mutedBeige.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 16),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRecipeTile extends StatelessWidget {
  const _ProfileRecipeTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
            ),
          );
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
                  width: 100,
                  height: 100,
                  child: RecipeNetworkImage(imageUrl: recipe.imageUrl, height: 100),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(recipe.rating.toStringAsFixed(1)),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text('${recipe.durationMinutes} Min'),
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

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.person_outline_rounded,
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

class _InlineProfileMessage extends StatelessWidget {
  const _InlineProfileMessage({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_outline_rounded,
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
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
