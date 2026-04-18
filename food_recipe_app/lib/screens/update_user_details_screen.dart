import 'package:flutter/material.dart';
import 'package:food_recipe_app/core/app_theme.dart';
import 'package:food_recipe_app/data/user_repository.dart';
import 'package:food_recipe_app/models/user_profile.dart';
import 'package:food_recipe_app/widgets/common_widgets.dart';

class UpdateUserDetailsScreen extends StatefulWidget {
  const UpdateUserDetailsScreen({super.key});

  @override
  State<UpdateUserDetailsScreen> createState() => _UpdateUserDetailsScreenState();
}

class _UpdateUserDetailsScreenState extends State<UpdateUserDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserRepository.instance.fetchCurrentUserProfile();
    if (!mounted) return;

    _applyProfile(profile);
    setState(() => _isLoading = false);
  }

  void _applyProfile(UserProfile? profile) {
    if (profile == null) return;
    _nameController.text = profile.displayName;
    _photoUrlController.text = profile.photoUrl ?? '';
    _bioController.text = profile.bio ?? '';
    _email = profile.email;
  }

  Future<void> _saveProfile() async {
    final displayName = _nameController.text.trim();
    if (displayName.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await UserRepository.instance.updateCurrentUserProfile(
        displayName: displayName,
        photoUrl: _photoUrlController.text.trim(),
        bio: _bioController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('Details updated.');
      Navigator.of(context).pop();
    } catch (e) {
      _showMessage('Could not update details: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
        title: const Text('User Details Update'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      UserAvatar(
                        name: _nameController.text.isNotEmpty ? _nameController.text : 'Chef',
                        photoUrl: _photoUrlController.text.trim().isEmpty
                            ? null
                            : _photoUrlController.text.trim(),
                        radius: 42,
                      ),
                      const SizedBox(height: 18),
                      RoundedInput(
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),
                      RoundedInput(
                        hint: 'Photo URL',
                        icon: Icons.image_outlined,
                        controller: _photoUrlController,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Bio',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 44),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.mutedBeige,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email: ${_email.isEmpty ? 'Not available' : _email}',
                          style: TextStyle(
                            color: AppColors.textDark.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isSaving ? 'Saving...' : 'Save Changes',
                  onTap: _isSaving ? () {} : _saveProfile,
                ),
              ],
            ),
    );
  }
}
