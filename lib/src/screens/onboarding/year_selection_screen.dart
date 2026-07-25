import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class YearSelectionScreen extends StatefulWidget {
  const YearSelectionScreen({super.key});

  @override
  State<YearSelectionScreen> createState() => _YearSelectionScreenState();
}

class _YearSelectionScreenState extends State<YearSelectionScreen> {
  String? _selectedYear;
  bool _isNavigating = false;

  final List<YearOption> _years = [
    YearOption(
      value: 'freshman',
      title: 'FRESHMAN',
      subtitle: 'Year 1 Student',
      description: 'Two semesters with stream or track selection',
      icon: Icons.looks_one,
      color: AppColors.primary,
      badge: '6-8 subjects',
    ),
    YearOption(
      value: 'senior',
      title: 'SENIOR',
      subtitle: 'Years 2, 3, and 4',
      description: 'Content is being prepared by the admin team',
      icon: Icons.school,
      color: Colors.orange,
      badge: 'Coming Soon',
    ),
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedYear == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('university_year', _selectedYear!);
    await prefs.setString('selected_year', _selectedYear!);

    if (!mounted) return;

    if (_selectedYear == 'freshman') {
      context.pushReplacement('/semester-selection');
    } else {
      context.pushReplacement('/senior-year');
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
        title: const Text('Select Your Year'),
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
                  color: AppColors.primary.withAlpha(((255 * 0.05)).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose your academic year at the university',
                        style: TextStyle(color: AppColors.primary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Year cards
              ..._years.map((year) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildYearCard(year),
              )),
              
              const Spacer(),

              // Info text based on selection
              if (_selectedYear != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (_selectedYear == 'freshman' ? AppColors.primary : Colors.orange).withAlpha(((255 * 0.1)).toInt()),
                        (_selectedYear == 'freshman' ? AppColors.primary : Colors.orange).withAlpha(((255 * 0.05)).toInt()),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_selectedYear == 'freshman' ? AppColors.primary : Colors.orange).withAlpha(((255 * 0.2)).toInt()),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedYear == 'freshman' ? Icons.info_outline : Icons.construction,
                        color: _selectedYear == 'freshman' ? AppColors.primary : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedYear == 'freshman'
                              ? 'Freshman: You will select your semester, stream/track, and subjects for Year 1.'
                              : 'Senior content (Years 2-4) is being prepared. You will be notified when it becomes available.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedYear == 'freshman' ? AppColors.primary : Colors.orange[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Continue Button
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedYear != null && !_isNavigating ? _saveAndContinue : () {},
                isDisabled: _selectedYear == null || _isNavigating,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearCard(YearOption year) {
    final isSelected = _selectedYear == year.value;
    final color = year.color;

    return GestureDetector(
      onTap: () => setState(() => _selectedYear = year.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(((255 * 0.05)).toInt()) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withAlpha(((255 * 0.2)).toInt()), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(((255 * 0.1)).toInt()) : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(year.icon, color: isSelected ? color : Colors.grey[600], size: 32),
            ),
            const SizedBox(width: 18),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        year.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: year.color.withAlpha(((255 * 0.1)).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          year.badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: year.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    year.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    year.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // Checkmark
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

class YearOption {
  final String value;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String badge;

  YearOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.badge,
  });
}