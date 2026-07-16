import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/offline_database.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _userName;
  String? _userGrade;
  String? _userStream;
  String? _userPath;
  List<String> _subjects = [];
  bool _isLoading = true;
  int _streakDays = 0;
  int _totalStudyHours = 0;
  int _lessonsCompleted = 0;
  int _quizzesPassed = 0;
  Map<String, dynamic>? _dailyQuote;
  List<Map<String, dynamic>> _examTips = [];

  // Hardcoded subjects by path
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

  // Custom subject icon assets
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

  // Subject colors (from blueprint)
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

      final user = FirebaseAuth.instance.currentUser;
      _userName = user?.displayName?.split(' ')[0] ?? 
                  prefs.getString('user_name')?.split(' ')[0] ?? 
                  'Student';

      _subjects = _getSubjectsForPath(_userGrade, _userStream, semester, track);
      
      // Load user progress data
      await _loadUserProgress(prefs);
      
      // Load daily quote from Firebase (admin managed)
      await _loadDailyQuote();
      
      // Load exam tips from Firebase (admin managed)
      await _loadExamTips();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading home: $e');
    }
  }

  Future<void> _loadUserProgress(SharedPreferences prefs) async {
    try {
      final firebase = FirebaseService();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        final userData = await firebase.getDocument('users', user.uid);
        if (userData != null) {
          _streakDays = userData['current_streak'] ?? prefs.getInt('streak_days') ?? 0;
          _totalStudyHours = userData['total_study_hours'] ?? 0;
          _lessonsCompleted = userData['lessons_completed'] ?? 0;
          _quizzesPassed = userData['quizzes_passed'] ?? 0;
        } else {
          _streakDays = prefs.getInt('streak_days') ?? 0;
          _totalStudyHours = prefs.getInt('total_study_hours') ?? 0;
          _lessonsCompleted = prefs.getInt('lessons_completed') ?? 0;
          _quizzesPassed = prefs.getInt('quizzes_passed') ?? 0;
        }
      } else {
        _streakDays = prefs.getInt('streak_days') ?? 0;
        _totalStudyHours = prefs.getInt('total_study_hours') ?? 0;
        _lessonsCompleted = prefs.getInt('lessons_completed') ?? 0;
        _quizzesPassed = prefs.getInt('quizzes_passed') ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      _streakDays = prefs.getInt('streak_days') ?? 0;
    }
  }

  Future<void> _loadDailyQuote() async {
    try {
      final firebase = FirebaseService();
      final settings = await firebase.getAppSettings();
      
      if (settings != null && settings['daily_quote'] != null) {
        final quote = settings['daily_quote'];
        _dailyQuote = {
          'text': quote['text']?.toString() ?? 'Education is the most powerful weapon which you can use to change the world.',
          'author': quote['author']?.toString() ?? 'Nelson Mandela',
        };
      } else {
        // Default quote
        _dailyQuote = {
          'text': 'Education is the most powerful weapon which you can use to change the world.',
          'author': 'Nelson Mandela',
        };
      }
    } catch (e) {
      debugPrint('Error loading daily quote: $e');
      _dailyQuote = {
        'text': 'Education is the most powerful weapon which you can use to change the world.',
        'author': 'Nelson Mandela',
      };
    }
  }

  Future<void> _loadExamTips() async {
    try {
      final firebase = FirebaseService();
      final tips = await firebase.getDocuments('exam_tips');
      _examTips = tips;
    } catch (e) {
      debugPrint('Error loading exam tips: $e');
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

  Widget _getSubjectIconWidget(String subject, {double size = 26}) {
    final assetPath = _subjectIconAssets[subject];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(_getSubjectFallbackIcon(subject), color: _getSubjectColor(subject), size: size);
          },
        ),
      );
    }
    return Icon(_getSubjectFallbackIcon(subject), color: _getSubjectColor(subject), size: size);
  }

  IconData _getSubjectFallbackIcon(String subject) {
    switch (subject) {
      case 'Mathematics': return Icons.functions;
      case 'English': return Icons.menu_book;
      case 'Physics': return Icons.science;
      case 'Chemistry': return Icons.biotech;
      case 'Biology': return Icons.eco;
      case 'Aptitude': return Icons.psychology;
      case 'Geography': return Icons.public;
      case 'History': return Icons.history_edu;
      case 'Economics': return Icons.trending_up;
      case 'IT': return Icons.computer;
      case 'Agriculture': return Icons.agriculture;
      case 'Citizenship': return Icons.account_balance;
      case 'Logic': return Icons.lightbulb;
      case 'Psychology': return Icons.psychology_alt;
      case 'Anthropology': return Icons.groups;
      case 'Applied Mathematics': return Icons.calculate;
      case 'C++ Programming': return Icons.code;
      case 'Emerging Technologies': return Icons.devices;
      case 'English Skill 2': return Icons.spellcheck;
      case 'English Skill II': return Icons.spellcheck;
      case 'Entrepreneurship': return Icons.business_center;
      case 'Moral and Citizenship Education': return Icons.gavel;
      default: return Icons.book;
    }
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  void _navigateToStudy() {
    // Navigate to continue studying
    context.push('/subjects');
  }

  void _navigateToEntrance() {
    // Navigate to entrance tab
    // This would require accessing parent state or using a global key
    // For now, we'll navigate to entrance directly
    context.push('/entrance');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displaySubjects = _subjects.take(6).toList();
    final greeting = _getGreeting();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Date with Streak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting, $_userName!',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_getCurrentDate(), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text('$_streakDays days',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Stats Row
            Row(
              children: [
                _buildStatCard(Icons.timer, '$_totalStudyHours', 'Hours Studied', Colors.blue),
                const SizedBox(width: 8),
                _buildStatCard(Icons.check_circle, '$_lessonsCompleted', 'Lessons Done', Colors.green),
                const SizedBox(width: 8),
                _buildStatCard(Icons.quiz, '$_quizzesPassed', 'Quizzes Passed', Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                _buildQuickAction(Icons.play_circle, 'Continue', _navigateToStudy),
                const SizedBox(width: 8),
                _buildQuickAction(Icons.timer, 'Study Time', () {}),
                const SizedBox(width: 8),
                _buildQuickAction(Icons.assignment, 'Entrance', _navigateToEntrance),
                const SizedBox(width: 8),
                _buildQuickAction(Icons.download, 'Downloads', () => context.push('/settings/downloads')),
              ],
            ),
            const SizedBox(height: 24),

            // Your Subjects
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: () => _showAllSubjects(context),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subjects Grid (2x3)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: displaySubjects.length,
              itemBuilder: (context, index) {
                final subject = displaySubjects[index];
                final color = _getSubjectColor(subject);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => context.push('/subject-portal', extra: {'subject': subject}),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.15), color.withOpacity(0.03)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _getSubjectIconWidget(subject, size: 28),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('Tap to explore',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Daily Quote (from admin)
            if (_dailyQuote != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.08), AppColors.secondary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote, color: AppColors.primary, size: 28),
                    const SizedBox(height: 8),
                    Text(_dailyQuote!['text'] ?? '',
                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.4)),
                    const SizedBox(height: 8),
                    Text('- ${_dailyQuote!['author'] ?? 'Unknown'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Quick Tip
            if (_examTips.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick Tip',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(_examTips.first['tip']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllSubjects(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('All Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  ],
                ),
                Text('${_subjects.length} subjects', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final color = _getSubjectColor(subject);

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/subject-portal', extra: {'subject': subject});
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.15), color.withOpacity(0.03)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _getSubjectIconWidget(subject, size: 28),
                                Text(subject,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}