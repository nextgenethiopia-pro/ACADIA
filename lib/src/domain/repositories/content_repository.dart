/// Contract for content and chapter catalog reads/writes.
///
/// Implemented by [ContentRepositoryImpl] over `FirebaseService`. Wraps the
/// generic Firestore access used by the content/admin screens behind a
/// domain-named API. Return types mirror the underlying service so existing
/// screens can adopt this incrementally without behavior changes.
abstract class ContentRepository {
  /// Chapters matching the given academic-path filters.
  Future<List<Map<String, dynamic>>> getChapters(Map<String, dynamic> where);

  /// Content items for a specific unit/chapter (stream-aware).
  Future<List<Map<String, dynamic>>> getContentForUnit({
    required String grade,
    required String? stream,
    required String subject,
    required String unit,
  });

  /// Raw content documents matching arbitrary filters.
  Future<List<Map<String, dynamic>>> getContent(Map<String, dynamic> where);

  /// Adds a structured content item.
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
  });

  /// Adds an arbitrary document to a collection; returns the new id.
  Future<String> addDocument(String collection, Map<String, dynamic> data);

  /// Updates a content item.
  Future<void> updateContent(String contentId, Map<String, dynamic> data);

  /// Deletes a content item.
  Future<void> deleteContent(String contentId);

  /// Generic document delete (chapters, etc.).
  Future<void> deleteDocument(String collection, String docId);

  /// Fetches and decodes remote JSON (Internet Archive/Drive links).
  Future<dynamic> fetchRemoteJson(String url);
}
