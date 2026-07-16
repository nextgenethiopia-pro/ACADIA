import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ImageUploadService {
  static const String _catboxUrl = 'https://catbox.moe/user/api.php';

  /// Upload an image to Catbox.moe and return the direct URL
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_catboxUrl));
      
      // Add the required parameters
      request.fields['reqtype'] = 'fileupload';
      request.fields['userhash'] = ''; // Empty for anonymous upload
      
      // Attach the image file
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'fileToUpload',
        stream,
        length,
        filename: basename(imageFile.path),
      );
      
      request.files.add(multipartFile);
      
      // Send the request
      final response = await request.send();
      
      // Get the response body
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        // Catbox returns the direct URL as plain text
        final imageUrl = responseBody.trim();
        if (imageUrl.startsWith('https://files.catbox.moe/')) {
          return imageUrl;
        }
      }
      
      debugPrint('Catbox upload failed: $responseBody');
      return null;
    } catch (e) {
      debugPrint('Catbox upload error: $e');
      return null;
    }
  }
}