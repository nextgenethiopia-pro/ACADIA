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
    final pathValue = _selectedPath == 'high_school' ? 'HIGH SCHOOL' : 'UNIVERSITY';
    await prefs.setString('academic_path', pathValue);
    await prefs.setString('academic_level', _selectedPath == 'high_school' ? 'high_school' : 'university');

    if (!mounted) return;

    if (_selectedPath == 'high_school') {
      context.pushReplacement('/grade-selection');
    } else {
      context.pushReplacement('/generation-selection');
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
        title: const Text('Choose Your Academic Path'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'This choice is PERMANENT',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // High School Card
              _buildPathCard(
                title: 'HIGH SCHOOL',
                subtitle: 'Grades 9 - 12',
                description: 'Natural Science and Social Science streams available',
                icon: Icons.school,
                value: 'high_school',
                color: Colors.blue,
              ),
              const SizedBox(height: 16),

              // University Card
              _buildPathCard(
                title: 'UNIVERSITY',
                subtitle: 'Freshman - Senior',
                description: 'All generations and technology institutes',
                icon: Icons.account_balance,
                value: 'university',
                color: Colors.purple,
              ),
              const Spacer(),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You cannot change your academic path after registration. Choose carefully.',
                        style: TextStyle(color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Continue Button
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedPath != null && !_isNavigating ? _savePathAndContinue : () {},
                isDisabled: _selectedPath == null || _isNavigating,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedPath == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPath = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
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
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? color : Colors.grey[600], size: 32),
            ),
            const SizedBox(width: 18),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
                child: const Icon(Icons.check, color: Colors.white, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}