import 'package:flutter/material.dart';

class AppTheme {
  // Color Battle: Accessible Colors (WCAG 2.1 AA)
  static const Color primary = Color(0xFF1976D2); // Ratio 4.51:1 against white
  static const Color error = Color(0xFFD32F2F);   // Ratio 5.14:1 against white
  static const Color textMain = Color(0xFF212121); // Ratio 16:1 against white
  static const Color textSecondary = Color(0xFF757575); // Ratio 4.61:1 against white
  static const Color background = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primary,
        secondary: primary,
        error: error,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textMain, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primary,
        secondary: primary,
        error: error,
      ),
    );
  }
}
