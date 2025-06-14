import 'package:flutter/material.dart';
import 'package:mrcavirtuals/screens/quiz_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import 'dashboard_screen.dart';
//import 'quiz_screen.dart'; // Add this import for your quiz screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Check if we have a sign out message to display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.showSignOutMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully signed out',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        authProvider.clearSignOutMessage();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && authProvider.user != null) {
      final studentInitialized = await studentProvider.initializeStudent(
          authProvider.user!.uid);

      if (studentInitialized && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              studentProvider.error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    if (success && authProvider.user != null) {
      final studentInitialized = await studentProvider.initializeStudent(
          authProvider.user!.uid);

      if (studentInitialized && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              studentProvider.error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _skipToQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QuizSelectionScreen(), // Replace with your actual quiz screen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo with neumorphic effect
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onSurface.withOpacity(isDarkMode ? 0.03 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      ),
                      BoxShadow(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(isDarkMode ? 0.5 : 0.7),
                        blurRadius: 10,
                        offset: const Offset(-4, -4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // App title with modern typography
                Text(
                  'Mr CA Virtuals',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle with subtle fade
                Text(
                  'Student Login',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Login form with modern inputs
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field with validation
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          labelText: 'Email',
                          labelStyle: theme.textTheme.bodyMedium,
                          prefixIcon: Icon(Icons.email, color: theme.iconTheme.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: isDarkMode ? Colors.white54 : Colors.black38,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password field with validation
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          labelText: 'Password',
                          labelStyle: theme.textTheme.bodyMedium,
                          prefixIcon: Icon(Icons.lock, color: theme.iconTheme.color),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: theme.iconTheme.color,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: isDarkMode ? Colors.white54 : Colors.black38,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login button with vibrant gradient and scale animation
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(isDarkMode ? 0.3 : 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.all(Colors.transparent),
                            shadowColor: WidgetStateProperty.all(Colors.transparent),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                          child: _isLoading
                              ? SpinKitThreeBounce(
                            color: theme.colorScheme.onPrimary,
                            size: 24,
                          )
                              : Text(
                            'Login',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // OR divider with sleek design
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.outlineVariant,
                              thickness: 1.2,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.outlineVariant,
                              thickness: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Google Sign-In with modern neumorphic style
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.onSurface.withOpacity(isDarkMode ? 0.03 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: theme.outlinedButtonTheme.style?.copyWith(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google-logo.png',
                                height: 24,
                                width: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sign in with Google',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Skip button for practicing quiz
                      TextButton(
                        onPressed: _isLoading ? null : _skipToQuiz,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Practice Quiz for free',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: theme.colorScheme.primary.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}