import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepBlue,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepBlue,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static BoxDecoration gradientBackground({Brightness? brightness}) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF1A1C99), // Darker blue
                const Color(0xFF5A1D99), // Darker purple
                const Color(0xFF4A0D7A), // Darker violet
              ]
            : [
                Color.lerp(AppColors.deepBlue, Colors.white, 0.1) ?? AppColors.deepBlue,
                Color.lerp(AppColors.purple, Colors.white, 0.2) ?? AppColors.purple,
                Color.lerp(AppColors.violet, Colors.white, 0.15) ?? AppColors.violet,
              ],
      ),
    );
  }

  static BoxDecoration neonButtonDecoration({bool isPressed = false}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.neonBlue, AppColors.neonPurple],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: isPressed
          ? []
          : [
              BoxShadow(
                color: AppColors.neonBlue.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
    );
  }
}

