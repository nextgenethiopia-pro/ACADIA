import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';
import 'package:acadia/src/widgets/common/subject_icon_widget.dart';
import 'package:acadia/src/core/services/package_service.dart';
import 'package:acadia/src/core/services/download_manager.dart';
import 'package:acadia/src/core/di/injection.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/domain/repositories/github_content_repository.dart';
import 'package:acadia/src/domain/models/unit_content_result.dart';

class SubjectPortalScreen extends StatefulWidget {
  final String subjectId;
  const SubjectPortalScreen({super.key, required this.subjectId});

  @override
  State<SubjectPortalScreen> createState() => _SubjectPortalScreenState();
}

class _SubjectPortalScreenState extends State<SubjectPortalScreen> {
  Map<String, List<String>> _contentStructure = {};
  final Map<String, double> _unitProgress = {};
  final Map<String, bool> _unitCompleted = {};
  bool _isLoading = true;
  bool _isPurchased = false;
  DateTime? _purchaseExpiry;
  List<String> _contentTypes = [];
  final Map<String, String> _unitFiles = {};
  final Map<String, String> _unitTitles = {};
  String? _userGrade;
  final PackageService _packageService = PackageService();
  final GithubContentRepository _contentRepository =
      getIt<GithubContentRepository>();
  final DownloadManager _downloadManager = DownloadManager();
  final IsarService _isarService = IsarService.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _userGrade = await _resolveAcademicIdentifier(prefs);

      // Check purchase status
      _isPurchased = await _packageService.hasActivePackage();
      if (_isPurchased) {
        final daysRemaining = await _packageService.getDaysRemaining();
        if (daysRemaining > 0) {
          _purchaseExpiry = DateTime.now().add(Duration(days: daysRemaining));
        }
      }

      await _loadContentStructure();

      // Load local progress
      await _loadUserProgress();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading subject data: $e');
    }
  }

  Future<void> _loadContentStructure() async {
    final prefs = await SharedPreferences.getInstance();
    final academicId = _userGrade ?? await _resolveAcademicIdentifier(prefs);
    final stream =
        prefs.getString('stream') ?? prefs.getString('selected_stream');
    final normalizedStream = (stream ?? 'natural').trim().toLowerCase();

    final structure = <String, List<String>>{};
    final unitFiles = <String, String>{};
    final unitTitles = <String, String>{};
    final allTypes = <String>{};

    const supportedTypes = <String>[
      'short_note',
      'quiz',
      'exam',
      'flashcard',
      'past_paper',
    ];

    try {
      // Navigation is completely hardcoded/offline. GitHub is queried only
      // after the user opens a unit/chapter.
      final lower = academicId.toLowerCase();
      List<String> units;
      if (lower.startsWith('university_')) {
        final semesterMatch =
            RegExp(r'sem(?:ester)?[_\s-]*(\d+)').firstMatch(lower);
        final semester = semesterMatch?.group(1) ?? '1';
        final universityStream =
            lower.contains('social') ? 'social' : 'natural';
        final isPreEngineering = lower.contains('pre_engineering') ||
            lower.contains('pre-engineering') ||
            lower.contains('pre engineering');
        final track = semester == '2'
            ? (isPreEngineering ? 'pre_engineering' : 'other_natural_science')
            : null;
        units = AcademicStructure.getUniversityChapters(
          semester,
          universityStream,
          widget.subjectId,
          track,
        );
      } else {
        final gradeNumber =
            RegExp(r'(\d+)').firstMatch(academicId)?.group(1) ?? '9';
        units = AcademicStructure.getChapters(
          gradeNumber,
          normalizedStream == 'social_science' ? 'social' : normalizedStream,
          widget.subjectId,
        );
      }

      for (final unit in units) {
        final folder = unit.trim();
        if (folder.isEmpty) continue;
        structure[folder] = supportedTypes.toList(growable: false);
        unitFiles[folder] = folder;
        unitTitles[folder] = AcademicStructure.displayChapterTitle(folder);
        allTypes.addAll(supportedTypes);
      }

      _contentStructure = structure;
      _unitFiles
        ..clear()
        ..addAll(unitFiles);
      _unitTitles
        ..clear()
        ..addAll(unitTitles);
      _contentTypes = allTypes.toList(growable: false);
    } catch (e) {
      debugPrint('Error building hardcoded subject structure: $e');
      _contentStructure = {};
      _contentTypes = [];
      _unitFiles.clear();
      _unitTitles.clear();
    }
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

  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Progress is stored by ProgressRepository as one JSON string per unit
      // under 'progress_<subjectId>_<unitName>'.
      final prefix = 'progress_${widget.subjectId}_';
      for (final key
          in prefs.getKeys().where((key) => key.startsWith(prefix))) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          final decoded = json.decode(raw);
          if (decoded is! Map) continue;
          final unitName = decoded['unit_name']?.toString().isNotEmpty == true
              ? decoded['unit_name'].toString()
              : key.substring(prefix.length);
          if (unitName.isEmpty) continue;
          _unitCompleted[unitName] = decoded['is_completed'] == true;
          _unitProgress[unitName] =
              (decoded['progress'] as num?)?.toDouble() ?? 0.0;
        } catch (_) {
          debugPrint('Skipping unreadable progress entry: $key');
        }
      }
    } catch (e) {
      debugPrint('Error loading local progress: $e');
    }
  }

  double _getOverallProgress() {
    final units = _contentStructure.keys.toList();
    if (units.isEmpty) return 0.0;
    if (_unitProgress.isEmpty) return 0.0;

    double total = 0;
    for (final unit in units) {
      total += _unitProgress[unit] ?? 0.0;
    }
    return total / units.length;
  }

  int _getCompletedCount() => _unitCompleted.values.where((c) => c).length;
  int _getInProgressCount() =>
      _unitProgress.values.where((p) => p > 0 && p < 1.0).length;
  int _getPendingCount() {
    final units = _contentStructure.keys.toList();
    return units.length - _getCompletedCount() - _getInProgressCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorHex =
        AcademicStructure.subjectColors[widget.subjectId] ?? '#607D8B';
    final subjectColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjectId)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_contentStructure.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjectId)),
        body: RefreshIndicator(
          onRefresh: () async {
            final grade = _userGrade?.trim();
            if (grade != null && grade.isNotEmpty) {
              final refreshPrefs = await SharedPreferences.getInstance();
              await _contentRepository.refreshSubjectMetadata(
                grade: grade,
                subject: widget.subjectId,
                stream: refreshPrefs.getString('selected_stream') ??
                    refreshPrefs.getString('stream'),
              );
            }
            await _loadData();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              if (!_isPurchased) ...[
                const SizedBox(height: 120),
                const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  'Content Locked',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Purchase this grade to access learning materials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/payment'),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('UNLOCK NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 120),
                const Icon(Icons.menu_book_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'No units available',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This subject has no units defined for your programme.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final overallProgress = _getOverallProgress();
    final completedCount = _getCompletedCount();
    final inProgressCount = _getInProgressCount();
    final pendingCount = _getPendingCount();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.subjectId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [subjectColor, subjectColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SubjectIconWidget(
                            subject: widget.subjectId,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_contentStructure.length} Units',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Overall Progress
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isPurchased
                    ? subjectColor.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPurchased
                      ? subjectColor.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  if (!_isPurchased) ...[
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            color: Colors.orange[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Content Locked',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Text(
                                'Purchase this grade to unlock all units',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/payment'),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('UNLOCK NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_purchaseExpiry != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Valid until: ${_purchaseExpiry!.day}/${_purchaseExpiry!.month}/${_purchaseExpiry!.year}',
                            style: TextStyle(
                                color: Colors.green[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isPurchased
                            ? '${(overallProgress * 100).toInt()}%'
                            : 'Locked',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              _isPurchased ? subjectColor : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProgressStat('$completedCount', 'Completed'),
                      _buildProgressStat('$inProgressCount', 'In Progress'),
                      _buildProgressStat('$pendingCount', 'Pending'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content Types
          if (_contentTypes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Types',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _contentTypes.map((type) {
                          return _buildContentTypeChip(type, subjectColor);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Units List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Units',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (_contentStructure.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No units are defined for this subject.'),
                    ),
                  );
                }
                final units = _contentStructure.keys.toList();
                final unit = units[index];
                return _buildUnitCard(
                  context,
                  unit: unit,
                  title: _unitTitles[unit] ?? unit,
                  unitNumber: index + 1,
                  subjectColor: subjectColor,
                );
              },
              childCount:
                  _contentStructure.isEmpty ? 1 : _contentStructure.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeChip(String type, Color color) {
    final icon = _getContentTypeIcon(type);
    final label = _getContentTypeLabel(type);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndOpenUnit(String unit) async {
    if (!_isPurchased) {
      if (mounted) context.push('/payment');
      return;
    }
    setState(() => _isLoading = true);
    final unitFile = _unitFiles[unit] ?? unit;
    final displayTitle = _unitTitles[unit] ?? unit;
    final prefs = await SharedPreferences.getInstance();
    final grade = _userGrade ??
        prefs.getString('grade') ??
        prefs.getString('selected_grade') ??
        '9';
    final stream =
        prefs.getString('stream') ?? prefs.getString('selected_stream');
    try {
      final result = await _contentRepository.getUnitContentResult(
        grade: grade,
        subject: widget.subjectId,
        unitFile: unitFile,
        stream: stream,
      );
      if (!result.hasItems) {
        // Offline with a cleared resolution cache can still have downloaded
        // files; those must be shown instead of the download prompt.
        if (await _hasDownloadedContent(unitFile)) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _openChapter(unit, unitFile, displayTitle, offlineOnly: true);
          return;
        }
        if (mounted) {
          setState(() => _isLoading = false);
          final canRetry = result.status == UnitContentStatus.offlineNoCache;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.orange[800],
                duration: const Duration(seconds: 10),
                action: canRetry
                    ? SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () => _downloadAndOpenUnit(unit),
                      )
                    : null,
              ),
            );
        }
        return;
      }
      final downloadable = result.items.where((item) {
        final type = item['content_type']?.toString() ?? '';
        final url = item['download_url']?.toString() ?? '';
        return type != 'video' &&
            url.isNotEmpty &&
            !url.contains('youtube.com') &&
            !url.contains('youtu.be');
      }).toList();
      if (downloadable.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('No downloadable files are available for this unit.')),
          );
        }
        return;
      }
      final downloadedPaths = await _downloadManager.downloadContentBatch(
        contents: downloadable,
        subject: widget.subjectId,
        chapter: unitFile,
        grade: grade,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (downloadedPaths.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                  'No content is downloaded for this chapter yet. Turn on internet to download it.'),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _downloadAndOpenUnit(unit),
              ),
            ),
          );
        return;
      }
      _openChapter(unit, unitFile, displayTitle, offlineOnly: false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Download failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _openChapter(String unit, String unitFile, String displayTitle,
      {bool offlineOnly = false}) {
    final encodedUnit = Uri.encodeComponent(unitFile);
    context.push('/chapter/$encodedUnit', extra: {
      'unit': unitFile,
      'subjectId': widget.subjectId,
      'contentTypes': _contentStructure[unit] ?? const [],
      'chapterId': unitFile,
      'subjectName': widget.subjectId,
      'chapterName': displayTitle,
      'offlineOnly': offlineOnly,
    });
  }

  /// True when this unit has at least one downloaded file on the device, so
  /// an offline open can show the downloaded content even when the
  /// resolution cache is empty.
  Future<bool> _hasDownloadedContent(String unitFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final records = await _isarService.getDownloadedContentByContext(
        userId: user.uid,
        subject: widget.subjectId,
        chapter: unitFile,
      );
      for (final record in records) {
        if (record.isDownloaded != true) continue;
        final path = record.contentPath ?? '';
        if (path.isNotEmpty && File(path).existsSync()) return true;
      }
    } catch (e) {
      debugPrint('⚠️ Could not check downloaded content: $e');
    }
    return false;
  }

  Widget _buildUnitCard(
    BuildContext context, {
    required String unit,
    required String title,
    required int unitNumber,
    required Color subjectColor,
  }) {
    final progress = _unitProgress[unit] ?? 0.0;
    final isCompleted = _unitCompleted[unit] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: _isPurchased ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isPurchased ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
      child: InkWell(
        onTap: () => _downloadAndOpenUnit(unit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isPurchased
                      ? subjectColor.withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isPurchased
                      ? (isCompleted
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Text(
                              '$unitNumber',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
                              ),
                            ))
                      : Icon(Icons.lock, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isPurchased ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!_isPurchased) ...[
                      Text(
                        'Purchase to unlock',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (isCompleted) ...[
                      const Text(
                        'Completed ✓',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      if (progress > 0 && progress < 1.0) ...[
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(subjectColor),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Tap to start learning',
                          style: TextStyle(
                            fontSize: 12,
                            color: subjectColor,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (_isPurchased)
                IconButton(
                  tooltip: 'Download unit for offline use',
                  onPressed: () => _downloadAndOpenUnit(unit),
                  icon: const Icon(Icons.download_for_offline,
                      color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getContentTypeIcon(String type) {
    switch (type.toLowerCase()) {
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
        return Icons.article;
    }
  }

  String _getContentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'short_note':
        return 'Short Note';
      case 'quiz':
        return 'Quiz';
      case 'exam':
        return 'Exam';
      case 'flashcard':
        return 'Flashcard';
      case 'past_paper':
        return 'Past Paper';
      default:
        return type;
    }
  }
}
