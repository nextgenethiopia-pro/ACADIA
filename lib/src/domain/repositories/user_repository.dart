/// Contract for the current user's profile and app settings.
///
/// Implemented by [UserRepositoryImpl] over `FirebaseService`.
abstract class UserRepository {
  /// The current user's profile document, or null.
  Future<Map<String, dynamic>?> getUserProfile();

  /// Creates the current user's profile document.
  Future<void> createUserProfile(Map<String, dynamic> data);

  /// Updates the current user's profile document.
  Future<void> updateUserProfile(Map<String, dynamic> data);

  /// Global app settings (prices, quotes, welcome content), or null.
  Future<Map<String, dynamic>?> getAppSettings();

  /// Merges updates into global app settings.
  Future<void> updateAppSettings(Map<String, dynamic> settings);
}
