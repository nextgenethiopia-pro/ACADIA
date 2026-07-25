import '../../core/services/firebase_service.dart';
import '../../domain/repositories/user_repository.dart';

/// [UserRepository] implementation delegating to [FirebaseService].
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._service);

  final FirebaseService _service;

  @override
  Future<Map<String, dynamic>?> getUserProfile() =>
      _service.getUserProfile();

  @override
  Future<void> createUserProfile(Map<String, dynamic> data) =>
      _service.createUserProfile(data);

  @override
  Future<void> updateUserProfile(Map<String, dynamic> data) =>
      _service.updateUserProfile(data);

  @override
  Future<Map<String, dynamic>?> getAppSettings() => _service.getAppSettings();

  @override
  Future<void> updateAppSettings(Map<String, dynamic> settings) =>
      _service.updateAppSettings(settings);
}
