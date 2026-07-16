import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class GradeSelectionScreen extends StatefulWidget {
  const GradeSelectionScreen({super.key});

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen> {
  int? _selectedGrade;
  bool _isNavigating = false;

  final List<GradeOption> _grades = [
    GradeOption(grade: 9, color: Colors.blue, description: 'Foundation Level'),
    GradeOption(grade: 10, color: Colors.green, description: 'Secondary Level'),
    GradeOption(grade: 11, color: Colors.orange, description: 'College Prep'),
    GradeOption(grade: 12, color: Colors.purple, description: 'Exit Exam Prep'),
  ];

  Future<void> _saveGradeAndContinue() async {
    if (_selectedGrade == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_grade', _selectedGrade.toString());
    await prefs.setString('grade', _selectedGrade.toString());

    if (!mounted) return;

    if (_selectedGrade == 11 || _selectedGrade == 12) {
      context.pushReplacement('/stream-selection');
    } else {
      // For grades 9-10, skip stream selection
      // Set default stream as 'natural' for grade 9-10 (no stream choice)
      await prefs.setString('selected_stream', 'natural');
      await prefs.setString('stream', 'natural');
      
      // Mark that onboarding is complete
      await prefs.setBool('onboarding_complete', true);
      
      context.go('/dashboard');
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
        title: const Text('Select Your Grade'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Subtitle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose your current grade level',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Grade Grid (2x2)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _grades.length,
                  itemBuilder: (context, index) {
                    final gradeOption = _grades[index];
                    final grade = gradeOption.grade;
                    final color = gradeOption.color;
                    final isSelected = _selectedGrade == grade;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedGrade = grade),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.grey[50]!, Colors.grey[100]!],
                                ),
                          color: isSelected ? color.withOpacity(0.1) : null,
                          border: Border.all(
                            color: isSelected ? color : Colors.grey[200]!,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$grade',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color : Colors.grey[500],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    bottom: 0,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Grade $grade',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? color : Colors.grey[500],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              gradeOption.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? color.withOpacity(0.7) : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Info text based on selection
              if (_selectedGrade != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _selectedGrade == 11 || _selectedGrade == 12
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGrade == 11 || _selectedGrade == 12
                          ? Colors.orange.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedGrade == 11 || _selectedGrade == 12
                            ? Icons.track_changes
                            : Icons.info_outline,
                        color: _selectedGrade == 11 || _selectedGrade == 12
                            ? Colors.orange
                            : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedGrade == 11 || _selectedGrade == 12
                              ? 'You will need to select a stream (Natural Science or Social Science)'
                              : 'Grade $_selectedGrade includes all core subjects with no stream selection',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedGrade == 11 || _selectedGrade == 12
                                ? Colors.orange[700]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Continue Button
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedGrade != null && !_isNavigating ? _saveGradeAndContinue : () {},
                isDisabled: _selectedGrade == null || _isNavigating,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class GradeOption {
  final int grade;
  final Color color;
  final String description;

  GradeOption({
    required this.grade,
    required this.color,
    required this.description,
  });
}