import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/device_info_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Sign in with email and password with device verification
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();

      if (!userDoc.exists) {
        // User doesn't exist in Firestore, sign them out and return null
        await _auth.signOut();
        throw Exception('User not registered');
      }

      // Verify device after successful authentication
      final deviceVerified = await verifyDeviceAccess(result.user!.uid);
      if (!deviceVerified) {
        // Sign out if device verification fails
        await _auth.signOut();
        throw Exception('This account is already registered on another device');
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      // Let the specific Firebase error be handled by the provider
      throw e;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google with device verification
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('sign_in_failed');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        // User doesn't exist in Firestore, sign them out and return null
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw Exception('User not registered');
      }

      // Verify device after successful authentication
      final deviceVerified = await verifyDeviceAccess(userCredential.user!.uid);
      if (!deviceVerified) {
        // Sign out if device verification fails
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw Exception('This account is already registered on another device');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      throw e;
    } catch (e) {
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  // Verify and register device
  Future<bool> verifyDeviceAccess(String userId) async {
    try {
      // Get unique device ID
      final currentDeviceId = await _deviceInfoService.getUniqueDeviceId();

      // Guard against empty device IDs
      if (currentDeviceId.isEmpty || currentDeviceId == 'unknown' ||
          currentDeviceId == 'unknown_platform') {
        return false;
      }

      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      // If no unique_id stored yet (first login)
      if (userData == null || !userData.containsKey('unique_id') ||
          userData['unique_id'] == null || userData['unique_id'].toString().isEmpty) {
        // Register this device as the authorized device
        await _firestore.collection('users').doc(userId).update({
          'unique_id': currentDeviceId,
          'last_login': FieldValue.serverTimestamp(),
        });
        return true;
      }

      // Check if current device matches registered device
      final storedDeviceId = userData['unique_id'];
      final isMatch = storedDeviceId == currentDeviceId;

      // Update last login time if device verification passed
      if (isMatch) {
        await _firestore.collection('users').doc(userId).update({
          'last_login': FieldValue.serverTimestamp(),
        });
      }

      return isMatch;
    } catch (e) {
      // Log the error for debugging
      print('Device verification error: $e');
      // If error occurs during verification, fail safe
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Continue sign out process even if Google sign out fails
      print('Google sign out error: $e');
    }
    return await _auth.signOut();
  }
}