import 'package:flutter/material.dart';

class CustomAppThemeData {
  CustomAppThemeData();

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.blue,
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      dividerColor: Colors.grey.withOpacity(0.5),
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF262626),
        //  primaryVariant: const Color(0xFF000000),
        secondary: Color(0xFF3897f0),
        // secondaryVariant: const Color(0xFF1e3a8a),
        surface: Color(0xFF121212),
        background: Color(0xFF000000),
        error: Color(0xFFed4956),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFFFFFFFF),
        onBackground: Color(0xFFFFFFFF),
        onError: Color(0xFFFFFFFF),
      ),
    );
  }
}
