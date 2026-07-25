import '../../core/services/package_service.dart';
import '../../domain/repositories/package_repository.dart';

/// [PackageRepository] implementation delegating to [PackageService].
///
/// The service's validity/expiry logic is preserved as-is; this class only
/// exposes it behind the domain contract for DI and testability.
class PackageRepositoryImpl implements PackageRepository {
  PackageRepositoryImpl(this._service);

  final PackageService _service;

  @override
  Future<bool> hasActivePackage() => _service.hasActivePackage();

  @override
  Future<Map<String, dynamic>> getUserPackageInfo() =>
      _service.getUserPackageInfo();

  @override
  Future<int> getDaysRemaining() => _service.getDaysRemaining();

  @override
  Future<bool> isPackageExpired() => _service.isPackageExpired();

  @override
  Future<int> getPackagePrice() => _service.getPackagePrice();

  @override
  Future<String> getPackageName() => _service.getPackageName();

  @override
  Future<bool> isExpiringSoon() => _service.isExpiringSoon();

  @override
  Future<void> activatePackage(
    String userId, {
    String? packageName,
    int? packageAmount,
    String? paymentMethod,
  }) =>
      _service.activatePackage(
        userId,
        packageName: packageName,
        packageAmount: packageAmount,
        paymentMethod: paymentMethod,
      );

  @override
  Future<void> revokePackage(String userId) => _service.revokePackage(userId);
}
