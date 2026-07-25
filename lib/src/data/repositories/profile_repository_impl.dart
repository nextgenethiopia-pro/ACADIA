import 'dart:io';

import '../../core/services/profile_storage_service.dart';
import '../../domain/repositories/profile_repository.dart';

/// [ProfileRepository] implementation delegating to [ProfileStorageService].
///
/// Pure delegation — no logic change; only exposes the existing profile-photo
/// service behind the profile domain contract for DI and testability.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._profileStorageService);

  final ProfileStorageService _profileStorageService;

  @override
  Future<String?> updateProfilePhoto(
    String userId,
    File imageFile, {
    void Function(double progress)? onProgress,
  }) =>
      _profileStorageService.updateProfilePhoto(
        userId,
        imageFile,
        onProgress: onProgress,
      );

  @override
  Future<String?> getProfilePhotoUrl(String userId) =>
      _profileStorageService.getProfilePhotoUrl(userId);

  @override
  Future<bool> hasProfilePhoto(String userId) =>
      _profileStorageService.hasProfilePhoto(userId);

  @override
  Future<void> removeProfilePhoto(String userId) =>
      _profileStorageService.removeProfilePhoto(userId);

  @override
  Future<File?> pickImageFromGallery() =>
      _profileStorageService.pickImageFromGallery();

  @override
  Future<File?> takePhoto() => _profileStorageService.takePhoto();
}
