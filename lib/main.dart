import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_root_checker/flutter_root_checker.dart';
import 'package:hackersenpai/providers/quiz_provider.dart';
import 'package:hackersenpai/services/auth_service.dart';
import 'package:hackersenpai/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:secure_content/secure_content.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(
  );
  await Firebase.initializeApp(
    name: 'hackersenpai',
      options: DefaultFirebaseOptions.currentPlatform
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    if (availableVersion == null) {
      throw Exception('Failed to find an installed WebView2 runtime or non-stable Microsoft Edge installation.');
    }

    await WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(userDataFolder: 'custom_path'),
    );
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }


  bool isDeviceRooted = false;
  bool isEmulator = false;

  if (Platform.isAndroid) {
    // Check for root
    isDeviceRooted = FlutterRootChecker.isAndroidRoot;
    SecureContent().preventScreenshotAndroid(true);

    // Check for emulator
    isEmulator = await _isAndroidEmulator();
  } else if (Platform.isIOS) {
    // Check for jailbreak
    isDeviceRooted = FlutterRootChecker.isIosJailbreak;
  }

  // Deny access if device is rooted, jailbroken, or an emulator
  if (isDeviceRooted || isEmulator) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeProvider.lightTheme,
              darkTheme: ThemeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              home: RootedDeviceScreen(isEmulator: isEmulator), // Pass emulator flag
            );
          },
        ),
      ),
    );
  } else {
    runApp(
      Portal(
        child: const MyApp(),
      ),
    );
  }
}

// Function to detect Android emulator
Future<bool> _isAndroidEmulator() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;

  // Common emulator indicators
  final String model = androidInfo.model.toLowerCase();
  final String manufacturer = androidInfo.manufacturer.toLowerCase();
  final String brand = androidInfo.brand.toLowerCase();
  final String product = androidInfo.product.toLowerCase();
  final String hardware = androidInfo.hardware.toLowerCase();
  final String fingerprint = androidInfo.fingerprint.toLowerCase();

  // Check for known emulator properties
  return [
    // Generic emulator keywords
    model.contains('emulator'),
    model.contains('sdk_gphone'),
    model.contains('google_sdk'),
    manufacturer.contains('genymotion'),
    brand.contains('generic'),
    product.contains('emulator'),
    product.contains('sdk'),
    product.contains('vbox'),
    hardware.contains('goldfish'),
    hardware.contains('ranchu'),
    hardware.contains('vbox'),
    fingerprint.contains('generic'),
    // Specific emulator fingerprints
    androidInfo.isPhysicalDevice == false, // Most reliable check
  ].any((condition) => condition);
}

class RootedDeviceScreen extends StatelessWidget {
  final bool isEmulator; // Add emulator flag

  const RootedDeviceScreen({super.key, this.isEmulator = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Customize message based on emulator or rooted device
    final String message = isEmulator
        ? 'For security reasons, this app cannot run on emulators. Please use a physical device.'
        : 'For security reasons, this app cannot run on rooted or jailbroken devices. We prioritize the safety of our data. Kindly unroot or try using the app in another device';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            child: Material(
              borderRadius: BorderRadius.circular(24),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Security Alert',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                          foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          )),
                        ),
                        onPressed: () => exit(0),
                        child: Text(
                          'EXIT APP',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Mr CA Virtuals',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}