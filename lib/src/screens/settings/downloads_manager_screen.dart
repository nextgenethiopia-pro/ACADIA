import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'dart:io';

class DownloadsManagerScreen extends StatefulWidget {
  const DownloadsManagerScreen({super.key});

  @override
  State<DownloadsManagerScreen> createState() => _DownloadsManagerScreenState();
}

class _DownloadsManagerScreenState extends State<DownloadsManagerScreen> {
  List<Map<String, dynamic>> _downloads = [];
  double _storageUsed = 0.0;
  final double _storageTotal = 100.0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _hasNetworkError = false;

  final IsarService _isarService = IsarService.instance;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    if (mounted) {
      setState(() {
        _hasNetworkError = false;
        _errorMessage = null;
        if (!_isLoading) _isRefreshing = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRefreshing = false;
          });
        }
        return;
      }

      // Priority 1: Check local downloaded files on disk
      final downloads = <Map<String, dynamic>>[];
      double totalSizeMB = 0;
      bool foundLocalFiles = false;

      try {
        final downloadedContents =
            await _isarService.getAllDownloadedContent(user.uid);

        for (final content in downloadedContents) {
          final localPath = content.contentPath;
          if (localPath != null && localPath.isNotEmpty) {
            final file = File(localPath);
            if (await file.exists()) {
              foundLocalFiles = true;
              final fileSize = await file.length();
              final downloadMap = {
                'content_id': content.contentId,
                'title': '${content.subject} • ${content.chapter}',
                'subject': content.subject,
                'chapter': content.chapter,
                'content_type': content.contentType,
                'file_size_bytes': fileSize,
                'download_date': content.downloadedAt?.toIso8601String(),
                'local_path': localPath,
                'is_completed': content.isCompleted ? 1 : 0,
              };
              downloads.add(downloadMap);
              totalSizeMB += (fileSize / (1024 * 1024));
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking local files: $e');
      }

      // Priority 2: If no local files found, check Isar cache (metadata only)
      if (!foundLocalFiles) {
        try {
          final cachedContents =
              await _isarService.getAllDownloadedContent(user.uid);
          for (final content in cachedContents) {
            final downloadMap = {
              'content_id': content.contentId,
              'title': '${content.subject} • ${content.chapter}',
              'subject': content.subject,
              'chapter': content.chapter,
              'content_type': content.contentType,
              'file_size_bytes': content.fileSize,
              'download_date': content.downloadedAt?.toIso8601String(),
              'local_path': content.contentPath,
              'is_completed': content.isCompleted ? 1 : 0,
            };
            downloads.add(downloadMap);
            totalSizeMB += (content.fileSize / (1024 * 1024));
          }
        } catch (e) {
          debugPrint('Error checking Isar cache: $e');
          rethrow;
        }
      }

      if (downloads.isEmpty) {
        if (mounted) {
          setState(() {
            _downloads = [];
            _storageUsed = 0;
            _isLoading = false;
            _isRefreshing = false;
            _errorMessage = null;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _downloads = downloads;
          _storageUsed = totalSizeMB;
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading downloads (offline-first): $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _downloads = [];
          _storageUsed = 0;
          _hasNetworkError = false;
          _errorMessage = null;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadDownloads,
        ),
      ),
    );
  }

  Future<void> _deleteDownload(Map<String, dynamic> download) async {
    final contentId = download['content_id']?.toString() ?? '';
    final title = download['title']?.toString() ?? 'this item';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from local database
        await _isarService.deleteDownloadedContent(contentId, user.uid);

        await _loadDownloads();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: Text(
            'Are you sure you want to delete all ${_downloads.length} downloaded items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        // Delete all from local database
        for (final download in _downloads) {
          final contentId = download['content_id']?.toString() ?? '';
          if (contentId.isNotEmpty) {
            await _isarService.deleteDownloadedContent(contentId, user.uid);
          }
        }

        await _loadDownloads();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All downloads cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getContentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle;
      case 'short_note':
        return Icons.description;
      case 'quiz':
        return Icons.quiz;
      case 'exam':
        return Icons.assignment;
      case 'flashcard':
        return Icons.style;
      case 'past_paper':
        return Icons.folder_open;
      default:
        return Icons.description;
    }
  }

  Color _getContentColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return const Color(0xFFFF9800);
      case 'short_note':
        return const Color(0xFF2196F3);
      case 'quiz':
        return const Color(0xFF4CAF50);
      case 'exam':
        return const Color(0xFF9C27B0);
      case 'flashcard':
        return const Color(0xFFE91E63);
      case 'past_paper':
        return const Color(0xFF795548);
      default:
        return Colors.grey;
    }
  }

  void _openContent(Map<String, dynamic> download) {
    final contentType = download['content_type']?.toString() ?? '';
    final contentId = download['content_id']?.toString() ?? '';
    final title = download['title']?.toString() ?? '';

    switch (contentType) {
      case 'video':
        context.push('/video-player',
            extra: {'contentId': contentId, 'title': title});
        break;
      case 'short_note':
        context.push('/pdf-viewer',
            extra: {'contentId': contentId, 'title': title});
        break;
      case 'quiz':
        context.push('/quiz', extra: {'contentId': contentId, 'title': title});
        break;
      case 'exam':
        context.push('/exam', extra: {'contentId': contentId, 'title': title});
        break;
      case 'flashcard':
        context.push('/flashcard',
            extra: {'contentId': contentId, 'title': title});
        break;
      case 'past_paper':
        context.push('/quiz', extra: {'contentId': contentId, 'title': title});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storagePercentage = _storageTotal > 0
        ? (_storageUsed / _storageTotal * 100).clamp(0, 100)
        : 0;
    final isStorageWarning = storagePercentage > 80;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Downloads Manager'),
        elevation: 0,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading downloads...'),
                ],
              ),
            )
          : _hasNetworkError || (_errorMessage != null && _downloads.isEmpty)
              ? _buildErrorState(theme)
              : RefreshIndicator(
                  onRefresh: _loadDownloads,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Storage Usage
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.cardColor,
                              isStorageWarning
                                  ? Colors.orange.withOpacity(0.05)
                                  : theme.cardColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.storage,
                                        color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Storage Used',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isStorageWarning)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Low Space',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: storagePercentage / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isStorageWarning
                                      ? Colors.orange
                                      : AppColors.primary,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_storageUsed.toStringAsFixed(1)} MB of ${_storageTotal.toStringAsFixed(0)} MB used',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isStorageWarning
                                        ? Colors.orange
                                        : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${_downloads.length} items',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Downloads List
                      if (_downloads.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.file_download_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No downloads yet',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Downloaded content will appear here',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/subjects'),
                                icon: const Icon(Icons.explore),
                                label: const Text('Browse Subjects'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            ..._downloads.map((download) {
                              final isCompleted = download['is_completed'] == true;
                              final progress = (download['progress'] as num?)?.toDouble() ?? 0.0;
                              final size = (download['file_size_mb'] as num?)?.toDouble() ?? 0.0;
                              final date = download['downloaded_at']?.toString();
                              final type = download['content_type']?.toString() ?? '';
                              final title = download['title']?.toString() ?? 'Unknown';

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getFileIcon(type),
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _formatDate(date),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (size > 0)
                                            Text(
                                              '• ${_formatSize(size)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (!isCompleted && progress > 0) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress / 100,
                                            backgroundColor: Colors.grey[200],
                                            valueColor:
                                                const AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                            minHeight: 4,
                                          ),
                                        ),
                                      ],
                                      if (isCompleted) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.check_circle,
                                            size: 12, color: Colors.green),
                                        const SizedBox(width: 4),
                                        const Text('Completed',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green)),
                                      ],
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _deleteDownload(download),
                                    tooltip: 'Delete',
                                  ),
                                ),
                              );
                            }),

                            // Clear All Button
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _clearAllDownloads,
                                  icon: const Icon(Icons.delete_sweep, size: 18),
                                  label: const Text('CLEAR ALL DOWNLOADS'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle;
      case 'short_note':
        return Icons.description;
      case 'quiz':
        return Icons.quiz;
      case 'exam':
        return Icons.assignment;
      case 'flashcard':
        return Icons.style;
      case 'past_paper':
        return Icons.folder_open;
      default:
        return Icons.description;
    }
  }

  String _formatSize(double sizeInMB) {
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(1)} KB';
    } else if (sizeInMB >= 1024) {
      return '${(sizeInMB / 1024).toStringAsFixed(1)} GB';
    } else {
      return '${sizeInMB.toStringAsFixed(1)} MB';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildErrorState(ThemeData theme) {
    final isNetworkError = _errorMessage != null &&
        (_errorMessage!.toLowerCase().contains('network') ||
         _errorMessage!.toLowerCase().contains('connection'));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              isNetworkError ? 'Connection Error' : 'Error',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load downloads',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDownloads,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
