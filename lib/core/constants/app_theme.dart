import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFFE0BD6A),
      onPrimary: Color(0xFF1A1404),
      secondary: Color(0xFFD1CEBF),
      surface: Color(0xFFFAF9F6),
      onSurface: Color(0xFF2D2D2A),
      outline: Color(0xFFE9E5DC),
      outlineVariant: Color(0xFFD7D2C5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF5F2ED),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFFE0BD6A),
      onPrimary: Color(0xFF1A1404),
      secondary: Color(0xFF2B2B2D),
      onSecondary: Color(0xFFE8E8E8),
      surface: Color(0xFF101113),
      onSurface: Color(0xFFF2F2F2),
      outline: Color(0xFF2A2A2A),
      outlineVariant: Color(0xFF1B1B1B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF030303),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF2F2F2),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121316),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF1D1D1D)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF161719),
        indicatorColor: Color(0x33E0BD6A),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF2F2F2),
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF2F2F2),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE2E2E2),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFCFCFCF),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0BD6A),
        ),
      ),
    );
  }
}
