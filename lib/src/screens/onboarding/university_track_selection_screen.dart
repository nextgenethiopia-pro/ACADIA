import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class UniversityTrackSelectionScreen extends StatefulWidget {
  const UniversityTrackSelectionScreen({super.key});

  @override
  State<UniversityTrackSelectionScreen> createState() => _UniversityTrackSelectionScreenState();
}

class _UniversityTrackSelectionScreenState extends State<UniversityTrackSelectionScreen> {
  String? _selectedTrack;
  bool _isNavigating = false;

  // Subject colors from ACADIA spec
  static const Map<String, Color> _subjectColors = {
    'Anthropology': Color(0xFFFFD54F),
    'Applied Mathematics': Color(0xFF7E57C2),
    'C++ Programming': Color(0xFF424242),
    'Emerging Technologies': Color(0xFFB0BEC5),
    'English Skill 2': Color(0xFF2196F3),
    'English Skill II': Color(0xFF2196F3),
    'Entrepreneurship': Color(0xFFFFD700),
    'History': Color(0xFF795548),
    'Moral and Citizenship Education': Color(0xFF808000),
    'Biology': Color(0xFFE91E63),
    'Chemistry': Color(0xFF4CAF50),
    'Economics': Color(0xFFFF5722),
  };

  // Hardcoded subjects for Freshman Second Semester (from ACADIA spec)
  static const Map<String, List<String>> _subjects = {
    'pre_engineering': [
      'Anthropology',
      'Applied Mathematics',
      'C++ Programming',
      'Emerging Technologies',
      'English Skill 2',
      'Entrepreneurship',
      'History',
      'Moral and Citizenship Education',
    ],
    'other_natural_science': [
      'Anthropology',
      'Biology',
      'Chemistry',
      'Economics',
      'Emerging Technologies',
      'English Skill II',
      'History',
      'Moral and Citizenship Education',
    ],
  };

  final List<TrackOption> _tracks = [
    TrackOption(
      value: 'pre_engineering',
      title: 'PRE-ENGINEERING',
      subtitle: '8 subjects',
      description: 'Focus on engineering, mathematics, and technical fields',
      icon: Icons.engineering,
      color: Colors.orange,
    ),
    TrackOption(
      value: 'other_natural_science',
      title: 'OTHER NATURAL SCIENCE',
      subtitle: '8 subjects',
      description: 'Focus on biology, chemistry, and life sciences',
      icon: Icons.biotech,
      color: Colors.teal,
    ),
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedTrack == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('track', _selectedTrack!);
    await prefs.setString('selected_track', _selectedTrack!);
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
        title: const Text('Select Your Track'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Semester info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.semester, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Freshman - Second Semester',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '8 subjects',
                      style: TextStyle(color: AppColors.primary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Track cards
              ..._tracks.map((track) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTrackCard(track),
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
                onPressed: _selectedTrack != null && !_isNavigating ? _saveAndContinue : () {},
                isDisabled: _selectedTrack == null || _isNavigating,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard(TrackOption track) {
    final isSelected = _selectedTrack == track.value;
    final color = track.color;
    final subjects = _subjects[track.value] ?? [];

    return GestureDetector(
      onTap: () => setState(() => _selectedTrack = track.value),
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
            // Icon and checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(track.icon, color: color, size: 28),
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

            // Title and description
            Text(
              track.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              track.description,
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

class TrackOption {
  final String value;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  TrackOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}