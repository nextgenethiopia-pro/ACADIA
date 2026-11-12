import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/di/injection.dart';
import 'package:acadia/src/core/services/content_file_guard.dart';
import 'package:acadia/src/core/services/download_manager.dart';
import 'package:acadia/src/core/services/package_service.dart';
import 'package:acadia/src/core/services/progress_tracking_service.dart';
import 'package:acadia/src/domain/models/unit_content_result.dart';
import 'package:acadia/src/domain/repositories/github_content_repository.dart';
import 'package:acadia/src/domain/repositories/progress_repository.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChapterContentScreen extends StatefulWidget {
  final String chapterId;
  final String subjectName;
  final String chapterName;
  final bool offlineOnly;

  const ChapterContentScreen({
    super.key,
    required this.chapterId,
    required this.subjectName,
    required this.chapterName,
    this.offlineOnly = false,
  });

  @override
  State<ChapterContentScreen> createState() => _ChapterContentScreenState();
}

class _ChapterContentScreenState extends State<ChapterContentScreen> {
  final IsarService _isarService = IsarService.instance;
  final PackageService _packageService = PackageService();

  /// The chapter folder or identifier used for repository access and for
  /// matching downloaded records. It is never used as a display label.
  String get _rawChapterKey {
    final id = widget.chapterId.trim();
    if (id.isNotEmpty) return id;
    return widget.chapterName.trim();
  }

  String get _displayChapterName {
    final candidate = _rawChapterKey;
    if (candidate.isEmpty) return 'Chapter';
    final withoutExtension = candidate.toLowerCase().endsWith('.json')
        ? candidate.substring(0, candidate.length - 5)
        : candidate;
    return AcademicStructure.displayChapterTitle(withoutExtension);
  }

  final List<String> _contentTypes = [
    'short_note',
    'quiz',
    'exam',
    'video',
    'past_paper',
    'flashcard',
  ];

  Map<String, List<Map<String, dynamic>>> _contentByType = {};
  Map<String, bool> _downloadedContent = {};
  final Map<String, double> _downloadProgress = {};

  bool _isLoading = true;
  bool _hasActivePackage = false;
  String? _loadError;
  UnitContentResult? _result;
  final DownloadManager _downloadManager = DownloadManager();
  String _userGrade = '';

  final Map<String, bool> _expandedSections = {};

  final Map<String, Color> _typeColors = {
    'short_note': const Color(0xFF2196F3),
    'quiz': const Color(0xFF4CAF50),
    'exam': const Color(0xFF9C27B0),
    'video': const Color(0xFFFF9800),
    'past_paper': const Color(0xFF795548),
    'flashcard': const Color(0xFFE91E63),
  };

  final Map<String, IconData> _typeIcons = {
    'short_note': Icons.sticky_note_2_outlined,
    'quiz': Icons.quiz_outlined,
    'exam': Icons.assignment_outlined,
    'video': Icons.play_circle_outline,
    'past_paper': Icons.folder_open_outlined,
    'flashcard': Icons.style_outlined,
  };

  final Map<String, String> _typeLabels = {
    'short_note': 'Short Notes',
    'quiz': 'Quiz',
    'exam': 'Exams',
    'video': 'Videos',
    'past_paper': 'Past Papers',
    'flashcard': 'Flashcards',
  };

  @override
  void initState() {
    super.initState();
    for (final type in _contentTypes) {
      _expandedSections[type] = true;
    }
    _loadContent();
  }

  Future<String> _resolveAcademicIdentifier(SharedPreferences prefs) async {
    final academicLevel = prefs.getString('academic_level');
    final academicPath = prefs.getString('academic_path');
    final storedGrade =
        prefs.getString('grade') ?? prefs.getString('selected_grade');
    final year =
        prefs.getString('university_year') ?? prefs.getString('selected_year');
    final semester = prefs.getString('semester');
    final isUniversity = academicLevel == 'university' ||
        academicPath == 'UNIVERSITY' ||
        (storedGrade?.startsWith('university_') ?? false) ||
        (semester != null && year == 'freshman');

    if (isUniversity) {
      final stream = prefs.getString('stream') ??
          prefs.getString('selected_stream') ??
          'natural';
      if (semester == '2') {
        final track = prefs.getString('selected_track') ??
            prefs.getString('track') ??
            'other_natural_science';
        return 'university_${year ?? 'freshman'}_sem2_$track';
      }
      if (semester != null) {
        return 'university_${year ?? 'freshman'}_sem${semester}_$stream';
      }
    }

    if (storedGrade != null && storedGrade.isNotEmpty) return storedGrade;
    return '';
  }

  String _normalizedGroupType(String type) {
    if (type == 'pdf' || type == 'notes') return 'short_note';
    return type;
  }

  /// Records which content sections of this chapter the student has opened.
  /// Chapter progress is the share of available sections that were opened;
  /// once every section has been opened the chapter counts as completed and
  /// feeds the Isar-backed study stats.
  Future<void> _recordProgress(String contentType) async {
    try {
      final normalized = _normalizedGroupType(contentType);
      final prefs = await SharedPreferences.getInstance();
      final key = 'chapter_opened_${widget.subjectName}_$_rawChapterKey';

      final opened = <String>{};
      final raw = prefs.getString(key);
      if (raw != null) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          opened.addAll(decoded.map((entry) => entry.toString()));
        }
      }
      if (!opened.add(normalized)) return;
      await prefs.setString(key, json.encode(opened.toList()));

      final availableTypes = _contentByType.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => entry.key)
          .toSet();
      if (availableTypes.isEmpty) return;

      final openedAvailable = opened.where(availableTypes.contains).length;
      final progress = openedAvailable / availableTypes.length;
      final completed = progress >= 1.0;

      await getIt<ProgressRepository>().saveUnitProgress(
        unitName: _rawChapterKey,
        subjectId: widget.subjectName,
        progress: progress,
        isCompleted: completed,
      );
      debugPrint(
          '📊 Progress for $_rawChapterKey: ${(progress * 100).toStringAsFixed(0)}% ($openedAvailable/${availableTypes.length} sections)');

      if (completed) {
        await ProgressTrackingService()
            .completeChapter(_rawChapterKey, widget.subjectName);
      }
    } catch (e) {
      debugPrint('⚠️ Could not record chapter progress: $e');
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _result = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userGrade = await _resolveAcademicIdentifier(prefs);
      final stream =
          prefs.getString('stream') ?? prefs.getString('selected_stream');

      _hasActivePackage = await _packageService.hasActivePackage();

      UnitContentResult? result;
      String? loadError;

      if (widget.offlineOnly) {
        result = await _loadOfflineContent();
      } else if (_userGrade.isNotEmpty) {
        result = await getIt<GithubContentRepository>().getUnitContentResult(
          grade: _userGrade,
          subject: widget.subjectName,
          unitFile: _rawChapterKey,
          stream: stream,
        );
      } else {
        loadError =
            'Your class could not be determined. Sign in again or complete onboarding and retry.';
      }

      final items = result?.items ?? const <Map<String, dynamic>>[];
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final type in _contentTypes) {
        grouped[type] = items
            .where((item) =>
                _normalizedGroupType(item['content_type']?.toString() ?? '') ==
                type)
            .toList();
      }

      final user = FirebaseAuth.instance.currentUser;
      final downloaded = <String, bool>{};
      for (final item in items) {
        final contentId = item['id']?.toString() ?? '';
        if (contentId.isEmpty) continue;
        if (widget.offlineOnly) {
          downloaded[contentId] = true;
        } else if (user != null) {
          downloaded[contentId] = await _isarService.getDownloadedContentById(
                contentId,
                user.uid,
              ) !=
              null;
        }
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _contentByType = grouped;
        _downloadedContent = downloaded;
        _loadError = loadError;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chapter content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError =
              'The content could not be loaded. Check your connection and try again.';
        });
      }
    }
  }

  Future<UnitContentResult> _loadOfflineContent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const UnitContentResult(
        items: [],
        status: UnitContentStatus.offlineNoCache,
        message: 'Sign in to access content you downloaded for offline use.',
      );
    }

    final localDownloads = await _isarService.getAllDownloadedContent(user.uid);
    final prefs = await SharedPreferences.getInstance();
    final chapterKey = _rawChapterKey.toLowerCase();
    final displayName = _displayChapterName.toLowerCase();
    final subjectName = widget.subjectName.trim().toLowerCase();

    final items = <Map<String, dynamic>>[];
    for (final download in localDownloads) {
      final subject = (download.subject ?? '').trim().toLowerCase();
      final chapter = (download.chapter ?? '').trim().toLowerCase();
      final path = (download.contentPath ?? '').trim();
      final contentId = download.contentId ?? '';
      final matches = contentId.isNotEmpty &&
          subject == subjectName &&
          (chapter == chapterKey || chapter == displayName) &&
          download.isDownloaded == true &&
          path.isNotEmpty;
      if (!matches) continue;

      final file = File(path);
      if (!await file.exists()) {
        debugPrint('🧹 Removing offline record for missing file: $path');
        await _isarService.deleteDownloadedContent(contentId, user.uid);
        continue;
      }

      final lower = path.toLowerCase();
      final contentType = download.contentType ?? '';
      // Short notes are served from notes.json only; PDF files downloaded
      // from the repository by older builds are removed so they stop
      // appearing as short-note documents.
      if (contentType == 'short_note' && lower.endsWith('.pdf')) {
        debugPrint('🧹 Removing legacy repository PDF: $path');
        await file.delete();
        await _isarService.deleteDownloadedContent(contentId, user.uid);
        continue;
      }
      if (lower.endsWith('.pdf') && !await ContentFileGuard.isPdfFile(path)) {
        debugPrint('🧹 Removing invalid offline PDF: $path');
        await file.delete();
        await _isarService.deleteDownloadedContent(contentId, user.uid);
        continue;
      }
      if (lower.endsWith('.json')) {
        try {
          final text = await file.readAsString();
          final decoded = json.decode(text.replaceFirst('\uFEFF', ''));
          if (decoded is! Map && decoded is! List) {
            throw const FormatException('JSON root is not an object or array');
          }
        } catch (e) {
          debugPrint('🧹 Removing unreadable offline JSON: $path ($e)');
          await file.delete();
          await _isarService.deleteDownloadedContent(contentId, user.uid);
          continue;
        }
      }

      final isPdf = lower.endsWith('.pdf');
      items.add(<String, dynamic>{
        'id': contentId,
        'title': _offlineDisplayTitle(
          download.title ?? '',
          contentId,
          download.contentType ?? '',
          isPdf,
        ),
        'content_type': download.contentType ?? '',
        'download_url': path,
        'local_path': path,
        'remote_url': prefs.getString('download_source_$contentId') ?? '',
        'file_format': isPdf ? 'pdf' : 'json',
        'source': 'local',
      });
    }

    if (items.isEmpty) {
      return const UnitContentResult(
        items: [],
        status: UnitContentStatus.offlineNoCache,
        message:
            'This chapter has no downloaded content on this device. Reconnect and open the chapter again to download it.',
      );
    }

    return UnitContentResult(
      items: items,
      status: UnitContentStatus.offlineCached,
      message: 'Showing content saved on this device.',
    );
  }

  /// Older download records predate title persistence. Derive a distinct label
  /// from the content id so a unit with several PDFs does not show identical
  /// rows for every document.
  String _offlineDisplayTitle(
    String storedTitle,
    String contentId,
    String contentType,
    bool isPdf,
  ) {
    final stored = storedTitle.trim();
    if (stored.isNotEmpty) return stored;

    if (contentType == 'short_note') {
      const pdfMarker = '_short_note_pdf_';
      final index = contentId.indexOf(pdfMarker);
      if (index >= 0) {
        final slug = contentId
            .substring(index + pdfMarker.length)
            .replaceAllMapped(
                RegExp(r'([a-zA-Z])(\d)'), (match) => '${match[1]} ${match[2]}')
            .replaceAll(RegExp(r'[_-]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (slug.isEmpty || slug.toLowerCase() == 'main notes') {
          return '$_displayChapterName Notes';
        }
        final readable = slug
            .split(' ')
            .map((word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
        return '$_displayChapterName — $readable';
      }
      return isPdf
          ? '$_displayChapterName Notes'
          : '$_displayChapterName Structured Notes';
    }

    return _displayChapterName;
  }

  void _toggleSection(String type) {
    setState(() {
      _expandedSections[type] = !(_expandedSections[type] ?? true);
    });
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Premium Required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'You need to purchase the package to access this content.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/payment');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  bool _isContentLocked(Map<String, dynamic> content) {
    final isFree = content['free_content'] == true || content['free'] == true;
    if (isFree) return false;
    return !_hasActivePackage;
  }

  Future<void> _downloadContent(Map<String, dynamic> content) async {
    if (!widget.offlineOnly && _isContentLocked(content)) {
      _showPremiumDialog();
      return;
    }

    final contentId = content['id']?.toString() ?? '';
    if (contentId.isEmpty) return;

    setState(() => _downloadProgress[contentId] = 0);

    try {
      if (_userGrade.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _userGrade = await _resolveAcademicIdentifier(prefs);
      }

      await _downloadManager.downloadContent(
        contentId: contentId,
        title: content['title']?.toString() ?? 'Untitled',
        downloadUrl: content['download_url']?.toString() ?? '',
        contentType: content['content_type']?.toString() ?? '',
        fileFormat: content['file_format']?.toString() ?? 'json',
        subject: widget.subjectName,
        chapter: _rawChapterKey,
        grade: _userGrade,
        pageCount: (content['page_count'] as num?)?.toInt(),
        totalQuestions: (content['total_questions'] as num?)?.toInt(),
        totalCards: (content['total_cards'] as num?)?.toInt(),
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
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteDownload(String contentId) async {
    await _deleteDownload(contentId);
  }

  Future<void> _deleteDownload(String contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text(
            'Remove this content from your device? You can download it again later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _isarService.deleteDownloadedContent(contentId, user.uid);
        setState(() => _downloadedContent[contentId] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Content deleted'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _openContent(Map<String, dynamic> content) {
    if (_isContentLocked(content)) {
      _showPremiumDialog();
      return;
    }

    final contentType = content['content_type']?.toString() ?? '';
    _recordProgress(contentType);
    final contentId = content['id']?.toString() ?? '';
    final title = content['title']?.toString() ?? '';
    final storedRemote = content['remote_url']?.toString().trim() ?? '';
    final remoteUrl = storedRemote.isNotEmpty
        ? storedRemote
        : content['download_url']?.toString() ?? '';
    final localPath = content['local_path']?.toString() ?? '';

    String documentSource = remoteUrl;
    if (localPath.toLowerCase().endsWith('.pdf')) {
      documentSource = localPath;
    } else if (remoteUrl.toLowerCase().endsWith('.pdf')) {
      documentSource = remoteUrl;
    } else if (localPath.isNotEmpty) {
      documentSource = localPath;
    }

    switch (contentType) {
      case 'video':
        context.push('/video-player', extra: {
          'contentId': contentId,
          'title': title,
          'videoUrl':
              localPath.isNotEmpty && localPath.toLowerCase().endsWith('.mp4')
                  ? localPath
                  : remoteUrl,
        });
        break;
      case 'pdf':
      case 'short_note':
      case 'notes':
        context.push('/pdf-viewer', extra: {
          'contentId': contentId,
          'title': title,
          'downloadUrl': documentSource,
          'remoteUrl': remoteUrl,
        });
        break;
      case 'quiz':
        context.push('/quiz', extra: {
          'contentId': contentId,
          'title': title,
          'downloadUrl': remoteUrl,
          'totalQuestions': content['total_questions'],
          'timeLimitMinutes': content['time_limit_minutes'],
        });
        break;
      case 'exam':
      case 'past_paper':
        context.push('/exam', extra: {
          'contentId': contentId,
          'title': title,
          'downloadUrl': remoteUrl,
          'totalQuestions': content['total_questions'],
          'timeLimitMinutes': content['time_limit_minutes'],
        });
        break;
      case 'flashcard':
        context.push('/flashcard', extra: {
          'contentId': contentId,
          'title': title,
          'downloadUrl': remoteUrl,
          'totalCards': content['total_cards'],
        });
        break;
      default:
        debugPrint('Unknown content type: $contentType');
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
        if (fileSize != null) parts.add('$fileSize MB');
        break;
      case 'pdf':
      case 'short_note':
      case 'notes':
        final pages = item['page_count'];
        final fileSize = item['file_size_mb'];
        if (pages != null) parts.add('$pages pages');
        if (fileSize != null) parts.add('$fileSize MB');
        break;
      case 'quiz':
      case 'exam':
      case 'past_paper':
        final questions = item['total_questions'];
        final time = item['time_limit_minutes'];
        final year = item['year'];
        if (year != null) parts.add('$year');
        if (questions != null) parts.add('$questions questions');
        if (time != null) parts.add('$time min');
        break;
      case 'flashcard':
        final cards = item['total_cards'];
        if (cards != null) parts.add('$cards cards');
        break;
    }

    return parts.join(' • ');
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

  String _statusTitle(UnitContentStatus? status) {
    switch (status) {
      case UnitContentStatus.missingUnit:
        return 'Content Not Found';
      case UnitContentStatus.invalidJson:
        return 'Content Could Not Be Read';
      case UnitContentStatus.unsupportedPath:
        return 'Not Available for This Programme';
      case UnitContentStatus.offlineNoCache:
      case UnitContentStatus.networkError:
        return 'Connection Problem';
      case UnitContentStatus.empty:
        return 'No Content Published Yet';
      default:
        return 'Content Unavailable';
    }
  }

  IconData _statusIcon(UnitContentStatus? status) {
    switch (status) {
      case UnitContentStatus.missingUnit:
        return Icons.folder_off_outlined;
      case UnitContentStatus.invalidJson:
        return Icons.file_present_outlined;
      case UnitContentStatus.offlineNoCache:
      case UnitContentStatus.networkError:
        return Icons.cloud_off_outlined;
      case UnitContentStatus.unsupportedPath:
        return Icons.school_outlined;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _probeMessage(String type, ContentProbe? probe) {
    final label = (_typeLabels[type] ?? type).toLowerCase();
    if (probe == null) {
      return widget.offlineOnly
          ? 'This section was not saved for offline use.'
          : 'No $label are published for this chapter.';
    }
    switch (probe.status) {
      case ContentProbeStatus.found:
        return 'The published $label file contains no items.';
      case ContentProbeStatus.missing:
        return 'No $label file exists in the repository for this chapter.';
      case ContentProbeStatus.invalidJson:
        return 'The $label file could not be read. It may be invalid JSON.';
      case ContentProbeStatus.networkError:
        return 'The $label file could not be fetched. Check your connection and retry.';
    }
  }

  Widget _buildSectionEmptyState(String type) {
    final probe = _result?.probeFor(type);
    final isError = probe?.status == ContentProbeStatus.invalidJson ||
        probe?.status == ContentProbeStatus.networkError;
    final isMissing = probe?.status == ContentProbeStatus.missing;
    final color = isError
        ? Colors.red
        : isMissing
            ? Colors.grey
            : Colors.grey;
    final icon = isError
        ? Icons.error_outline
        : isMissing
            ? Icons.folder_off_outlined
            : Icons.inbox_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _probeMessage(type, probe),
                style: TextStyle(color: color, fontSize: 13),
              ),
            ),
            if (isError || probe?.status == ContentProbeStatus.networkError)
              IconButton(
                tooltip: 'Retry',
                onPressed: _loadContent,
                icon: const Icon(Icons.refresh, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _probeStatusIcon(ContentProbe? probe) {
    if (probe == null) return const SizedBox.shrink();
    switch (probe.status) {
      case ContentProbeStatus.found:
        return const Icon(Icons.check_circle_outline,
            size: 16, color: Colors.green);
      case ContentProbeStatus.missing:
        return const Icon(Icons.remove_circle_outline,
            size: 16, color: Colors.grey);
      case ContentProbeStatus.invalidJson:
        return const Icon(Icons.warning_amber_rounded,
            size: 16, color: Colors.orange);
      case ContentProbeStatus.networkError:
        return const Icon(Icons.cloud_off_outlined,
            size: 16, color: Colors.red);
    }
  }

  Widget _buildStatusBanner() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    final bool show =
        result.status == UnitContentStatus.partial || result.showsCachedContent;
    if (!show) return const SizedBox.shrink();

    final fromDevice = widget.offlineOnly;
    final isWarning = result.status == UnitContentStatus.partial;
    final color = isWarning ? Colors.orange : AppColors.primary;
    final icon = fromDevice
        ? Icons.offline_pin_outlined
        : isWarning
            ? Icons.info_outline
            : Icons.cloud_done_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(color: color, fontSize: 12.5),
            ),
          ),
          if (!fromDevice)
            TextButton(
              onPressed: _loadContent,
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusScreen(
    String title,
    String message,
    UnitContentStatus? status,
  ) {
    final result = _result;
    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          Icon(
            _statusIcon(status),
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (result != null && result.probes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: _contentTypes.map((type) {
                    final probe = result.probeFor(type);
                    if (probe == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          _probeStatusIcon(probe),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _typeLabels[type] ?? type,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            _probeLabel(probe.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  String _probeLabel(ContentProbeStatus status) {
    switch (status) {
      case ContentProbeStatus.found:
        return 'Found';
      case ContentProbeStatus.missing:
        return 'Not in repository';
      case ContentProbeStatus.invalidJson:
        return 'Unreadable';
      case ContentProbeStatus.networkError:
        return 'Fetch failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final hasItems = result?.hasItems ?? false;
    final statusFailure = result != null && !hasItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildStatusScreen('Content Unavailable', _loadError!, null)
              : statusFailure
                  ? _buildStatusScreen(
                      _statusTitle(result.status),
                      result.message,
                      result.status,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
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
                              Text(
                                widget.subjectName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displayChapterName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusBanner(),
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
    final isExpanded = _expandedSections[type] ?? true;
    final probe = _result?.probeFor(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleSection(type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _probeStatusIcon(probe),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isExpanded)
          items.isEmpty
              ? _buildSectionEmptyState(type)
              : Column(
                  children: items
                      .map((item) => _buildContentItem(item, color))
                      .toList(),
                ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildContentItem(Map<String, dynamic> item, Color color) {
    final contentId = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? 'Untitled';
    final isDownloaded = _downloadedContent[contentId] == true;
    final downloadProgress = _downloadProgress[contentId];
    final isFree = item['free_content'] == true || item['free'] == true;
    final contentType = item['content_type']?.toString() ?? '';
    final isLocked = _isContentLocked(item);

    final subtitleText = _getSubtitle(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: isLocked
            ? _showPremiumDialog
            : isDownloaded
                ? () => _openContent(item)
                : () => _downloadContent(item),
        onLongPress: isLocked
            ? _showPremiumDialog
            : isDownloaded
                ? () => _confirmAndDeleteDownload(item['id']?.toString() ?? '')
                : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.withOpacity(0.1)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcons[contentType] ?? Icons.article,
                      color: isLocked ? Colors.grey : color,
                      size: 28,
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock,
                            color: Colors.white, size: 10),
                      ),
                    ),
                  if (isDownloaded && !isLocked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  if (isFree && !isDownloaded && !isLocked)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isLocked ? Colors.grey : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          color: isLocked ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: Colors.grey),
                            SizedBox(width: 3),
                            Text('Premium',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      )
                    else if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Free Content',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                  ],
                ),
              ),
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
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isLocked)
                IconButton(
                  icon: const Icon(Icons.lock, color: Colors.grey, size: 24),
                  onPressed: _showPremiumDialog,
                  tooltip: 'Premium Content',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else if (isDownloaded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('OFFLINE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.download,
                      color: AppColors.primary, size: 24),
                  onPressed: () => _downloadContent(item),
                  tooltip: 'Download for offline use',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
