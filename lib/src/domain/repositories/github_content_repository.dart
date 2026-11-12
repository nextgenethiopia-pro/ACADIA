import '../models/unit_content_result.dart';

/// Contract for the GitHub-hosted content catalog (read path).
///
/// Implemented by [GithubContentRepositoryImpl] over `GithubContentService`.
/// This is the content read path in the target architecture: units and content
/// items come from GitHub JSON (cached 24h), while Firestore keeps only
/// identity, settings, payments, and entitlements.
abstract class GithubContentRepository {
  /// Points the underlying source at the repo/branch base URL from
  /// Firestore `settings/content_config.github_base_url`.
  void configureBaseUrl(String? baseUrl);

  /// Master subject index grouped by academic path.
  Future<Map<String, dynamic>?> getSubjectsIndex();

  /// Subjects declared for an academic metadata key.
  Future<List<Map<String, dynamic>>> getSubjects({
    required String academicKey,
  });

  /// Master entrance index grouped by stream.
  Future<Map<String, dynamic>?> getEntranceIndex();

  /// Entrance metadata for a stream.
  Future<Map<String, dynamic>?> getEntranceMetadata({
    required String stream,
  });

  /// Entrance content filtered by its metadata fields.
  Future<List<Map<String, dynamic>>> getEntranceContent({
    required String stream,
    String? subject,
    String? type,
    String? grade,
    String? year,
  });

  /// Table of contents for a subject (units + which content types exist).
  Future<Map<String, dynamic>?> getSubjectMetadata({
    required String grade,
    required String subject,
    String? stream,
  });

  /// Units declared in a subject's metadata.
  Future<List<Map<String, dynamic>>> getUnits({
    required String grade,
    required String subject,
    String? stream,
  });

  /// Normalized content items for a unit, in the app's content-item map shape.
  Future<List<Map<String, dynamic>>> getUnitContent({
    required String grade,
    required String subject,
    required String unitFile,
    String? stream,
  });

  /// Content items plus explicit per-section probe results, allowing the UI to
  /// distinguish empty, missing, malformed, and offline states.
  Future<UnitContentResult> getUnitContentResult({
    required String grade,
    required String subject,
    required String unitFile,
    String? stream,
  });

  /// Fetch only an Entrance Exam unit from the dedicated Entrance repository tree.
  Future<List<Map<String, dynamic>>> getEntranceExamUnitContent({
    required String stream,
    required String subject,
    required String grade,
    required String unit,
  });

  /// Force-refreshes the master subject index.
  Future<Map<String, dynamic>?> refreshSubjectsIndex();

  /// Force-refreshes the master entrance index and selected stream metadata.
  Future<Map<String, dynamic>?> refreshEntranceMetadata({
    required String stream,
  });

  /// Force-refresh a subject's metadata (bypasses the 24h cache).
  Future<Map<String, dynamic>?> refreshSubjectMetadata({
    required String grade,
    required String subject,
    String? stream,
  });

  /// Clears all cached GitHub content (logout / manual reset).
  Future<void> clearCache();
}
