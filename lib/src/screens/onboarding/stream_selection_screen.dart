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

  static const Map<int, Map<String, List<String>>> _streamSubjects = {
    11: {
      'natural': [
        'Mathematics',
        'Physics',
        'Chemistry',
        'Biology',
        'IT',
        'English',
        'Agriculture',
        'Aptitude',
      ],
      'social': [
        'Economics',
        'Geography',
        'History',
        'Citizenship',
        'IT',
        'English',
        'Mathematics',
        'Aptitude',
      ],
    },
    12: {
      'natural': [
        'Mathematics',
        'Physics',
        'Chemistry',
        'Biology',
        'IT',
        'English',
        'Agriculture',
        'Aptitude',
      ],
      'social': [
        'Economics',
        'Geography',
        'History',
        'Citizenship',
        'IT',
        'English',
        'Mathematics',
        'Aptitude',
      ],
    },
  };

  final List<StreamOption> _streams = const [
    StreamOption(
      value: 'natural',
      title: 'NATURAL SCIENCE',
      description: 'Focus on science and technology-oriented subjects.',
      icon: Icons.science_outlined,
    ),
    StreamOption(
      value: 'social',
      title: 'SOCIAL SCIENCE',
      description: 'Focus on humanities, society, and analytical studies.',
      icon: Icons.menu_book_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadGrade();
  }

  Future<void> _loadGrade() async {
    final prefs = await SharedPreferences.getInstance();
    final gradeString =
        prefs.getString('grade') ?? prefs.getString('selected_grade') ?? '11';

    if (!mounted) return;

    setState(() {
      _grade = int.tryParse(gradeString) ?? 11;
    });
  }

  List<String> _getSubjects(String stream) {
    return _streamSubjects[_grade ?? 11]?[stream] ?? const [];
  }

  Future<void> _saveStreamAndContinue() async {
    if (_selectedStream == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stream', _selectedStream!);
    await prefs.setString('selected_stream', _selectedStream!);
    await prefs.setBool('how_to_seen', false);
    await prefs.setBool('onboarding_complete', false);

    if (!mounted) return;
    context.pushReplacement('/register');
  }

  @override
  Widget build(BuildContext context) {
    final grade = _grade ?? 11;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isNavigating ? null : () => context.pop(),
        ),
        title: const Text('Select Your Stream'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(((255 * 0.08)).toInt()),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(((255 * 0.14)).toInt()),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Grade $grade',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '8 subjects per stream',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(((255 * 0.12)).toInt()),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withAlpha(((255 * 0.28)).toInt()),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This choice is permanent and will be saved to your account during registration.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ..._streams.map(
                (stream) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildStreamCard(stream),
                ),
              ),
              const Spacer(),
              if (_selectedStream != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(((255 * 0.14)).toInt()),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After choosing your stream, you will continue to registration to complete your account setup.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedStream != null && !_isNavigating
                    ? _saveStreamAndContinue
                    : () {},
                isDisabled: _selectedStream == null || _isNavigating,
                isLoading: _isNavigating,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamCard(StreamOption stream) {
    final isSelected = _selectedStream == stream.value;
    final subjects = _getSubjects(stream.value);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _isNavigating
          ? null
          : () => setState(() => _selectedStream = stream.value),
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
                  ? AppColors.primary.withAlpha(((255 * 0.14)).toInt())
                  : Colors.black.withAlpha(((255 * 0.04)).toInt()),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(((255 * 0.10)).toInt()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    stream.icon,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
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
              ],
            ),
            const SizedBox(height: 16),
            Text(
              stream.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stream.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects
                  .map(
                    (subject) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
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
    );
  }
}

class StreamOption {
  final String value;
  final String title;
  final String description;
  final IconData icon;

  const StreamOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
  });
}
