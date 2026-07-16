import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:acadia/src/core/config/app_config.dart';

/// ImageUploadService
///
/// Uploads images to ImgBB and returns the hosted image URL. The API key is
/// provided at build time via [AppConfig.imgbbApiKey] (`--dart-define`), never
/// hardcoded in source. Callers store the returned URL (e.g. in Firestore).
class ImageUploadService {
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Upload a file to ImgBB. Returns the image URL, or null on failure.
  static Future<String?> uploadImage(
    File imageFile, {
    void Function(int sent, int total)? onSendProgress,
    String? name,
  }) async {
    final bytes = await imageFile.readAsBytes();
    return uploadBytes(bytes, onSendProgress: onSendProgress, name: name);
  }

  /// Upload raw bytes to ImgBB. Returns the image URL, or null on failure.
  static Future<String?> uploadBytes(
    Uint8List bytes, {
    void Function(int sent, int total)? onSendProgress,
    String? name,
  }) async {
    if (!AppConfig.imgbbConfigured) {
      debugPrint('ImgBB not configured: missing IMGBB_API_KEY --dart-define');
      return null;
    }

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'image': base64Encode(bytes),
        if (name != null) 'name': name,
      });

      final response = await dio.post(
        '$_uploadUrl?key=${AppConfig.imgbbApiKey}',
        data: formData,
        onSendProgress: onSendProgress,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return (data['display_url'] ?? data['url']) as String?;
      }

      debugPrint('ImgBB upload failed: ${response.data}');
      return null;
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }
}
