import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/secrets.dart';

/// Thrown when an ImgBB upload fails, carrying the HTTP status and the raw
/// ImgBB response so callers can show/log what actually went wrong.
class ImgbbUploadException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ImgbbUploadException(this.message, {this.statusCode, this.body});

  @override
  String toString() => message;
}

class ImgbbService {
  /// ImgBB API key. Resolved from `--dart-define=IMGBB_API_KEY=...` via
  /// [Secrets]; no longer hardcoded in source. See [Secrets] for rotation.
  static const String apiKey = Secrets.imgbbApiKey;

  static const String uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads [imageFile] and returns the direct `https://i.ibb.co/...` URL.
  ///
  /// Throws [ImgbbUploadException] — never returns null — so the caller can
  /// surface the real reason (invalid key, code 103 "forbidden", network...).
  static Future<String> uploadImage(File imageFile) async {
    if (apiKey.trim().isEmpty) {
      throw ImgbbUploadException('IMGBB_API_KEY is empty in this build.');
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['key'] = apiKey
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded is Map ? decoded['data'] : null;
        final url = data is Map ? data['url'] : null;
        if (url is String && url.isNotEmpty) {
          return url;
        }
        throw ImgbbUploadException(
          'ImgBB accepted the request but returned no image URL.',
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      throw ImgbbUploadException(
        _describeError(response),
        statusCode: response.statusCode,
        body: response.body,
      );
    } on ImgbbUploadException {
      rethrow;
    } on SocketException catch (e) {
      throw ImgbbUploadException('Network unreachable: ${e.message}');
    } on HttpException catch (e) {
      throw ImgbbUploadException('HTTP failure: ${e.message}');
    } catch (e) {
      throw ImgbbUploadException('Upload failed: $e');
    }
  }

  /// ImgBB errors look like:
  /// `{"status_code":400,"error":{"message":"...","code":103}}`.
  static String _describeError(http.Response response) {
    String detail = '';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        detail = '${error['message']} (imgbb code ${error['code']})';
      }
    } catch (_) {
      // Body was not JSON — fall back to the raw text below.
    }
    if (detail.trim().isEmpty) detail = response.body;
    return 'ImgBB HTTP ${response.statusCode}: $detail'.trim();
  }
}
