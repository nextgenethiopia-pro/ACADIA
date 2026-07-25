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

  /// Table of contents for a subject (units + which content types exist).
  Future<Map<String, dynamic>?> getSubjectMetadata({
    required String grade,
    required String subject,
  });

  /// Units declared in a subject's metadata.
  Future<List<Map<String, dynamic>>> getUnits({
    required String grade,
    required String subject,
  });

  /// Normalized content items for a unit, in the app's content-item map shape.
  Future<List<Map<String, dynamic>>> getUnitContent({
    required String grade,
    required String subject,
    required String unitFile,
  });

  /// Force-refresh a subject's metadata (bypasses the 24h cache).
  Future<Map<String, dynamic>?> refreshSubjectMetadata({
    required String grade,
    required String subject,
  });

  /// Clears all cached GitHub content (logout / manual reset).
  Future<void> clearCache();
}
