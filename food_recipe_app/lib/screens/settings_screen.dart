import 'package:flutter/material.dart';
import 'package:food_recipe_app/core/app_theme.dart';
import 'package:food_recipe_app/screens/splash_screen.dart';
import 'package:food_recipe_app/screens/update_user_details_screen.dart';
import 'package:food_recipe_app/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.signOut();
    } catch (_) {
      // Navigation back to splash should still happen.
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textDark,
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.manage_accounts_rounded,
                  title: 'User details update',
                  subtitle: 'Edit your name, bio, and profile image.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UpdateUserDetailsScreen(),
                      ),
                    );
                  },
                ),
                Divider(color: AppColors.cardBorder, height: 1),
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out and return to the splash screen.',
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.mutedBeige,
        child: Icon(icon, color: AppColors.primaryGreen),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textDark.withValues(alpha: 0.6),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.primaryGreen,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }
}
