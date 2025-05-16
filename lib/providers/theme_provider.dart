import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeKey = 'theme_mode';

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
  }

  // Define light theme
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: Colors.grey[100],
    colorScheme: ColorScheme.light(
      primary: Colors.blueAccent,
      secondary: Colors.cyanAccent,
      surface: Colors.white,
      onSurface: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
      surfaceContainerHighest: Colors.grey[300]!,
      outlineVariant: Colors.grey[300]!,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
    cardColor: Colors.white,
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    ),
    iconTheme: IconThemeData(color: Colors.grey[600]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  // Define dark theme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    colorScheme: ColorScheme.dark(
      primary: Colors.blueAccent,
      secondary: Colors.cyanAccent,
      surface: Colors.grey[800]!,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.black,
      surfaceContainerHighest: Colors.grey[700]!,
      outlineVariant: Colors.grey[600]!,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
    cardColor: Colors.grey[800],
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey[400],
      ),
    ),
    iconTheme: IconThemeData(color: Colors.grey[400]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}