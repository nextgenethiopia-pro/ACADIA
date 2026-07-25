import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth Service (Auth + Firestore Profiles)
/// Stores rich ACADIA registration data in Firebase Auth + Firestore.
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  static const List<String> adminEmails = [
    'nextgenethiopia@gmail.com',
    'adminacadia@gmail.com',
    'firaoltadesa21@gmail.com',
  ];

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? grade,
    String? stream,
    String? academicPath,
    String? generation,
    String? university,
    String? universityYear,
    String? semester,
    String? track,
    String? highSchoolName,
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

      await user.updateDisplayName(fullName);

      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPath = _normalizeAcademicPath(academicPath);
      final normalizedGrade = _normalizeNullable(grade);
      final normalizedStream = _normalizeNullable(stream);
      final normalizedGeneration = _normalizeNullable(generation);
      final normalizedUniversity = _normalizeNullable(university);
      final normalizedUniversityYear = _normalizeNullable(universityYear);
      final normalizedSemester = _normalizeNullable(semester);
      final normalizedTrack = _normalizeNullable(track);
      final normalizedPhone = _normalizePhone(phoneNumber);
      final normalizedHighSchoolName = _normalizeNullable(highSchoolName);
      final isAdmin = adminEmails.contains(normalizedEmail);

      final profileData = <String, dynamic>{
        'uid': user.uid,
        'email': normalizedEmail,
        'full_name': fullName.trim(),
        'phone_number': normalizedPhone,
        'academic_path': normalizedPath,
        'academic_level': _academicLevelFromPath(normalizedPath),
        'grade': normalizedGrade,
        'stream': normalizedStream,
        'generation': normalizedGeneration,
        'selected_generation': normalizedGeneration,
        'university': normalizedUniversity,
        'selected_university': normalizedUniversity,
        'university_name': normalizedUniversity,
        'university_year': normalizedUniversityYear,
        'selected_year': normalizedUniversityYear,
        'semester': normalizedSemester,
        'track': normalizedTrack,
        'selected_track': normalizedTrack,
        'high_school_name': normalizedHighSchoolName,
        'is_admin': isAdmin,
        'is_email_verified': false,
        'is_profile_complete': true,
        'onboarding_complete': true,
        'registration_source': 'email_password',
        'device_binding_enabled': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      profileData.removeWhere((key, value) => value == null);

      await _firestore.collection('users').doc(user.uid).set(profileData);

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

      final isHardcodedAdmin = adminEmails.contains(email.toLowerCase());
      if (!user.emailVerified && !isHardcodedAdmin) {
        return {
          'success': false,
          'error': 'Please verify your email before signing in.',
          'needsVerification': true,
        };
      }

      await _firestore.collection('users').doc(user.uid).set({
        'last_sign_in': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_email_verified': user.emailVerified,
      }, SetOptions(merge: true));

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFirebaseErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

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

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? highSchoolName,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user signed in'};
      }

      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (fullName != null && fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
        updates['full_name'] = fullName.trim();
      }

      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        updates['avatar_url'] = avatarUrl.trim();
      }

      final normalizedPhone = _normalizePhone(phoneNumber);
      if (phoneNumber != null) {
        updates['phone_number'] = normalizedPhone;
      }

      if (highSchoolName != null) {
        updates['high_school_name'] = _normalizeNullable(highSchoolName);
      }

      updates.removeWhere((key, value) => value == null);

      await _firestore.collection('users').doc(user.uid).set(
            updates,
            SetOptions(merge: true),
          );

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to update profile: $e'};
    }
  }

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

  Future<bool> isAdmin() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      if (user.email != null &&
          adminEmails.contains(user.email!.toLowerCase())) {
        return true;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['is_admin'] ?? false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final isAdmin = adminEmails.contains(user.email?.toLowerCase());
        final data = <String, dynamic>{
          'uid': user.uid,
          'email': user.email,
          'full_name': user.displayName ?? 'Student',
          'is_admin': isAdmin,
          'is_email_verified': user.emailVerified,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(user.uid).set(data);
        return data;
      }

      final profile = doc.data()!;
      if (profile['is_email_verified'] != user.emailVerified) {
        await _firestore.collection('users').doc(user.uid).set({
          'is_email_verified': user.emailVerified,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        profile['is_email_verified'] = user.emailVerified;
      }

      return profile;
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  String? _normalizeNullable(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _normalizePhone(String? value) {
    final normalized = _normalizeNullable(value);
    if (normalized == null) return null;
    return normalized.replaceAll(RegExp(r'\s+'), '');
  }

  String? _normalizeAcademicPath(String? value) {
    final normalized = _normalizeNullable(value);
    if (normalized == null) return null;

    final upper = normalized.toUpperCase();
    if (upper == 'HIGH SCHOOL' || upper == 'HIGH_SCHOOL') {
      return 'HIGH SCHOOL';
    }
    if (upper == 'UNIVERSITY') {
      return 'UNIVERSITY';
    }
    return normalized;
  }

  String? _academicLevelFromPath(String? academicPath) {
    switch (academicPath) {
      case 'HIGH SCHOOL':
        return 'high_school';
      case 'UNIVERSITY':
        return 'university';
      default:
        return null;
    }
  }

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
