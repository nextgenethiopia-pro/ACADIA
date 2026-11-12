import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/di/injection.dart';
import 'package:acadia/src/domain/repositories/github_content_repository.dart';
import 'package:acadia/src/core/services/download_manager.dart';
import 'package:acadia/src/core/services/github_content_service.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EntrancePastPapersScreen extends StatefulWidget {
  const EntrancePastPapersScreen({super.key});

  @override
  State<EntrancePastPapersScreen> createState() =>
      _EntrancePastPapersScreenState();
}

class _EntrancePastPapersScreenState extends State<EntrancePastPapersScreen> {
  final IsarService _isarService = IsarService.instance;
  final DownloadManager _downloadManager = DownloadManager();
  
  String? _userStream;
  String? _selectedYear;
  String? _selectedSubject;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _fetchedContent = [];
  bool _isFetchingContent = false;

  // ============================================
  // DYNAMIC YEARS — Replaced by repository metadata when it loads.
  // The fallback lists the years currently published in the repository.
  // ============================================
  List<int> _years = List.generate(9, (index) => 2018 - index);

  // ============================================
  // HARDCODED SUBJECTS PER STREAM
  // ============================================
  final List<String> _naturalSubjects = [
    'Mathematics',
    'English',
    'Physics',
    'Chemistry',
    'Biology',
    'Aptitude'
  ];
  
  final List<String> _socialSubjects = [
    'Mathematics',
    'English',
    'Aptitude',
    'Economics',
    'Geography',
    'History'
  ];

  // ============================================
  // SUBJECT ICONS & COLORS
  // ============================================
  static const Map<String, IconData> _subjectIcons = {
    'Mathematics': Icons.calculate,
    'English': Icons.menu_book,
    'Physics': Icons.science,
    'Chemistry': Icons.biotech,
    'Biology': Icons.pest_control,
    'Aptitude': Icons.psychology,
    'Geography': Icons.public,
    'History': Icons.history_edu,
    'Economics': Icons.trending_up,
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream') ?? 'natural';

      // Discover available past paper years from entrance metadata
      final stream = _normalizeStream(_userStream);
      final meta = await getIt<GithubContentRepository>().getEntranceMetadata(stream: stream);
      if (meta != null) {
        final pastPapers = meta['pastPapers'];
        if (pastPapers != null && pastPapers['years'] is List) {
          final discoveredYears = (pastPapers['years'] as List)
              .map((y) => int.tryParse(y.toString()) ?? 0)
              .where((y) => y > 0)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));
          if (discoveredYears.isNotEmpty && mounted) {
            setState(() {
              _years = discoveredYears;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  // ============================================
  // GET SUBJECTS BASED ON STREAM (HARDCODED)
  // ============================================
  List<String> get _availableSubjects {
    return _normalizeStream(_userStream) == 'social_science'
        ? _socialSubjects
        : _naturalSubjects;
  }

  String get _yearRangeLabel {
    if (_years.isEmpty) return 'Choose a year to view available subjects';
    if (_years.length == 1) {
      return 'Past papers are available for ${_years.first}';
    }
    final newest = _years.reduce((a, b) => a > b ? a : b);
    final oldest = _years.reduce((a, b) => a < b ? a : b);
    return 'Past papers are available from $oldest to $newest';
  }

  // ============================================
  // FETCH CONTENT FROM GITHUB (ONLY AFTER SUBJECT CLICK)
  // ============================================
  Future<void> _fetchSubjectContent(String subject, int year) async {
    setState(() {
      _isFetchingContent = true;
      _selectedSubject = subject;
      _fetchedContent.clear();
    });
    try {
      // 1. Check local Isar database first
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final local = await _isarService.getDownloadedContentByContext(
          userId: user.uid,
          subject: subject,
          grade: 'entrance',
          chapter: 'Past Paper $year',
        );
        final matching = local.map((r) => <String, dynamic>{
          'id': r.contentId,
          'title': r.title ?? '$subject - $year',
          'content_type': r.contentType ?? 'past_paper',
          'download_url': r.contentPath ?? '',
          'total_questions': r.totalQuestions ?? 40,
          'time_limit_minutes': 60,
        }).toList();
        if (matching.isNotEmpty) {
          setState(() { _fetchedContent = matching; _isFetchingContent = false; });
          return;
        }
      }

      // 2. Query GitHub repository for this year and subject
      final stream = _normalizeStream(_userStream);
      final repository = getIt<GithubContentRepository>();
      final remoteItems = await repository.getEntranceContent(
        stream: stream,
        type: 'past_paper',
        subject: subject,
        year: year.toString(),
      );

      if (remoteItems.isNotEmpty) {
        if (mounted) {
          setState(() {
            _fetchedContent = remoteItems;
            _isFetchingContent = false;
          });
        }
        return;
      }

      // 3. Fallback: check the canonical repository path directly. Some
      // papers (for example Aptitude) exist on disk but are missing from the
      // compact `pastPapers.subjects` list in the stream metadata.
      final streamFolder = stream.contains('social') ? 'Social_Science' : 'Natural_Science';
      final conventionalUrl =
          'https://raw.githubusercontent.com/Acadia-et/ACADIA-CONTENT/main/entrance/$streamFolder/past_papers/$year/$subject.json';
      final directService = getIt<GithubContentService>();
      final directData = await directService.fetchJsonFromUrl(conventionalUrl);
      if (directData != null) {
        final item = {
          'id': 'entrance_${stream}_${subject.toLowerCase()}_$year',
          'subject': subject,
          'title': '$subject - $year',
          'year': year,
          'content_type': 'past_paper',
          'total_questions': (directData['questions'] as List?)?.length ?? 40,
          'time_limit_minutes': 60,
          'download_url': conventionalUrl,
        };
        if (mounted) {
          setState(() {
            _fetchedContent = [item];
            _isFetchingContent = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() => _isFetchingContent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No past papers available for $subject ($year).')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingContent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load past paper: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _normalizeStream(String? stream) {
    switch (stream?.trim().toLowerCase()) {
      case 'natural':
      case 'natural science':
      case 'natural_science':
        return 'natural_science';
      case 'social':
      case 'social science':
      case 'social_science':
        return 'social_science';
      default:
        return stream?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    }
  }

  void _openContent(Map<String, dynamic> content) {
    final contentId = content['id']?.toString() ?? '';
    final title = content['title']?.toString() ?? 'Past Paper';
    final downloadUrl = content['download_url']?.toString() ?? '';
    final totalQuestions = content['total_questions'] ?? 40;
    final timeLimitMinutes = content['time_limit_minutes'] ?? 60;

    context.push('/exam', extra: {
      'contentId': contentId,
      'title': title,
      'downloadUrl': downloadUrl,
      'totalQuestions': totalQuestions,
      'timeLimitMinutes': timeLimitMinutes,
    });
  }

  Widget _getSubjectIcon(String subject, {double size = 32}) {
    final assetPath = _subjectIconAssets[subject];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            _subjectIcons[subject] ?? Icons.article,
            size: size,
            color: _subjectColors[subject] ?? Colors.grey,
          ),
        ),
      );
    }
    return Icon(
      _subjectIcons[subject] ?? Icons.article,
      size: size,
      color: _subjectColors[subject] ?? Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedYear == null 
            ? 'Past Papers' 
            : _selectedSubject == null 
                ? 'Year $_selectedYear' 
                : '$_selectedSubject - $_selectedYear'),
        leading: IconButton(
          onPressed: () {
            if (_selectedSubject != null) {
              setState(() {
                _selectedSubject = null;
                _fetchedContent.clear();
              });
            } else if (_selectedYear != null) {
              setState(() {
                _selectedYear = null;
                _subjects.clear();
              });
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isFetchingContent
          ? const Center(child: CircularProgressIndicator())
          : _selectedYear == null
              ? _buildYearGrid()
              : _selectedSubject == null
                  ? _buildSubjectGrid()
                  : _buildContentList(),
    );
  }

  // ============================================
  // YEAR GRID (3x3)
  // ============================================
  Widget _buildYearGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Year',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _yearRangeLabel,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _years.length,
              itemBuilder: (context, index) {
                final year = _years[index];
                return _buildYearCard(year);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadYear(int year) async {
    setState(() {
      _isFetchingContent = true;
      _selectedYear = year.toString();
      _selectedSubject = null;
      _fetchedContent.clear();
      _subjects = _availableSubjects.map((s) => {'subject': s, 'year': year}).toList();
    });
    try {
      final stream = _normalizeStream(_userStream);
      final repository = getIt<GithubContentRepository>();
      for (final subject in _availableSubjects) {
        final content = await repository.getEntranceContent(
          stream: stream,
          type: 'past_paper',
          subject: subject,
          year: year.toString(),
        );
        final downloadable = content.where((item) {
          final url = item['download_url']?.toString() ?? '';
          return url.isNotEmpty && !url.contains('youtube.com') && !url.contains('youtu.be');
        }).toList();
        if (downloadable.isNotEmpty) {
          await _downloadManager.downloadContentBatch(
            contents: downloadable,
            subject: subject,
            chapter: 'Past Paper $year',
            grade: 'entrance',
          );
        }
      }
      if (!mounted) return;
      setState(() => _isFetchingContent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All available $year past papers downloaded for offline use'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingContent = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildYearCard(int year) {
    return InkWell(
      onTap: () => _downloadYear(year),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              year.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Download offline',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SUBJECT GRID (HARDCODED, 2 columns)
  // ============================================
  Widget _buildSubjectGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Year $_selectedYear',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_availableSubjects.length} subjects',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a subject to start practicing',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _availableSubjects.length,
              itemBuilder: (context, index) {
                final subject = _availableSubjects[index];
                return _buildSubjectCard(subject);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subject) {
    final color = _subjectColors[subject] ?? Colors.grey;
    final year = int.tryParse(_selectedYear ?? '0') ?? 0;

    return InkWell(
      onTap: () => _fetchSubjectContent(subject, year),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getSubjectIcon(subject, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Click to load',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CONTENT LIST (AFTER FETCHING FROM GITHUB)
  // ============================================
  Widget _buildContentList() {
    if (_fetchedContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No content available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different subject',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSubject = null;
                  _fetchedContent.clear();
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Subjects'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_selectedSubject - $_selectedYear',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_fetchedContent.length} papers',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a paper to start practicing',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _fetchedContent.length,
              itemBuilder: (context, index) {
                final content = _fetchedContent[index];
                return _buildContentCard(content);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(Map<String, dynamic> content) {
    final title = content['title']?.toString() ?? 'Past Paper';
    final year = content['year']?.toString() ?? '';
    final totalQuestions = content['total_questions'] ?? 40;
    final timeLimitMinutes = content['time_limit_minutes'] ?? 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openContent(content),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(Icons.calendar_today, year, Colors.grey),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.quiz, '$totalQuestions questions', Colors.blue),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.timer, '$timeLimitMinutes min', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
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