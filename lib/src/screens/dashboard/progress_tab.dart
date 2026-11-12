import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final IsarService _isarService = IsarService.instance;
  String? _userGrade;
  String? _userStream;
  String? _userPath;
  List<String> _subjects = [];
  final Map<String, double> _subjectProgress = {};
  bool _isLoading = true;

  // Stats
  double _totalStudyHours = 0;
  int _lessonsCompleted = 0;
  int _totalLessons = 0;
  int _quizzesPassed = 0;
  int _totalQuizzes = 0;
  double _averageScore = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<String, int> _weeklyActivity = {};
  List<Map<String, dynamic>> _achievements = [];

  // ============================================
  // SUBJECT DATA
  // ============================================
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
    'IT': Color(0xFF3F51B5),
    'Agriculture': Color(0xFF8BC34A),
    'Citizenship': Color(0xFF00BCD4),
    'Logic': Color(0xFF1A237E),
    'Psychology': Color(0xFFCE93D8),
    'Anthropology': Color(0xFFFFD54F),
    'Applied Mathematics': Color(0xFF7E57C2),
    'C++ Programming': Color(0xFF424242),
    'Emerging Technologies': Color(0xFFB0BEC5),
    'English Skill 2': Color(0xFF2196F3),
    'English Skill II': Color(0xFF2196F3),
    'Entrepreneurship': Color(0xFFFFD700),
    'Moral and Citizenship Education': Color(0xFF808000),
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
    'IT': 'assets/icons/subjects_icon/It_icon.jpg',
    'Agriculture': 'assets/icons/subjects_icon/Agriculture_icon.jpg',
    'Citizenship': 'assets/icons/subjects_icon/Citizenship_icon.jpg',
    'Logic': 'assets/icons/subjects_icon/Logic_icon.jpg',
    'Psychology': 'assets/icons/subjects_icon/Psychology_icon.jpg',
    'Anthropology': 'assets/icons/subjects_icon/Anthropology_icon.jpg',
    'Applied Mathematics': 'assets/icons/subjects_icon/Applied_math_icon.jpg',
    'C++ Programming': 'assets/icons/subjects_icon/C++_icon.jpg',
    'Emerging Technologies': 'assets/icons/subjects_icon/Emerging_icon.jpg',
    'English Skill 2': 'assets/icons/subjects_icon/English_icon.jpg',
    'English Skill II': 'assets/icons/subjects_icon/English_icon.jpg',
    'Entrepreneurship': 'assets/icons/subjects_icon/Economics_icon.jpg',
    'Moral and Citizenship Education': 'assets/icons/subjects_icon/Civic_icon.jpg',
  };

  static const Map<String, List<String>> _subjectsByPath = {
    'grade_9': ['Biology', 'Chemistry', 'Citizenship', 'Economics', 'English', 'Geography', 'History', 'IT', 'Mathematics', 'Physics'],
    'grade_10': ['Biology', 'Chemistry', 'Citizenship', 'Economics', 'English', 'Geography', 'History', 'IT', 'Mathematics', 'Physics'],
    'grade_11_natural': ['Agriculture', 'Aptitude', 'Biology', 'Chemistry', 'English', 'IT', 'Mathematics', 'Physics'],
    'grade_11_social': ['Aptitude', 'Citizenship', 'Economics', 'English', 'Geography', 'History', 'IT', 'Mathematics'],
    'grade_12_natural': ['Agriculture', 'Aptitude', 'Biology', 'Chemistry', 'English', 'IT', 'Mathematics', 'Physics'],
    'grade_12_social': ['Aptitude', 'Citizenship', 'Economics', 'English', 'Geography', 'History', 'IT', 'Mathematics'],
    'freshman_sem1_natural': ['English', 'Geography', 'Logic', 'Mathematics', 'Physics', 'Psychology'],
    'freshman_sem1_social': ['Economics', 'English', 'Geography', 'Logic', 'Mathematics', 'Psychology'],
    'freshman_sem2_pre_eng': ['Anthropology', 'Applied Mathematics', 'C++ Programming', 'Emerging Technologies', 'English Skill 2', 'Entrepreneurship', 'History', 'Moral and Citizenship Education'],
    'freshman_sem2_other': ['Anthropology', 'Biology', 'Chemistry', 'Economics', 'Emerging Technologies', 'English Skill II', 'History', 'Moral and Citizenship Education'],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================
  // LOAD DATA
  // ============================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userPath = prefs.getString('academic_path');
      _userGrade = prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream');
      final semester = prefs.getString('semester') ?? '1';
      final track = prefs.getString('selected_track');

      _subjects = _getSubjectsForPath(_userGrade, _userStream, semester, track);

      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'local_user';
      await _isarService.initializeUserProgress(userId);

      await _loadLocalProgress();
      await _loadWeeklyActivity();
      await _loadAchievements();
      await _loadSubjectProgress();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading progress: $e');
    }
  }

  // ============================================
  // LOAD LOCAL PROGRESS
  // ============================================
  Future<void> _loadLocalProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'local_user';

      final userProgress = await _isarService.getUserProgress(userId);

      if (userProgress.isNotEmpty) {
        _totalStudyHours =
            (userProgress['total_study_time'] as num? ?? 0) / 3600.0;
        _lessonsCompleted = userProgress['lessons_completed'] as int? ?? 0;
        _quizzesPassed = userProgress['quizzes_passed'] as int? ?? 0;
        _averageScore =
            (userProgress['average_score'] as num?)?.toDouble() ?? 0.0;
        _currentStreak = userProgress['current_streak'] as int? ?? 1;
        _longestStreak = userProgress['longest_streak'] as int? ?? 1;
      }

      final downloadedContents =
          await _isarService.getAllDownloadedContent(userId);
      final downloadedQuizCount = downloadedContents
          .where((c) => c.contentType == 'quiz' || c.contentType == 'exam')
          .length;
      _totalQuizzes = downloadedQuizCount > _quizzesPassed
          ? downloadedQuizCount
          : (_quizzesPassed > 0 ? _quizzesPassed : 10);

      // Compute total curriculum lessons from AcademicStructure
      int totalChapters = 0;
      final gradeNum =
          RegExp(r'(\d+)').firstMatch(_userGrade ?? '')?.group(1) ?? '9';
      for (final s in _subjects) {
        totalChapters +=
            AcademicStructure.getChapters(gradeNum, _userStream ?? 'natural', s)
                .length;
      }
      _totalLessons = totalChapters > 0 ? totalChapters : 24;
    } catch (e) {
      debugPrint('Error loading local progress: $e');
    }
  }

  Future<void> _loadWeeklyActivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'local_user';

      final weeklyActivityList = await _isarService.getWeeklyActivity(userId);
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weeklyActivity = <String, int>{for (var d in days) d: 0};

      for (final activity in weeklyActivityList) {
        final dayOfWeek = activity['day_of_week'] as int? ?? 1;
        final dayIndex = (dayOfWeek - 1).clamp(0, 6);
        final dayName = days[dayIndex];
        final hours = (activity['hours_studied'] as num?)?.toDouble() ?? 0.0;
        weeklyActivity[dayName] =
            hours >= 1 ? hours.round() : (hours > 0 ? 1 : 0);
      }
      _weeklyActivity = weeklyActivity;
    } catch (e) {
      debugPrint('Error loading weekly activity: $e');
      _weeklyActivity = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0
      };
    }
  }

  Future<void> _loadSubjectProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'local_user';

      final subjectProgressList =
          await _isarService.getSubjectProgress(userId);
      for (final sp in subjectProgressList) {
        final subject = (sp['subject'] as String? ?? '').trim();
        final rawPct =
            (sp['completion_percentage'] as num?)?.toDouble() ?? 0.0;
        // Normalize 0..100 percentage to 0.0..1.0
        final normalizedPct =
            (rawPct > 1.0 ? rawPct / 100.0 : rawPct).clamp(0.0, 1.0);
        if (subject.isNotEmpty) {
          _subjectProgress[subject] = normalizedPct;
          _subjectProgress[subject.toLowerCase()] = normalizedPct;
        }
      }
    } catch (e) {
      debugPrint('Error loading subject progress: $e');
    }
  }

  Future<void> _loadAchievements() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'local_user';

      final achievements = await _isarService.getAchievements(userId);
      _achievements = achievements.map((a) {
        return {
          'title': a['badge_name'] as String? ?? 'Achievement',
          'unlocked': a['is_unlocked'] as bool? ?? false,
          'icon': Icons.emoji_events,
          'color': Colors.amber,
          'description': 'Completed achievement',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      _achievements = [];
    }
  }

  // ============================================
  // HELPERS
  // ============================================
  List<String> _getSubjectsForPath(
      String? grade, String? stream, String? semester, String? track) {
    final normalizedPath = (_userPath ?? '').toUpperCase();
    final normalizedStream = (stream ?? '').toLowerCase();
    final streamKey =
        normalizedStream.contains('social') ? 'social' : 'natural';

    if (normalizedPath == 'UNIVERSITY' ||
        normalizedPath.contains('UNIVERSITY') ||
        (grade == null && semester != null) ||
        (grade?.toLowerCase().startsWith('university') ?? false)) {
      if (semester == '2') {
        return AcademicStructure.getUniversitySubjects('2', streamKey, track);
      } else {
        return AcademicStructure.getUniversitySubjects('1', streamKey);
      }
    }

    final gradeNum =
        RegExp(r'(\d+)').firstMatch(grade ?? '')?.group(1) ?? '9';
    return AcademicStructure.getSubjects(gradeNum, streamKey);
  }

  Widget _getSubjectIcon(String subject, {double size = 20}) {
    final assetPath = _subjectIconAssets[subject];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.book, size: size)),
      );
    }
    return Icon(Icons.book, size: size);
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  double get _overallProgress {
    if (_subjects.isEmpty) return 0.0;
    double total = 0.0;
    for (final subject in _subjects) {
      final p = _subjectProgress[subject] ??
          _subjectProgress[subject.toLowerCase()] ??
          0.0;
      total += p;
    }
    return (total / _subjects.length).clamp(0.0, 1.0);
  }

  double _getMaxWeeklyActivity() {
    double max = 0;
    for (final value in _weeklyActivity.values) {
      if (value > max) max = value.toDouble();
    }
    return max > 0 ? max : 1;
  }

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with streak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text('$_currentStreak days', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Cards Row
            Row(
              children: [
                _buildStatCard('Study Time', '${_totalStudyHours.toStringAsFixed(0)}h', Icons.timer, Colors.blue),
                const SizedBox(width: 8),
                _buildStatCard('Completed', '$_lessonsCompleted/$_totalLessons', Icons.check_circle, Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('Quizzes', '$_quizzesPassed/$_totalQuizzes', Icons.quiz, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('Avg. Score', '${_averageScore.toStringAsFixed(0)}%', Icons.analytics, Colors.purple),
                const SizedBox(width: 8),
                _buildStatCard('Longest Streak', '$_longestStreak days', Icons.emoji_events, Colors.amber),
                const SizedBox(width: 8),
                _buildStatCard('Overall', '${(_overallProgress * 100).toInt()}%', Icons.trending_up, AppColors.primary),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly Activity Chart
            const Text('Weekly Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Study hours per day', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8)],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxWeeklyActivity(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10));
                      }),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10)),
                        );
                      }),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                  barGroups: List.generate(7, (index) {
                    final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
                    final value = _weeklyActivity[day]?.toDouble() ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: AppColors.primary,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subject Progress
            const Text('Subject Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ..._subjects.map((subject) {
              final progress = _subjectProgress[subject] ?? 0.0;
              final color = _getSubjectColor(subject);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getSubjectIcon(subject, size: 20),
                        const SizedBox(width: 8),
                        Text(subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        Text('${(progress * 100).toInt()}%',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Achievements
            const Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final achievement = _achievements[index];
                final unlocked = achievement['unlocked'] == true;
                final color = achievement['color'] as Color? ?? Colors.amber;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: unlocked ? color.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: unlocked ? color.withOpacity(0.3) : Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(achievement['icon'] as IconData? ?? Icons.emoji_events,
                          color: unlocked ? color : Colors.grey[400], size: 28),
                      const Spacer(),
                      Text(achievement['title'] as String? ?? 'Achievement',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                              color: unlocked ? Colors.black87 : Colors.grey[500])),
                      const SizedBox(height: 2),
                      Text(achievement['description'] as String? ?? '',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      if (!unlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}