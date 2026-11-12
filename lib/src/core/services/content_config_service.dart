import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'github_content_service.dart';
import '../../local_database/isar_service.dart';

/// ContentConfigService — runtime config for the GitHub content delivery layer.
///
/// Reads `settings/app_config` from Firestore (admin-set) and caches it
/// locally in SharedPreferences for offline use.
///
/// The ONLY purpose of this service is to supply the GitHub base URL and
/// app-level settings to [GithubContentService]. It is NOT a content source.
///
/// Content = GitHub. Metadata config = Firestore settings collection.
class ContentConfigService {
  static final ContentConfigService _instance =
      ContentConfigService._internal();
  factory ContentConfigService() => _instance;
  ContentConfigService._internal();

  static const String _cacheKey = 'app_content_config_v2';

  Map<String, dynamic>? _cachedConfig;

  /// Default GitHub raw base URL. Admin can override via Firestore
  /// `settings/app` → `github_base_url`.
  static const String _defaultGithubBase =
      'https://raw.githubusercontent.com/Acadia-et/ACADIA-CONTENT/main';

  // ============================================
  // INIT
  // ============================================

  /// Called at startup. Loads cached config, then applies it to
  /// [GithubContentService] so content URLs are always current.
  Future<void> initialize({
    required GithubContentService githubService,
    IsarService? isarService,
    Map<String, dynamic>? firestoreConfig,
  }) async {
    // Start from local cache
    _cachedConfig = await _loadLocalConfig();

    // If admin has pushed a new config from Firestore, merge it
    if (firestoreConfig != null && firestoreConfig.isNotEmpty) {
      _cachedConfig = {...?_cachedConfig, ...firestoreConfig};
      await _saveLocalConfig(_cachedConfig!);
    }

    // Apply base URL to GitHub service
    final baseUrl = getGithubBaseUrl();
    githubService.configureBaseUrl(baseUrl);
  }

  // ============================================
  // ACCESSORS
  // ============================================

  String getGithubBaseUrl() {
    return (_cachedConfig?['github_base_url'] as String?)?.trim().isNotEmpty ==
            true
        ? _cachedConfig!['github_base_url'] as String
        : _defaultGithubBase;
  }

  String getConfigVersion() {
    return (_cachedConfig?['version'] as String?) ?? '1.0.0';
  }

  String getLastUpdated() {
    return (_cachedConfig?['last_updated'] as String?) ?? '';
  }

  Map<String, dynamic>? getCachedConfig() => _cachedConfig;

  bool isConfigLoaded() => _cachedConfig != null;

  /// Package prices keyed by `grade_<N>` or `university_<year>`.
  int getPackagePrice({required String grade, String? schoolLevel}) {
    final prices =
        _cachedConfig?['package_prices'] as Map<String, dynamic>?;
    if (prices == null) return 300;

    if (schoolLevel == 'university') {
      return (prices['university'] as int?) ?? 300;
    }
    return (prices['grade_$grade'] as int?) ?? 300;
  }

  // ============================================
  // LOCAL CACHE
  // ============================================

  Future<void> _saveLocalConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(config));
    } catch (e) {
      debugPrint('ContentConfigService: save error: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadLocalConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) return json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ContentConfigService: load error: $e');
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      _cachedConfig = null;
    } catch (e) {
      debugPrint('ContentConfigService: clear error: $e');
    }
  }
}
