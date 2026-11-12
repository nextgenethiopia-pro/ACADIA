import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';
import 'package:acadia/src/domain/models/unit_content_result.dart';

/// Authoritative GitHub Content Service for ACADIA.
///
/// Features:
/// - Offline-first caching via Isar [ContentEntry] (24h TTL, stale fallback on error).
/// - Centralized URL normalization for raw, blob, and relative GitHub URLs.
/// - Hardcoded academic curriculum navigation mapping to repository paths.
/// - Authoritative content file resolution:
///   - Short notes: `short_note/notes.json` (and binary PDFs)
///   - Quiz: `quiz/quiz.json`
///   - Exam: `exam/exam.json`
///   - Videos: `video/videos.json`
///   - Past papers: `past_paper/past_paper.json`
///   - Flashcards: `flashcard/flashcards.json`
/// - Entrance exam content handling from dedicated entrance repository tree.
class GithubContentService {
  GithubContentService({
    IsarService? isar,
    http.Client? client,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 300),
  })  : _isar = isar ?? IsarService.instance,
        _client = client ?? http.Client();

  static final GithubContentService instance = GithubContentService();

  final IsarService _isar;
  final http.Client _client;

  /// Extra attempts after the first request when GitHub fails transiently.
  final int maxRetries;

  /// Base backoff, multiplied by the retry attempt number.
  final Duration retryDelay;

  static bool _isTransientStatus(int status) =>
      status == 408 || status == 425 || status == 429 || status >= 500;

  /// Retries transport exceptions, timeouts and transient HTTP statuses so a
  /// single dropped connection does not surface as "repository unreachable".
  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send, {
    required String label,
    required Duration timeout,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        final response = await send().timeout(timeout);
        if (!_isTransientStatus(response.statusCode) || attempt >= maxRetries) {
          return response;
        }
        debugPrint(
            '[GithubContentService] HTTP ${response.statusCode} for $label; retrying (${attempt + 1}/$maxRetries)');
      } catch (e) {
        if (attempt >= maxRetries) rethrow;
        debugPrint(
            '[GithubContentService] Request failed for $label: $e; retrying (${attempt + 1}/$maxRetries)');
      }
      attempt++;
      await Future<void>.delayed(retryDelay * attempt);
    }
  }

  static const String defaultRawBaseUrl =
      'https://raw.githubusercontent.com/Acadia-et/ACADIA-CONTENT/main';
  static const String repoBaseUrl =
      'https://github.com/Acadia-et/ACADIA-CONTENT';

  String _baseUrl = defaultRawBaseUrl;

  /// Current base URL for raw content fetching.
  String get baseUrl => _baseUrl;

  /// Configure or override base URL (e.g. from Firestore content config).
  void configureBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      var clean = url.trim();
      while (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      _baseUrl = normalizeRawUrl(clean);
      debugPrint('[GithubContentService] Base URL configured: $_baseUrl');
    }
  }

  // ============================================================
  // URL NORMALIZATION (Centralized)
  // ============================================================

  /// Static helper for callers (e.g. DownloadManager) to normalize download URLs.
  static String normalizeDownloadUrl(String pathOrUrl) =>
      instance.normalizeRawUrl(pathOrUrl);

  /// Converts any GitHub URL (blob, raw, or relative path) into a valid raw.githubusercontent.com URL.
  String normalizeRawUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return '';

    var clean = pathOrUrl.trim();

    // Remove duplicated raw.githubusercontent.com segments if any
    while (clean.contains('raw.githubusercontent.com') &&
        clean.indexOf('raw.githubusercontent.com') !=
            clean.lastIndexOf('raw.githubusercontent.com')) {
      clean = clean.substring(clean.indexOf('raw.githubusercontent.com') +
          'raw.githubusercontent.com'.length);
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'https://raw.githubusercontent.com$clean';
      }
    }

    // Convert github.com blob URLs
    if (clean.contains('github.com/') && clean.contains('/blob/')) {
      clean = clean
          .replaceAll(
              'https://github.com/', 'https://raw.githubusercontent.com/')
          .replaceAll(
              'http://github.com/', 'https://raw.githubusercontent.com/')
          .replaceAll('/blob/', '/');
    }

    // Convert github.com raw URLs
    if (clean.contains('github.com/') && clean.contains('/raw/')) {
      clean = clean
          .replaceAll(
              'https://github.com/', 'https://raw.githubusercontent.com/')
          .replaceAll(
              'http://github.com/', 'https://raw.githubusercontent.com/')
          .replaceAll('/raw/', '/');
    }

    // Prepend raw base URL if it's a relative repository path
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      if (clean.startsWith('/')) {
        clean = clean.substring(1);
      }
      clean = '$_baseUrl/$clean';
    }

    // Properly encode spaces in path segments if not already encoded
    try {
      final uri = Uri.parse(clean);
      final encodedPath = uri.pathSegments
          .map((segment) => Uri.encodeComponent(Uri.decodeComponent(segment)))
          .join('/');
      return uri.replace(path: encodedPath).toString();
    } catch (_) {
      return clean.replaceAll(' ', '%20');
    }
  }

  // ============================================================
  // ISAR OFFLINE CACHE HELPERS
  // ============================================================

  Future<Map<String, dynamic>?> _getCachedJson(String key,
      {bool allowStale = false}) async {
    try {
      final entry = await _isar.getContentEntry(key);
      if (entry == null || entry.payloadJson.isEmpty) return null;

      if (!allowStale && entry.fetchedAt != null) {
        final age = DateTime.now().difference(entry.fetchedAt!).inSeconds;
        if (age > entry.ttlSeconds) {
          debugPrint('[GithubContentService] Cache expired for key: $key');
          return null; // Expired
        }
      }

      final decoded = json.decode(entry.payloadJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is List) {
        return {'items': decoded};
      }
    } catch (e) {
      debugPrint('[GithubContentService] Error reading cache for $key: $e');
    }
    return null;
  }

  Future<void> _saveCacheJson(String key, dynamic data,
      {int ttl = 86400, String? version}) async {
    try {
      final payload = json.encode(data);
      final entry = ContentEntry()
        ..key = key
        ..payloadJson = payload
        ..source = 'github'
        ..fetchedAt = DateTime.now()
        ..ttlSeconds = ttl
        ..contentVersion = version
        ..size = payload.length;

      await _isar.putContentEntry(entry);
      debugPrint(
          '[GithubContentService] Cached key: $key (${payload.length} bytes)');
    } catch (e) {
      debugPrint('[GithubContentService] Error saving cache for $key: $e');
    }
  }

  /// Clears all cached GitHub content entries from Isar.
  Future<void> clearCache() async {
    try {
      await _isar.clearContentEntries();
      debugPrint('[GithubContentService] Cleared content cache.');
    } catch (e) {
      debugPrint('[GithubContentService] Error clearing cache: $e');
    }
  }

  // ============================================================
  // LOW-LEVEL HTTP FETCHER
  // ============================================================

  /// Fetches and decodes a JSON file, keeping the failure reason instead of
  /// collapsing 404s, network errors, and malformed payloads into the same
  /// null result.
  Future<_JsonFetch> _fetchJson(String pathOrUrl) async {
    final primaryUrl = normalizeRawUrl(pathOrUrl);
    if (primaryUrl.isEmpty) {
      return const _JsonFetch(failure: _FetchFailure.invalidPath);
    }
    debugPrint('[GithubContentService] GET: $primaryUrl');

    try {
      final response = await _sendWithRetry(
        () => _client.get(Uri.parse(primaryUrl)),
        label: primaryUrl,
        timeout: const Duration(seconds: 15),
      );
      debugPrint(
          '[GithubContentService] HTTP ${response.statusCode} for $primaryUrl');

      if (response.statusCode == 404) {
        return _JsonFetch(
          failure: _FetchFailure.notFound,
          httpStatus: response.statusCode,
        );
      }
      if (response.statusCode != 200) {
        return _JsonFetch(
          failure: _FetchFailure.httpError,
          httpStatus: response.statusCode,
        );
      }

      var text = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
        text = text.substring(1);
      }
      if (text.trim().isEmpty) {
        return _JsonFetch(
          failure: _FetchFailure.invalidJson,
          httpStatus: response.statusCode,
        );
      }

      final decoded = json.decode(text);
      if (decoded is Map<String, dynamic>) {
        return _JsonFetch(
          data: decoded,
          httpStatus: response.statusCode,
        );
      }
      if (decoded is List) {
        return _JsonFetch(
          data: {'items': decoded},
          httpStatus: response.statusCode,
        );
      }
      return _JsonFetch(
        failure: _FetchFailure.invalidJson,
        httpStatus: response.statusCode,
      );
    } on TimeoutException {
      debugPrint('[GithubContentService] Timeout for $primaryUrl');
      return const _JsonFetch(failure: _FetchFailure.timeout);
    } on FormatException catch (e) {
      debugPrint('[GithubContentService] Invalid JSON for $primaryUrl: $e');
      return const _JsonFetch(failure: _FetchFailure.invalidJson);
    } catch (e) {
      debugPrint(
          '[GithubContentService] Network exception for $primaryUrl: $e');
      return const _JsonFetch(failure: _FetchFailure.network);
    }
  }

  Future<Map<String, dynamic>?> fetchJsonFromUrl(String pathOrUrl) async {
    final result = await _fetchJson(pathOrUrl);
    return result.data;
  }

  Future<bool?> _fileExists(String pathOrUrl) async {
    final url = normalizeRawUrl(pathOrUrl);
    if (url.isEmpty) return false;
    try {
      final response = await _sendWithRetry(
        () => _client.head(Uri.parse(url)),
        label: 'HEAD $url',
        timeout: const Duration(seconds: 6),
      );
      if (response.statusCode == 200) return true;
      if (response.statusCode == 404) return false;
      debugPrint(
          '[GithubContentService] HEAD ${response.statusCode} for $url; verifying with GET');
    } catch (e) {
      debugPrint(
          '[GithubContentService] HEAD failed for $url: $e; verifying with GET');
    }

    // Some networks and proxies reject HEAD even when GET works. A ranged GET
    // keeps the fallback verification lightweight.
    try {
      final response = await _sendWithRetry(
        () => _client.get(
          Uri.parse(url),
          headers: const {'Range': 'bytes=0-0'},
        ),
        label: 'GET $url',
        timeout: const Duration(seconds: 8),
      );
      if (response.statusCode == 200 || response.statusCode == 206) return true;
      if (response.statusCode == 404) return false;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // VERSION CHECK
  // ============================================================

  Future<String?> checkContentVersion({bool force = false}) async {
    final url = '$_baseUrl/version.json';
    final data = await fetchJsonFromUrl(url);
    if (data != null) {
      return data['version']?.toString();
    }
    return null;
  }

  // ============================================================
  // PATH & GRADE NORMALIZATION HELPERS
  // ============================================================

  String normalizeGrade(String grade) {
    final trimmed = grade.trim();
    if (trimmed.isEmpty) return 'Grade_9';
    if (trimmed.toLowerCase().startsWith('university')) return trimmed;

    final match = RegExp(r'(\d+)').firstMatch(trimmed);
    if (match != null) {
      return 'Grade_${match.group(1)}';
    }
    return trimmed;
  }

  String normalizeSubject(String subject) {
    return subject.trim().toLowerCase().replaceAll(' ', '_');
  }

  String resolveUnitFolder(String unit) {
    var clean = unit.trim();
    if (clean.endsWith('.json')) {
      clean = clean.substring(0, clean.length - 5);
    }
    // If it's in file format e.g. "Unit_1__INTRODUCTION_TO_BIOLOGY"
    // convert double underscore to "_ " and single underscores to spaces
    final fileMatch = RegExp(r'^Unit[_\s]*(\d+)[_\s]*__(.+)$', caseSensitive: false).firstMatch(clean);
    if (fileMatch != null) {
      final unitNum = fileMatch.group(1);
      final title = fileMatch.group(2)!.replaceAll('_', ' ');
      return 'Unit ${unitNum}_ $title';
    }

    // Replace colons with underscores to match GitHub repository folder names
    // e.g. "Unit 1: INTRODUCTION TO BIOLOGY" -> "Unit 1_ INTRODUCTION TO BIOLOGY"
    clean = clean.replaceAll(': ', '_ ').replaceAll(':', '_');
    return clean;
  }

  String resolveUnitJsonFileName(String unit) {
    var clean = unit.trim();
    if (clean.endsWith('.json')) return clean;

    // e.g. "Unit 1: INTRODUCTION TO BIOLOGY" -> "Unit_1__INTRODUCTION_TO_BIOLOGY.json"
    // Colons followed by space become double underscore
    clean = clean.replaceAll(': ', '__').replaceAll(':', '__');
    clean = clean.replaceAll(' ', '_');
    return '$clean.json';
  }

  /// Repository-relative subject folder for the supplied academic identity.
  ///
  /// University paths come from the hardcoded curriculum mappings; grade 11/12
  /// paths include the stream folder. Returns null when no such program exists
  /// in the repository (e.g. Social Science second semester).
  String? resolveSubjectBasePath({
    required String grade,
    required String subject,
    String? stream,
  }) {
    final trimmed = grade.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('university')) {
      final semesterMatch =
          RegExp(r'sem(?:ester)?[_\s-]*(\d+)').firstMatch(lower);
      final semester = semesterMatch?.group(1) ?? '1';
      final isPreEngineering = lower.contains('pre_engineering') ||
          lower.contains('pre-engineering') ||
          lower.contains('pre engineering');
      final track = isPreEngineering ? 'pre_engineering' : null;
      final universityStream = lower.contains('social') ? 'social' : 'natural';
      return AcademicStructure.getUniversitySubjectPath(
        semester: semester,
        stream: universityStream,
        subject: subject,
        track: track,
      );
    }

    final gradeNumber = RegExp(r'(\d+)').firstMatch(trimmed)?.group(1);
    if (gradeNumber == null) return null;

    final normGrade = 'Grade_$gradeNumber';
    final normSub = normalizeSubject(subject);
    if (gradeNumber == '9' || gradeNumber == '10') {
      return '$normGrade/$normSub';
    }

    final normalizedStream = (stream ?? '').trim().toLowerCase();
    final streamFolder = normalizedStream.contains('social')
        ? 'Social_Science'
        : 'Natural_Science';
    return '$normGrade/$streamFolder/$normSub';
  }

  List<String> unitFolderCandidates(String unit) {
    var raw = unit.trim();
    if (raw.endsWith('.json')) {
      raw = raw.substring(0, raw.length - 5);
    }
    if (raw.isEmpty) return const [];

    final resolved = resolveUnitFolder(raw);
    final candidates = <String>{resolved};

    final separator = resolved.indexOf('_');
    if (separator > 0) {
      final prefix = resolved.substring(0, separator + 1);
      final rest = resolved.substring(separator + 1).trim();
      if (rest.isNotEmpty) {
        candidates.add('$prefix $rest');
        candidates.add('$prefix${rest.toLowerCase()}');
        candidates.add('$prefix ${rest.toLowerCase()}');
        candidates.add(resolved.toUpperCase());
      }
    }
    candidates.add(raw);
    return candidates.where((candidate) => candidate.isNotEmpty).toList();
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String displayUnitTitle(String unit) {
    return AcademicStructure.displayChapterTitle(resolveUnitFolder(unit));
  }

  List<Map<String, dynamic>> _cachedItems(ContentEntry? entry) {
    if (entry == null || entry.payloadJson.isEmpty) return const [];
    try {
      final decoded = json.decode(entry.payloadJson);
      if (decoded is Map && decoded['items'] is List) {
        return (decoded['items'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (e) {
      debugPrint('[GithubContentService] Invalid cache payload: $e');
    }
    return const [];
  }

  Map<String, ContentProbe> _cachedProbes(ContentEntry? entry) {
    if (entry == null || entry.payloadJson.isEmpty) return const {};
    try {
      final decoded = json.decode(entry.payloadJson);
      if (decoded is Map && decoded['probes'] is List) {
        final probes = <String, ContentProbe>{};
        for (final raw in decoded['probes'] as List) {
          if (raw is Map) {
            final probe = ContentProbe.fromJson(Map<String, dynamic>.from(raw));
            probes[probe.type] = probe;
          }
        }
        return probes;
      }
    } catch (_) {}
    return const {};
  }

  // ============================================================
  // SUBJECTS & CURRICULUM INDEX
  // ============================================================

  Future<Map<String, dynamic>?> getSubjectsIndex() async {
    const cacheKey = 'gh_subjects_index';
    final cached = await _getCachedJson(cacheKey);
    if (cached != null) return cached;

    final data = await fetchJsonFromUrl('$_baseUrl/metadata/subjects.json');
    if (data != null) {
      await _saveCacheJson(cacheKey, data);
      return data;
    }

    // Build fallback from hardcoded AcademicStructure
    final fallback = <String, dynamic>{
      'high_school': {
        'Grade_9': AcademicStructure.grade9Subjects.keys.toList(),
        'Grade_10': AcademicStructure.grade10Subjects.keys.toList(),
        'Grade_11_Natural':
            AcademicStructure.grade11NaturalSubjects.keys.toList(),
        'Grade_11_Social':
            AcademicStructure.grade11SocialSubjects.keys.toList(),
        'Grade_12_Natural':
            AcademicStructure.grade12NaturalSubjects.keys.toList(),
        'Grade_12_Social':
            AcademicStructure.grade12SocialSubjects.keys.toList(),
      },
    };
    return fallback;
  }

  Future<Map<String, dynamic>?> refreshSubjectsIndex() async {
    const cacheKey = 'gh_subjects_index';
    final data = await fetchJsonFromUrl('$_baseUrl/metadata/subjects.json');
    if (data != null) {
      await _saveCacheJson(cacheKey, data);
      return data;
    }
    return getSubjectsIndex();
  }

  Future<List<Map<String, dynamic>>> getSubjects(
      {required String academicKey}) async {
    final index = await getSubjectsIndex();
    if (index == null) return [];

    final subjects = <Map<String, dynamic>>[];
    // Extract matching subjects for key
    if (index.containsKey(academicKey) && index[academicKey] is List) {
      for (final s in index[academicKey]) {
        subjects.add({'id': s.toString(), 'name': s.toString()});
      }
    }
    return subjects;
  }

  // ============================================================
  // SUBJECT METADATA & UNITS
  // ============================================================

  Future<Map<String, dynamic>?> getSubjectMetadata({
    required String grade,
    required String subject,
    String? stream,
  }) async {
    final normSub = normalizeSubject(subject);
    final basePath =
        resolveSubjectBasePath(grade: grade, subject: subject, stream: stream);
    final cacheKey =
        'gh_sub_meta_${basePath != null ? _slugify(basePath) : _slugify(grade)}_$normSub';

    final cached = await _getCachedJson(cacheKey);
    if (cached != null) return cached;

    if (basePath != null) {
      final data = await fetchJsonFromUrl('$_baseUrl/$basePath/metadata.json');
      if (data != null) {
        await _saveCacheJson(cacheKey, data);
        return data;
      }
    }

    final units = _curriculumUnits(grade, subject, stream);
    return {
      'id': '${normSub}_${normalizeGrade(grade)}',
      'grade': normalizeGrade(grade),
      'subject': normSub,
      'units': units
          .map((u) => {
                'id': resolveUnitJsonFileName(u).replaceAll('.json', ''),
                'title': u,
                'file': resolveUnitJsonFileName(u),
                'folder': resolveUnitFolder(u),
                'content_types': [
                  'short_note',
                  'video',
                  'quiz',
                  'exam',
                  'past_paper',
                  'flashcard'
                ],
              })
          .toList(),
    };
  }

  Future<Map<String, dynamic>?> refreshSubjectMetadata({
    required String grade,
    required String subject,
    String? stream,
  }) async {
    final basePath =
        resolveSubjectBasePath(grade: grade, subject: subject, stream: stream);
    if (basePath != null) {
      final cacheKey =
          'gh_sub_meta_${_slugify(basePath)}_${normalizeSubject(subject)}';
      final data = await fetchJsonFromUrl('$_baseUrl/$basePath/metadata.json');
      if (data != null) {
        await _saveCacheJson(cacheKey, data);
        return data;
      }
    }
    return getSubjectMetadata(grade: grade, subject: subject, stream: stream);
  }

  List<String> _curriculumUnits(String grade, String subject, String? stream) {
    final lower = grade.trim().toLowerCase();
    if (lower.startsWith('university')) {
      final semesterMatch =
          RegExp(r'sem(?:ester)?[_\s-]*(\d+)').firstMatch(lower);
      final semester = semesterMatch?.group(1) ?? '1';
      final universityStream = lower.contains('social') ? 'social' : 'natural';
      final track = lower.contains('pre_engineering') ||
              lower.contains('pre-engineering') ||
              lower.contains('pre engineering')
          ? 'pre_engineering'
          : 'other_natural_science';
      return AcademicStructure.getUniversityChapters(
          semester, universityStream, subject, track);
    }
    final gradeNum = RegExp(r'(\d+)').firstMatch(grade)?.group(1) ?? '9';
    return AcademicStructure.getChapters(
        gradeNum, stream ?? 'natural', subject);
  }

  Future<List<Map<String, dynamic>>> getUnits({
    required String grade,
    required String subject,
    String? stream,
  }) async {
    final meta = await getSubjectMetadata(
        grade: grade, subject: subject, stream: stream);
    if (meta != null && meta['units'] is List) {
      return List<Map<String, dynamic>>.from(meta['units']);
    }

    final chapters = _curriculumUnits(grade, subject, stream);
    return chapters
        .map((c) => {
              'id': resolveUnitJsonFileName(c).replaceAll('.json', ''),
              'title': displayUnitTitle(c),
              'file': resolveUnitJsonFileName(c),
              'folder': resolveUnitFolder(c),
            })
        .toList();
  }

  // ============================================================
  // UNIT CONTENT FETCHING (Highest Priority)
  // ============================================================

  Future<List<Map<String, dynamic>>> getUnitContent({
    required String grade,
    required String subject,
    required String unitFile,
    String? stream,
  }) async {
    final result = await getUnitContentResult(
      grade: grade,
      subject: subject,
      unitFile: unitFile,
      stream: stream,
    );
    return result.items;
  }

  /// Resolves every designated content file for a curriculum unit.
  ///
  /// This is the authoritative read path:
  /// short_note/notes.json (or the published PDF), quiz/quiz.json,
  /// exam/exam.json, video/videos.json, past_paper/past_paper.json,
  /// flashcard/flashcards.json. The curriculum supplies the unit folder name;
  /// no subject/unit metadata or directory listing is required to navigate.
  Future<UnitContentResult> getUnitContentResult({
    required String grade,
    required String subject,
    required String unitFile,
    String? stream,
  }) async {
    final basePath = resolveSubjectBasePath(
      grade: grade,
      subject: subject,
      stream: stream,
    );
    if (basePath == null) {
      return const UnitContentResult(
        items: [],
        status: UnitContentStatus.unsupportedPath,
        message:
            'This programme does not have published content in the repository yet.',
      );
    }

    final candidates = unitFolderCandidates(unitFile);
    if (candidates.isEmpty) {
      return UnitContentResult(
        items: const [],
        status: UnitContentStatus.missingUnit,
        message: 'The chapter identifier is empty.',
        unitPath: basePath,
      );
    }

    var unitFolder = candidates.first;
    var networkUnavailable = false;

    // Fast matching against published subject metadata if available
    final meta = await getSubjectMetadata(grade: grade, subject: subject, stream: stream);
    if (meta != null && meta['units'] is List) {
      final unitNum = RegExp(r'(\d+)').firstMatch(unitFile)?.group(1);
      final cleanUnit = unitFile.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      for (final u in meta['units']) {
        if (u is Map) {
          final uFolder = u['folder']?.toString() ?? '';
          final uFile = u['file']?.toString() ?? '';
          final uTitle = u['title']?.toString() ?? '';
          final uId = u['id']?.toString() ?? '';
          final mNum = RegExp(r'(\d+)').firstMatch(uTitle.isNotEmpty ? uTitle : uFolder)?.group(1);
          final cleanMeta = (uFolder + uFile + uTitle + uId).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

          if ((unitNum != null && mNum != null && unitNum == mNum) ||
              cleanMeta.contains(cleanUnit) ||
              cleanUnit.contains(cleanMeta)) {
            if (uFolder.isNotEmpty) {
              unitFolder = uFolder;
              break;
            }
          }
        }
      }
    }

    // Verify folder exists or check candidate folders
    for (final candidate in candidates) {
      final exists =
          await _fileExists('$_baseUrl/$basePath/$candidate/short_note/notes.json') ??
          await _fileExists('$_baseUrl/$basePath/$candidate/metadata.json');
      if (exists == null) {
        networkUnavailable = true;
        break;
      }
      if (exists) {
        unitFolder = candidate;
        break;
      }
    }

    final baseSlug = _slugify(basePath);
    final unitSlug = _slugify(unitFolder.isNotEmpty ? unitFolder : candidates.first);
    // v5 cache key includes unitSlug so content from different units is never mixed.
    final cacheKey = 'gh_content_v5_${baseSlug}_$unitSlug';
    final cacheEntry = await _isar.getContentEntry(cacheKey);

    final unitBase = '$basePath/$unitFolder';
    final unitUrl = '$_baseUrl/$unitBase';
    final displayTitle = displayUnitTitle(unitFile);
    final probes = <String, ContentProbe>{};
    final items = <Map<String, dynamic>>[];

    debugPrint(
        '[GithubContentService] Resolving unit: $unitBase (unitFile="$unitFile", slug="$unitSlug")');

    // 1. Short notes: the authoritative source is short_note/notes.json under the specific unit folder.
    final shortNote = await _resolveShortNote(
      unitUrl: unitUrl,
      displayTitle: displayTitle,
      subject: subject,
      grade: grade,
      chapter: unitFile,
      baseSlug: baseSlug,
      unitSlug: unitSlug,
    );
    probes['short_note'] = shortNote.probe;
    items.addAll(shortNote.items);

    // 2. Structured sections with authoritative file names.
    const sections = <String, List<String>>{
      'quiz': ['quiz', 'quiz.json'],
      'exam': ['exam', 'exam.json'],
      'video': ['video', 'videos.json'],
      'past_paper': ['past_paper', 'past_paper.json'],
      'flashcard': ['flashcard', 'flashcards.json'],
    };

    var itemIndex = 0;
    for (final entry in sections.entries) {
      final type = entry.key;
      final sectionUrl =
          normalizeRawUrl('$unitUrl/${entry.value[0]}/${entry.value[1]}');
      final response = await _fetchJson(sectionUrl);
      probes[type] = _probeFromFetch(type, response);

      if (response.data == null) continue;
      final rawItems = _extractSectionItems(response.data!);
      for (final raw in rawItems) {
        items.add(_normalizeSectionItem(
          raw: raw,
          type: type,
          sectionUrl: sectionUrl,
          index: itemIndex++,
          baseSlug: baseSlug,
          unitSlug: unitSlug,
          displayTitle: displayTitle,
          subject: subject,
          grade: grade,
          chapter: unitFile,
          unitPath: unitBase,
        ));
      }
    }

    // 3. Subject-level unit JSON fallback only if nothing resolved
    if (items.isEmpty) {
      final legacyUrl = normalizeRawUrl(
          '$_baseUrl/$basePath/${resolveUnitJsonFileName(unitFolder)}');
      final legacy = await _fetchJson(legacyUrl);
      final legacyItems = legacy.data == null
          ? <Map<String, dynamic>>[]
          : _extractSectionItems(legacy.data!);
      for (var i = 0; i < legacyItems.length; i++) {
        final raw = legacyItems[i];
        final type = raw['content_type']?.toString().toLowerCase().trim() ?? '';
        if (type.isEmpty) continue;
        items.add(_normalizeSectionItem(
          raw: raw,
          type: type,
          sectionUrl: normalizeRawUrl(raw['download_url']?.toString() ?? ''),
          index: itemIndex++,
          baseSlug: baseSlug,
          unitSlug: unitSlug,
          displayTitle: displayTitle,
          subject: subject,
          grade: grade,
          chapter: unitFile,
          unitPath: unitBase,
        ));
      }
    }

    final hasNetworkFailure =
        probes.values.any((p) => p.status == ContentProbeStatus.networkError);
    // Any non-network probe outcome (including a 404) proves GitHub responded,
    // so a failed metadata HEAD alone must not be reported as unreachable.
    final repositoryResponded =
        probes.values.any((p) => p.status != ContentProbeStatus.networkError);
    final repositoryUnreachable =
        hasNetworkFailure || (networkUnavailable && !repositoryResponded);
    final hasInvalidJson =
        probes.values.any((p) => p.status == ContentProbeStatus.invalidJson);
    final allMissing = probes.isNotEmpty &&
        probes.values.every((p) => p.status == ContentProbeStatus.missing);

    if (items.isNotEmpty) {
      final partial = probes.values.any((p) => p.failed);
      final status =
          partial ? UnitContentStatus.partial : UnitContentStatus.success;
      final message = partial
          ? 'Some content loaded. One or more sections could not be fetched.'
          : 'Content loaded.';
      await _saveCacheJson(cacheKey, {
        'items': items,
        'probes': probes.values.map((p) => p.toJson()).toList(),
      });
      debugPrint(
          '[GithubContentService] Resolved ${items.length} items for $unitBase');
      return UnitContentResult(
        items: items,
        status: status,
        message: message,
        probes: probes,
        unitPath: unitBase,
      );
    }

    // No usable items: prefer previously saved content for network failures.
    if (repositoryUnreachable && cacheEntry != null) {
      final staleItems = _cachedItems(cacheEntry);
      if (staleItems.isNotEmpty) {
        return UnitContentResult(
          items: staleItems,
          status: UnitContentStatus.offlineCached,
          message:
              'The content repository is unreachable. Showing previously saved content.',
          probes: _cachedProbes(cacheEntry),
          fromCache: true,
          unitPath: basePath,
        );
      }
    }

    if (repositoryUnreachable) {
      return UnitContentResult(
        items: const [],
        status: UnitContentStatus.offlineNoCache,
        message:
            'No content is downloaded for this chapter yet. Turn on internet to download it.',
        probes: probes,
        unitPath: basePath,
      );
    }

    if (allMissing) {
      return UnitContentResult(
        items: const [],
        status: UnitContentStatus.missingUnit,
        message:
            'The content files for this chapter were not found in the repository.',
        probes: probes,
        unitPath: basePath,
      );
    }

    if (hasInvalidJson) {
      return UnitContentResult(
        items: const [],
        status: UnitContentStatus.invalidJson,
        message:
            'The repository returned content that could not be read for this chapter.',
        probes: probes,
        unitPath: basePath,
      );
    }

    return UnitContentResult(
      items: const [],
      status: UnitContentStatus.empty,
      message:
          'This chapter is published but currently contains no content items.',
      probes: probes,
      unitPath: basePath,
    );
  }

  /// Short notes come exclusively from `short_note/notes.json`. Repository PDF
  /// files are intentionally not used; the viewer renders the structured JSON
  /// by generating a local PDF document from it.
  Future<_ShortNoteResolution> _resolveShortNote({
    required String unitUrl,
    required String displayTitle,
    required String subject,
    required String grade,
    required String chapter,
    required String baseSlug,
    required String unitSlug,
  }) async {
    final notesUrl = normalizeRawUrl('$unitUrl/short_note/notes.json');
    final notesResponse = await _fetchJson(notesUrl);

    if (notesResponse.data != null) {
      final notes = notesResponse.data!;
      final items = <Map<String, dynamic>>[];

      final rawItems = notes['items'] ?? notes['materials'];
      if (rawItems is List && rawItems.isNotEmpty) {
        for (var i = 0; i < rawItems.length; i++) {
          final raw = rawItems[i];
          if (raw is Map) {
            final rawMap = Map<String, dynamic>.from(raw);
            final rawId = rawMap['id']?.toString().trim() ?? '';
            final rawTitle = rawMap['title']?.toString().trim() ?? '';
            final rawUrl = rawMap['download_url']?.toString().trim() ?? '';
            final downloadUrl =
                rawUrl.isNotEmpty ? normalizeRawUrl(rawUrl) : notesUrl;
            final isPdf = downloadUrl.toLowerCase().endsWith('.pdf');

            items.add({
              'id': rawId.isNotEmpty
                  ? rawId
                  : 'gh_${baseSlug}_${unitSlug}_short_note_$i',
              'title': rawTitle.isNotEmpty
                  ? rawTitle
                  : '$displayTitle Notes ${i + 1}',
              'content_type': 'short_note',
              'download_url': downloadUrl,
              'file_format': rawMap['file_format']?.toString() ??
                  (isPdf ? 'pdf' : 'json'),
              'file_size_mb': rawMap['file_size_mb'],
              'has_pdf': isPdf,
              'requires_pdf_generation': !isPdf,
              'subject': subject,
              'grade': grade,
              'chapter': chapter,
              'free_content': rawMap['free_content'] ?? false,
              'source': 'github',
            });
          }
        }
      }

      if (items.isEmpty) {
        final chapterData = notes['chapter'] ?? notes['metadata'];
        final noteTitle = chapterData is Map
            ? (chapterData['chapter_title'] ?? chapterData['title'])
                ?.toString()
                .trim()
            : null;
        items.add({
          'id': 'gh_${baseSlug}_${unitSlug}_short_note',
          'title': (noteTitle != null && noteTitle.isNotEmpty)
              ? noteTitle
              : '$displayTitle Notes',
          'content_type': 'short_note',
          'download_url': notesUrl,
          'file_format': 'json',
          'has_pdf': false,
          'requires_pdf_generation': true,
          'subject': subject,
          'grade': grade,
          'chapter': chapter,
          'free_content': false,
          'source': 'github',
        });
      }

      return _ShortNoteResolution(
        items: items,
        probe: const ContentProbe(
          type: 'short_note',
          status: ContentProbeStatus.found,
          httpStatus: 200,
        ),
      );
    }

    return _ShortNoteResolution(
      items: const [],
      probe: _probeFromFetch('short_note', notesResponse),
    );
  }

  List<Map<String, dynamic>> _extractSectionItems(Map<String, dynamic> data) {
    final raw = data['items'] ?? data['content'] ?? data['materials'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data['questions'] is List || data['cards'] is List) {
      return [Map<String, dynamic>.from(data)];
    }
    return const [];
  }

  Map<String, dynamic> _normalizeSectionItem({
    required Map<String, dynamic> raw,
    required String type,
    required String sectionUrl,
    required int index,
    required String baseSlug,
    required String unitSlug,
    required String displayTitle,
    required String subject,
    required String grade,
    required String chapter,
    required String unitPath,
  }) {
    final normalized = Map<String, dynamic>.from(raw);
    final rawId = raw['id']?.toString().trim() ?? '';
    final rawTitle = raw['title']?.toString().trim() ?? '';
    final rawUrl = raw['download_url']?.toString().trim() ?? '';

    normalized['id'] =
        rawId.isNotEmpty ? rawId : 'gh_${baseSlug}_${unitSlug}_${type}_$index';
    normalized['title'] = rawTitle.isNotEmpty
        ? rawTitle
        : '$displayTitle ${_sectionLabel(type)} ${index + 1}';
    normalized['content_type'] = type;
    if (type == 'video') {
      normalized['download_url'] = normalizeRawUrl(rawUrl);
    } else {
      normalized['download_url'] =
          rawUrl.isNotEmpty ? normalizeRawUrl(rawUrl) : sectionUrl;
    }
    normalized['file_format'] =
        raw['file_format']?.toString() ?? (type == 'video' ? '' : 'json');
    normalized['subject'] = subject;
    normalized['grade'] = grade;
    normalized['chapter'] = chapter;
    normalized['unit_path'] = unitPath;
    normalized['free_content'] = raw['free_content'] ?? false;
    normalized['source'] = 'github';

    final questions = raw['questions'];
    if (normalized['total_questions'] == null && questions is List) {
      normalized['total_questions'] = questions.length;
    }
    final cards = raw['cards'];
    if (normalized['total_cards'] == null && cards is List) {
      normalized['total_cards'] = cards.length;
    }
    return normalized;
  }

  String _sectionLabel(String type) {
    switch (type) {
      case 'quiz':
        return 'Quiz';
      case 'exam':
        return 'Exam';
      case 'video':
        return 'Video';
      case 'past_paper':
        return 'Past Paper';
      case 'flashcard':
        return 'Flashcards';
      default:
        return 'Content';
    }
  }

  ContentProbe _probeFromFetch(String type, _JsonFetch response) {
    if (response.data != null) {
      return ContentProbe(
        type: type,
        status: ContentProbeStatus.found,
        httpStatus: response.httpStatus,
      );
    }
    switch (response.failure) {
      case _FetchFailure.notFound:
        return ContentProbe(
          type: type,
          status: ContentProbeStatus.missing,
          httpStatus: response.httpStatus ?? 404,
        );
      case _FetchFailure.invalidJson:
      case _FetchFailure.invalidPath:
        return ContentProbe(
          type: type,
          status: ContentProbeStatus.invalidJson,
          httpStatus: response.httpStatus,
        );
      default:
        return ContentProbe(
          type: type,
          status: ContentProbeStatus.networkError,
          httpStatus: response.httpStatus,
        );
    }
  }

  // ============================================================
  // ENTRANCE CONTENT & PAST PAPERS
  // ============================================================

  Future<Map<String, dynamic>?> getEntranceIndex() async {
    const cacheKey = 'gh_entrance_index';
    final cached = await _getCachedJson(cacheKey);
    if (cached != null) return cached;

    final data = await fetchJsonFromUrl('$_baseUrl/entrance/index.json');
    if (data != null) {
      await _saveCacheJson(cacheKey, data);
      return data;
    }

    final fallback = {
      'streams': ['natural_science', 'social_science'],
    };
    return fallback;
  }

  String _normalizeStreamKey(String stream) {
    final lower = stream.trim().toLowerCase();
    if (lower.contains('social')) return 'social_science';
    return 'natural_science';
  }

  Future<Map<String, dynamic>?> getEntranceMetadata(
      {required String stream}) async {
    final streamKey = _normalizeStreamKey(stream);
    final cacheKey = 'gh_entrance_meta_$streamKey';

    final cached = await _getCachedJson(cacheKey);
    if (cached != null) return cached;

    final remoteUrl = '$_baseUrl/entrance/$streamKey.json';
    final data = await fetchJsonFromUrl(remoteUrl);
    if (data != null) {
      await _saveCacheJson(cacheKey, data);
      return data;
    }

    return null;
  }

  Future<Map<String, dynamic>?> refreshEntranceMetadata(
      {required String stream}) async {
    final streamKey = _normalizeStreamKey(stream);
    final cacheKey = 'gh_entrance_meta_$streamKey';

    final remoteUrl = '$_baseUrl/entrance/$streamKey.json';
    final data = await fetchJsonFromUrl(remoteUrl);
    if (data != null) {
      await _saveCacheJson(cacheKey, data);
      return data;
    }
    return getEntranceMetadata(stream: stream);
  }

  Future<List<Map<String, dynamic>>> getEntranceContent({
    required String stream,
    String? subject,
    String? type,
    String? grade,
    String? year,
  }) async {
    final meta = await getEntranceMetadata(stream: stream);
    if (meta == null) return [];

    final streamKey = _normalizeStreamKey(stream);
    final streamFolder =
        streamKey == 'social_science' ? 'Social_Science' : 'Natural_Science';
    final subjectFilter = (subject ?? '').trim().toLowerCase();
    final typeFilter = (type ?? '').trim().toLowerCase();
    final gradeFilter = (grade ?? '').trim();
    final yearFilter = (year ?? '').trim();

    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    bool matchesFilters(Map<String, dynamic> item) {
      if (subjectFilter.isNotEmpty && subjectFilter != 'all') {
        final itemSubject =
            item['subject']?.toString().toLowerCase().trim() ?? '';
        if (itemSubject != subjectFilter) return false;
      }
      if (typeFilter.isNotEmpty && typeFilter != 'all') {
        final itemType =
            item['content_type']?.toString().toLowerCase().trim() ?? '';
        if (itemType != typeFilter) return false;
      }
      if (gradeFilter.isNotEmpty && gradeFilter != 'All') {
        final itemGrade = item['grade']?.toString().trim() ?? '';
        if (itemGrade.isNotEmpty && itemGrade != gradeFilter) return false;
      }
      if (yearFilter.isNotEmpty && yearFilter != 'All') {
        final itemYear = item['year']?.toString().trim() ?? '';
        if (itemYear.isNotEmpty && itemYear != yearFilter) return false;
      }
      return true;
    }

    void addUnique(Map<String, dynamic> item) {
      final key = '${item['content_type']}|${item['year']}|${item['subject']}'
          .toLowerCase();
      if (!seen.add(key)) return;
      result.add(item);
    }

    final rawItems = meta['items'] ?? meta['content'] ?? meta['materials'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        if (!matchesFilters(item)) continue;

        final itemType =
            item['content_type']?.toString().toLowerCase().trim() ?? '';
        final itemYear = item['year']?.toString().trim() ?? '';
        final itemSubject = item['subject']?.toString().trim() ?? '';

        if (itemType == 'past_paper' &&
            itemYear.isNotEmpty &&
            itemSubject.isNotEmpty) {
          // The stream metadata contains stale/wrong past-paper URLs. Rebuild
          // the canonical repository path instead of trusting the index.
          item['download_url'] = normalizeRawUrl(
              '$_baseUrl/entrance/$streamFolder/past_papers/$itemYear/$itemSubject.json');
        } else {
          item['download_url'] =
              normalizeRawUrl(item['download_url']?.toString() ?? '');
        }
        addUnique(item);
      }
    }

    // Metadata only lists a subset of past-paper items; the repository holds
    // a file for every year in `pastPapers.years`. Build the full, real list
    // from that declaration instead of inventing or omitting years.
    final wantsPastPapers =
        typeFilter.isEmpty || typeFilter == 'all' || typeFilter == 'past_paper';
    if (wantsPastPapers) {
      final pastPapers = meta['pastPapers'];
      final years = <int>[];
      final subjects = <String>[];
      if (pastPapers is Map) {
        final rawYears = pastPapers['years'];
        if (rawYears is List) {
          years.addAll(rawYears
              .map((y) => int.tryParse(y.toString()) ?? 0)
              .where((y) => y > 0));
        }
        final rawSubjects = pastPapers['subjects'];
        if (rawSubjects is List) {
          subjects.addAll(rawSubjects
              .map((s) => s.toString().trim())
              .where((s) => s.isNotEmpty));
        }
      }
      if (years.isNotEmpty && subjects.isNotEmpty) {
        for (final paperYear in years.toSet().toList()..sort((a, b) => b - a)) {
          for (final paperSubject in subjects.toSet()) {
            final candidate = <String, dynamic>{
              'id':
                  'entrance_${streamKey}_${_slugify(paperSubject)}_$paperYear',
              'subject': paperSubject,
              'title': '$paperSubject - $paperYear',
              'year': paperYear,
              'content_type': 'past_paper',
              'download_url': normalizeRawUrl(
                  '$_baseUrl/entrance/$streamFolder/past_papers/$paperYear/$paperSubject.json'),
              'file_format': 'json',
              'source': 'github',
            };
            if (!matchesFilters(candidate)) continue;
            addUnique(candidate);
          }
        }
      }
    }

    result.sort((a, b) {
      final yearA = int.tryParse(a['year']?.toString() ?? '') ?? 0;
      final yearB = int.tryParse(b['year']?.toString() ?? '') ?? 0;
      if (yearA != yearB) return yearB.compareTo(yearA);
      return (a['subject']?.toString() ?? '')
          .compareTo(b['subject']?.toString() ?? '');
    });
    return result;
  }

  /// The entrance tree exposes curriculum metadata per unit but currently has
  /// no practice quiz/exam files. Returning an empty list is intentional: the
  /// UI must state that practice content is not published rather than probing
  /// invented paths.
  Future<List<Map<String, dynamic>>> getEntranceExamUnitContent({
    required String stream,
    required String subject,
    required String grade,
    required String unit,
  }) async {
    return const [];
  }
}

enum _FetchFailure {
  none,
  notFound,
  httpError,
  invalidJson,
  invalidPath,
  timeout,
  network,
}

class _JsonFetch {
  const _JsonFetch({
    this.data,
    this.httpStatus,
    this.failure = _FetchFailure.none,
  });

  final Map<String, dynamic>? data;
  final int? httpStatus;
  final _FetchFailure failure;
}

class _ShortNoteResolution {
  const _ShortNoteResolution({required this.items, required this.probe});

  final List<Map<String, dynamic>> items;
  final ContentProbe probe;
}
