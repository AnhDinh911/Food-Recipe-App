import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryBackground = Color(0xFFFFFFFF);
  static const Color primaryGreen = Color(0xFF1F8A8A);
  static const Color mutedBeige = Color(0xFFD5EFEF);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color textDark = Color(0xFF1A2238);
  static const Color cardBackground = Color(0xFFFBFBFB);
  static const Color cardBorder = Color(0x14C4C4C4);
  static const Color cardShadow = Color(0xFFC4C4C4);
}

class AppAssets {
  static const String splashFood = 'assets/images/splash.jpg';
  static const String loginFood = 'assets/images/login_food.jpg';
  static const String registerChef = 'assets/images/register_chef.png';
}

ThemeData buildAppTheme() {
  final baseTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.primaryBackground,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
  );

  return ThemeData(
    scaffoldBackgroundColor: AppColors.primaryBackground,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
    textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
    primaryTextTheme: GoogleFonts.poppinsTextTheme(baseTheme.primaryTextTheme),
    appBarTheme: baseTheme.appBarTheme.copyWith(
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
