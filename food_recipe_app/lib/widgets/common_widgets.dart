import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_recipe_app/core/app_theme.dart';

class AssetImageWithFallback extends StatelessWidget {
  const AssetImageWithFallback({
    super.key,
    required this.assetPath,
    required this.fallback,
  });

  final String assetPath;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class RoundedInput extends StatelessWidget {
  const RoundedInput({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.keyboardType,
  });

  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.primaryGreen.withValues(alpha: 0.75)),
        prefixIcon: Icon(icon, color: AppColors.mutedBeige),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        label: const Text('Sign up with Google'),
      ),
    );
  }
}

class RecipeNetworkImage extends StatelessWidget {
  const RecipeNetworkImage({
    super.key,
    required this.imageUrl,
    required this.height,
    this.borderRadius,
  });

  final String imageUrl;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppColors.primaryGreen.withValues(alpha: 0.75),
        ),
      ),
    );

    final error = Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        size: 32,
        color: Colors.grey,
      ),
    );

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => error,
      memCacheHeight: height >= 300 ? 720 : 320,
    );

    if (borderRadius == null) return image;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
    this.backgroundColor = AppColors.primaryGreen,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final trimmedPhotoUrl = photoUrl?.trim();
    if (trimmedPhotoUrl != null && trimmedPhotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor.withValues(alpha: 0.12),
        backgroundImage: CachedNetworkImageProvider(trimmedPhotoUrl),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String value) {
    final pieces = value
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);

    if (pieces.isEmpty) return 'C';
    return pieces
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
  }
}
