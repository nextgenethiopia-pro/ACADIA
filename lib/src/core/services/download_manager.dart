import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_database.dart';

class DownloadManager {
  final Dio _dio = Dio();
  final OfflineDatabase _offlineDb = OfflineDatabase.instance;
  
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
  /// dart:io does not expose free-disk-space, so we simply confirm the
  /// documents directory is reachable and assume space is available.
  Future<bool> hasEnoughSpace(int requiredBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      await directory.stat();
      return true;
    } catch (e) {
      debugPrint('Error checking storage space: $e');
      return true; // Assume enough space if can't check
    }
  }

  /// Get formatted file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    int? pageCount,
    int? totalQuestions,
    int? totalCards,
    Function(double)? onProgress,
  }) async {
    // Check if already downloaded
    final isDownloaded = await _offlineDb.isContentDownloaded(contentId);
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
    int? pageCount,
    int? totalQuestions,
    int? totalCards,
    Function(double)? onProgress,
  }) async {
    // Check if already downloaded
    final isDownloaded = await _offlineDb.isContentDownloaded(contentId);
    if (isDownloaded) {
      final record = await _offlineDb.getDownloadRecord(contentId);
      if (record != null) {
        final filePath = record['local_path'] as String;
        final file = File(filePath);
        if (await file.exists()) {
          throw Exception('Content already downloaded');
        } else {
          // File exists in DB but not on disk, remove record and re-download
          await _offlineDb.deleteDownload(contentId);
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
      case 'video': subDir = 'videos'; break;
      case 'short_note': subDir = 'pdfs'; break;
      case 'quiz':
      case 'exam':
      case 'flashcard':
      case 'past_paper':
        subDir = 'json_content';
        break;
      default: subDir = 'downloads';
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

      await _offlineDb.saveDownloadRecord(data: {
        'content_id': contentId,
        'title': title,
        'subject': subject,
        'chapter': chapter,
        'content_type': contentType,
        'download_url': downloadUrl,
        'local_path': filePath,
        'file_size_bytes': fileSize,
        'file_format': fileFormat,
        'page_count': pageCount,
        'total_questions': totalQuestions,
        'total_cards': totalCards,
        'download_date': DateTime.now().toIso8601String(),
        'last_accessed': DateTime.now().toIso8601String(),
        'is_completed': 0,
      });

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
    final db = await _offlineDb.database;
    
    String query = '''
      SELECT * FROM offline_content 
      WHERE status = 'downloaded'
    ''';
    final List<Object?> args = [];
    
    if (contentType != null && contentType.isNotEmpty) {
      query += ' AND content_type = ?';
      args.add(contentType);
    }
    
    query += ' ORDER BY download_date DESC';
    
    final result = await db.rawQuery(query, args);
    return result;
  }

  /// Get total storage used by downloads
  Future<double> getTotalStorageUsed() async {
    final db = await _offlineDb.database;
    final result = await db.rawQuery('''
      SELECT SUM(file_size_bytes) as total 
      FROM offline_content 
      WHERE status = 'downloaded'
    ''');
    
    final totalBytes = (result.first['total'] as int?) ?? 0;
    return totalBytes / (1024 * 1024); // Return in MB
  }

  /// Get storage used by content type
  Future<Map<String, double>> getStorageByType() async {
    final db = await _offlineDb.database;
    final result = await db.rawQuery('''
      SELECT content_type, SUM(file_size_bytes) as total 
      FROM offline_content 
      WHERE status = 'downloaded'
      GROUP BY content_type
    ''');
    
    final Map<String, double> storageByType = {};
    for (final row in result) {
      final type = row['content_type'] as String;
      final bytes = (row['total'] as int?) ?? 0;
      storageByType[type] = bytes / (1024 * 1024);
    }
    return storageByType;
  }

  /// Update last accessed time
  Future<void> updateLastAccessed(String contentId) async {
    final db = await _offlineDb.database;
    await db.update(
      'offline_content',
      {'last_accessed': DateTime.now().toIso8601String()},
      where: 'content_id = ?',
      whereArgs: [contentId],
    );
  }

  /// Check if content is downloaded
  Future<bool> isContentDownloaded(String contentId) async {
    return await _offlineDb.isContentDownloaded(contentId);
  }

  /// Get download record
  Future<Map<String, dynamic>?> getDownloadRecord(String contentId) async {
    return await _offlineDb.getDownloadRecord(contentId);
  }

  /// Delete download
  Future<void> deleteDownload(String contentId) async {
    final record = await getDownloadRecord(contentId);
    if (record != null) {
      final filePath = record['local_path'] as String;
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _offlineDb.deleteDownload(contentId);
    }
  }

  /// Delete all downloads
  Future<void> deleteAllDownloads() async {
    final downloads = await getDownloads();
    for (final download in downloads) {
      final filePath = download['local_path'] as String;
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _offlineDb.deleteAllDownloads();
  }

  /// Verify all downloaded files exist
  Future<List<String>> verifyDownloads() async {
    final missingFiles = <String>[];
    final downloads = await getDownloads();
    
    for (final download in downloads) {
      final filePath = download['local_path'] as String;
      final file = File(filePath);
      if (!await file.exists()) {
        missingFiles.add(download['content_id'] as String);
        // Remove invalid record from database
        await _offlineDb.deleteDownload(download['content_id'] as String);
      }
    }
    
    return missingFiles;
  }
}