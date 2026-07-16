import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/services/download_manager.dart';
import 'package:acadia/src/core/constants/colors.dart';

class EntrancePastPapersScreen extends StatefulWidget {
  const EntrancePastPapersScreen({super.key});

  @override
  State<EntrancePastPapersScreen> createState() => _EntrancePastPapersScreenState();
}

class _EntrancePastPapersScreenState extends State<EntrancePastPapersScreen> {
  String? _userStream;
  List<Map<String, dynamic>> _allPapers = [];
  Map<String, List<Map<String, dynamic>>> _papersBySubject = {};
  Set<String> _downloadedContentIds = {};
  Map<String, double> _downloadProgress = {};
  bool _isLoading = true;
  bool _isRefreshing = false;

  // 6 subjects per stream (from ACADIA spec)
  final List<String> _naturalSubjects = [
    'Mathematics', 'English', 'Biology', 'Chemistry', 'Physics', 'Aptitude'
  ];
  final List<String> _socialSubjects = [
    'Mathematics', 'English', 'Aptitude', 'Economics', 'Geography', 'History'
  ];

  final DownloadManager _downloadManager = DownloadManager();
  final OfflineDatabase _offlineDb = OfflineDatabase.instance;

  // Subject icons
  static const Map<String, String> _subjectIconAssets = {
    'Mathematics': 'assets/icons/subjects_icon/Math_icon.jpg',
    'English': 'assets/icons/subjects_icon/English_icon.jpg',
    'Physics': 'assets/icons/subjects_icon/Physics_icon.jpg',
    'Chemistry': 'assets/icons/subjects_icon/Chemistry_icon.jpg',
    'Biology': 'assets/icons/subjects_icon/Biology_icon.jpg',
    'Aptitude': 'assets/icons/subjects_icon/Aptitude_icon.jpg',
    'Geography': 'assets/icons/subjects_icon/Geography_icon.jpg',
    'History': 'assets/icons/subjects_icon/History_icon.jpg',
    'Economics': 'assets/icons/subjects_icon/Economics_icon.jpg',
  };

  static const Map<String, Color> _subjectColors = {
    'Mathematics': Color(0xFF9C27B0),
    'English': Color(0xFF2196F3),
    'Physics': Color(0xFFFF9800),
    'Chemistry': Color(0xFF4CAF50),
    'Biology': Color(0xFFE91E63),
    'Aptitude': Color(0xFF708090),
    'Geography': Color(0xFF009688),
    'History': Color(0xFF795548),
    'Economics': Color(0xFFFF5722),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        if (!_isLoading) _isRefreshing = true;
      });
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream') ?? 'natural';

      final firebase = FirebaseService();
      final papers = await firebase.getDocuments('entrance_materials', where: {
        'type': 'past_paper',
        'status': 'active',
      });

      // Filter by user's stream
      final filteredPapers = papers.where((paper) {
        final paperStream = paper['stream']?.toString() ?? '';
        return paperStream == _userStream || paperStream.isEmpty;
      }).toList();

      // Group by subject
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final paper in filteredPapers) {
        final subject = paper['subject']?.toString() ?? 'Unknown';
        grouped.putIfAbsent(subject, () => []);
        grouped[subject]!.add(paper);
      }

      // Sort papers by year (newest first) within each subject
      for (final subject in grouped.keys) {
        grouped[subject]!.sort((a, b) {
          final yearA = int.tryParse(a['year']?.toString() ?? '0') ?? 0;
          final yearB = int.tryParse(b['year']?.toString() ?? '0') ?? 0;
          return yearB.compareTo(yearA);
        });
      }

      // Check which are downloaded
      final downloaded = <String>{};
      for (final paper in filteredPapers) {
        final contentId = paper['id']?.toString() ?? '';
        if (contentId.isNotEmpty && await _offlineDb.isContentDownloaded(contentId)) {
          downloaded.add(contentId);
        }
      }

      if (mounted) {
        setState(() {
          _allPapers = filteredPapers;
          _papersBySubject = grouped;
          _downloadedContentIds = downloaded;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      debugPrint('Error loading past papers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading past papers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> get _subjects {
    return _userStream == 'social' ? _socialSubjects : _naturalSubjects;
  }

  Widget _getSubjectIcon(String subject, {double size = 24}) {
    final assetPath = _subjectIconAssets[subject];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.description, size: size),
        ),
      );
    }
    return Icon(Icons.description, size: size);
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  Future<void> _downloadPaper(Map<String, dynamic> paper) async {
    final contentId = paper['id']?.toString() ?? '';
    if (contentId.isEmpty) return;

    setState(() => _downloadProgress[contentId] = 0);

    try {
      await _downloadManager.downloadContent(
        contentId: contentId,
        title: paper['title']?.toString() ?? 'Past Paper',
        downloadUrl: paper['download_url']?.toString() ?? paper['url']?.toString() ?? '',
        contentType: 'exam',
        fileFormat: 'json',
        subject: paper['subject']?.toString() ?? '',
        chapter: 'Past Paper ${paper['year'] ?? ''}',
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress[contentId] = progress);
        },
      );

      if (mounted) {
        setState(() {
          _downloadedContentIds.add(contentId);
          _downloadProgress.remove(contentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Past paper downloaded!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(contentId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openPaper(Map<String, dynamic> paper) {
    final contentId = paper['id']?.toString() ?? '';
    final title = paper['title']?.toString() ?? 'Past Paper';
    final year = paper['year']?.toString() ?? '';

    context.push('/exam', extra: {
      'contentId': contentId,
      'title': '$title ($year)',
    });
  }

  Future<void> _deleteDownload(String contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Past Paper'),
        content: const Text('Remove this past paper from your device? You can download it again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _offlineDb.deleteDownload(contentId);
      setState(() => _downloadedContentIds.remove(contentId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Past paper deleted'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Past Papers'),
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjects = _subjects;
    final totalPapers = _allPapers.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Papers'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Header
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
                  const Icon(Icons.description, color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  const Text('Past Papers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    'Complete national exams from 2014 onwards',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalPapers papers available',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subjects
            ...subjects.map((subject) {
              final papers = _papersBySubject[subject] ?? [];
              return _buildSubjectSection(subject, papers);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSection(String subject, List<Map<String, dynamic>> papers) {
    final color = _getSubjectColor(subject);
    final hasPapers = papers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject header
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _getSubjectIcon(subject, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                subject,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${papers.length} papers',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Papers list
        if (!hasPapers)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Content will be uploaded soon by admin',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...papers.map((paper) => _buildPaperCard(paper, color)),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> paper, Color color) {
    final contentId = paper['id']?.toString() ?? '';
    final title = paper['title']?.toString() ?? 'Past Paper';
    final year = paper['year']?.toString() ?? '';
    final questions = paper['total_questions']?.toString() ?? '';
    final timeLimit = paper['time_limit_minutes']?.toString() ?? '';
    final isDownloaded = _downloadedContentIds.contains(contentId);
    final downloadProgress = _downloadProgress[contentId];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isDownloaded ? () => _openPaper(paper) : () => _downloadPaper(paper),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Paper icon
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.assignment, color: color, size: 24),
                  ),
                  if (isDownloaded)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Paper info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(Icons.calendar_today, year, color),
                        if (questions.isNotEmpty)
                          _buildInfoChip(Icons.quiz, '$questions questions', Colors.blue),
                        if (timeLimit.isNotEmpty)
                          _buildInfoChip(Icons.timer, '$timeLimit min', Colors.orange),
                      ],
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
                      CircularProgressIndicator(value: downloadProgress, strokeWidth: 3),
                      Text('${(downloadProgress * 100).toInt()}%', style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                )
              else if (isDownloaded)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Text('OFFLINE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'open') _openPaper(paper);
                        if (action == 'delete') _deleteDownload(contentId);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Practice Now')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                      child: Icon(Icons.more_vert, color: Colors.grey[500]),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: Icon(Icons.download, color: AppColors.primary),
                  onPressed: () => _downloadPaper(paper),
                  tooltip: 'Download for offline practice',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}