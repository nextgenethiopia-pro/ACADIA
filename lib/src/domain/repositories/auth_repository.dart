import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/result.dart';

/// Contract for authentication and the signed-in user's profile.
///
/// Implemented by [AuthRepositoryImpl] over `FirebaseAuthService`. The
/// presentation layer depends only on this abstraction (resolved via DI).
abstract class AuthRepository {
  /// The currently signed-in Firebase user, or null.
  User? get currentUser;

  /// Emits on sign-in / sign-out.
  Stream<User?> get authStateChanges;

  /// Registers a new account and sends a verification email.
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? grade,
    String? stream,
    String? academicPath,
  });

  /// Signs in with email/password. Returns an [AuthException] with
  /// `needsVerification = true` when the email is not yet verified.
  Future<Result<User>> signIn({
    required String email,
    required String password,
  });

  /// Signs the current user out.
  Future<void> signOut();

  /// Sends a password-reset email.
  Future<Result<void>> resetPassword(String email);

  /// Updates the current user's password.
  Future<Result<void>> updatePassword(String newPassword);

  /// Updates the current user's display name / avatar.
  Future<Result<void>> updateProfile({String? fullName, String? avatarUrl});

  /// Resends the verification email to the current user.
  Future<Result<void>> resendVerificationEmail();

  /// Whether the current user is an admin.
  Future<bool> isAdmin();

  /// Returns the current user's Firestore profile document.
  Future<Map<String, dynamic>?> getUserProfile();
}
