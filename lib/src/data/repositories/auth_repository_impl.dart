import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/app_exception.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] implementation that delegates to [FirebaseAuthService]
/// and maps its `Map<String, dynamic>` responses to typed [Result] values.
///
/// The underlying service logic is unchanged; this only standardizes the
/// return contract and error typing for the presentation layer.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final FirebaseAuthService _service;

  @override
  User? get currentUser => _service.currentUser;

  @override
  Stream<User?> get authStateChanges => _service.authStateChanges;

  @override
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? grade,
    String? stream,
    String? academicPath,
  }) async {
    final res = await _service.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
      grade: grade,
      stream: stream,
      academicPath: academicPath,
    );
    return _toUserResult(res);
  }

  @override
  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _service.signIn(email: email, password: password);
    return _toUserResult(res);
  }

  @override
  Future<void> signOut() => _service.signOut();

  @override
  Future<Result<void>> resetPassword(String email) async =>
      _toVoidResult(await _service.resetPassword(email));

  @override
  Future<Result<void>> updatePassword(String newPassword) async =>
      _toVoidResult(await _service.updatePassword(newPassword));

  @override
  Future<Result<void>> updateProfile(
          {String? fullName, String? avatarUrl}) async =>
      _toVoidResult(await _service.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      ));

  @override
  Future<Result<void>> resendVerificationEmail() async =>
      _toVoidResult(await _service.resendVerificationEmail());

  @override
  Future<bool> isAdmin() => _service.isAdmin();

  @override
  Future<Map<String, dynamic>?> getUserProfile() => _service.getUserProfile();

  // --- mapping helpers -------------------------------------------------

  Result<User> _toUserResult(Map<String, dynamic> res) {
    if (res['success'] == true && res['user'] is User) {
      return Ok(res['user'] as User);
    }
    return Err(AuthException(
      (res['error'] ?? 'Authentication failed').toString(),
      needsVerification: res['needsVerification'] == true,
    ));
  }

  Result<void> _toVoidResult(Map<String, dynamic> res) {
    if (res['success'] == true) return const Ok(null);
    return Err(AuthException((res['error'] ?? 'Operation failed').toString()));
  }
}
