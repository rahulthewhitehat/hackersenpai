import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_root_checker/flutter_root_checker.dart';
import 'package:mrcavirtuals/services/auth_service.dart';
import 'package:mrcavirtuals/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:secure_content/secure_content.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check if device is rooted...

  bool isDeviceRooted = false;

  if (Platform.isAndroid) {
    isDeviceRooted = FlutterRootChecker.isAndroidRoot;
    // Enable screenshot prevention for Android
    SecureContent().preventScreenshotAndroid(true);
  } else if (Platform.isIOS) {
    isDeviceRooted = FlutterRootChecker.isIosJailbreak;
  }

  if (isDeviceRooted) {
    // If device is rooted, show warning and exit
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RootedDeviceScreen(),
      ),
    );
  } else {
    runApp(
      Portal(
        child: MyApp(),
      ),
    );
  }
}

class RootedDeviceScreen extends StatelessWidget {
  const RootedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueAccent.shade400,
              Colors.blue.shade800,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      size: 64,
                      color: Colors.blueAccent.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Security Alert',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'For security reasons, this app cannot run on rooted or jailbroken devices. We prioritize the safety of our data. Kindly unroot or try using the app in another device',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Exit App',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => exit(0),
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
      ],
      child: MaterialApp(
        title: 'Mr CA Virtuals',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}