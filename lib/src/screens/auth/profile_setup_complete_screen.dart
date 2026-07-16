import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/blocs/auth/auth_bloc.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class ProfileSetupCompleteScreen extends StatefulWidget {
  const ProfileSetupCompleteScreen({super.key});

  @override
  State<ProfileSetupCompleteScreen> createState() => _ProfileSetupCompleteScreenState();
}

class _ProfileSetupCompleteScreenState extends State<ProfileSetupCompleteScreen> {
  String _academicPath = 'Student';
  String _academicDetails = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAcademicPath();
  }

  Future<void> _loadAcademicPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('academic_path');
    final grade = prefs.getString('selected_grade');
    final stream = prefs.getString('selected_stream');
    
    // University specific
    final generation = prefs.getString('selected_generation');
    final university = prefs.getString('selected_university');
    final universityYear = prefs.getString('selected_year');
    final semester = prefs.getString('semester');
    final track = prefs.getString('selected_track');

    setState(() {
      if (path == 'UNIVERSITY') {
        if (universityYear == 'freshman') {
          if (semester == '1') {
            _academicPath = 'University Freshman - Semester 1';
            _academicDetails = '$stream Stream';
          } else if (semester == '2') {
            _academicPath = 'University Freshman - Semester 2';
            _academicDetails = '$track Track';
          } else {
            _academicPath = 'University Student';
            _academicDetails = '';
          }
        } else {
          _academicPath = 'University Senior Student';
          _academicDetails = generation != null && university != null 
              ? '$generation - $university' 
              : '';
        }
      } else if (grade != null) {
        if (grade == '11' || grade == '12') {
          _academicPath = 'Grade $grade';
          _academicDetails = stream == 'natural' ? 'Natural Science' : 'Social Science';
        } else {
          _academicPath = 'Grade $grade';
          _academicDetails = '';
        }
      } else {
        _academicPath = 'Student';
        _academicDetails = '';
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Success Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Account Created Successfully!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Your academic path has been set',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Academic Path Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        // Icon and Path
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Academic Path',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _academicPath,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (_academicDetails.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _academicDetails,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Permanent Warning Badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, color: Colors.amber[700], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'This path is permanently locked and cannot be changed',
                                style: TextStyle(
                                  color: Colors.amber[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Box - Package Purchase Required
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Content Access',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your subjects are visible, but chapters are locked until you purchase your grade package.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified, color: Colors.green[600], size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Purchase once, unlocks all chapters for 1 year',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Next Steps Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Steps:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStepItem(1, 'Browse all your subjects in the Subjects tab'),
                        const SizedBox(height: 8),
                        _buildStepItem(2, 'Purchase your grade package to unlock chapters'),
                        const SizedBox(height: 8),
                        _buildStepItem(3, 'Download content and study offline'),
                        const SizedBox(height: 8),
                        _buildStepItem(4, 'Track your progress in the Progress tab'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Go to Dashboard Button
                  GradientButton(
                    text: 'Go to Dashboard',
                    onPressed: () => context.go('/dashboard'),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Skip for now (if needed)
                  TextButton(
                    onPressed: () => context.go('/dashboard'),
                    child: Text(
                      'I\'ll set up later',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepItem(int step, String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}