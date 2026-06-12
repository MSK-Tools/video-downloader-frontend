import 'package:flutter/material.dart';

class MskColors {
  static const Color primary = Color(0xFF072B57);     // Deep Blue
  static const Color secondary = Color(0xFFF47A20);   // Vibrant Orange
  static const Color background = Color(0xFFFFFFFF);  // Pure White
  static const Color surface = Color(0xFFF5F6F8);     // Light Slate / Gray-White
  static const Color accent = Color(0xFFE53935);      // Accent Red
  
  static const Color textDark = Color(0xFF1E293B);    // Slate 800
  static const Color textLight = Color(0xFF64748B);   // Slate 500
  static const Color cardBg = Color(0xFFFFFFFF);
}

class MskTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MskColors.primary,
        primary: MskColors.primary,
        secondary: MskColors.secondary,
        error: MskColors.accent,
        background: MskColors.background,
        surface: MskColors.surface,
      ),
      scaffoldBackgroundColor: MskColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: MskColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: MskColors.cardBg,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MskColors.secondary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MskColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MskColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: MskColors.textLight),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: MskColors.textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: MskColors.textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MskColors.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: MskColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: MskColors.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: MskColors.textLight,
        ),
      ),
    );
  }
}
