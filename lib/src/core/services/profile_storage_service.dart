import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileStorageService {
  static final ProfileStorageService _instance = ProfileStorageService._internal();
  factory ProfileStorageService() => _instance;
  ProfileStorageService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  
  static const String _profilePhotoKey = 'profile_photo_url';
  static const String _profilePhotoUpdatedKey = 'profile_photo_updated_at';

  // Upload progress callback
  void Function(double progress)? onUploadProgress;

  /// Upload profile photo to the image host (ImgBB).
  Future<String?> uploadProfilePhoto(File imageFile, {void Function(double progress)? onProgress}) async {
    final url = await ImageUploadService.uploadImage(
      imageFile,
      name: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    if (url == null) {
      throw Exception('Image upload failed. Please try again.');
    }
    return url;
  }

  /// Update user's profile photo URL in Firebase
  Future<void> updateProfilePhotoUrl(String userId, String imageUrl) async {
    try {
      await _firebaseService.updateDocument('users', userId, {
        'profile_photo_url': imageUrl,
        'profile_photo_updated_at': DateTime.now().toIso8601String(),
      });
      
      // Also update local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_profilePhotoKey}_$userId', imageUrl);
      await prefs.setString('${_profilePhotoUpdatedKey}_$userId', DateTime.now().toIso8601String());
      
    } catch (e) {
      debugPrint('Error updating profile photo URL: $e');
      rethrow;
    }
  }

  /// Get user's profile photo URL
  Future<String?> getProfilePhotoUrl(String userId) async {
    try {
      // First check local cache
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('${_profilePhotoKey}_$userId');
      
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        return cachedUrl;
      }
      
      // If not cached, fetch from Firebase
      final userProfile = await _firebaseService.getUserProfile();
      final firebaseUrl = userProfile?['profile_photo_url'] as String?;
      
      if (firebaseUrl != null && firebaseUrl.isNotEmpty) {
        // Cache for future use
        await prefs.setString('${_profilePhotoKey}_$userId', firebaseUrl);
        return firebaseUrl;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting profile photo URL: $e');
      return null;
    }
  }

  /// Remove profile photo
  Future<void> removeProfilePhoto(String userId) async {
    try {
      await _firebaseService.updateDocument('users', userId, {
        'profile_photo_url': null,
      });
      
      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_profilePhotoKey}_$userId');
      await prefs.remove('${_profilePhotoUpdatedKey}_$userId');
      
    } catch (e) {
      debugPrint('Error removing profile photo: $e');
      rethrow;
    }
  }

  /// Check if user has a profile photo
  Future<bool> hasProfilePhoto(String userId) async {
    final url = await getProfilePhotoUrl(userId);
    return url != null && url.isNotEmpty;
  }

  /// Get profile photo last updated time
  Future<DateTime?> getProfilePhotoUpdatedAt(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedAtStr = prefs.getString('${_profilePhotoUpdatedKey}_$userId');
      
      if (updatedAtStr != null) {
        return DateTime.parse(updatedAtStr);
      }
      
      final userProfile = await _firebaseService.getUserProfile();
      final firebaseUpdatedAt = userProfile?['profile_photo_updated_at'] as String?;
      
      if (firebaseUpdatedAt != null) {
        return DateTime.parse(firebaseUpdatedAt);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting profile photo updated at: $e');
      return null;
    }
  }

  /// Clear local cache for a user
  Future<void> clearLocalCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_profilePhotoKey}_$userId');
      await prefs.remove('${_profilePhotoUpdatedKey}_$userId');
    } catch (e) {
      debugPrint('Error clearing local cache: $e');
    }
  }

  /// Clear all local profile photo caches
  Future<void> clearAllLocalCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_profilePhotoKey) || key.startsWith(_profilePhotoUpdatedKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing all local caches: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take photo from camera
  Future<File?> takePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Get the full profile photo flow: upload, get URL, update user
  Future<String?> updateProfilePhoto(String userId, File imageFile, {void Function(double progress)? onProgress}) async {
    try {
      // 1. Upload to the image host
      final imageUrl = await uploadProfilePhoto(imageFile, onProgress: onProgress);
      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }
      
      // 2. Update user profile in Firebase
      await updateProfilePhotoUrl(userId, imageUrl);
      
      return imageUrl;
    } catch (e) {
      debugPrint('Error in updateProfilePhoto flow: $e');
      rethrow;
    }
  }

  /// Get profile photo as a widget (cached network image)
  Widget buildProfilePhoto(
    String userId, {
    double width = 100,
    double height = 100,
    BoxFit fit = BoxFit.cover,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(50)),
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return FutureBuilder<String?>(
      future: getProfilePhotoUrl(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ??
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
        }
        
        final imageUrl = snapshot.data;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return ClipRRect(
            borderRadius: borderRadius,
            child: Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder ??
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
              },
              errorBuilder: (context, error, stackTrace) {
                return errorWidget ??
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    );
              },
            ),
          );
        }
        
        return errorWidget ??
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.grey),
            );
      },
    );
  }
}