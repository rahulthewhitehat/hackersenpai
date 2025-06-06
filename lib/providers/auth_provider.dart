import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSignOutMessage = false;

  AuthProvider(this._authService) {
    _user = _authService.currentUser;
    // Listen to auth state changes
    _authService.authStateChanges().listen((user) {
      if (_user != null && user == null) {
        // This indicates sign out occurred
        _showSignOutMessage = true;
      }
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get showSignOutMessage => _showSignOutMessage;

  // Clear sign out message flag once it's been displayed
  void clearSignOutMessage() {
    _showSignOutMessage = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _setError('Email and password cannot be empty');
      return false;
    }

    _setLoading(true);
    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(_parseFirebaseAuthError(e.toString()));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithGoogle();
      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(_parseFirebaseAuthError(e.toString()));
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _showSignOutMessage = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _parseFirebaseAuthError(String errorMessage) {
    if (errorMessage.contains('device')) {
      return 'This account is already registered on another device. Contact mail2mrca@gmail.com';
    } else if (errorMessage.contains('user-not-found') ||
        errorMessage.contains('User not registered')) {
      return 'Account not registered. Please contact admin.';
    } else if (errorMessage.contains('wrong-password') ||
        errorMessage.contains('incorrect') ||
        errorMessage.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Incorrect email or password. Please try again.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network connection error. Check your internet';
    } else if (errorMessage.contains('sign_in_failed')) {
      return 'Google sign in failed. Please try again.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Invalid email format';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed login attempts. Try again later.';
    } else {
      return 'Authentication failed. Please try again or contact admin.';
    }
  }
}