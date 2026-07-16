import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// GithubContentService
///
/// Delivers educational content and metadata from the GitHub content repo
/// (see [AppConfig.contentRepo]) so content changes do not require an APK
/// rebuild. Raw files are read from `raw.githubusercontent.com`; large binary
/// assets should live in GitHub Releases and be referenced by URL in metadata.
///
/// Expected repo layout (flexible — callers pass relative paths):
/// ```
/// manifest.json                       # { "version": "2024.06.01" }
/// high-school/grade_12/biology/metadata.json
/// high-school/grade_12/biology/units.json
/// high-school/grade_12/biology/mcq.json
/// high-school/grade_12/biology/flashcards.json
/// ```
class GithubContentService {
  GithubContentService._internal();
  static final GithubContentService instance =
      GithubContentService._internal();

  static const String _versionKey = 'github_content_version';
  static const String _jsonCachePrefix = 'github_content_json_';

  final http.Client _client = http.Client();

  Uri _rawUri(String relativePath) {
    final clean = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return Uri.parse('${AppConfig.contentRawBaseUrl}/$clean');
  }

  /// Reads the remote content version from `manifest.json`.
  Future<String?> fetchRemoteVersion() async {
    final manifest = await fetchJson('manifest.json', useCache: false);
    return manifest?['version']?.toString();
  }

  /// The last content version we successfully synced.
  Future<String?> getStoredVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_versionKey);
  }

  /// Returns true when the remote content version differs from the stored one.
  /// Fails closed (returns false) when the version cannot be fetched, so the
  /// app keeps using cached content instead of thrashing the network.
  Future<bool> hasNewContent() async {
    final remote = await fetchRemoteVersion();
    if (remote == null) return false;
    final stored = await getStoredVersion();
    return remote != stored;
  }

  /// Records [version] as the currently synced content version.
  Future<void> markSynced(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, version);
  }

  /// Fetches and decodes a JSON file from the content repo.
  ///
  /// When [useCache] is true the last successful response is cached in
  /// SharedPreferences and returned if the network is unavailable.
  Future<Map<String, dynamic>?> fetchJson(
    String relativePath, {
    bool useCache = true,
  }) async {
    final raw = await fetchRaw(relativePath, useCache: useCache);
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      debugPrint('GithubContentService: $relativePath is not a JSON object');
      return null;
    } catch (e) {
      debugPrint('GithubContentService: JSON decode failed for $relativePath: $e');
      return null;
    }
  }

  /// Fetches a raw text file from the content repo, with optional caching.
  Future<String?> fetchRaw(
    String relativePath, {
    bool useCache = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_jsonCachePrefix$relativePath';

    try {
      final response = await _client
          .get(_rawUri(relativePath))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        if (useCache) await prefs.setString(cacheKey, response.body);
        return response.body;
      }
      debugPrint(
          'GithubContentService: ${response.statusCode} for $relativePath');
    } catch (e) {
      debugPrint('GithubContentService: fetch failed for $relativePath: $e');
    }

    if (useCache) return prefs.getString(cacheKey);
    return null;
  }
}
