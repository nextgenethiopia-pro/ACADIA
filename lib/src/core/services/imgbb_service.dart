import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/secrets.dart';

class ImgbbService {
  /// ImgBB API key. Resolved from `--dart-define=IMGBB_API_KEY=...` via
  /// [Secrets]; no longer hardcoded in source. See [Secrets] for rotation.
  static const String apiKey = Secrets.imgbbApiKey;

  static const String uploadUrl = 'https://api.imgbb.com/1/upload';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['key'] = apiKey
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading to ImgBB: $e');
      return null;
    }
  }
}
