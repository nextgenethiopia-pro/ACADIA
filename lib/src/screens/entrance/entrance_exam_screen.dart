import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/services/download_manager.dart';
import 'package:acadia/src/core/content/github_content_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

class EntranceExamScreen extends StatefulWidget {
  final String? subject;
  final String? stream;
  final String? grade;

  const EntranceExamScreen({super.key, this.subject, this.stream, this.grade});

  @override
  State<EntranceExamScreen> createState() => _EntranceExamScreenState();
}

class _EntranceExamScreenState extends State<EntranceExamScreen> {
  String? _userStream;
  String? _selectedSubject;
  String? _selectedGrade;
  List<Map<String, dynamic>> _allContent = [];
  Map<String, List<Map<String, dynamic>>> _contentByChapter = {};
  Set<String> _downloadedContentIds = {};
  Map<String, double> _downloadProgress = {};
  bool _isLoading = true;

  final DownloadManager _downloadManager = DownloadManager();
  final OfflineDatabase _offlineDb = OfflineDatabase.instance;

  // 6 subjects per stream (from ACADIA spec)
  final List<String> _naturalSubjects = [
    'Mathematics', 'English', 'Biology', 'Chemistry', 'Physics', 'Aptitude'
  ];
  final List<String> _socialSubjects = [
    'Mathematics', 'English', 'Aptitude', 'Economics', 'Geography', 'History'
  ];
  final List<String> _grades = ['9', '10', '11', '12'];

  // Chapter counts per grade and subject
  final Map<String, Map<String, int>> _chapterCounts = {
    '9': {
      'Mathematics': 9, 'English': 8, 'Biology': 6, 'Chemistry': 5,
      'Physics': 7, 'Aptitude': 2, 'Geography': 6, 'History': 9, 'Economics': 8,
    },
    '10': {
      'Mathematics': 7, 'English': 10, 'Biology': 6, 'Chemistry': 6,
      'Physics': 6, 'Aptitude': 2, 'Geography': 8, 'History': 9, 'Economics': 8,
    },
    '11': {
      'Mathematics': 5, 'English': 10, 'Biology': 6, 'Chemistry': 6,
      'Physics': 7, 'Aptitude': 2, 'Geography': 8, 'History': 9, 'Economics': 7,
    },
    '12': {
      'Mathematics': 5, 'English': 10, 'Biology': 6, 'Chemistry': 5,
      'Physics': 5, 'Aptitude': 2, 'Geography': 8, 'History': 9, 'Economics': 8,
    },
  };

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
    _selectedSubject = widget.subject;
    _selectedGrade = widget.grade;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userStream = widget.stream ?? prefs.getString('stream') ?? prefs.getString('selected_stream') ?? 'natural';

      if (_selectedSubject != null && _selectedGrade != null) {
        await _loadContentForSubjectAndGrade();
      } else if (_selectedSubject != null) {
        await _loadContentForSubject();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading entrance exam data: $e');
    }
  }

  Future<void> _loadContentForSubject() async {
    try {
      final firebase = FirebaseService();
      final content = await firebase.getDocuments('entrance_materials', where: {
        'type': 'entrance_exam',
        'subject': _selectedSubject,
        'stream': _userStream,
        'status': 'active',
      });

      _groupContentByChapter(content);
    } catch (e) {
      debugPrint('Error loading subject content: $e');
    }
  }

  Future<void> _loadContentForSubjectAndGrade() async {
    // Primary: GitHub content repo (entrance/grade_<grade>/<subject>.json).
    List<Map<String, dynamic>> github = const [];
    try {
      github = await GithubContentService.instance.fetchEntranceItems(
        grade: _selectedGrade!,
        subject: _selectedSubject!,
      );
    } catch (e) {
      debugPrint('Error loading GitHub entrance content: $e');
    }

    // Fallback/merge: Firestore admin-uploaded entrance materials.
    List<Map<String, dynamic>> firestore = const [];
    try {
      final firebase = FirebaseService();
      firestore = await firebase.getDocuments('entrance_materials', where: {
        'type': 'entrance_exam',
        'subject': _selectedSubject,
        'stream': _userStream,
        'grade': _selectedGrade,
        'status': 'active',
      });
    } catch (e) {
      debugPrint('Error loading Firestore entrance content: $e');
    }

    _groupContentByChapter(_mergeById(github, firestore));
  }

  /// Merges two content lists, de-duplicating by `id` (GitHub items win).
  List<Map<String, dynamic>> _mergeById(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> fallback,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final item in [...fallback, ...primary]) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      byId[id] = item;
    }
    return byId.values.toList(growable: false);
  }

  Future<void> _groupContentByChapter(List<Map<String, dynamic>> content) async {
    // Group by chapter
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in content) {
      final chapter = item['chapter']?.toString() ?? 'Unit 1';
      grouped.putIfAbsent(chapter, () => []);
      grouped[chapter]!.add(item);
    }

    // Check downloads
    final downloaded = <String>{};
    for (final item in content) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && await _offlineDb.isContentDownloaded(id)) {
        downloaded.add(id);
      }
    }

    setState(() {
      _allContent = content;
      _contentByChapter = grouped;
      _downloadedContentIds = downloaded;
    });
  }

  List<String> get _subjects {
    return _userStream == 'social' ? _socialSubjects : _naturalSubjects;
  }

  int _getChapterCount(String subject, String grade) {
    return _chapterCounts[grade]?[subject] ?? 5;
  }

  int _getAvailableChaptersCount() {
    return _contentByChapter.keys.length;
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
          errorBuilder: (_, __, ___) => Icon(Icons.quiz, size: size),
        ),
      );
    }
    return Icon(Icons.quiz, size: size);
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  Future<void> _downloadContent(Map<String, dynamic> content) async {
    final contentId = content['id']?.toString() ?? '';
    if (contentId.isEmpty) return;

    setState(() => _downloadProgress[contentId] = 0);

    try {
      await _downloadManager.downloadContent(
        contentId: contentId,
        title: content['title']?.toString() ?? 'Entrance Questions',
        downloadUrl: content['download_url']?.toString() ?? content['url']?.toString() ?? '',
        contentType: 'quiz', // Use quiz viewer for entrance exam
        fileFormat: 'json',
        subject: content['subject']?.toString() ?? '',
        chapter: content['chapter']?.toString() ?? '',
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
          const SnackBar(content: Text('Questions downloaded!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
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

  void _openContent(Map<String, dynamic> content) {
    final contentId = content['id']?.toString() ?? '';
    final title = content['title']?.toString() ?? 'Entrance Questions';
    context.push('/quiz', extra: {'contentId': contentId, 'title': title});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Entrance Exam'),
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGrade != null 
            ? 'Grade $_selectedGrade $_selectedSubject' 
            : (_selectedSubject ?? 'Entrance Exam')),
        leading: IconButton(
          onPressed: () {
            if (_selectedGrade != null && _selectedSubject != null) {
              // Go back to grade selection
              setState(() => _selectedGrade = null);
            } else if (_selectedSubject != null) {
              // Go back to subject selection
              setState(() {
                _selectedSubject = null;
                _contentByChapter = {};
              });
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _selectedSubject == null
          ? _buildSubjectSelection()
          : _selectedGrade == null
              ? _buildGradeSelection()
              : _buildChapterList(),
    );
  }

  // ============================================================
  // STEP 1: Select Subject
  // ============================================================
  Widget _buildSubjectSelection() {
    final subjects = _subjects;

    return RefreshIndicator(
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
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.quiz, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                const Text('Entrance Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 4),
                Text('Practice questions by grade and chapter',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Select Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final color = _getSubjectColor(subject);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubject = subject;
                      _selectedGrade = null;
                    });
                    _loadContentForSubject();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.12), color.withOpacity(0.03)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getSubjectIcon(subject, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          subject,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2: Select Grade
  // ============================================================
  Widget _buildGradeSelection() {
    final color = _getSubjectColor(_selectedSubject ?? '');
    final subjects = _subjects;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Selected subject header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              _getSubjectIcon(_selectedSubject ?? '', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedSubject ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Select Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _grades.length,
          itemBuilder: (context, index) {
            final grade = _grades[index];
            final chapterCount = _getChapterCount(_selectedSubject ?? '', grade);
            final availableCount = _getAvailableChaptersForGrade(grade);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => setState(() => _selectedGrade = grade),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.1), color.withOpacity(0.03)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Grade $grade',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$chapterCount chapters',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _getAvailableChaptersForGrade(String grade) {
    // Count chapters that have content for this grade
    int count = 0;
    for (final chapter in _contentByChapter.keys) {
      final items = _contentByChapter[chapter] ?? [];
      for (final item in items) {
        if (item['grade']?.toString() == grade) {
          count++;
          break;
        }
      }
    }
    return count > 0 ? count : _contentByChapter.length;
  }

  // ============================================================
  // STEP 3: Show Chapters
  // ============================================================
  Widget _buildChapterList() {
    final color = _getSubjectColor(_selectedSubject ?? '');
    final chapters = _contentByChapter.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async {
        await _loadContentForSubjectAndGrade();
        return Future.value();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Breadcrumb navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedGrade = null),
                  child: Text(_selectedSubject ?? '', style: TextStyle(color: color, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('Grade $_selectedGrade', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chapter header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chapters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chapters.length} chapters',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (chapters.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No content available yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Content will be uploaded soon by admin',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...chapters.map((chapter) {
              final items = _contentByChapter[chapter] ?? [];
              return _buildChapterCard(chapter, items, color);
            }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildChapterCard(String chapter, List<Map<String, dynamic>> items, Color color) {
    final content = items.isNotEmpty ? items.first : null;
    final contentId = content?['id']?.toString() ?? '';
    final title = content?['title']?.toString() ?? chapter;
    final questions = content?['total_questions']?.toString() ?? '0';
    final lastUpdated = content?['last_updated']?.toString() ?? content?['created_at']?.toString() ?? '';
    final isDownloaded = _downloadedContentIds.contains(contentId);
    final downloadProgress = _downloadProgress[contentId];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: content != null
            ? (isDownloaded ? () => _openContent(content) : () => _downloadContent(content))
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Chapter icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              
              // Chapter info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.quiz, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('$questions questions', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (lastUpdated.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.update, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text('Updated: ${_formatDate(lastUpdated)}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action button
              if (content == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('No content yet', style: TextStyle(fontSize: 10, color: Colors.grey)),
                )
              else if (downloadProgress != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: downloadProgress, strokeWidth: 3),
                      Text('${(downloadProgress * 100).toInt()}%', style: const TextStyle(fontSize: 10)),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('OFFLINE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.download, color: AppColors.primary),
                  onPressed: () => _downloadContent(content),
                  tooltip: 'Download for offline practice',
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}