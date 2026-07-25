import 'dart:io';

/// Contract for the current user's profile photo and profile edits.
///
/// Implemented by `ProfileRepositoryImpl` over `ProfileStorageService`
/// (photo upload, local cache) and `UserRepository` (Firestore profile).
/// Presentation resolves this via DI instead of touching ImgBB/Firebase
/// services directly.
abstract class ProfileRepository {
  /// Uploads [imageFile] as the user's profile photo and persists the URL.
  ///
  /// Returns the hosted photo URL, or null on failure.
  /// [onProgress] reports 0.0–1.0 when supported.
  Future<String?> updateProfilePhoto(
    String userId,
    File imageFile, {
    void Function(double progress)? onProgress,
  });

  /// The current user's profile photo URL (local cache first, then remote).
  Future<String?> getProfilePhotoUrl(String userId);

  /// Whether the user has any profile photo stored.
  Future<bool> hasProfilePhoto(String userId);

  /// Removes the user's profile photo locally and remotely.
  Future<void> removeProfilePhoto(String userId);

  /// Lets the user pick an image from the gallery; returns null on cancel.
  Future<File?> pickImageFromGallery();

  /// Lets the user take a photo with the camera; returns null on cancel.
  Future<File?> takePhoto();
}
