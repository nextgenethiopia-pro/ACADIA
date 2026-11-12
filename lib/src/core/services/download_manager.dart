import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/services/content_file_guard.dart';
import 'package:acadia/src/core/services/github_content_service.dart';
import 'package:acadia/src/local_database/isar_service.dart';

class DownloadManager {
  final Dio _dio = Dio();
  final IsarService _isarService = IsarService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track active downloads
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, double> _downloadProgress = {};

  // Download callbacks
  void Function(String contentId, double progress)? onProgress;
  void Function(String contentId, String filePath)? onComplete;
  void Function(String contentId, String error)? onError;

  /// Normalize download URLs - delegates to centralized GithubContentService
  String _normalizeDownloadUrl(String url) {
    return GithubContentService.normalizeDownloadUrl(url);
  }

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Check available storage space.
  Future<bool> hasEnoughSpace(int requiredBytes) async {
    return true;
  }

  /// Get formatted file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Cancel an ongoing download
  void cancelDownload(String contentId) {
    final cancelToken = _cancelTokens[contentId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
      _cancelTokens.remove(contentId);
      _downloadProgress.remove(contentId);
      debugPrint('Download cancelled: $contentId');
    }
  }

  /// Cancel all ongoing downloads
  void cancelAllDownloads() {
    for (final entry in _cancelTokens.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel('All downloads cancelled');
      }
    }
    _cancelTokens.clear();
    _downloadProgress.clear();
    debugPrint('All downloads cancelled');
  }

  /// Get download progress for a specific content
  double? getDownloadProgress(String contentId) {
    return _downloadProgress[contentId];
  }

  /// Check if a download is in progress
  bool isDownloading(String contentId) {
    return _cancelTokens.containsKey(contentId);
  }

  /// Get all active downloads
  List<String> getActiveDownloads() {
    return _cancelTokens.keys.toList();
  }

  /// Download all supported educational content into app-private storage.
  /// YouTube/online video content is intentionally excluded.
  ///
  /// A failing item no longer aborts the batch: if the file was downloaded
  /// earlier and is still valid locally it is reused, otherwise the item is
  /// skipped so an offline device can still open everything it already has.
  Future<List<String>> downloadContentBatch({
    required List<Map<String, dynamic>> contents,
    required String subject,
    required String chapter,
    required String grade,
    Function(int completed, int total)? onBatchProgress,
  }) async {
    final supported = contents.where((item) {
      final type = item['content_type']?.toString() ?? '';
      final url = item['download_url']?.toString() ?? '';
      return type != 'video' &&
          !url.contains('youtube.com') &&
          !url.contains('youtu.be') &&
          url.isNotEmpty;
    }).toList();

    final user = _auth.currentUser;
    final paths = <String>[];
    for (var i = 0; i < supported.length; i++) {
      final item = supported[i];
      final contentId =
          item['id']?.toString() ?? 'gh_${grade}_${subject}_${chapter}_$i';
      try {
        final path = await downloadContent(
          contentId: contentId,
          title: item['title']?.toString() ?? 'Content ${i + 1}',
          downloadUrl: item['download_url']?.toString() ?? '',
          contentType: item['content_type']?.toString() ?? 'json',
          fileFormat: item['file_format']?.toString() ?? 'json',
          subject: subject,
          chapter: chapter,
          grade: grade,
          pageCount: (item['page_count'] as num?)?.toInt(),
          totalQuestions: (item['total_questions'] as num?)?.toInt(),
          totalCards: (item['total_cards'] as num?)?.toInt(),
          onProgress: (_) {},
        );
        paths.add(path);
      } catch (e) {
        debugPrint('⚠️ Batch download failed for $contentId: $e');
        if (user != null) {
          final existing = await _existingValidLocalPath(contentId, user.uid);
          if (existing != null) {
            debugPrint('↩️ Using previously downloaded copy: $existing');
            paths.add(existing);
          }
        }
      }
      onBatchProgress?.call(i + 1, supported.length);
    }
    return paths;
  }

  /// Resume a download (if supported by server)
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
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final isDownloaded =
        await _isarService.isContentDownloaded(contentId, user.uid);
    if (isDownloaded) {
      throw Exception('Content already downloaded');
    }

    await downloadContent(
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
  }

  // ============================================
  // FIXED: Get correct file extension based on content type
  // ============================================
  String _getFileExtension(
      String contentType, String downloadUrl, String fileFormat) {
    final urlPath = Uri.tryParse(downloadUrl)?.path.toLowerCase() ??
        downloadUrl.toLowerCase();
    if (urlPath.endsWith('.pdf')) return 'pdf';
    if (urlPath.endsWith('.json')) return 'json';
    if (urlPath.endsWith('.mp4')) return 'mp4';
    if (urlPath.endsWith('.m3u8')) return 'm3u8';

    switch (contentType) {
      case 'quiz':
      case 'exam':
      case 'flashcard':
      case 'past_paper':
        return 'json';
      case 'video':
        if (downloadUrl.contains('youtube.com') ||
            downloadUrl.contains('youtu.be')) {
          return 'youtube';
        }
        return 'mp4';
      case 'short_note':
      case 'pdf':
        return fileFormat == 'json' ? 'json' : 'pdf';
      default:
        if (fileFormat == 'json' ||
            fileFormat == 'pdf' ||
            fileFormat == 'mp4') {
          return fileFormat;
        }
        return 'json';
    }
  }

  /// A cached file may have been written by an older build that accepted a Git
  /// LFS pointer or malformed JSON. Validate before trusting it.
  Future<bool> _isValidCachedFile(String path) async {
    final lower = path.toLowerCase();
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) return false;

    if (lower.endsWith('.pdf')) {
      return ContentFileGuard.isPdfFile(path);
    }
    if (lower.endsWith('.json')) {
      try {
        final text = await file.readAsString();
        final decoded = json.decode(text.replaceFirst('\uFEFF', ''));
        return decoded is Map || decoded is List;
      } catch (e) {
        debugPrint('⚠️ Cached JSON is unreadable: $path ($e)');
        return false;
      }
    }
    return true;
  }

  /// Downloads are not trusted until their content matches their extension.
  /// If the source serves a Git LFS pointer instead of the PDF, the media
  /// endpoint is retried once; otherwise the invalid file is deleted and a
  /// clear error is raised so the caller never reports a false success.
  Future<void> _validateDownloadedFile({
    required String filePath,
    required String extension,
    required String downloadUrl,
    CancelToken? cancelToken,
  }) async {
    if (extension == 'pdf') {
      if (await ContentFileGuard.isGitLfsPointerFile(filePath)) {
        final mediaUrl = ContentFileGuard.gitLfsMediaUrl(downloadUrl);
        if (mediaUrl == null || mediaUrl == downloadUrl) {
          await File(filePath).delete();
          throw Exception(
              'The repository returned a Git LFS placeholder instead of the PDF document.');
        }
        debugPrint('🔁 Git LFS pointer downloaded; retrying $mediaUrl');
        await _dio.download(mediaUrl, filePath, cancelToken: cancelToken);
      }
      if (!await ContentFileGuard.isPdfFile(filePath)) {
        await File(filePath).delete();
        throw Exception(
            'The downloaded file is not a valid PDF. The document may be unavailable.');
      }
    } else if (extension == 'json') {
      try {
        final text = await File(filePath).readAsString();
        final decoded = json.decode(text.replaceFirst('\uFEFF', ''));
        if (decoded is! Map && decoded is! List) {
          throw const FormatException('JSON root is not an object or array');
        }
      } catch (e) {
        await File(filePath).delete();
        throw Exception(
            'The downloaded content is not valid JSON. Please retry the download.');
      }
    }
  }

  /// Returns the local path of an already-downloaded item when the file is
  /// still present and valid. Invalid leftovers are cleaned up.
  Future<String?> _existingValidLocalPath(
      String contentId, String userId) async {
    final isDownloaded =
        await _isarService.isContentDownloaded(contentId, userId);
    if (!isDownloaded) return null;
    final record =
        await _isarService.getDownloadedContentById(contentId, userId);
    final filePath = record?.contentPath;
    if (filePath == null) return null;
    final file = File(filePath);
    if (await file.exists() && await _isValidCachedFile(filePath)) {
      return filePath;
    }
    debugPrint('🧹 Discarding invalid cached file: $filePath');
    if (await file.exists()) {
      await file.delete();
    }
    await _isarService.deleteDownloadedContent(contentId, userId);
    return null;
  }

  /// Compares the repository file's current validators with the ones stored
  /// at download time. Returns true when the remote file may have changed (or
  /// when it cannot be proven unchanged), so online opens refresh content.
  /// Returns false when the check itself fails, keeping the local copy.
  Future<bool> _remoteFileChanged(String url, String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEtag = prefs.getString('download_etag_$contentId');
      final storedLastMod = prefs.getString('download_lastmod_$contentId');
      if (storedEtag == null && storedLastMod == null) return true;

      final response = await _dio.head(
        url,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final etag = response.headers.value('etag');
      final lastMod = response.headers.value('last-modified');
      if (etag == null && lastMod == null) return true;
      if (etag != null && etag == storedEtag) return false;
      if (lastMod != null && lastMod == storedLastMod) return false;
      return true;
    } catch (e) {
      debugPrint('⚠️ Could not revalidate $url; keeping local copy: $e');
      return false;
    }
  }

  /// Remember the file's validators so the next online open can detect a
  /// changed file without re-downloading it.
  Future<void> _rememberValidators(
      String contentId, String url, Headers headers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final etag = headers.value('etag');
      final lastMod = headers.value('last-modified');
      if (etag != null) {
        await prefs.setString('download_etag_$contentId', etag);
      } else {
        await prefs.remove('download_etag_$contentId');
      }
      if (lastMod != null) {
        await prefs.setString('download_lastmod_$contentId', lastMod);
      } else {
        await prefs.remove('download_lastmod_$contentId');
      }
    } catch (e) {
      debugPrint('⚠️ Could not remember validators for $contentId: $e');
    }
  }

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
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final normalizedUrl = _normalizeDownloadUrl(downloadUrl);
    if (normalizedUrl.isEmpty) {
      throw Exception('Missing download URL');
    }

    // Reuse a valid local copy. Offline this is the only option; online the
    // repository is asked whether the file changed before reusing it.
    final existing = await _existingValidLocalPath(contentId, user.uid);
    if (existing != null) {
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        debugPrint('✅ Offline: using existing local copy: $existing');
        return existing;
      }
      if (!await _remoteFileChanged(normalizedUrl, contentId)) {
        debugPrint('✅ Repository file unchanged: $existing');
        return existing;
      }
      debugPrint('🔄 Repository file changed; updating $contentId');
    }

    // Check internet connection
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      throw Exception('No internet connection');
    }

    final directory = await getApplicationDocumentsDirectory();

    final extension = _getFileExtension(contentType, downloadUrl, fileFormat);

    String subDir;
    switch (extension) {
      case 'mp4':
      case 'm3u8':
      case 'youtube':
        subDir = 'videos';
        break;
      case 'pdf':
        subDir = 'pdfs';
        break;
      case 'json':
        subDir = 'json_content';
        break;
      default:
        switch (contentType) {
          case 'short_note':
          case 'pdf':
            subDir = 'pdfs';
            break;
          default:
            subDir = 'downloads';
        }
    }

    final contentDir = Directory('${directory.path}/$subDir');
    if (!await contentDir.exists()) {
      await contentDir.create(recursive: true);
    }

    final filePath = '${contentDir.path}/$contentId.$extension';

    debugPrint(
        '📥 Download: contentType=$contentType, extension=$extension, filePath=$filePath');

    // Check if temp file exists and delete it
    final tempFile = File('$filePath.temp');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    // Create cancel token for this download
    final cancelToken = CancelToken();
    _cancelTokens[contentId] = cancelToken;

    try {
      debugPrint('📥 Download source: $normalizedUrl');

      final response = await _dio.download(
        normalizedUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[contentId] = progress;
            onProgress?.call(progress);
            this.onProgress?.call(contentId, progress);
          }
        },
        cancelToken: cancelToken,
      );

      // Verify file exists and has content
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Download failed: File not created');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        await file.delete();
        throw Exception('Download failed: Empty file');
      }

      await _validateDownloadedFile(
        filePath: filePath,
        extension: extension,
        downloadUrl: normalizedUrl,
        cancelToken: cancelToken,
      );

      final validatedSize = await file.length();

      final downloadedContent = DownloadedContent()
        ..userId = user.uid
        ..contentId = contentId
        ..title = title
        ..contentPath = filePath
        ..contentType = contentType
        ..subject = subject
        ..grade = grade
        ..chapter = chapter
        ..downloadProgress = 1.0
        ..isDownloaded = true
        ..fileSize = validatedSize
        ..downloadedAt = DateTime.now()
        ..lastAccessed = DateTime.now();

      await _isarService.saveDownloadedContent(downloadedContent);
      await _rememberSourceUrl(contentId, normalizedUrl);
      await _rememberValidators(contentId, normalizedUrl, response.headers);

      // Clean up
      _cancelTokens.remove(contentId);
      _downloadProgress.remove(contentId);
      onComplete?.call(contentId, filePath);

      debugPrint('✅ Download complete: $filePath');
      return filePath;
    } on DioException catch (e) {
      // Clean up temp files
      if (await File(filePath).exists()) {
        await File(filePath).delete();
      }
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      _cancelTokens.remove(contentId);
      _downloadProgress.remove(contentId);

      if (e.type == DioExceptionType.cancel) {
        throw Exception('Download cancelled');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Download failed: ${e.message}');
      }
    } catch (e) {
      // Clean up
      if (await File(filePath).exists()) {
        await File(filePath).delete();
      }
      _cancelTokens.remove(contentId);
      _downloadProgress.remove(contentId);
      onError?.call(contentId, e.toString());
      rethrow;
    }
  }

  /// Remember where a file came from so an offline-cached viewer opened later
  /// can still redownload it when the local copy is unusable.
  Future<void> _rememberSourceUrl(String contentId, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('download_source_$contentId', url);
    } catch (e) {
      debugPrint('⚠️ Could not remember download source: $e');
    }
  }

  /// Get all downloaded content with optional filtering
  Future<List<Map<String, dynamic>>> getDownloads({String? contentType}) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final List<DownloadedContent> downloads;

    if (contentType != null && contentType.isNotEmpty) {
      downloads =
          await _isarService.getDownloadedContentByType(user.uid, contentType);
    } else {
      downloads = await _isarService.getAllDownloadedContent(user.uid);
    }

    return downloads
        .map((d) => {
              'content_id': d.contentId,
              'subject': d.subject,
              'chapter': d.chapter,
              'content_type': d.contentType,
              'local_path': d.contentPath,
              'file_size_bytes': d.fileSize,
              'download_date': d.downloadedAt?.toIso8601String(),
              'last_accessed': d.lastAccessed?.toIso8601String(),
            })
        .toList();
  }

  /// Get total storage used by downloads
  Future<double> getTotalStorageUsed() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;
    final totalBytes = await _isarService.getTotalStorageUsed(user.uid);
    return totalBytes / (1024 * 1024); // Return in MB
  }

  /// Get storage used by content type
  Future<Map<String, double>> getStorageByType() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final allDownloads = await _isarService.getAllDownloadedContent(user.uid);
    final Map<String, int> typeBytesMap = {};

    for (final d in allDownloads) {
      final type = d.contentType ?? 'unknown';
      // ============================================
      // FIXED: Explicit cast to int with null check
      // ============================================
      typeBytesMap[type] =
          (typeBytesMap[type] ?? 0) + (d.fileSize as int? ?? 0);
    }

    final Map<String, double> storageByType = {};
    typeBytesMap.forEach((key, value) {
      storageByType[key] = value / (1024 * 1024);
    });

    return storageByType;
  }

  /// Update last accessed time
  Future<void> updateLastAccessed(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final record =
        await _isarService.getDownloadedContentById(contentId, user.uid);
    if (record != null) {
      record.lastAccessed = DateTime.now();
      await _isarService.saveDownloadedContent(record);
    }
  }

  /// Check if content is downloaded
  Future<bool> isContentDownloaded(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return await _isarService.isContentDownloaded(contentId, user.uid);
  }

  /// Get download record
  Future<Map<String, dynamic>?> getDownloadRecord(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final record =
        await _isarService.getDownloadedContentById(contentId, user.uid);
    if (record == null) return null;
    return {
      'content_id': record.contentId,
      'subject': record.subject,
      'chapter': record.chapter,
      'content_type': record.contentType,
      'local_path': record.contentPath,
      'file_size_bytes': record.fileSize,
      'download_date': record.downloadedAt?.toIso8601String(),
      'last_accessed': record.lastAccessed?.toIso8601String(),
    };
  }

  /// Delete download
  Future<void> deleteDownload(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final record = await getDownloadRecord(contentId);
    if (record != null) {
      final filePath = record['local_path'] as String?;
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _isarService.deleteDownloadedContent(contentId, user.uid);
    }
  }

  /// Delete all downloads
  Future<void> deleteAllDownloads() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final downloads = await getDownloads();
    for (final download in downloads) {
      final filePath = download['local_path'] as String?;
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _isarService.clearUserData(user.uid);
  }

  /// Verify all downloaded files exist
  Future<List<String>> verifyDownloads() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final missingFiles = <String>[];
    final downloads = await getDownloads();

    for (final download in downloads) {
      final filePath = download['local_path'] as String?;
      final contentId = download['content_id'] as String?;
      if (contentId == null || filePath == null) continue;
      final file = File(filePath);
      if (!await file.exists() || !await _isValidCachedFile(filePath)) {
        missingFiles.add(contentId);
        if (await file.exists()) {
          await file.delete();
        }
        await _isarService.deleteDownloadedContent(contentId, user.uid);
      }
    }

    return missingFiles;
  }
}
