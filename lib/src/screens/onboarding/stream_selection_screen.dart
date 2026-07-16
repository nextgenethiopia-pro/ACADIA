import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class StreamSelectionScreen extends StatefulWidget {
  const StreamSelectionScreen({super.key});

  @override
  State<StreamSelectionScreen> createState() => _StreamSelectionScreenState();
}

class _StreamSelectionScreenState extends State<StreamSelectionScreen> {
  String? _selectedStream;
  int? _grade;
  bool _isNavigating = false;

  // Subject colors from ACADIA spec
  static const Map<String, Color> _subjectColors = {
    'Mathematics': Color(0xFF9C27B0),
    'Physics': Color(0xFFFF9800),
    'Chemistry': Color(0xFF4CAF50),
    'Biology': Color(0xFFE91E63),
    'English': Color(0xFF2196F3),
    'IT': Color(0xFF3F51B5),
    'Agriculture': Color(0xFF8BC34A),
    'Aptitude': Color(0xFF708090),
    'Economics': Color(0xFFFF5722),
    'Geography': Color(0xFF009688),
    'History': Color(0xFF795548),
    'Citizenship': Color(0xFF00BCD4),
  };

  // Stream subjects from ACADIA spec
  static const Map<int, Map<String, List<String>>> _streamSubjects = {
    11: {
      'natural': ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'IT', 'English', 'Agriculture', 'Aptitude'],
      'social': ['Economics', 'Geography', 'History', 'Citizenship', 'IT', 'English', 'Mathematics', 'Aptitude'],
    },
    12: {
      'natural': ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'IT', 'English', 'Agriculture', 'Aptitude'],
      'social': ['Economics', 'Geography', 'History', 'Citizenship', 'IT', 'English', 'Mathematics', 'Aptitude'],
    },
  };

  final List<StreamOption> _streams = [
    StreamOption(
      value: 'natural',
      title: 'NATURAL SCIENCE',
      description: 'Focus on science and technology fields',
      icon: Icons.science,
      color: Colors.green,
    ),
    StreamOption(
      value: 'social',
      title: 'SOCIAL SCIENCE',
      description: 'Focus on humanities and social studies',
      icon: Icons.menu_book,
      color: Colors.blue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadGrade();
  }

  Future<void> _loadGrade() async {
    final prefs = await SharedPreferences.getInstance();
    final gradeString = prefs.getString('grade') ?? prefs.getString('selected_grade') ?? '11';
    setState(() {
      _grade = int.tryParse(gradeString);
    });
  }

  List<String> _getSubjects(String stream) {
    return _streamSubjects[_grade ?? 11]?[stream] ?? [];
  }

  Future<void> _saveStreamAndContinue() async {
    if (_selectedStream == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stream', _selectedStream!);
    await prefs.setString('selected_stream', _selectedStream!);
    await prefs.setBool('how_to_seen', false); // Show How-To popup on first dashboard load
    
    // Mark onboarding as complete
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select Your Stream'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grade indicator with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Grade $_grade',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_streamSubjects[_grade ?? 11]?['natural']?.length ?? 8} subjects per stream',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stream cards
              ..._streams.map((stream) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildStreamCard(stream),
              )),
              
              const Spacer(),

              // Permanent warning
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This choice is permanent and cannot be changed after registration.',
                        style: TextStyle(color: Colors.amber[800], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // Continue Button
              GradientButton(
                text: 'CONTINUE TO DASHBOARD',
                onPressed: _selectedStream != null && !_isNavigating ? _saveStreamAndContinue : () {},
                isDisabled: _selectedStream == null || _isNavigating,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamCard(StreamOption stream) {
    final isSelected = _selectedStream == stream.value;
    final color = stream.color;
    final subjects = _getSubjects(stream.value);

    return GestureDetector(
      onTap: () => setState(() => _selectedStream = stream.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(stream.icon, color: color, size: 28),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              stream.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stream.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            // Subjects divider
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 12),

            // Subjects grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects.map((subject) {
                final subjectColor = _subjectColors[subject] ?? color;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: subjectColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: subjectColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subject,
                        style: TextStyle(fontSize: 11, color: subjectColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class StreamOption {
  final String value;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  StreamOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}