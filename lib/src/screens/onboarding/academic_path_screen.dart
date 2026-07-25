import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class AcademicPathScreen extends StatefulWidget {
  const AcademicPathScreen({super.key});

  @override
  State<AcademicPathScreen> createState() => _AcademicPathScreenState();
}

class _AcademicPathScreenState extends State<AcademicPathScreen> {
  String? _selectedPath;
  bool _isNavigating = false;

  Future<void> _savePathAndContinue() async {
    if (_selectedPath == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    final isHighSchool = _selectedPath == 'high_school';
    final academicPath = isHighSchool ? 'HIGH SCHOOL' : 'UNIVERSITY';

    await prefs.setString('academic_path', academicPath);
    await prefs.setString(
      'academic_level',
      isHighSchool ? 'high_school' : 'university',
    );

    await prefs.remove('selected_grade');
    await prefs.remove('grade');
    await prefs.remove('selected_stream');
    await prefs.remove('stream');
    await prefs.remove('selected_generation');
    await prefs.remove('generation');
    await prefs.remove('selected_university');
    await prefs.remove('university');
    await prefs.remove('university_name');
    await prefs.remove('university_abbreviation');
    await prefs.remove('selected_year');
    await prefs.remove('semester');
    await prefs.remove('selected_track');
    await prefs.setBool('onboarding_complete', false);

    if (!mounted) return;

    if (isHighSchool) {
      context.pushReplacement('/grade-selection');
    } else {
      context.pushReplacement('/generation-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isNavigating ? null : () => context.pop(),
        ),
        title: const Text('Choose Your Academic Path'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the learning path that matches your academic journey.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(((255 * 0.75)).toInt()),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(((255 * 0.14)).toInt()),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.amber.withAlpha(((255 * 0.35)).toInt()),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber[800],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'This choice is PERMANENT',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildPathCard(
                value: 'high_school',
                title: 'HIGH SCHOOL',
                subtitle: 'Grades 9 - 12',
                description:
                    'Access grade-based learning materials for Ethiopian high school students, including Natural and Social Science streams.',
                icon: Icons.school,
                highlights: const [
                  'Grades 9 and 10 core subjects',
                  'Grade 11 and 12 stream selection',
                  'Entrance exam preparation support',
                ],
              ),
              const SizedBox(height: 16),
              _buildPathCard(
                value: 'university',
                title: 'UNIVERSITY',
                subtitle: 'Freshman - Senior',
                description:
                    'Choose your generation, institution, year, semester, and track to unlock structured university content.',
                icon: Icons.account_balance,
                highlights: const [
                  'Generation and university selection',
                  'Freshman semester-based content',
                  'Technology institutes supported',
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(((255 * 0.12)).toInt()),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'After this step, you will continue through registration setup based on your selected path. Your path will be stored and cannot be changed later.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedPath != null && !_isNavigating
                    ? _savePathAndContinue
                    : () {},
                isDisabled: _selectedPath == null || _isNavigating,
                isLoading: _isNavigating,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathCard({
    required String value,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<String> highlights,
  }) {
    final isSelected = _selectedPath == value;
    final accent = AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _isNavigating ? null : () => setState(() => _selectedPath = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(((255 * 0.06)).toInt()) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : Colors.grey.shade300,
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withAlpha(((255 * 0.14)).toInt())
                  : Colors.black.withAlpha(((255 * 0.04)).toInt()),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accent.withAlpha((255 * (isSelected ? 0.16 : 0.08)).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? accent : Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.2,
                      height: 1.45,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: highlights
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(((255 * 0.08)).toInt()),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withAlpha(((255 * 0.12)).toInt()),
                              ),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
