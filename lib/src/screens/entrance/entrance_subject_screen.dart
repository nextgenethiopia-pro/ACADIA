import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/firebase_service.dart';

class EntranceSubjectScreen extends StatefulWidget {
  final String subject;
  final String stream;

  const EntranceSubjectScreen({
    super.key,
    required this.subject,
    required this.stream,
  });

  @override
  State<EntranceSubjectScreen> createState() => _EntranceSubjectScreenState();
}

class _EntranceSubjectScreenState extends State<EntranceSubjectScreen> {
  String? _userGrade;
  bool _isLoading = true;
  Map<String, int> _availableChapters = {};

  final List<String> _allGrades = ['9', '10', '11', '12'];

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
    try {
      final prefs = await SharedPreferences.getInstance();
      _userGrade = prefs.getString('grade') ?? prefs.getString('selected_grade');
      
      // Fetch available chapters from Firebase
      await _fetchAvailableChapters();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading entrance subject data: $e');
    }
  }

  Future<void> _fetchAvailableChapters() async {
    try {
      final firebase = FirebaseService();
      final materials = await firebase.getDocuments('entrance_materials', where: {
        'type': 'entrance_exam',
        'subject': widget.subject,
        'stream': widget.stream,
        'status': 'active',
      });

      // Count chapters per grade
      final chapterCounts = <String, int>{};
      for (final material in materials) {
        final grade = material['grade']?.toString() ?? '';
        if (grade.isNotEmpty) {
          chapterCounts[grade] = (chapterCounts[grade] ?? 0) + 1;
        }
      }
      
      setState(() {
        _availableChapters = chapterCounts;
      });
    } catch (e) {
      debugPrint('Error fetching available chapters: $e');
    }
  }

  int _getAvailableChapterCount(String grade) {
    return _availableChapters[grade] ?? 0;
  }

  Widget _getSubjectIcon(String subject, {double size = 28}) {
    final assetPath = _subjectIconAssets[subject];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(assetPath, width: size, height: size, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.book, size: size)),
      );
    }
    return Icon(Icons.book, size: size);
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor(widget.subject);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subject)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Subject header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withAlpha((255 * 0.8).toInt()), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((255 * 0.2).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _getSubjectIcon(widget.subject, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.stream == 'natural' ? 'Natural Science Stream' : 'Social Science Stream',
                          style: TextStyle(color: Colors.white.withAlpha((255 * 0.8).toInt()), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_availableChapters.length} grades available',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grade cards
            ..._allGrades.map((grade) {
              final isCurrentGrade = grade == _userGrade;
              final chapterCount = _getAvailableChapterCount(grade);
              final hasContent = chapterCount > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isCurrentGrade ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isCurrentGrade ? BorderSide(color: color, width: 2) : BorderSide.none,
                ),
                child: InkWell(
                  onTap: hasContent
                      ? () {
                          context.push('/entrance/exam', extra: {
                            'subject': widget.subject,
                            'stream': widget.stream,
                            'grade': grade,
                          });
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: !hasContent ? Colors.grey[50] : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasContent
                                ? (isCurrentGrade ? color.withAlpha((255 * 0.1).toInt()) : Colors.grey[100])
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'G$grade',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: hasContent
                                  ? (isCurrentGrade ? color : Colors.grey[600])
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grade $grade',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: hasContent ? Colors.black87 : Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (hasContent) ...[
                                    Icon(Icons.quiz, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$chapterCount chapter${chapterCount != 1 ? 's' : ''}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ] else ...[
                                    Icon(Icons.hourglass_empty, size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Coming soon',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (hasContent)
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}