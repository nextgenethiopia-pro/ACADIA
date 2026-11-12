import '../../core/services/github_content_service.dart';
import '../../domain/models/unit_content_result.dart';
import '../../domain/repositories/github_content_repository.dart';

/// [GithubContentRepository] implementation delegating to
/// [GithubContentService]. Pure delegation — the caching/normalization logic
/// lives in the service; this exposes it behind the domain contract for DI.
class GithubContentRepositoryImpl implements GithubContentRepository {
  GithubContentRepositoryImpl(this._service);

  final GithubContentService _service;

  /// Preserves university identifiers instead of collapsing them into a
  /// numeric grade. Actual path normalization belongs to the service.
  String _normalizeGrade(String grade) {
    final trimmed = grade.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.toLowerCase().startsWith('university')) return trimmed;
    return _service.normalizeGrade(trimmed);
  }

  @override
  void configureBaseUrl(String? baseUrl) => _service.configureBaseUrl(baseUrl);

  @override
  Future<Map<String, dynamic>?> getSubjectsIndex() =>
      _service.getSubjectsIndex();

  @override
  Future<List<Map<String, dynamic>>> getSubjects({
    required String academicKey,
  }) =>
      _service.getSubjects(academicKey: academicKey);

  @override
  Future<Map<String, dynamic>?> getEntranceIndex() =>
      _service.getEntranceIndex();

  @override
  Future<Map<String, dynamic>?> getEntranceMetadata({
    required String stream,
  }) =>
      _service.getEntranceMetadata(stream: stream);

  @override
  Future<List<Map<String, dynamic>>> getEntranceContent({
    required String stream,
    String? subject,
    String? type,
    String? grade,
    String? year,
  }) =>
      _service.getEntranceContent(
        stream: stream,
        subject: subject,
        type: type,
        grade: grade,
        year: year,
      );

  @override
  Future<Map<String, dynamic>?> getSubjectMetadata({
    required String grade,
    required String subject,
    String? stream,
  }) =>
      _service.getSubjectMetadata(
        grade: _normalizeGrade(grade),
        subject: subject,
        stream: stream,
      );

  @override
  Future<List<Map<String, dynamic>>> getUnits({
    required String grade,
    required String subject,
    String? stream,
  }) =>
      _service.getUnits(
        grade: _normalizeGrade(grade),
        subject: subject,
        stream: stream,
      );

  @override
  Future<List<Map<String, dynamic>>> getUnitContent({
    required String grade,
    required String subject,
    required String unitFile,
    String? stream,
  }) =>
      _service.getUnitContent(
        grade: _normalizeGrade(grade),
        subject: subject,
        unitFile: unitFile,
        stream: stream,
      );

  @override
  Future<UnitContentResult> getUnitContentResult({
    required String grade,
    required String subject,
    required String unitFile,
    String? stream,
  }) =>
      _service.getUnitContentResult(
        grade: _normalizeGrade(grade),
        subject: subject,
        unitFile: unitFile,
        stream: stream,
      );

  @override
  Future<List<Map<String, dynamic>>> getEntranceExamUnitContent({
    required String stream,
    required String subject,
    required String grade,
    required String unit,
  }) =>
      _service.getEntranceExamUnitContent(
        stream: stream,
        subject: subject,
        grade: grade,
        unit: unit,
      );

  @override
  Future<Map<String, dynamic>?> refreshSubjectsIndex() =>
      _service.refreshSubjectsIndex();

  @override
  Future<Map<String, dynamic>?> refreshEntranceMetadata({
    required String stream,
  }) =>
      _service.refreshEntranceMetadata(stream: stream);

  @override
  Future<Map<String, dynamic>?> refreshSubjectMetadata({
    required String grade,
    required String subject,
    String? stream,
  }) =>
      _service.refreshSubjectMetadata(
        grade: _normalizeGrade(grade),
        subject: subject,
        stream: stream,
      );

  @override
  Future<void> clearCache() => _service.clearCache();
}