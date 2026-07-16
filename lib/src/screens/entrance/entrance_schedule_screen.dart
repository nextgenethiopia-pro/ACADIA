import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/firebase_service.dart';

class EntranceScheduleScreen extends StatefulWidget {
  const EntranceScheduleScreen({super.key});

  @override
  State<EntranceScheduleScreen> createState() => _EntranceScheduleScreenState();
}

class _EntranceScheduleScreenState extends State<EntranceScheduleScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  // Admin configurable content
  List<Map<String, dynamic>> _studySchedule = [];
  List<Map<String, dynamic>> _weeklyFocus = [];
  List<String> _studyTips = [];
  String? _headerTitle;
  String? _headerSubtitle;

  @override
  void initState() {
    super.initState();
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    if (mounted) {
      setState(() {
        if (!_isLoading) _isRefreshing = true;
      });
    }

    try {
      final firebase = FirebaseService();
      
      // Load study schedule from Firebase
      final schedule = await firebase.getDocuments('study_schedule', where: {
        'status': 'active',
      });
      
      // Load weekly focus from Firebase
      final weeklyFocus = await firebase.getDocuments('weekly_focus', where: {
        'status': 'active',
      });
      
      // Load study tips from Firebase
      final tips = await firebase.getDocuments('study_tips', where: {
        'status': 'active',
      });
      
      // Load header settings
      final settings = await firebase.getAppSettings();
      final entranceSettings = settings?['entrance_schedule'] ?? {};

      if (mounted) {
        setState(() {
          _studySchedule = schedule;
          _weeklyFocus = weeklyFocus;
          _studyTips = tips.map((t) => t['tip']?.toString() ?? '').toList();
          _headerTitle = entranceSettings['title']?.toString() ?? 'Study Schedule';
          _headerSubtitle = entranceSettings['subtitle']?.toString() ?? 'Plan your entrance exam preparation';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      
      // If no data from Firebase, use default content
      if (_studySchedule.isEmpty) {
        _loadDefaultSchedule();
      }
      if (_weeklyFocus.isEmpty) {
        _loadDefaultWeeklyFocus();
      }
      if (_studyTips.isEmpty) {
        _loadDefaultTips();
      }
      
    } catch (e) {
      debugPrint('Error loading schedule data: $e');
      // Load default content on error
      _loadDefaultSchedule();
      _loadDefaultWeeklyFocus();
      _loadDefaultTips();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _loadDefaultSchedule() {
    _studySchedule = [
      {
        'title': 'Morning Session',
        'time': '9:00 AM - 12:00 PM',
        'description': 'Focus on difficult subjects like Mathematics and Physics',
        'color': 'blue',
      },
      {
        'title': 'Afternoon Session',
        'time': '2:00 PM - 5:00 PM',
        'description': 'Review and practice with past papers',
        'color': 'orange',
      },
      {
        'title': 'Evening Session',
        'time': '7:00 PM - 9:00 PM',
        'description': 'Light review and flashcards for memorization',
        'color': 'purple',
      },
    ];
  }

  void _loadDefaultWeeklyFocus() {
    _weeklyFocus = [
      {'day': 'Monday', 'subject': 'Mathematics', 'color': 'purple'},
      {'day': 'Tuesday', 'subject': 'Physics', 'color': 'blue'},
      {'day': 'Wednesday', 'subject': 'English', 'color': 'indigo'},
      {'day': 'Thursday', 'subject': 'Biology', 'color': 'green'},
      {'day': 'Friday', 'subject': 'Chemistry', 'color': 'orange'},
      {'day': 'Saturday', 'subject': 'Past Papers', 'color': 'red'},
      {'day': 'Sunday', 'subject': 'Review', 'color': 'teal'},
    ];
  }

  void _loadDefaultTips() {
    _studyTips = [
      'Create a consistent study routine',
      'Take regular breaks (Pomodoro technique)',
      'Practice with timed tests',
      'Review mistakes to learn from them',
      'Stay healthy with proper sleep and nutrition',
    ];
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'teal': return Colors.teal;
      case 'indigo': return Colors.indigo;
      case 'pink': return Colors.pink;
      case 'amber': return Colors.amber;
      case 'brown': return Colors.brown;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Schedule'),
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Schedule'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadScheduleData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (admin configurable)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    Text(_headerTitle ?? 'Study Schedule',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                    Text(_headerSubtitle ?? 'Plan your entrance exam preparation',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Study Plan Section
              const Text('Recommended Study Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ..._studySchedule.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildScheduleCard(
                  session['title']?.toString() ?? '',
                  session['time']?.toString() ?? '',
                  session['description']?.toString() ?? '',
                  _getColorFromString(session['color']?.toString() ?? 'blue'),
                ),
              )),
              const SizedBox(height: 24),

              // Weekly Focus Section
              const Text('Weekly Focus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _buildWeeklyPlan(),
              const SizedBox(height: 24),

              // Study Tips Section
              const Text('Study Tips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _studyTips.map((tip) => _buildTipItem(tip)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPlan() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _weeklyFocus.map((item) {
            final day = item['day']?.toString() ?? '';
            final subject = item['subject']?.toString() ?? '';
            final color = _getColorFromString(item['color']?.toString() ?? 'blue');
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(subject, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(String title, String time, String description, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.access_time, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(time, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}