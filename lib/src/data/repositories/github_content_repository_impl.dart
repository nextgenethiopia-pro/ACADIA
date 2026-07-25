import '../../core/services/github_content_service.dart';
import '../../domain/repositories/github_content_repository.dart';

/// [GithubContentRepository] implementation delegating to
/// [GithubContentService]. Pure delegation — the caching/normalization logic
/// lives in the service; this exposes it behind the domain contract for DI.
class GithubContentRepositoryImpl implements GithubContentRepository {
  GithubContentRepositoryImpl(this._service);

  final GithubContentService _service;

  @override
  void configureBaseUrl(String? baseUrl) => _service.configureBaseUrl(baseUrl);

  @override
  Future<Map<String, dynamic>?> getSubjectMetadata({
    required String grade,
    required String subject,
  }) =>
      _service.getSubjectMetadata(grade: grade, subject: subject);

  @override
  Future<List<Map<String, dynamic>>> getUnits({
    required String grade,
    required String subject,
  }) =>
      _service.getUnits(grade: grade, subject: subject);

  @override
  Future<List<Map<String, dynamic>>> getUnitContent({
    required String grade,
    required String subject,
    required String unitFile,
  }) =>
      _service.getUnitContent(
        grade: grade,
        subject: subject,
        unitFile: unitFile,
      );

  @override
  Future<Map<String, dynamic>?> refreshSubjectMetadata({
    required String grade,
    required String subject,
  }) =>
      _service.refreshSubjectMetadata(grade: grade, subject: subject);

  @override
  Future<void> clearCache() => _service.clearCache();
}
