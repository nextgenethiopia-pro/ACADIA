import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/di/injection.dart';
import 'package:acadia/src/domain/repositories/github_content_repository.dart';

import 'package:acadia/src/core/constants/academic_structure.dart';

class EntranceExamScreen extends StatefulWidget {
  final String? initialSubject;
  final String? initialGrade;
  final String? initialStream;

  const EntranceExamScreen({
    super.key,
    this.initialSubject,
    this.initialGrade,
    this.initialStream,
  });

  @override
  State<EntranceExamScreen> createState() => _EntranceExamScreenState();
}

class _EntranceExamScreenState extends State<EntranceExamScreen> {
  String? _userStream;
  String? _selectedSubject;
  String? _selectedGrade;
  String? _selectedUnit;
  List<Map<String, dynamic>> _fetchedContent = [];
  bool _isFetchingContent = false;

  // ============================================
  // HARDCODED SUBJECTS
  // ============================================
  List<String> get _subjects {
    final stream = _normalizeStream(_userStream);
    if (stream == 'social_science') {
      return const [
        'Mathematics',
        'English',
        'Aptitude',
        'Economics',
        'Geography',
        'History',
      ];
    }
    return const [
      'Mathematics',
      'English',
      'Physics',
      'Chemistry',
      'Biology',
      'Aptitude',
    ];
  }

  // ============================================
  // HARDCODED GRADES (9, 10, 11, 12)
  // ============================================
  final List<String> _grades = ['9', '10', '11', '12'];

  // ============================================
  // HARDCODED UNITS PER GRADE & SUBJECT (REAL GITHUB STRUCTURE)
  // ============================================
  List<String> _getUnits(String subject, String grade) {
    return AcademicStructure.getEntranceChapters(
      grade,
      _normalizeStream(_userStream),
      subject,
    );
  }

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
      final stream = widget.initialStream ??
          prefs.getString('stream') ??
          prefs.getString('selected_stream') ??
          'natural';

      setState(() {
        _userStream = stream;
        if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
          _selectedSubject = widget.initialSubject;
        }
        if (widget.initialGrade != null && widget.initialGrade!.isNotEmpty) {
          _selectedGrade = widget.initialGrade;
        }
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  // ============================================
  // FETCH CONTENT FROM GITHUB (ONLY AFTER UNIT CLICK)
  // ============================================
  Future<void> _fetchUnitContent(String subject, String grade, String unit) async {
    setState(() {
      _isFetchingContent = true;
      _selectedUnit = unit;
      _fetchedContent.clear();
    });

    try {
      final normalizedStream = _normalizeStream(_userStream);
      final repository = getIt<GithubContentRepository>();
      
      final content = await repository.getEntranceExamUnitContent(
        grade: grade,
        subject: subject,
        unit: unit,
        stream: normalizedStream,
      );

      setState(() {
        _fetchedContent = content;
        _isFetchingContent = false;
      });

      if (_fetchedContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No practice exam is published for $subject Grade $grade $unit.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching entrance unit content: $e');
      setState(() => _isFetchingContent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load practice exams. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
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
    final contentType = content['content_type']?.toString().toLowerCase() ?? '';
    final contentId = content['id']?.toString() ?? '';
    final title = content['title']?.toString() ?? 'Entrance Content';
    final downloadUrl = content['download_url']?.toString() ?? '';
    final totalQuestions = content['total_questions'] ?? 40;
    final timeLimitMinutes = content['time_limit_minutes'] ?? 60;

    switch (contentType) {
      case 'short_note':
      case 'pdf':
      case 'notes':
        context.push('/pdf-viewer', extra: {
          'contentId': contentId,
          'title': title,
          'downloadUrl': downloadUrl,
        });
        break;
      case 'quiz':
        context.push('/quiz', extra: {
          'contentId': contentId,
          'title': title,
          'downloadUrl': downloadUrl,
        });
        break;
      case 'video':
        context.push('/video-player', extra: {
          'contentId': contentId,
          'title': title,
          'videoUrl': downloadUrl,
        });
        break;
      case 'flashcard':
        context.push('/flashcard', extra: {
          'contentId': contentId,
          'title': title,
        });
        break;
      case 'exam':
      case 'past_paper':
      default:
        context.push('/exam', extra: {
          'contentId': contentId,
          'title': title,
          'downloadUrl': downloadUrl,
          'totalQuestions': totalQuestions,
          'timeLimitMinutes': timeLimitMinutes,
        });
    }
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
        title: Text(_selectedSubject == null 
            ? 'Entrance Exam' 
            : _selectedGrade == null 
                ? '$_selectedSubject - Select Grade' 
                : _selectedUnit == null
                    ? '$_selectedSubject - Grade $_selectedGrade'
                    : '$_selectedUnit'),
        leading: IconButton(
          onPressed: () {
            if (_selectedUnit != null) {
              setState(() {
                _selectedUnit = null;
                _fetchedContent.clear();
              });
            } else if (_selectedGrade != null) {
              setState(() {
                _selectedGrade = null;
              });
            } else if (_selectedSubject != null) {
              setState(() {
                _selectedSubject = null;
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
          : _selectedSubject == null
              ? _buildSubjectGrid()
              : _selectedGrade == null
                  ? _buildGradeGrid()
                  : _selectedUnit == null
                      ? _buildUnitGrid()
                      : _buildContentList(),
    );
  }

  // ============================================
  // SUBJECT GRID (3 columns)
  // ============================================
  Widget _buildSubjectGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Subject',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a subject to start practicing',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
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

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubject = subject;
        });
      },
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // GRADE GRID (HARDCODED: 11, 12)
  // ============================================
  Widget _buildGradeGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedSubject - Select Grade',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your grade level',
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
              itemCount: _grades.length,
              itemBuilder: (context, index) {
                final grade = _grades[index];
                return _buildGradeCard(grade);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(String grade) {
    final color = AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGrade = grade;
        });
      },
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
            Text(
              'Grade $grade',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose grade',
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UNIT GRID (HARDCODED PER SUBJECT & GRADE)
  // ============================================
  Widget _buildUnitGrid() {
    final units = _getUnits(_selectedSubject!, _selectedGrade!);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedSubject - Grade $_selectedGrade',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a unit to start practicing',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: units.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No units available for this subject',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      final unit = units[index];
                      return _buildUnitCard(unit);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(String unit) {
    final color = AppColors.primary;

    return InkWell(
      onTap: () => _fetchUnitContent(_selectedSubject!, _selectedGrade!, unit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Click to load',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No practice exam published for this unit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The repository currently holds entrance curriculum metadata '
                'for this unit but no exam file. Real entrance past papers are '
                'available in the Past Papers section.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/entrance/past-papers'),
                icon: const Icon(Icons.assignment),
                label: const Text('Open Past Papers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedUnit = null;
                    _fetchedContent.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Units'),
              ),
            ],
          ),
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
                '$_selectedUnit',
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
                  '${_fetchedContent.length} exams',
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
            'Select an exam to start practicing',
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
    final title = content['title']?.toString() ?? 'Entrance Exam';
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
                child: const Icon(Icons.quiz, color: AppColors.primary, size: 24),
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