import 'package:flutter/material.dart';

class AppColors {
  // Background colors
  static const Color lightBackground = Color(0xFFFAFAFC);
  static const Color darkBackground = Color(0xFF121212);

  // Primary text colors
  static const Color lightPrimaryText = Color(0xFF1A1A1A);
  static const Color darkPrimaryText = Color(0xFFE0E0E0);

  // Text colors (theme-aware)
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);

  // Additional color constants used in the app
  static const Color accentBlack = Color(0xFF000000);
  static const Color lightGrey = Color(0xFFBDBDBD);

  // Accent gradient colors
  static const Color accentStart = Color(0xFFFF4081); // vibrant magenta
  static const Color accentEnd = Color(0xFF7C4DFF);   // electric indigo

  // Secondary accent
  static const Color secondaryAccent = Color(0xFF00BFA5); // bright teal

  // Additional UI colors
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color darkCardColor = Color(0xFF252525);

  // Gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentStart, accentEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentStart,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightPrimaryText,
        onBackground: AppColors.lightPrimaryText,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightCardColor,
      
      // Typography
      textTheme: _buildTextTheme(AppColors.lightPrimaryText),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: AppColors.lightPrimaryText,
        ),
        iconTheme: IconThemeData(color: AppColors.lightPrimaryText),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.lightCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentStart,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentStart, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: AppColors.lightPrimaryText.withOpacity(0.6),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentStart,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentStart,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkPrimaryText,
        onBackground: AppColors.darkPrimaryText,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCardColor,
      
      // Typography
      textTheme: _buildTextTheme(AppColors.darkPrimaryText),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: AppColors.darkPrimaryText,
        ),
        iconTheme: IconThemeData(color: AppColors.darkPrimaryText),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.darkCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentStart,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentStart, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: AppColors.darkPrimaryText.withOpacity(0.6),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentStart,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Headings (Poppins Bold)
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: textColor,
      ),
      
      // Body text (Inter Regular)
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: textColor,
      ),
      
      // Captions & Monospace (Roboto Mono)
      labelLarge: const TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.w400,
        fontSize: 10,
      ),
    );
  }
} 