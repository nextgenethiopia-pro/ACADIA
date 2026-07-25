import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../local_database/isar_service.dart';
import '../../local_database/schemas/content_entry.dart';

/// GithubContentService — reads the educational content catalog from GitHub,
/// cached offline-first in Isar.
///
/// Content-as-code design (see architecture doc §4):
///   {base}/{grade}/{subject}/metadata.json   -> table of contents (units)
///   {base}/{grade}/{subject}/{unitFile}.json  -> content items for a unit
///
/// Firestore stays the system of record for identity/settings; the *content
/// read path* is GitHub raw JSON, served free over its CDN. Media bytes live
/// on YouTube / GitHub Releases / ImgBB — this service only fetches the JSON
/// catalog and normalizes it into the same map shape the content screens
/// already consume (`content_type`, `title`, `download_url`, `free_content`,
/// `page_count`, `total_questions`, `total_cards`, `year`, ...).
///
/// Every fetch is cached in Isar ([ContentEntry]) with a 24h TTL so the app
/// feels instant and works offline; on network failure it falls back to the
/// last cached payload. A repo-root `version.json` is probed at most once per
/// [versionCheckInterval]; when its `version` changes, cached catalog rows are
/// evicted so the next read pulls fresh content.
class GithubContentService {
  GithubContentService({required IsarService isar, http.Client? client})
      : _isar = isar,
        _client = client ?? http.Client();

  final IsarService _isar;
  final http.Client _client;

  /// Default raw base. Overridden at runtime by the Firestore
  /// `settings/content_config.github_base_url` value so content can move
  /// without an APK update.
  static const String _defaultBaseUrl =
      'https://raw.githubusercontent.com/acadia-content/main';

  String _baseUrl = _defaultBaseUrl;

  /// Cache freshness window. After this the app re-checks GitHub.
  static const Duration cacheTtl = Duration(hours: 24);

  /// How often the global content version is re-checked. The spec calls for a
  /// daily version probe; per-file cache entries stay valid until the version
  /// bumps, which is what keeps bandwidth low.
  static const Duration versionCheckInterval = Duration(hours: 24);

  /// Prefix for per-file catalog cache keys (see [ContentEntry.key]).
  static const String _cachePrefix = 'gh_content_';

  /// Key for the single row that stores the last known content version.
  static const String _versionKey = 'gh::version';

  String? _contentVersion;

  /// Point the service at a specific repo/branch base (from Firestore config).
  /// A trailing slash is trimmed for consistent path joins.
  void configureBaseUrl(String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) return;
    var url = baseUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;

  /// The last known content version (from `version.json`), or null if the
  /// version has not yet been probed.
  String? get contentVersion => _contentVersion;

  // ============================================
  // GLOBAL CONTENT VERSION (version.json)
  // ============================================

  /// Checks the repo-root `version.json` and, when its `version` field has
  /// changed since the last probe, invalidates every cached catalog file so
  /// the next read pulls fresh content. Safe to call on a timer / on startup.
  ///
  /// Returns the (possibly updated) current content version. Network failures
  /// are swallowed — the previously cached version wins and the app keeps
  /// working offline.
  Future<String?> checkContentVersion({bool force = false}) async {
    // Throttle: only hit the network once per [versionCheckInterval] unless
    // forced (e.g. pull-to-refresh).
    if (!force) {
      final stamp = await _isar.getContentEntry(_versionKey);
      if (stamp != null && stamp.fetchedAt != null) {
        final age = DateTime.now().difference(stamp.fetchedAt!);
        if (age < versionCheckInterval) {
          _contentVersion ??= stamp.contentVersion;
          return _contentVersion;
        }
      }
    }

    try {
      final data = await _getJson('version.json', forceRefresh: force);
      if (data is Map<String, dynamic>) {
        final remoteVersion = data['version']?.toString();
        final knownVersion = _contentVersion ??
            (await _isar.getContentEntry(_versionKey))?.contentVersion;

        if (remoteVersion != null && remoteVersion != knownVersion) {
          // Version bumped (or first run) — drop cached catalog so subsequent
          // reads re-fetch the latest files.
          await _clearMetadataCache();
          _contentVersion = remoteVersion;
        } else {
          _contentVersion = remoteVersion ?? knownVersion;
        }
        await _isar.putContentEntry(ContentEntry()
          ..key = _versionKey
          ..payloadJson = _contentVersion ?? ''
          ..source = 'github'
          ..fetchedAt = DateTime.now()
          ..ttlSeconds = versionCheckInterval.inSeconds
          ..contentVersion = _contentVersion);
      }
    } catch (e) {
      debugPrint('GithubContentService: version check failed: $e');
      _contentVersion ??=
          (await _isar.getContentEntry(_versionKey))?.contentVersion;
    }
    return _contentVersion;
  }

  /// Drops every cached catalog entry (keeps the version stamp).
  Future<void> _clearMetadataCache() async {
    await _isar.deleteContentEntriesByPrefix(_cachePrefix);
  }

  // ============================================
  // CATALOG READS
  // ============================================

  /// Table of contents for a subject: the list of units and which content
  /// types each unit provides. Returns `null` when unavailable offline.
  Future<Map<String, dynamic>?> getSubjectMetadata({
    required String grade,
    required String subject,
  }) async {
    final path = '${_gradeSeg(grade)}/${_subjectSeg(subject)}/metadata.json';
    final data = await _getJson(path);
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  /// Units declared in a subject's metadata, as `{title, video, pdf, mcq, ...}`.
  Future<List<Map<String, dynamic>>> getUnits({
    required String grade,
    required String subject,
  }) async {
    final meta = await getSubjectMetadata(grade: grade, subject: subject);
    final units = meta?['units'];
    if (units is List) {
      return units
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  /// Normalized content items for a single unit, grouped-ready for the
  /// chapter screen. Reads `{unitFile}.json` which contains an `items` array;
  /// each item is normalized to the app's content-item map shape.
  Future<List<Map<String, dynamic>>> getUnitContent({
    required String grade,
    required String subject,
    required String unitFile,
  }) async {
    final file = unitFile.endsWith('.json') ? unitFile : '$unitFile.json';
    final path = '${_gradeSeg(grade)}/${_subjectSeg(subject)}/$file';
    final data = await _getJson(path);

    final rawItems = data is Map<String, dynamic>
        ? data['items']
        : (data is List ? data : null);
    if (rawItems is! List) return const [];

    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < rawItems.length; i++) {
      final raw = rawItems[i];
      if (raw is Map) {
        items.add(_normalizeItem(
          raw.cast<String, dynamic>(),
          grade: grade,
          subject: subject,
          unit: unitFile,
          index: i,
        ));
      }
    }
    return items;
  }

  // ============================================
  // NORMALIZATION
  // ============================================

  /// Maps a GitHub JSON content item into the same shape the content screens
  /// already read from Firestore, so no UI code has to change to adopt GitHub.
  Map<String, dynamic> _normalizeItem(
    Map<String, dynamic> raw, {
    required String grade,
    required String subject,
    required String unit,
    required int index,
  }) {
    final type = (raw['content_type'] ?? raw['type'] ?? '').toString();

    // Media URL can arrive under several names depending on content type.
    final downloadUrl = (raw['download_url'] ??
            raw['pdf_url'] ??
            raw['youtube_url'] ??
            raw['url'] ??
            '')
        .toString();

    final id = (raw['id'] ??
            'gh_${grade}_${subject}_${unit}_$index'
                .replaceAll(RegExp(r'\s+'), '_')
                .toLowerCase())
        .toString();

    return <String, dynamic>{
      'id': id,
      'title': (raw['title'] ?? 'Untitled').toString(),
      'content_type': type,
      'download_url': downloadUrl,
      'file_format': (raw['file_format'] ?? _defaultFormat(type)).toString(),
      'free_content': raw['free_content'] == true || raw['free'] == true,
      'source': 'github',
      // Optional metadata used by _getSubtitle in the chapter screen.
      if (raw['duration_seconds'] != null)
        'duration_seconds': raw['duration_seconds'],
      if (raw['file_size_mb'] != null) 'file_size_mb': raw['file_size_mb'],
      if (raw['page_count'] != null) 'page_count': raw['page_count'],
      if (raw['total_questions'] != null)
        'total_questions': raw['total_questions'],
      if (raw['time_limit_minutes'] != null)
        'time_limit_minutes': raw['time_limit_minutes'],
      if (raw['total_cards'] != null) 'total_cards': raw['total_cards'],
      if (raw['year'] != null) 'year': raw['year'],
      // Inline payloads for quiz/exam/flashcards (no extra fetch needed).
      if (raw['questions'] != null) 'questions': raw['questions'],
      if (raw['cards'] != null) 'cards': raw['cards'],
    };
  }

  String _defaultFormat(String type) {
    switch (type) {
      case 'video':
        return 'youtube';
      case 'short_note':
      case 'past_paper':
        return 'pdf';
      case 'quiz':
      case 'exam':
      case 'flashcard':
        return 'json';
      default:
        return 'json';
    }
  }

  // ============================================
  // FETCH + Isar CACHE (offline-first)
  // ============================================

  /// Fetches and decodes JSON at [path], honoring the Isar cache. Falls back
  /// to the last cached payload on any network/parse error so the catalog is
  /// always readable offline.
  Future<dynamic> _getJson(String path, {bool forceRefresh = false}) async {
    final url = '$_baseUrl/$path';
    final cacheKey = '$_cachePrefix$path';

    if (!forceRefresh) {
      final cached = await _isar.getContentEntry(cacheKey);
      if (cached != null && _isFresh(cached)) {
        final decoded = _decode(cached.payloadJson);
        if (decoded != null) return decoded;
      }
    }

    try {
      final res = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        await _isar.putContentEntry(ContentEntry()
          ..key = cacheKey
          ..payloadJson = res.body
          ..source = 'github'
          ..fetchedAt = DateTime.now()
          ..ttlSeconds = cacheTtl.inSeconds
          ..contentVersion = _contentVersion
          ..size = res.bodyBytes.length);
        return json.decode(res.body);
      }
      debugPrint('GithubContentService: $url -> HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('GithubContentService: fetch failed for $url: $e');
    }

    // Network failed — serve stale cache if present.
    final stale = await _isar.getContentEntry(cacheKey);
    if (stale != null) {
      final decoded = _decode(stale.payloadJson);
      if (decoded != null) return decoded;
    }
    return null;
  }

  bool _isFresh(ContentEntry entry) {
    final fetched = entry.fetchedAt;
    if (fetched == null) return false;
    return DateTime.now().difference(fetched) < cacheTtl;
  }

  dynamic _decode(String payload) {
    try {
      return jsonDecode(payload);
    } catch (_) {
      return null;
    }
  }

  /// Force a fresh fetch of a subject's metadata (e.g. pull-to-refresh).
  Future<Map<String, dynamic>?> refreshSubjectMetadata({
    required String grade,
    required String subject,
  }) async {
    final path = '${_gradeSeg(grade)}/${_subjectSeg(subject)}/metadata.json';
    final data = await _getJson(path, forceRefresh: true);
    return data is Map<String, dynamic> ? data : null;
  }

  /// Clears all cached GitHub content (e.g. on logout or manual reset).
  Future<void> clearCache() async {
    await _clearMetadataCache();
    await _isar.deleteContentEntry(_versionKey);
  }

  // ============================================
  // PATH SEGMENTS
  // ============================================

  /// `12` -> `Grade12`, leaves `university` and pre-formatted values alone.
  String _gradeSeg(String grade) {
    final g = grade.trim();
    if (RegExp(r'^\d+$').hasMatch(g)) return 'Grade$g';
    return g;
  }

  /// Subject folder is the lowercased, underscore-joined subject name.
  String _subjectSeg(String subject) =>
      subject.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}
