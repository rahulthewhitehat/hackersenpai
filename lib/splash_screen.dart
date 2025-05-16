import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mrcavirtuals/screens/dashboard_screen.dart';
import 'package:mrcavirtuals/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _particleController;
  late AnimationController _backgroundController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _particleScale;
  late Animation<double> _particleOpacity;
  Animation<Color?>? _backgroundColor;

  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Initialize particles
    for (int i = 0; i < 10; i++) { // Reduced particle count to improve performance
      _particles.add(Particle());
    }

    // Logo animation (scale + rotation)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Slightly faster for performance
    )..forward();

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoRotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOutBack),
      ),
    );

    // Title animation (fade + slide)
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Faster for performance
    )..forward();

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.easeOutBack,
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Adjusted for smoother performance
    )..repeat(reverse: true);

    _particleScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeInOut,
      ),
    );

    _particleOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeInOut,
      ),
    );

    // Background controller initialized, but color set in didChangeDependencies
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize background color animation here to access Theme.of(context)
    _backgroundColor = ColorTween(
      begin: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      end: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
    ).animate(_backgroundController);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _particleController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    await Future.delayed(const Duration(seconds: 2)); // Reduced delay for faster loading

    if (authProvider.isAuthenticated) {
      final success = await studentProvider.initializeStudent(authProvider.user!.uid);
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      } else if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColor?.value ?? Theme.of(context).colorScheme.primary.withOpacity(0.1),
          body: Stack(
            children: [
              // Floating particles background
              ..._particles.map((particle) {
                return Positioned(
                  left: particle.x * MediaQuery.of(context).size.width,
                  top: particle.y * MediaQuery.of(context).size.height,
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _particleScale.value,
                        child: Opacity(
                          opacity: _particleOpacity.value * particle.opacity,
                          child: Container(
                            width: particle.size,
                            height: particle.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with particles
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3 * _logoController.value),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Main logo
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: Transform.rotate(
                                angle: _logoRotation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(4, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: 80,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Animated Title
                    AnimatedBuilder(
                      animation: _titleController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleFade,
                            child: Text(
                              'Mr CA Virtuals',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                  ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // Modern loading animation
                    SizedBox(
                      width: 100,
                      height: 4,
                      child: AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary.withOpacity(_particleOpacity.value),
                              ),
                              value: _particleController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;

  Particle()
      : x = _random.nextDouble(),
        y = _random.nextDouble(),
        size = 5 + _random.nextDouble() * 10, // Smaller particles for performance
        opacity = 0.2 + _random.nextDouble() * 0.6,
        speed = 0.5 + _random.nextDouble() * 1.5;

  static final Random _random = Random();
}