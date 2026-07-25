import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class SemesterSelectionScreen extends StatefulWidget {
  const SemesterSelectionScreen({super.key});

  @override
  State<SemesterSelectionScreen> createState() =>
      _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen> {
  String? _selectedSemester;
  bool _isNavigating = false;

  final List<SemesterOption> _semesters = const [
    SemesterOption(
      value: '1',
      title: 'FRESHMAN SEMESTER 1',
      subtitle: '6 subjects',
      description:
          'Choose between Natural Science and Social Science after this step.',
      icon: Icons.looks_one_rounded,
      subjects: [
        'English',
        'Geography',
        'Logic',
        'Mathematics',
        'Physics',
        'Psychology',
      ],
    ),
    SemesterOption(
      value: '2',
      title: 'FRESHMAN SEMESTER 2',
      subtitle: '8 subjects',
      description:
          'Choose between Pre-Engineering and Other Natural Science after this step.',
      icon: Icons.looks_two_rounded,
      subjects: [
        'Anthropology',
        'Applied Mathematics',
        'C++ Programming',
        'Emerging Technologies',
        'English Skill 2',
        'Entrepreneurship',
        'History',
        'Moral and Citizenship Education',
      ],
    ),
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedSemester == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('semester', _selectedSemester!);
    await prefs.setBool('onboarding_complete', false);

    if (!mounted) return;

    if (_selectedSemester == '1') {
      context.pushReplacement('/university-stream-selection');
    } else {
      context.pushReplacement('/university-track-selection');
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
        title: const Text('Select Semester'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(((255 * 0.12)).toInt()),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(((255 * 0.10)).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your freshman semester',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your semester selection helps ACADIA prepare the correct university onboarding path before registration.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.45,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ..._semesters.map(
                (semester) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSemesterCard(semester),
                ),
              ),

              const SizedBox(height: 24),

              // Info text based on selection
              if (_selectedSemester != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(((255 * 0.12)).toInt()),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.amber.withAlpha(((255 * 0.30)).toInt()),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[800],
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedSemester == '1'
                              ? 'Next you will choose your freshman stream, then continue to registration.'
                              : 'Next you will choose your freshman track, then continue to registration.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.amber[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedSemester != null && !_isNavigating
                    ? _saveAndContinue
                    : () {},
                isDisabled: _selectedSemester == null || _isNavigating,
                isLoading: _isNavigating,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterCard(SemesterOption semester) {
    final isSelected = _selectedSemester == semester.value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _isNavigating
          ? null
          : () => setState(() => _selectedSemester = semester.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withAlpha(((255 * 0.06)).toInt()) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withAlpha(((255 * 0.12)).toInt())
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
                color: AppColors.primary.withAlpha((255 * (isSelected ? 0.16 : 0.08)).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                semester.icon,
                color: AppColors.primary,
                size: 30,
              ),
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
                          semester.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color:
                                isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: isSelected ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    semester.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    semester.description,
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.45,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: semester.subjects
                        .map(
                          (subject) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(((255 * 0.08)).toInt()),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(((255 * 0.12)).toInt()),
                              ),
                            ),
                            child: Text(
                              subject,
                              style: const TextStyle(
                                fontSize: 11.2,
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

class SemesterOption {
  final String value;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> subjects;

  const SemesterOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.subjects,
  });
}
