import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider()
      : _themeMode = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
      ? ThemeMode.dark
      : ThemeMode.light;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFFF4511E), // Vibrant orange as primary
      secondary: const Color(0xFFFFB300), // Amber as secondary/accent
      surface: const Color(0xFFFFF3E0), // Light orange-tinted surface
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.black87,
      error: const Color(0xFFD32F2F), // Deep red for errors
      errorContainer: const Color(0xFFFF8A65), // Soft orange for error containers
      surfaceContainer: const Color(0xFFFFE0B2), // Light orange container
      surfaceContainerHigh: const Color(0xFFFFD180), // Slightly darker orange
      outlineVariant: const Color(0xFFE0E0E0), // Neutral gray for outlines
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF3E0), // Light orange background
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFF3E2723)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF3E2723)),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF3E2723)),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF3E2723)), // Dark brown for icons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFFF4511E)), // Orange buttons
        foregroundColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevation: WidgetStateProperty.all(2),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFF4511E), // Orange FAB
      foregroundColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFFF4511E), // Orange app bar
      foregroundColor: Colors.white,
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFFF5722), // Slightly brighter orange for dark mode
      secondary: const Color(0xFFFFCA28), // Brighter amber for dark mode
      surface: const Color(0xFF3E2723), // Dark brown surface
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.white,
      error: const Color(0xFFEF5350), // Red accent for errors
      errorContainer: const Color(0xFFE64A19), // Darker orange for error containers
      surfaceContainer: const Color(0xFF4E342E), // Darker brown container
      surfaceContainerHigh: const Color(0xFF5D4037), // Slightly lighter brown
      outlineVariant: const Color(0xFF757575), // Gray for outlines
    ),
    scaffoldBackgroundColor: const Color(0xFF3E2723), // Dark brown background
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
    ),
    iconTheme: const IconThemeData(color: Colors.white), // White icons for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFFFF5722)), // Brighter orange buttons
        foregroundColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevation: WidgetStateProperty.all(2),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF5722), // Brighter orange FAB
      foregroundColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFFFF5722), // Orange app bar
      foregroundColor: Colors.white,
    ),
  );
}