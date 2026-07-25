/// Contract for package (subscription) status and lifecycle.
///
/// Implemented by [PackageRepositoryImpl] over `PackageService`. Encapsulates
/// the 1-year validity and chapter-locking rules used by the dashboard and
/// admin payment approval.
abstract class PackageRepository {
  /// Whether the current user has a valid, non-expired package.
  Future<bool> hasActivePackage();

  /// Full package info map (has_package, is_pro, days_remaining, etc.).
  Future<Map<String, dynamic>> getUserPackageInfo();

  /// Days remaining before expiry (0 when none/expired).
  Future<int> getDaysRemaining();

  /// Whether the current package has expired.
  Future<bool> isPackageExpired();

  /// Price for the current user's grade/level.
  Future<int> getPackagePrice();

  /// Human-readable package name for the user's academic path.
  Future<String> getPackageName();

  /// Whether the package expires within 7 days.
  Future<bool> isExpiringSoon();

  /// Admin: activate a user's package (1-year validity from now).
  Future<void> activatePackage(
    String userId, {
    String? packageName,
    int? packageAmount,
    String? paymentMethod,
  });

  /// Admin: revoke a user's package.
  Future<void> revokePackage(String userId);
}
