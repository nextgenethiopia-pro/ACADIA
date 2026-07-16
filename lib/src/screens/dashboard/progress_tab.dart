import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
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
  Map<String, int> _weeklyActivity = {}; // Mon-Sun activity in hours
  List<Map<String, dynamic>> _achievements = [];

  // Subject colors and icons
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
      
      // Load real progress from local database
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

  Future<void> _loadLocalProgress() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load user progress from local table
      final progressResult = await db.query(
        'user_progress',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (progressResult.isNotEmpty) {
        final progress = progressResult.first;
        _totalStudyHours = (progress['total_study_hours'] as num?)?.toDouble() ?? 0;
        _lessonsCompleted = (progress['lessons_completed'] as num?)?.toInt() ?? 0;
        _quizzesPassed = (progress['quizzes_passed'] as num?)?.toInt() ?? 0;
        _averageScore = (progress['average_score'] as num?)?.toDouble() ?? 0;
        _currentStreak = (progress['current_streak'] as num?)?.toInt() ?? 0;
        _longestStreak = (progress['longest_streak'] as num?)?.toInt() ?? 0;
      } else {
        // Create default progress record
        await db.insert('user_progress', {
          'user_id': userId,
          'total_study_hours': 0,
          'lessons_completed': 0,
          'quizzes_passed': 0,
          'average_score': 0,
          'current_streak': 0,
          'longest_streak': 0,
          'last_active_date': DateTime.now().toIso8601String(),
        });
      }

      // Get total lessons from content table
      final contentCount = await db.query('offline_content');
      _totalLessons = contentCount.length;
      
      // Get total quizzes from content table
      final quizzesResult = await db.query(
        'offline_content',
        where: 'content_type IN (?, ?)',
        whereArgs: ['quiz', 'exam'],
      );
      _totalQuizzes = quizzesResult.length;

      // Also try to sync with Firebase if online
      _syncWithFirebase(userId);
      
    } catch (e) {
      debugPrint('Error loading local progress: $e');
    }
  }

  Future<void> _syncWithFirebase(String userId) async {
    try {
      final firebase = FirebaseService();
      final userData = await firebase.getDocument('users', userId);
      
      if (userData != null) {
        final offlineDb = OfflineDatabase.instance;
        final db = await offlineDb.database;
        
        await db.update(
          'user_progress',
          {
            'total_study_hours': userData['total_study_hours'] ?? _totalStudyHours,
            'lessons_completed': userData['lessons_completed'] ?? _lessonsCompleted,
            'quizzes_passed': userData['quizzes_passed'] ?? _quizzesPassed,
            'average_score': userData['average_score'] ?? _averageScore,
            'current_streak': userData['current_streak'] ?? _currentStreak,
            'longest_streak': userData['longest_streak'] ?? _longestStreak,
          },
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        
        // Reload updated data
        final updated = await db.query(
          'user_progress',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        
        if (updated.isNotEmpty) {
          setState(() {
            _totalStudyHours = (updated.first['total_study_hours'] as num?)?.toDouble() ?? 0;
            _lessonsCompleted = (updated.first['lessons_completed'] as num?)?.toInt() ?? 0;
            _quizzesPassed = (updated.first['quizzes_passed'] as num?)?.toInt() ?? 0;
            _averageScore = (updated.first['average_score'] as num?)?.toDouble() ?? 0;
            _currentStreak = (updated.first['current_streak'] as num?)?.toInt() ?? 0;
            _longestStreak = (updated.first['longest_streak'] as num?)?.toInt() ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
    }
  }

  Future<void> _loadWeeklyActivity() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get activity logs for the last 7 days
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final activityResult = await db.query(
          'study_activity',
          where: 'user_id = ? AND activity_date >= ? AND activity_date < ?',
          whereArgs: [userId, dayStart.toIso8601String(), dayEnd.toIso8601String()],
        );
        
        double totalHours = 0;
        for (final activity in activityResult) {
          totalHours += (activity['study_minutes'] as num?)?.toInt() ?? 0;
        }
        
        _weeklyActivity[weekDays[i]] = (totalHours / 60).ceil();
      }
    } catch (e) {
      debugPrint('Error loading weekly activity: $e');
      // Default empty activity
      _weeklyActivity = {'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0};
    }
  }

  Future<void> _loadSubjectProgress() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      for (final subject in _subjects) {
        // Get total content for this subject
        final totalContent = await db.query(
          'offline_content',
          where: 'subject = ?',
          whereArgs: [subject],
        );
        
        // Get completed content for this subject
        final completedContent = await db.query(
          'offline_content',
          where: 'subject = ? AND is_completed = 1',
          whereArgs: [subject],
        );
        
        final total = totalContent.length;
        final completed = completedContent.length;
        final progress = total > 0 ? completed / total : 0.0;
        
        _subjectProgress[subject] = progress;
      }
    } catch (e) {
      debugPrint('Error loading subject progress: $e');
    }
  }

  Future<void> _loadAchievements() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load achievements from local database
      final achievementsResult = await db.query(
        'user_achievements',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      final unlockedSet = <String>{};
      for (final achievement in achievementsResult) {
        if (achievement['unlocked'] == 1) {
          unlockedSet.add(achievement['achievement_name'].toString());
        }
      }
      
      // Define achievements based on ACADIA spec
      _achievements = [
        {'title': 'First Steps', 'description': 'Complete first content item', 'icon': Icons.school, 'color': Colors.blue, 'unlocked': _lessonsCompleted > 0},
        {'title': 'Perfect Week', 'description': '7-day study streak', 'icon': Icons.local_fire_department, 'color': Colors.orange, 'unlocked': _currentStreak >= 7},
        {'title': 'Quiz Master', 'description': 'Pass 10 quizzes', 'icon': Icons.quiz, 'color': Colors.green, 'unlocked': _quizzesPassed >= 10},
        {'title': 'Dedicated', 'description': '50 hours of study', 'icon': Icons.timer, 'color': Colors.purple, 'unlocked': _totalStudyHours >= 50},
      ];
      
      // Save unlocked achievements to local DB if not already
      for (final achievement in _achievements) {
        if (achievement['unlocked'] == true && !unlockedSet.contains(achievement['title'])) {
          await db.insert('user_achievements', {
            'user_id': userId,
            'achievement_name': achievement['title'],
            'unlocked': 1,
            'unlocked_at': DateTime.now().toIso8601String(),
          });
        }
      }
      
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      // Fallback achievements
      _achievements = [
        {'title': 'First Steps', 'description': 'Complete first content item', 'icon': Icons.school, 'color': Colors.blue, 'unlocked': false},
        {'title': 'Perfect Week', 'description': '7-day study streak', 'icon': Icons.local_fire_department, 'color': Colors.orange, 'unlocked': false},
        {'title': 'Quiz Master', 'description': 'Pass 10 quizzes', 'icon': Icons.quiz, 'color': Colors.green, 'unlocked': false},
        {'title': 'Dedicated', 'description': '50 hours of study', 'icon': Icons.timer, 'color': Colors.purple, 'unlocked': false},
      ];
    }
  }

  List<String> _getSubjectsForPath(String? grade, String? stream, String? semester, String? track) {
    if (grade == null) return [];
    String key;
    if (grade == '9') {
      key = 'grade_9';
    } else if (grade == '10') {
      key = 'grade_10';
    } else if (grade == '11') {
      key = stream == 'social' ? 'grade_11_social' : 'grade_11_natural';
    } else if (grade == '12') {
      key = stream == 'social' ? 'grade_12_social' : 'grade_12_natural';
    } else if (_userPath == 'university' || _userPath == 'UNIVERSITY') {
      if (semester == '2') {
        key = track == 'pre_engineering' ? 'freshman_sem2_pre_eng' : 'freshman_sem2_other';
      } else {
        key = stream == 'social' ? 'freshman_sem1_social' : 'freshman_sem1_natural';
      }
    } else {
      return [];
    }
    return _subjectsByPath[key] ?? [];
  }

  Widget _getSubjectIcon(String subject, {double size = 20}) {
    final assetPath = _subjectIconAssets[subject];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(assetPath, width: size, height: size, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.book, size: size)),
      );
    }
    return Icon(Icons.book, size: size);
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  double get _overallProgress {
    if (_subjectProgress.isEmpty) return 0;
    double total = 0;
    for (final progress in _subjectProgress.values) {
      total += progress;
    }
    return total / _subjectProgress.length;
  }

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
                  maxY: _getMaxWeeklyActivity() + 1,
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
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
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
                final color = achievement['color'] as Color;

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
                      Icon(achievement['icon'] as IconData,
                          color: unlocked ? color : Colors.grey[400], size: 28),
                      const Spacer(),
                      Text(achievement['title'] as String,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                              color: unlocked ? Colors.black87 : Colors.grey[500])),
                      const SizedBox(height: 2),
                      Text(achievement['description'] as String,
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

  double _getMaxWeeklyActivity() {
    double max = 0;
    for (final value in _weeklyActivity.values) {
      if (value > max) max = value.toDouble();
    }
    return max;
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