import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// Firebase Auth Service (Auth + Firestore Profiles)
/// Fully migrated from Supabase
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  static const List<String> adminEmails = [
    'nextgenethiopia@gmail.com',
    'adminacadia@gmail.com'
    'firaoltadesa21@gmail.com'
  ];

  /// Sign Up with Email & Password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? grade,
    String? stream,
    String? academicPath,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'error': 'Failed to create user'};
      }

      // Update display name in Firebase
      await user.updateDisplayName(fullName);

      // Create profile in Firestore
      final isAdmin = adminEmails.contains(email.toLowerCase());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'grade': grade,
        'stream': stream,
        'academic_path': academicPath,
        'is_admin': isAdmin,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Send email verification
      await user.sendEmailVerification();

      return {
        'success': true,
        'user': user,
        'message': 'Verification email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFirebaseErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  /// Sign In with Email & Password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'error': 'Failed to sign in'};
      }

      // Check if email is verified (skip for hardcoded admins)
      final isHardcodedAdmin = adminEmails.contains(email.toLowerCase());
      if (!user.emailVerified && !isHardcodedAdmin) {
        return {
          'success': false,
          'error': 'Please verify your email before signing in.',
          'needsVerification': true,
        };
      }

      // Update last sign in
      await _firestore.collection('users').doc(user.uid).update({
        'last_sign_in': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFirebaseErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Reset Password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFirebaseErrorMessage(e)};
    }
  }

  /// Update Password
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user signed in'};
      }

      await user.updatePassword(newPassword);
      return {'success': true, 'message': 'Password updated successfully'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFirebaseErrorMessage(e)};
    }
  }

  /// Update Profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user signed in'};
      }

      if (fullName != null) {
        await user.updateDisplayName(fullName);
      }

      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to update profile: $e'};
    }
  }

  /// Resend Verification Email
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user signed in'};
      }

      await user.sendEmailVerification();
      return {
        'success': true,
        'message': 'Verification email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFirebaseErrorMessage(e)};
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      // Hardcoded admin emails bypass Firestore check
      if (user.email != null &&
          adminEmails.contains(user.email!.toLowerCase())) {
        return true;
      }

      // For other users, check Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['is_admin'] ?? false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Create profile if it doesn't exist (e.g. legacy users)
        final isAdmin = adminEmails.contains(user.email?.toLowerCase());
        final data = {
          'uid': user.uid,
          'email': user.email,
          'full_name': user.displayName ?? 'Student',
          'is_admin': isAdmin,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(user.uid).set(data);
        return data;
      }

      return doc.data();
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
