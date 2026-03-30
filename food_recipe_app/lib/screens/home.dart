import 'package:flutter/material.dart'; // Flutter Material UI widgets
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_recipe_app/core/app_theme.dart'; // App colors and asset paths
import 'package:food_recipe_app/services/auth_service.dart'; // Firebase auth helper methods
import 'package:food_recipe_app/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = _displayName(user);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopGreeting(username: username),
              const SizedBox(height: 22),
              _SectionTitle(title: 'Featured'),
              const SizedBox(height: 12),
              const _FeaturedCards(),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Category', trailing: 'See All'),
              const SizedBox(height: 12),
              const _CategoryRow(),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Popular Recipes', trailing: 'See All'),
              const SizedBox(height: 12),
              const _PopularGrid(),
              const SizedBox(height: 22),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.shopping_cart_outlined,
            color: AppColors.textDark,
            size: 20,
          ),
        ),
      ],
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

class _FeaturedCards extends StatelessWidget {
  const _FeaturedCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _FeaturedCard(
            title: 'Asian White Noodle\nWith Extra Seafood',
            subtitle: '20 Min',
            accent: AppColors.primaryGreen,
          ),
          SizedBox(width: 14),
          _FeaturedCard(
            title: 'Healthy Salmon\nWith Fresh Herbs',
            subtitle: '25 Min',
            accent: AppColors.accentOrange,
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.85), AppColors.mutedBeige],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const CircleAvatar(radius: 10, backgroundColor: Colors.white),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, {bool active = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: active ? AppColors.primaryGreen : Colors.white,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Breakfast', active: true),
        const SizedBox(width: 10),
        chip('Lunch'),
        const SizedBox(width: 10),
        chip('Dinner'),
      ],
    );
  }
}

class _PopularGrid extends StatelessWidget {
  const _PopularGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _RecipeTile(
            title: 'Healthy Taco Salad',
            stats: '120 Kcal',
            color: AppColors.accentOrange,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _RecipeTile(
            title: 'Japanese-style Pancakes',
            stats: '64 Kcal',
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({
    required this.title,
    required this.stats,
    required this.color,
  });

  final String title;
  final String stats;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.9), AppColors.textDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_fire_department_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                stats,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.home_filled, color: AppColors.primaryGreen),
          const Icon(Icons.search, color: Colors.grey),
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen,
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white),
          ),
          const Icon(Icons.notifications_none_outlined, color: Colors.grey),
          const Icon(Icons.person_outline, color: Colors.grey),
        ],
      ),
    );
  }
}
