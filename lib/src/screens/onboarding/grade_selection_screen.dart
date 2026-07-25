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

  final List<GradeOption> _grades = const [
    GradeOption(
      grade: 9,
      shade: AppColors.primary,
      description: 'Foundation Level',
    ),
    GradeOption(
      grade: 10,
      shade: AppColors.primaryLight,
      description: 'Secondary Level',
    ),
    GradeOption(
      grade: 11,
      shade: AppColors.primary,
      description: 'College Prep',
    ),
    GradeOption(
      grade: 12,
      shade: AppColors.primaryDark,
      description: 'Exit Exam Prep',
    ),
  ];

  Future<void> _saveGradeAndContinue() async {
    if (_selectedGrade == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    final selectedGrade = _selectedGrade!.toString();

    await prefs.setString('selected_grade', selectedGrade);
    await prefs.setString('grade', selectedGrade);
    await prefs.setBool('onboarding_complete', false);

    if (_selectedGrade == 9 || _selectedGrade == 10) {
      await prefs.setString('selected_stream', 'general');
      await prefs.setString('stream', 'general');
    } else {
      await prefs.remove('selected_stream');
      await prefs.remove('stream');
    }

    if (!mounted) return;

    if (_selectedGrade == 11 || _selectedGrade == 12) {
      context.pushReplacement('/stream-selection');
    } else {
      context.pushReplacement('/register');
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
        title: const Text('Select Your Grade'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Icons.school,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose your current grade level. Grades 11 and 12 will continue to stream selection, while Grades 9 and 10 will continue directly to registration.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _grades.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final option = _grades[index];
                    final isSelected = _selectedGrade == option.grade;

                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _isNavigating
                          ? null
                          : () => setState(() => _selectedGrade = option.grade),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? option.shade.withAlpha(((255 * 0.08)).toInt())
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? option.shade
                                : Colors.grey.shade300,
                            width: isSelected ? 2.4 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? option.shade.withAlpha(((255 * 0.16)).toInt())
                                  : Colors.black.withAlpha(((255 * 0.04)).toInt()),
                              blurRadius: isSelected ? 18 : 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: AnimatedOpacity(
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
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${option.grade}',
                              style: TextStyle(
                                fontSize: 54,
                                height: 0.95,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? option.shade
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Grade ${option.grade}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color:
                                    isSelected ? option.shade : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              option.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.35,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedGrade != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
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
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedGrade == 11 || _selectedGrade == 12
                              ? 'Next step: choose your stream before registration.'
                              : 'Next step: continue directly to registration.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedGrade != null && !_isNavigating
                    ? _saveGradeAndContinue
                    : () {},
                isDisabled: _selectedGrade == null || _isNavigating,
                isLoading: _isNavigating,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class GradeOption {
  final int grade;
  final Color shade;
  final String description;

  const GradeOption({
    required this.grade,
    required this.shade,
    required this.description,
  });
}
