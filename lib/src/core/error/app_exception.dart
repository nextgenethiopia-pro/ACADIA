/// Typed application exceptions used across the repository layer.
///
/// Data sources (Firebase, SQLite, Dio) throw provider-specific errors.
/// Repositories catch those and map them to one of these typed exceptions so
/// the presentation layer never depends on Firebase/Dio error types.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Network connectivity / timeout failures.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Authentication / authorization failures.
class AuthException extends AppException {
  const AuthException(super.message,
      {super.cause, this.needsVerification = false});

  /// True when the failure is specifically an unverified email.
  final bool needsVerification;
}

/// Permission denied (e.g. Firestore security rules).
class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

/// Requested resource does not exist.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

/// Local cache / SQLite failures.
class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

/// Fallback for unclassified errors.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause});
}
