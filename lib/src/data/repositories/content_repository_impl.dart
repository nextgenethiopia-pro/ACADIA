import '../../core/services/firebase_service.dart';
import '../../domain/repositories/content_repository.dart';

/// [ContentRepository] implementation delegating to [FirebaseService].
///
/// Pure delegation — no logic change; only exposes the generic service behind
/// the content domain contract for DI and testability.
class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl(this._service);

  final FirebaseService _service;

  @override
  Future<List<Map<String, dynamic>>> getChapters(
    Map<String, dynamic> where,
  ) =>
      _service.getDocuments('chapters', where: where);

  @override
  Future<List<Map<String, dynamic>>> getContentForUnit({
    required String grade,
    required String? stream,
    required String subject,
    required String unit,
  }) =>
      _service.getContentForUnit(
        grade: grade,
        stream: stream,
        subject: subject,
        unit: unit,
      );

  @override
  Future<List<Map<String, dynamic>>> getContent(
    Map<String, dynamic> where,
  ) =>
      _service.getDocuments('content', where: where);

  @override
  Future<void> addContent({
    required String type,
    required String grade,
    required String? stream,
    required String subject,
    required String unit,
    required String title,
    required String externalUrl,
    String? description,
    String? thumbnailUrl,
  }) =>
      _service.addContent(
        type: type,
        grade: grade,
        stream: stream,
        subject: subject,
        unit: unit,
        title: title,
        externalUrl: externalUrl,
        description: description,
        thumbnailUrl: thumbnailUrl,
      );

  @override
  Future<String> addDocument(String collection, Map<String, dynamic> data) =>
      _service.addDocument(collection, data);

  @override
  Future<void> updateContent(String contentId, Map<String, dynamic> data) =>
      _service.updateContent(contentId, data);

  @override
  Future<void> deleteContent(String contentId) =>
      _service.deleteContent(contentId);

  @override
  Future<void> deleteDocument(String collection, String docId) =>
      _service.deleteDocument(collection, docId);

  @override
  Future<dynamic> fetchRemoteJson(String url) => _service.fetchRemoteJson(url);
}
