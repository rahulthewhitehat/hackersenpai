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
      primary: Color(0xFFE63946),       // Vibrant red
      secondary: Color(0xFFF4A261),     // Warm orange
      tertiary: Color(0xFF2A9D8F),      // Earthy teal-green
      surface: Color(0xFFF8F9FA),       // Very light gray
      background: Color(0xFFFFFFFF),    // Pure white
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF212529),     // Dark gray for text
      error: Color(0xFFD62839),         // Darker red for errors
      errorContainer: Color(0xFFF77F00), // Bright orange for warnings
      surfaceContainer: Color(0xFFE9ECEF),  // Light gray container
      surfaceContainerHigh: Color(0xFFDEE2E6), // Slightly darker gray
      outlineVariant: Color(0xFFCED4DA),     // Border color
    ),
    scaffoldBackgroundColor: Color(0xFFF8F9FA),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFF212529)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212529)),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF495057)),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF6C757D)),
    ),
    iconTheme: IconThemeData(color: Color(0xFF495057)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Color(0xFFE63946)),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevation: WidgetStateProperty.all(2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFE63946),
      foregroundColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFFE63946)),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF212529),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFFF7B00),       // Bright orange
      secondary: Color(0xFFA7C957),      // Lime green
      tertiary: Color(0xFFD8F3DC),       // Mint green
      surface: Color(0xFF121212),       // Dark surface
      background: Color(0xFF000000),    // True black
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFFE9E9E9),     // Light gray for text
      error: Color(0xFFFF6B6B),        // Soft red
      errorContainer: Color(0xFFFFB700), // Golden yellow for warnings
      surfaceContainer: Color(0xFF1E1E1E),  // Dark container
      surfaceContainerHigh: Color(0xFF2A2A2A), // Slightly lighter container
      outlineVariant: Color(0xFF3D3D3D),     // Border color
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFFE9E9E9)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE9E9E9)),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFB5B5B5)),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF8A8A8A)),
    ),
    iconTheme: IconThemeData(color: Color(0xFFB5B5B5)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Color(0xFFFF7B00)),
        foregroundColor: WidgetStateProperty.all(Colors.black),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevation: WidgetStateProperty.all(2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF7B00),
      foregroundColor: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFFFF7B00)),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE9E9E9),
      ),
    ),
  );
}