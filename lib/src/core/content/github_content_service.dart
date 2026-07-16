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
/// Expected repo layout (see the content repo README for the full schema):
/// ```
/// manifest.json                            # { "version": "2025.07.16" }
/// structure.txt                            # canonical academic path
/// high-school/grade_10/biology.json        # per-subject index: units -> items
/// high-school/grade_10/biology/unit1-quiz.json   # quiz/exam/flashcard detail
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

  /// Builds the repo-relative path to a subject's index file, e.g.
  /// `high-school/grade_10/biology.json` or
  /// `university/freshman/sem1/natural/mathematics.json`.
  String subjectIndexPath({
    required String? academicPath,
    required String grade,
    required String? stream,
    required String subject,
    String semester = '1',
    String? track,
  }) {
    final slug = _slug(subject);
    final streamSlug = (stream ?? 'natural').toLowerCase().contains('social')
        ? 'social'
        : 'natural';

    if (academicPath == 'university' || academicPath == 'UNIVERSITY') {
      if (semester == '2') {
        final trackSlug = (track ?? '').toLowerCase().contains('pre')
            ? 'pre_engineering'
            : 'other_natural';
        return 'university/freshman/sem2/$trackSlug/$slug.json';
      }
      return 'university/freshman/sem1/$streamSlug/$slug.json';
    }

    if (grade == '11' || grade == '12') {
      return 'high-school/grade_$grade/$streamSlug/$slug.json';
    }
    return 'high-school/grade_$grade/$slug.json';
  }

  /// Fetches the content items for a single unit/chapter of a subject.
  ///
  /// Returns items shaped like the Firestore `content` documents
  /// (`content_type`, `title`, `download_url`, `id`, ...), so callers can treat
  /// GitHub and Firestore content uniformly. Returns an empty list when the
  /// subject file or unit is not found.
  Future<List<Map<String, dynamic>>> fetchChapterItems({
    required String? academicPath,
    required String grade,
    required String? stream,
    required String subject,
    required String unit,
    String semester = '1',
    String? track,
  }) async {
    final path = subjectIndexPath(
      academicPath: academicPath,
      grade: grade,
      stream: stream,
      subject: subject,
      semester: semester,
      track: track,
    );

    final data = await fetchJson(path);
    final units = data?['units'];
    if (units is! List) return const [];

    final target = unit.trim().toLowerCase();
    for (final u in units) {
      if (u is! Map) continue;
      final name = u['unit']?.toString().trim().toLowerCase();
      if (name != target) continue;
      final items = u['items'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: false);
    }
    return const [];
  }

  /// Builds the repo-relative path to an entrance-exam subject index, e.g.
  /// `entrance/grade_12/biology.json`. Entrance content is organised by grade
  /// and subject (independent of the high-school/university academic tree),
  /// with chapters as the grouping unit.
  String entranceIndexPath({
    required String grade,
    required String subject,
  }) =>
      'entrance/grade_$grade/${_slug(subject)}.json';

  /// Fetches entrance-exam content items for a subject and grade from GitHub.
  ///
  /// The index file uses the same shape as a subject index — a `units` (or
  /// `chapters`) list, each with a name and an `items` list. Returned items are
  /// flattened and tagged with `chapter`, `subject`, and `grade` so callers can
  /// group them and treat them like Firestore `entrance_materials` documents.
  Future<List<Map<String, dynamic>>> fetchEntranceItems({
    required String grade,
    required String subject,
  }) async {
    final data = await fetchJson(entranceIndexPath(grade: grade, subject: subject));
    final groups = data?['units'] ?? data?['chapters'];
    if (groups is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final group in groups) {
      if (group is! Map) continue;
      final chapter =
          (group['unit'] ?? group['chapter'] ?? '').toString();
      final items = group['items'];
      if (items is! List) continue;
      for (final m in items.whereType<Map>()) {
        final item = Map<String, dynamic>.from(m);
        item['chapter'] ??= chapter;
        item['subject'] ??= subject;
        item['grade'] ??= grade;
        out.add(item);
      }
    }
    return out;
  }

  String _slug(String subject) =>
      subject.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

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
