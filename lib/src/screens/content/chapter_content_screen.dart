import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/download_manager.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/content/github_content_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

class ChapterContentScreen extends StatefulWidget {
  final String chapterId;
  final String subjectName;
  final String chapterName;

  const ChapterContentScreen({
    super.key,
    required this.chapterId,
    required this.subjectName,
    required this.chapterName,
  });

  @override
  State<ChapterContentScreen> createState() => _ChapterContentScreenState();
}

class _ChapterContentScreenState extends State<ChapterContentScreen> {
  // 6 content types (from ACADIA spec)
  final List<String> _contentTypes = [
    'video',
    'short_note',
    'quiz',
    'exam',
    'flashcard',
    'past_paper',
  ];

  // Content items grouped by type
  Map<String, List<Map<String, dynamic>>> _contentByType = {};
  Map<String, bool> _downloadedContent = {};
  Map<String, double> _downloadProgress = {};

  bool _isLoading = true;
  final DownloadManager _downloadManager = DownloadManager();
  final OfflineDatabase _offlineDb = OfflineDatabase.instance;

  // Content type colors from ACADIA spec
  final Map<String, Color> _typeColors = {
    'video': const Color(0xFFFF9800),      // Orange
    'short_note': const Color(0xFF2196F3), // Blue
    'quiz': const Color(0xFF4CAF50),       // Green
    'exam': const Color(0xFF9C27B0),       // Purple
    'flashcard': const Color(0xFFE91E63),  // Pink
    'past_paper': const Color(0xFF795548), // Brown
  };

  final Map<String, IconData> _typeIcons = {
    'video': Icons.play_circle_outline,
    'short_note': Icons.description_outlined,
    'quiz': Icons.quiz_outlined,
    'exam': Icons.assignment_outlined,
    'flashcard': Icons.style_outlined,
    'past_paper': Icons.folder_open_outlined,
  };

  final Map<String, String> _typeLabels = {
    'video': 'Video',
    'short_note': 'Short Note',
    'quiz': 'Quiz',
    'exam': 'Exam',
    'flashcard': 'Flashcard',
    'past_paper': 'Past Paper',
  };

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();

      // Fetch content from GitHub (content repo) for this unit, merged with any
      // Firestore content. GitHub is the primary source; Firestore is fallback.
      final githubItems = await _fetchGithubItems();

      final firestoreContent = await firebase.getDocuments('content', where: {
        'chapter': widget.chapterId,
        'status': 'approved',
      });

      final content = <Map<String, dynamic>>[...githubItems];
      final seenIds = githubItems
          .map((e) => e['id']?.toString())
          .whereType<String>()
          .toSet();
      for (final item in firestoreContent) {
        final id = item['id']?.toString();
        if (id == null || !seenIds.contains(id)) content.add(item);
      }

      // Group by content type
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final type in _contentTypes) {
        grouped[type] = content.where((c) => c['content_type']?.toString() == type).toList();
      }

      // Check which content is already downloaded
      final downloaded = <String, bool>{};
      for (final item in content) {
        final contentId = item['id']?.toString() ?? '';
        if (contentId.isNotEmpty) {
          downloaded[contentId] = await _offlineDb.isContentDownloaded(contentId);
        }
      }

      if (mounted) {
        setState(() {
          _contentByType = grouped;
          _downloadedContent = downloaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading chapter content: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGithubItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final grade =
          prefs.getString('grade') ?? prefs.getString('selected_grade') ?? '9';
      final stream =
          prefs.getString('stream') ?? prefs.getString('selected_stream');
      final academicPath = prefs.getString('academic_path');
      final semester = prefs.getString('semester') ?? '1';
      final track = prefs.getString('selected_track');

      return await GithubContentService.instance.fetchChapterItems(
        academicPath: academicPath,
        grade: grade,
        stream: stream,
        subject: widget.subjectName,
        unit: widget.chapterName,
        semester: semester,
        track: track,
      );
    } catch (e) {
      debugPrint('Error fetching GitHub content: $e');
      return const [];
    }
  }

  Future<void> _downloadContent(Map<String, dynamic> content) async {
    final contentId = content['id']?.toString() ?? '';
    if (contentId.isEmpty) return;

    setState(() => _downloadProgress[contentId] = 0);

    try {
      await _downloadManager.downloadContent(
        contentId: contentId,
        title: content['title']?.toString() ?? 'Untitled',
        downloadUrl: content['download_url']?.toString() ?? '',
        contentType: content['content_type']?.toString() ?? '',
        fileFormat: content['file_format']?.toString() ?? 'json',
        subject: widget.subjectName,
        chapter: widget.chapterName,
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress[contentId] = progress);
        },
      );

      if (mounted) {
        setState(() {
          _downloadedContent[contentId] = true;
          _downloadProgress.remove(contentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${content['title']} downloaded!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(contentId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteDownload(String contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Remove this content from your device? You can download it again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _offlineDb.deleteDownload(contentId);
      setState(() => _downloadedContent[contentId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content deleted'), backgroundColor: Colors.orange),
      );
    }
  }

  void _openContent(Map<String, dynamic> content) {
    final contentType = content['content_type']?.toString() ?? '';
    final contentId = content['id']?.toString() ?? '';
    final title = content['title']?.toString() ?? '';

    switch (contentType) {
      case 'video':
        context.push('/video-player', extra: {'contentId': contentId, 'title': title});
        break;
      case 'short_note':
        context.push('/pdf-viewer', extra: {'contentId': contentId, 'title': title});
        break;
      case 'quiz':
        context.push('/quiz', extra: {'contentId': contentId, 'title': title});
        break;
      case 'exam':
        context.push('/exam', extra: {'contentId': contentId, 'title': title});
        break;
      case 'flashcard':
        context.push('/flashcard', extra: {'contentId': contentId, 'title': title});
        break;
      case 'past_paper':
        context.push('/quiz', extra: {'contentId': contentId, 'title': title});
        break;
    }
  }

  String _getSubtitle(Map<String, dynamic> item) {
    final contentType = item['content_type']?.toString() ?? '';
    final parts = <String>[];

    switch (contentType) {
      case 'video':
        final duration = item['duration_seconds'];
        final fileSize = item['file_size_mb'];
        if (duration != null) parts.add(_formatDuration(duration));
        if (fileSize != null) parts.add('${fileSize} MB');
        break;
      case 'short_note':
        final pages = item['page_count'];
        final fileSize = item['file_size_mb'];
        if (pages != null) parts.add('$pages pages');
        if (fileSize != null) parts.add('${fileSize} MB');
        break;
      case 'quiz':
      case 'exam':
        final questions = item['total_questions'];
        final time = item['time_limit_minutes'];
        if (questions != null) parts.add('$questions questions');
        if (time != null) parts.add('$time min');
        break;
      case 'flashcard':
        final cards = item['total_cards'];
        if (cards != null) parts.add('$cards cards');
        break;
      case 'past_paper':
        final questions = item['total_questions'];
        final year = item['year'];
        if (year != null) parts.add('$year');
        if (questions != null) parts.add('$questions questions');
        break;
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Chapter header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1A237E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.subjectName,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(widget.chapterName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content type sections
                ..._contentTypes.map((type) {
                  final items = _contentByType[type] ?? [];
                  return _buildContentSection(type, items);
                }),
              ],
            ),
    );
  }

  Widget _buildContentSection(String type, List<Map<String, dynamic>> items) {
    final color = _typeColors[type] ?? Colors.grey;
    final icon = _typeIcons[type] ?? Icons.article;
    final label = _typeLabels[type] ?? type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            if (items.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${items.length}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Content items or empty state
        if (items.isEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.grey[400], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Content will be uploaded soon by admin',
                            style: TextStyle(color: Colors.grey[500])),
                        Text('Check back later for updates',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...items.map((item) => _buildContentItem(item, color)),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContentItem(Map<String, dynamic> item, Color color) {
    final contentId = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? 'Untitled';
    final isDownloaded = _downloadedContent[contentId] == true;
    final downloadProgress = _downloadProgress[contentId];
    final isFree = item['free_content'] == true;
    final contentType = item['content_type']?.toString() ?? '';

    final subtitle = _getSubtitle(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: isDownloaded ? () => _openContent(item) : () => _downloadContent(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Content type icon
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_typeIcons[contentType] ?? Icons.article, color: color, size: 28),
                  ),
                  if (isDownloaded)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                  if (isFree && !isDownloaded)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('FREE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Free Content', style: TextStyle(color: Colors.blue, fontSize: 10)),
                      ),
                  ],
                ),
              ),

              // Action button
              if (downloadProgress != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: downloadProgress,
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                      Text(
                        '${(downloadProgress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else if (isDownloaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      const Text('OFFLINE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item['file_size_mb'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${item['file_size_mb']} MB',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.download, color: AppColors.primary, size: 24),
                      onPressed: () => _downloadContent(item),
                      tooltip: 'Download for offline use',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null) return '';
    final s = seconds is int ? seconds : int.tryParse(seconds.toString()) ?? 0;
    final hours = s ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    final remainingSeconds = s % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${s}s';
  }
}