import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_model.dart';
import 'developer_welcome_notification.dart';
import 'session_service.dart';

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
    String? username,
    String? phoneNumber,
    String? academicLevel,
    String? academicPath,
    String? grade,
    String? stream,
    String? department,
    String? year,
    String? semester,
    Map<String, dynamic>? onboardingSelections,
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

      final normalizedEmail = email.trim().toLowerCase();
      final isAdmin = adminEmails.contains(normalizedEmail);

      await user.updateDisplayName(fullName);

      final now = DateTime.now();
      final normalizedAcademicLevel = (academicLevel?.trim().isNotEmpty == true)
          ? academicLevel!.trim()
          : (academicPath?.trim().isNotEmpty == true
              ? academicPath!.trim()
              : 'HIGH SCHOOL');

      final profileData = UserModel(
        id: user.uid,
        email: normalizedEmail,
        fullName: fullName.trim(),
        username: (username?.trim().isNotEmpty == true)
            ? username!.trim()
            : (normalizedEmail.isNotEmpty
                ? normalizedEmail.split('@')[0]
                : 'user${user.uid.substring(user.uid.length.clamp(0, 4))}'),
        phoneNumber: _normalizePhone(phoneNumber) ?? '',
        academicLevel: normalizedAcademicLevel,
        grade: _normalizeNullable(grade),
        stream: _normalizeNullable(stream),
        department: _normalizeNullable(department),
        year: _normalizeNullable(year),
        semester: _normalizeNullable(semester),
        onboardingSelections: onboardingSelections,
        selectedPackage: 'free',
        paymentStatus: 'free',
        accountStatus: isAdmin ? 'admin' : 'active',
        registrationDate: now,
        lastLogin: now,
        notificationPreferences: true,
        createdAt: now,
        updatedAt: now,
      );

      final userDocData = {
        ...profileData.toJson(),
        'academic_path': academicPath ?? normalizedAcademicLevel,
        'academicPath': academicPath ?? normalizedAcademicLevel,
        'is_admin': isAdmin,
        'is_email_verified': user.emailVerified,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userDocData, SetOptions(merge: true));

      // Send verification email AFTER profile is written to ensure
      // Firebase Auth session is fully established
      String? verificationEmailError;
      if (!isAdmin) {
        try {
          final freshUser = _firebaseAuth.currentUser ?? user;
          await freshUser.sendEmailVerification();
          debugPrint(
            '[signUp] verification email requested for ${user.email}',
          );
        } on FirebaseAuthException catch (e) {
          verificationEmailError = '${e.code}: ${e.message ?? 'no message'}';
          debugPrint(
            '[signUp] verification email FAILED: code=${e.code} '
            'message=${e.message}',
          );
        } catch (e, stackTrace) {
          verificationEmailError = e.toString();
          debugPrint('[signUp] verification email FAILED (non-auth): $e');
          debugPrint('$stackTrace');
        }
      }

      if (!isAdmin) {
        // One deterministic, user-scoped developer welcome per account. A
        // fixed document ID makes this idempotent if signup is ever retried.
        try {
          await DeveloperWelcomeNotification.ensureCreated(
            userId: user.uid,
            exists: (docId) async =>
                (await _firestore.collection('notifications').doc(docId).get())
                    .exists,
            create: (docId) => _firestore
                .collection('notifications')
                .doc(docId)
                .set({
              'target_user_id': user.uid,
              'title': 'Welcome to ACADIA 🎉',
              'message':
                  'Hi ${fullName.trim().split(' ').first}, I\'m Firaol Tadesa, '
                  'founder of NextGen Ethiopia and ACADIA. Thank you for joining. '
                  'Verify your email, then explore your lessons, quizzes, and '
                  'past papers. — The ACADIA team',
              'type': 'welcome',
              'is_read': false,
              'image_url': '',
              'created_by': 'NextGen ACADIA',
              'created_at': FieldValue.serverTimestamp(),
            }),
          );
        } catch (_) {
          // Non-critical — do not block signup if notification fails
        }
      }

      return {
        'success': true,
        'user': user,
        'needsVerification': !isAdmin,
        'verificationEmailError': verificationEmailError,
        'message': isAdmin
            ? 'Admin account created successfully.'
            : verificationEmailError == null
                ? 'Verification email sent. Please check your inbox.'
                : 'Account created, but the verification email could not be '
                    'sent ($verificationEmailError).',
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

      // One account = one registered device. The account is registered to the
      // first device that signs in; other devices are rejected until the
      // registered device signs out.
      final deviceLock = await SessionService.instance.claimDevice(user.uid);
      if (!deviceLock.granted) {
        await _firebaseAuth.signOut();
        return {
          'success': false,
          'error': SessionService.deviceLockedMessage,
          'deviceLocked': true,
        };
      }

      await _firestore.collection('users').doc(user.uid).set({
        'last_login': FieldValue.serverTimestamp(),
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
    final userId = _firebaseAuth.currentUser?.uid;

    // Securely release the device registration so the account can be used on
    // another device after signing out here.
    if (userId != null) {
      await SessionService.instance.releaseDevice(userId);
    }

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
    String? username,
    String? avatarUrl,
    String? phoneNumber,
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
      
      if (username != null && username.trim().isNotEmpty) {
        updates['username'] = username.trim();
      }

      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        updates['avatar_url'] = avatarUrl.trim();
      }

      final normalizedPhone = _normalizePhone(phoneNumber);
      if (phoneNumber != null) {
        updates['phone_number'] = normalizedPhone;
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
        final now = DateTime.now();
        final data = UserModel(
          id: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? 'Student',
          username: user.email?.split('@')[0] ?? 'student',
          accountStatus: 'active',
          registrationDate: now,
          lastLogin: now,
          createdAt: now,
          updatedAt: now,
          academicLevel: 'HIGH SCHOOL',
          phoneNumber: '',
          selectedPackage: 'free',
          paymentStatus: 'free',
          notificationPreferences: true,
        );
        final createdProfile = {
          ...data.toJson(),
          'academic_path': data.academicLevel,
          'academicPath': data.academicLevel,
          'is_admin': isAdmin,
          'is_email_verified': user.emailVerified,
        };
        await _firestore.collection('users').doc(user.uid).set(createdProfile, SetOptions(merge: true));
        return createdProfile;
      }

      final docData = doc.data()!;
      final profile = UserModel.fromJson(docData);
      final normalizedProfile = profile.toJson();
      final normalizedAcademicPath = (docData['academic_path'] ??
              docData['academicPath'] ??
              docData['academic_level'] ??
              profile.academicLevel)
          .toString();

      normalizedProfile.addAll(docData);
      normalizedProfile['academic_path'] = normalizedAcademicPath;
      normalizedProfile['academicPath'] = normalizedAcademicPath;
      normalizedProfile['academic_level'] = normalizedAcademicPath;
      normalizedProfile['academicLevel'] = normalizedAcademicPath;
      normalizedProfile['grade'] = profile.grade ?? docData['grade'];
      normalizedProfile['stream'] = profile.stream ?? docData['stream'];
      normalizedProfile['department'] = profile.department ?? docData['department'];
      normalizedProfile['year'] = profile.year ?? docData['year'];
      normalizedProfile['semester'] = profile.semester ?? docData['semester'];
      normalizedProfile['onboarding_selections'] = profile.onboardingSelections ?? docData['onboarding_selections'];
      normalizedProfile['is_admin'] = docData['is_admin'] ?? adminEmails.contains(user.email?.toLowerCase());
      normalizedProfile['is_email_verified'] = user.emailVerified;

      return normalizedProfile;
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
