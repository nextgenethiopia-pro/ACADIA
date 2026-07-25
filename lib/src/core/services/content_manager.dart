import '../error/app_exception.dart';
import '../utils/result.dart';
import 'github_content_service.dart';

/// Offline-first content orchestration layer.
///
/// Thin application service over [GithubContentService] that:
///  * exposes a typed [Result]-based API so presentation code never catches
///    raw network errors;
///  * adds bounded retry with exponential backoff for transient failures
///    (timeouts, socket/handshake/connection errors);
///  * owns the global content-version probe and cache-reset entry points.
///
/// The heavy lifting (GitHub fetch, normalize, Isar cache + stale fallback) is
/// delegated to [GithubContentService]; this class composes and hardens it so
/// screens migrate to one clean, dependency-injected (riverpod) entry point.
class ContentManager {
  ContentManager({required GithubContentService github}) : _github = github;

  final GithubContentService _github;

  /// Retry attempts after the first try for a transient failure
  /// (1 initial + [maxRetries] = 3 requests worst case).
  static const int maxRetries = 2;

  /// Probes `version.json` and, on a bump, evicts stale catalog rows so the
  /// next read pulls fresh content. Safe to call on startup; network failures
  /// are swallowed (the cached version wins and the app stays usable).
  Future<String?> ensureContentVersion({bool force = false}) =>
      _github.checkContentVersion(force: force);

  /// Subject table of contents (`{units: [...]}`). Cache-first; returns an
  /// [Err] with a user-facing message when nothing is available offline.
  Future<Result<Map<String, dynamic>>> getSubjectMetadata({
    required String grade,
    required String subject,
  }) async {
    try {
      final data = await _withRetry(
        () => _github.getSubjectMetadata(grade: grade, subject: subject),
      );
      if (data != null) return Ok(data);
      return const Err(NotFoundException(
          'Subject content is not available offline. Connect to the internet and try again.'));
    } on Exception catch (e) {
      return Err(NetworkException('Failed to load subject metadata.', cause: e));
    }
  }

  /// Units list for a subject. Cache-first.
  Future<Result<List<Map<String, dynamic>>>> getUnits({
    required String grade,
    required String subject,
  }) async {
    try {
      final units =
          await _withRetry(() => _github.getUnits(grade: grade, subject: subject));
      return Ok(units);
    } on Exception catch (e) {
      return Err(NetworkException('Failed to load units.', cause: e));
    }
  }

  /// Normalized content items for a unit. Cache-first.
  Future<Result<List<Map<String, dynamic>>>> getUnitContent({
    required String grade,
    required String subject,
    required String unitFile,
  }) async {
    try {
      final items = await _withRetry(
        () => _github.getUnitContent(
            grade: grade, subject: subject, unitFile: unitFile),
      );
      return Ok(items);
    } on Exception catch (e) {
      return Err(NetworkException('Failed to load content.', cause: e));
    }
  }

  /// Force a network refresh of a subject's metadata (pull-to-refresh).
  Future<Result<Map<String, dynamic>>> refreshSubjectMetadata({
    required String grade,
    required String subject,
  }) async {
    try {
      final data =
          await _github.refreshSubjectMetadata(grade: grade, subject: subject);
      if (data != null) return Ok(data);
      return const Err(NotFoundException(
          'Subject content could not be refreshed. Check your connection.'));
    } on Exception catch (e) {
      return Err(NetworkException('Refresh failed.', cause: e));
    }
  }

  /// Drops the entire content cache (logout / manual reset).
  Future<void> clearCache() => _github.clearCache();

  /// Retries [fn] up to [maxRetries] times with exponential backoff
  /// (0.5s, 1s, 2s). Only retries on transient failures (timeout / socket /
  /// handshake / host-lookup / connection errors); permanent errors rethrow.
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    var attempt = 0;
    while (true) {
      try {
        return await fn().timeout(const Duration(seconds: 15));
      } on Exception catch (e) {
        if (attempt >= maxRetries || !_isTransient(e)) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
        attempt++;
      }
    }
  }

  bool _isTransient(Exception e) {
    final text = e.toString().toLowerCase();
    return text.contains('timeout') ||
        text.contains('socket') ||
        text.contains('handshake') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('failed host lookup');
  }
}
