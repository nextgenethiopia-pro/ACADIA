import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class SemesterSelectionScreen extends StatefulWidget {
  const SemesterSelectionScreen({super.key});

  @override
  State<SemesterSelectionScreen> createState() => _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen> {
  String? _selectedSemester;
  bool _isNavigating = false;

  final List<SemesterOption> _semesters = [
    SemesterOption(
      value: '1',
      title: 'FIRST SEMESTER',
      subtitle: '6 subjects',
      description: 'Choose between Natural Science or Social Science stream',
      icon: Icons.looks_one,
      color: Colors.blue,
      subjects: ['English', 'Geography', 'Logic', 'Mathematics', 'Physics', 'Psychology'],
    ),
    SemesterOption(
      value: '2',
      title: 'SECOND SEMESTER',
      subtitle: '8 subjects',
      description: 'Choose between Pre-Engineering or Other Natural Science track',
      icon: Icons.looks_two,
      color: Colors.orange,
      subjects: [
        'Anthropology', 'Applied Mathematics', 'C++ Programming', 'Emerging Technologies',
        'English Skill 2', 'Entrepreneurship', 'History', 'Moral and Citizenship Education'
      ],
    ),
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedSemester == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('semester', _selectedSemester!);

    if (!mounted) return;

    if (_selectedSemester == '1') {
      context.pushReplacement('/university-stream-selection');
    } else {
      context.pushReplacement('/university-track-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select Semester'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select your freshman semester to see available subjects',
                        style: TextStyle(color: AppColors.primary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Semester cards
              ..._semesters.map((semester) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSemesterCard(semester),
              )),
              
              const Spacer(),

              // Info text based on selection
              if (_selectedSemester != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (_selectedSemester == '1' ? Colors.blue : Colors.orange).withOpacity(0.1),
                        (_selectedSemester == '1' ? Colors.blue : Colors.orange).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_selectedSemester == '1' ? Colors.blue : Colors.orange).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _selectedSemester == '1' ? Colors.blue : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedSemester == '1'
                              ? 'First Semester: You will choose between Natural Science and Social Science streams'
                              : 'Second Semester: You will choose between Pre-Engineering and Other Natural Science tracks',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedSemester == '1' ? Colors.blue[700] : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Continue Button
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedSemester != null && !_isNavigating ? _saveAndContinue : () {},
                isDisabled: _selectedSemester == null || _isNavigating,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterCard(SemesterOption semester) {
    final isSelected = _selectedSemester == semester.value;
    final color = semester.color;

    return GestureDetector(
      onTap: () => setState(() => _selectedSemester = semester.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(semester.icon, color: isSelected ? color : Colors.grey[600], size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semester.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    semester.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    semester.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  // Subject count preview
                  Wrap(
                    spacing: 4,
                    children: semester.subjects.take(3).map((subject) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subject,
                          style: TextStyle(fontSize: 9, color: isSelected ? color : Colors.grey[500]),
                        ),
                      );
                    }).toList(),
                  ),
                  if (semester.subjects.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+${semester.subjects.length - 3} more',
                        style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                      ),
                    ),
                ],
              ),
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
      ),
    );
  }
}

class SemesterOption {
  final String value;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> subjects;

  SemesterOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.subjects,
  });
}