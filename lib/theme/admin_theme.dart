import 'package:flutter/material.dart';

class AdminTheme {
  static const Color primary = Color(0xFF005C55); // Teal 
  static const Color primaryContainer = Color(0xFF0F766E);
  static const Color secondary = Color(0xFFF97416); // Orange
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0B1C30);
  static const Color textSecondary = Color(0xFF3E4947);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFBA1A1A);
  
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: outline, width: 1),
        ),
      ),
      useMaterial3: true,
    );
  }
  
  static ThemeData get darkThemeData {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF333333)),
      useMaterial3: true,
    );
  }
}
