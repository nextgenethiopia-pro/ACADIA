import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ContentConfigService - Fetches content configuration from Firebase Firestore
///
/// This service:
/// 1. Fetches content_config from Firestore on app startup
/// 2. Caches the config locally in SharedPreferences for offline use
/// 3. Provides content URLs for all grades, subjects, and chapters
/// 4. Falls back to cached config if network is unavailable
///
/// Admin updates content via Admin Panel → saves to Firestore → App fetches on startup
class ContentConfigService {
  static final ContentConfigService _instance = ContentConfigService._internal();
  factory ContentConfigService() => _instance;
  ContentConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache key for local storage
  static const String _cacheKey = 'content_config';
  static const String _configVersionKey = 'content_config_version';

  // Cached config data
  Map<String, dynamic>? _cachedConfig;
  String? _cachedVersion;

  // Listeners for config updates
  final List<void Function(Map<String, dynamic>)> _listeners = [];

  /// Load content configuration from Firestore
  /// Tries to fetch from Firestore first, falls back to cached version
  Future<Map<String, dynamic>> loadConfig({bool forceRefresh = false}) async {
    // If we have cached config and not forcing refresh, return it
    if (!forceRefresh && _cachedConfig != null) {
      return _cachedConfig!;
    }

    // Try to fetch from Firestore
    try {
      final doc = await _firestore.collection('settings').doc('content_config').get();

      if (doc.exists) {
        final config = doc.data()!;
        final version = config['version']?.toString() ?? '1.0.0';

        // Save to local storage for offline use
        await _saveLocalConfig(json.encode(config));

        // Update cached config
        _cachedConfig = config;
        _cachedVersion = version;

        // Notify listeners
        _notifyListeners(config);

        return config;
      }
    } catch (e) {
      debugPrint('Failed to fetch config from Firestore: $e');
    }

    // Fall back to cached config
    return await _loadLocalConfig();
  }

  /// Get cached config (already loaded in memory)
  Map<String, dynamic>? getCachedConfig() {
    return _cachedConfig;
  }

  /// Get base URL for content files (Internet Archive)
  String getBaseUrl() {
    return 'https://archive.org/download';
  }

  /// Get content URL for a specific content item
  ///
  /// Path: school_level → grade → stream → subject → chapter → content_type
  String? getContentUrl({
    required String schoolLevel,
    required String grade,
    String? stream,
    required String subject,
    required String chapter,
    required String contentType,
  }) {
    final config = _cachedConfig;
    if (config == null) return null;

    try {
      final contentMap = config['content_map'] as Map<String, dynamic>?;
      if (contentMap == null) return null;

      // Navigate through the nested structure
      final schoolData = contentMap[schoolLevel] as Map<String, dynamic>?;
      if (schoolData == null) return null;

      final gradeData = schoolData['grade_$grade'] as Map<String, dynamic>?;
      if (gradeData == null) return null;

      // Stream is optional for grades 9-10
      Map<String, dynamic>? streamData;
      if (stream != null && stream.isNotEmpty) {
        streamData = gradeData[stream] as Map<String, dynamic>?;
        if (streamData == null) return null;
      } else {
        streamData = gradeData;
      }

      final subjectData = streamData[subject.toLowerCase()] as Map<String, dynamic>?;
      if (subjectData == null) return null;

      final chapterData = subjectData[chapter] as Map<String, dynamic>?;
      if (chapterData == null) return null;

      return chapterData[contentType] as String?;
    } catch (e) {
      debugPrint('Error getting content URL: $e');
      return null;
    }
  }

  /// Get all content for a subject (list of chapters with URLs)
  List<Map<String, dynamic>> getSubjectContent({
    required String schoolLevel,
    required String grade,
    String? stream,
    required String subject,
  }) {
    final config = _cachedConfig;
    if (config == null) return [];

    try {
      final contentMap = config['content_map'] as Map<String, dynamic>?;
      if (contentMap == null) return [];

      final schoolData = contentMap[schoolLevel] as Map<String, dynamic>?;
      if (schoolData == null) return [];

      final gradeData = schoolData['grade_$grade'] as Map<String, dynamic>?;
      if (gradeData == null) return [];

      Map<String, dynamic>? streamData;
      if (stream != null && stream.isNotEmpty) {
        streamData = gradeData[stream] as Map<String, dynamic>?;
      } else {
        streamData = gradeData;
      }
      
      if (streamData == null) return [];

      final subjectData = streamData[subject.toLowerCase()] as Map<String, dynamic>?;
      if (subjectData == null) return [];

      final chapters = <Map<String, dynamic>>[];
      subjectData.forEach((chapterName, content) {
        chapters.add({
          'name': chapterName,
          'content': content as Map<String, dynamic>,
        });
      });

      return chapters;
    } catch (e) {
      debugPrint('Error getting subject content: $e');
      return [];
    }
  }

  /// Get config version
  String? getConfigVersion() {
    return _cachedConfig?['version'] as String?;
  }

  /// Get last updated timestamp
  String? getLastUpdated() {
    return _cachedConfig?['last_updated'] as String?;
  }

  /// Refresh config from Firestore (manual refresh)
  Future<Map<String, dynamic>> refreshConfig() async {
    return await loadConfig(forceRefresh: true);
  }

  /// Check if config is loaded
  bool isConfigLoaded() {
    return _cachedConfig != null;
  }

  /// Add listener for config updates
  void addListener(void Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(Map<String, dynamic> config) {
    for (final listener in _listeners) {
      listener(config);
    }
  }

  /// Save config to local storage
  Future<void> _saveLocalConfig(String configJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, configJson);
    } catch (e) {
      debugPrint('Error saving config to local storage: $e');
    }
  }

  /// Load config from local storage
  Future<Map<String, dynamic>> _loadLocalConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_cacheKey);

      if (configJson != null) {
        final config = json.decode(configJson);
        _cachedConfig = config as Map<String, dynamic>;
        _cachedVersion = config['version'] as String?;
        return config;
      }
    } catch (e) {
      debugPrint('Error loading config from local storage: $e');
    }

    // Return empty config if nothing cached
    return {'content_map': {}, 'version': '1.0.0', 'last_updated': ''};
  }

  /// Clear cached config (for logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_configVersionKey);
      _cachedConfig = null;
      _cachedVersion = null;
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}