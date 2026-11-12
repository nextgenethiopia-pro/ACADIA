import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/download_manager.dart';
import '../../local_database/isar_service.dart';
import '../../domain/repositories/download_repository.dart';

/// [DownloadRepository] implementation delegating to [DownloadManager] for
/// the download orchestration and [IsarService] for record persistence.
///
/// Uses Isar for offline storage as per the new architecture.
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(this._downloadManager, this._isarService);

  final DownloadManager _downloadManager;
  final IsarService _isarService;

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
  Future<bool> isContentDownloaded(String contentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final downloaded = await _isarService.getDownloadedContentById(contentId, user.uid);
    return downloaded != null;
  }

  @override
  Future<Map<String, dynamic>?> getDownloadRecord(String contentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final downloaded = await _isarService.getDownloadedContentById(contentId, user.uid);
    if (downloaded == null) return null;
    return {
      'content_id': downloaded.contentId,
      'subject': downloaded.subject,
      'chapter': downloaded.chapter,
      'content_type': downloaded.contentType,
      'file_size_bytes': downloaded.fileSize,
      'download_date': downloaded.downloadedAt?.toIso8601String(),
      'local_path': downloaded.contentPath,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final downloadedContents = await _isarService.getAllDownloadedContent(user.uid);
    return downloadedContents.map((content) => {
      'content_id': content.contentId,
      'subject': content.subject,
      'chapter': content.chapter,
      'content_type': content.contentType,
      'file_size_bytes': content.fileSize,
      'download_date': content.downloadedAt?.toIso8601String(),
      'local_path': content.contentPath,
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getDownloadsByType(String contentType) async {
    final allDownloads = await getAllDownloads();
    return allDownloads.where((d) => d['content_type'] == contentType).toList();
  }

  @override
  Future<void> deleteDownload(String contentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _isarService.deleteDownloadedContent(contentId, user.uid);
  }

  @override
  Future<void> deleteAllDownloads() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final allDownloads = await _isarService.getAllDownloadedContent(user.uid);
    for (final content in allDownloads) {
      await _isarService.deleteDownloadedContent(content.contentId ?? '', user.uid);
    }
  }

  @override
  Future<int> getTotalStorageUsed() async {
    final allDownloads = await getAllDownloads();
    return allDownloads.fold<int>(0, (sum, d) => sum + (d['file_size_bytes'] as int? ?? 0));
  }
}
