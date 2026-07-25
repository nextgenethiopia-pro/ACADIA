import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/local_database/schemas/schemas.dart';

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

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Check available storage space.
  ///
  /// Dart's [FileStat] exposes no free-space getter, so we optimistically
  /// assume space is available; download failures are handled by the caller.
  Future<bool> hasEnoughSpace(int requiredBytes) async {
    return true;
  }

  /// Get formatted file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    // Check if already downloaded
    final isDownloaded = await _isarService.isContentDownloaded(contentId, user.uid);
    if (isDownloaded) {
      throw Exception('Content already downloaded');
    }

    // Create a new download (resume would require server support)
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
    // Check if already downloaded
    final isDownloaded = await _isarService.isContentDownloaded(contentId, user.uid);
    if (isDownloaded) {
      final record = await _isarService.getDownloadedContentById(contentId, user.uid);
      if (record != null) {
        final filePath = record.contentPath;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            throw Exception('Content already downloaded');
          } else {
            // File exists in DB but not on disk, remove record and re-download
            await _isarService.deleteDownloadedContent(contentId, user.uid);
          }
        }
      }
    }

    // Check internet connection
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      throw Exception('No internet connection');
    }

    final directory = await getApplicationDocumentsDirectory();

    String subDir;
    switch (contentType) {
      case 'video':
        subDir = 'videos';
        break;
      case 'short_note':
        subDir = 'pdfs';
        break;
      case 'quiz':
      case 'exam':
      case 'flashcard':
      case 'past_paper':
        subDir = 'json_content';
        break;
      default:
        subDir = 'downloads';
    }

    final contentDir = Directory('${directory.path}/$subDir');
    if (!await contentDir.exists()) {
      await contentDir.create(recursive: true);
    }

    final filePath = '${contentDir.path}/$contentId.$fileFormat';

    // Check if temp file exists and delete it
    final tempFile = File('$filePath.temp');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    // Create cancel token for this download
    final cancelToken = CancelToken();
    _cancelTokens[contentId] = cancelToken;

    try {
      await _dio.download(
        downloadUrl,
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

      final downloadedContent = DownloadedContent()
        ..userId = user.uid
        ..contentId = contentId
        ..contentPath = filePath
        ..contentType = contentType
        ..subject = subject
        ..grade = grade
        ..chapter = chapter
        ..downloadProgress = 1.0
        ..isDownloaded = true
        ..fileSize = fileSize
        ..downloadedAt = DateTime.now()
        ..lastAccessed = DateTime.now();

      await _isarService.saveDownloadedContent(downloadedContent);

      // Clean up
      _cancelTokens.remove(contentId);
      _downloadProgress.remove(contentId);
      onComplete?.call(contentId, filePath);

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

  /// Get all downloaded content with optional filtering
  Future<List<Map<String, dynamic>>> getDownloads({String? contentType}) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final List<DownloadedContent> downloads;

    if (contentType != null && contentType.isNotEmpty) {
      downloads = await _isarService.getDownloadedContentByType(user.uid, contentType);
    } else {
      downloads = await _isarService.getAllDownloadedContent(user.uid);
    }

    return downloads.map((d) => {
      'content_id': d.contentId,
      'subject': d.subject,
      'chapter': d.chapter,
      'content_type': d.contentType,
      'local_path': d.contentPath,
      'file_size_bytes': d.fileSize,
      'download_date': d.downloadedAt?.toIso8601String(),
      'last_accessed': d.lastAccessed?.toIso8601String(),
    }).toList();
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
      typeBytesMap[type] = (typeBytesMap[type] ?? 0) + d.fileSize;
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
    final record = await _isarService.getDownloadedContentById(contentId, user.uid);
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
    final record = await _isarService.getDownloadedContentById(contentId, user.uid);
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
    // Clear downloaded content for this user
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
      if (!await file.exists()) {
        missingFiles.add(contentId);
        // Remove invalid record from database
        await _isarService.deleteDownloadedContent(contentId, user.uid);
      }
    }

    return missingFiles;
  }
}
