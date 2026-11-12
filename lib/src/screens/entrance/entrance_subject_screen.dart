import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _gradesData = [];

  // Subject icons from assets
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userGrade =
          prefs.getString('grade') ?? prefs.getString('selected_grade') ?? '9';
      final stream = widget.stream.trim().toLowerCase() == 'social'
          ? 'social'
          : 'natural';

      // Entrance navigation is hardcoded and works offline. The actual
      // content is fetched later, only after the user clicks a unit.
      final gradesData = <Map<String, dynamic>>[];
      for (final grade in AcademicStructure.grades) {
        final units = AcademicStructure.getChapters(grade, stream, widget.subject);
        gradesData.add({
          'grade': grade,
          'unitCount': units.length,
          'totalItems': units.length,
          'hasContent': units.isNotEmpty,
          'isCurrentGrade': grade == userGrade,
        });
      }

      if (mounted) {
        setState(() {
          _gradesData = gradesData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hardcoded entrance structure: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load entrance structure: $e';
        });
      }
    }
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  Widget _getSubjectIcon(String subject, {double size = 36}) {
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
            Icons.book,
            size: size,
            color: Colors.white,
          ),
        ),
      );
    }
    return Icon(Icons.book, size: size, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor(widget.subject);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subject),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subject),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final totalUnits = _gradesData.fold(0, (sum, g) => sum + (g['unitCount'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Header with subject icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_gradesData.length} grades • $totalUnits units',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Grade',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_gradesData.length} grades',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._gradesData.map((gradeData) {
              final grade = gradeData['grade'] as String;
              final unitCount = gradeData['unitCount'] as int;
              final isCurrentGrade = gradeData['isCurrentGrade'] as bool;
              final hasContent = gradeData['hasContent'] as bool;

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
                                ? (isCurrentGrade ? color.withOpacity(0.1) : Colors.grey[100])
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
                              if (hasContent)
                                Row(
                                  children: [
                                    Icon(Icons.quiz, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$unitCount unit${unitCount != 1 ? 's' : ''}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Icon(Icons.hourglass_empty, size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Coming soon',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (isCurrentGrade)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Your Grade',
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}