import '../../core/services/download_manager.dart';
import '../../core/services/offline_database.dart';
import '../../domain/repositories/download_repository.dart';

/// [DownloadRepository] implementation delegating to [DownloadManager] for
/// the download orchestration and [OfflineDatabase] for record persistence.
///
/// Pure delegation — no logic change; only wires the two existing singletons
/// behind the download domain contract for DI and testability.
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(this._downloadManager, this._offlineDatabase);

  final DownloadManager _downloadManager;
  final OfflineDatabase _offlineDatabase;

  @override
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
  }) =>
      _downloadManager.downloadContent(
        contentId: contentId,
        title: title,
        downloadUrl: downloadUrl,
        contentType: contentType,
        fileFormat: fileFormat,
        subject: subject,
        chapter: chapter,
        grade: grade,
        pageCount: pageCount,
        totalQuestions: totalQuestions,
        totalCards: totalCards,
        onProgress: onProgress,
      );

  @override
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
  }) =>
      _downloadManager.resumeDownload(
        contentId: contentId,
        title: title,
        downloadUrl: downloadUrl,
        contentType: contentType,
        fileFormat: fileFormat,
        subject: subject,
        chapter: chapter,
        grade: grade,
        pageCount: pageCount,
        totalQuestions: totalQuestions,
        totalCards: totalCards,
        onProgress: onProgress,
      );

  @override
  void cancelDownload(String contentId) =>
      _downloadManager.cancelDownload(contentId);

  @override
  void cancelAllDownloads() => _downloadManager.cancelAllDownloads();

  @override
  double? getDownloadProgress(String contentId) =>
      _downloadManager.getDownloadProgress(contentId);

  @override
  bool isDownloading(String contentId) =>
      _downloadManager.isDownloading(contentId);

  @override
  List<String> getActiveDownloads() => _downloadManager.getActiveDownloads();

  @override
  Future<bool> hasInternetConnection() =>
      _downloadManager.hasInternetConnection();

  @override
  String formatFileSize(int bytes) => _downloadManager.formatFileSize(bytes);

  // ---- Offline persistence ----

  @override
  Future<bool> isContentDownloaded(String contentId) =>
      _offlineDatabase.isContentDownloaded(contentId);

  @override
  Future<Map<String, dynamic>?> getDownloadRecord(String contentId) =>
      _offlineDatabase.getDownloadRecord(contentId);

  @override
  Future<List<Map<String, dynamic>>> getAllDownloads() =>
      _offlineDatabase.getAllDownloads();

  @override
  Future<List<Map<String, dynamic>>> getDownloadsByType(String contentType) =>
      _offlineDatabase.getDownloadsByType(contentType);

  @override
  Future<void> deleteDownload(String contentId) =>
      _offlineDatabase.deleteDownload(contentId);

  @override
  Future<void> deleteAllDownloads() => _offlineDatabase.deleteAllDownloads();

  @override
  Future<int> getTotalStorageUsed() => _offlineDatabase.getTotalStorageUsed();
}
