import '../../core/services/download_manager.dart';

/// Contract for content download lifecycle and offline file tracking.
///
/// Implemented by [DownloadRepositoryImpl] over [DownloadManager] (download
/// orchestration, progress callbacks) and `OfflineDatabase` (download-record
/// persistence). The presentation layer resolves this via DI instead of
/// instantiating the underlying services directly.
abstract class DownloadRepository {
  /// Downloads a content item to private app storage.
  ///
  /// Returns the local file path on success. [onProgress] reports 0.0–1.0.
  /// Throws on auth, connectivity, or disk failures — callers should catch.
  Future<String> downloadContent({
    required String contentId,
    required String title,
    required String downloadUrl,
    required String contentType,
    required String fileFormat,
    required String subject,
    required String chapter,
    required String grade,
    int? pageCount,
    int? totalQuestions,
    int? totalCards,
    Function(double)? onProgress,
  });

  /// Resumes (re-starts) a download if the server supports range requests.
  Future<void> resumeDownload({
    required String contentId,
    required String title,
    required String downloadUrl,
    required String contentType,
    required String fileFormat,
    required String subject,
    required String chapter,
    required String grade,
    int? pageCount,
    int? totalQuestions,
    int? totalCards,
    Function(double)? onProgress,
  });

  /// Cancels an in-flight download by content id.
  void cancelDownload(String contentId);

  /// Cancels every active download.
  void cancelAllDownloads();

  /// Progress (0.0–1.0) for an active download, or null if none.
  double? getDownloadProgress(String contentId);

  /// Whether a download is currently in progress for [contentId].
  bool isDownloading(String contentId);

  /// Content ids currently being downloaded.
  List<String> getActiveDownloads();

  /// Whether the device currently has any network connection.
  Future<bool> hasInternetConnection();

  /// Human-readable size label (e.g. "1.2 MB").
  String formatFileSize(int bytes);

  // ---- Offline persistence (delegated to OfflineDatabase) ----

  /// Whether [contentId] has been fully downloaded and is available offline.
  Future<bool> isContentDownloaded(String contentId);

  /// The persisted download record for [contentId], or null.
  Future<Map<String, dynamic>?> getDownloadRecord(String contentId);

  /// All offline download records (for the Downloads manager screen).
  Future<List<Map<String, dynamic>>> getAllDownloads();

  /// Download records filtered by content type.
  Future<List<Map<String, dynamic>>> getDownloadsByType(String contentType);

  /// Removes a downloaded file and its record.
  Future<void> deleteDownload(String contentId);

  /// Removes every downloaded file and record.
  Future<void> deleteAllDownloads();

  /// Total bytes used by offline content.
  Future<int> getTotalStorageUsed();
}
