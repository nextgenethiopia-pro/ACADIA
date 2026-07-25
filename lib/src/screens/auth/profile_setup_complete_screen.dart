import 'dart:async';

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
  State<ProfileSetupCompleteScreen> createState() =>
      _ProfileSetupCompleteScreenState();
}

class _ProfileSetupCompleteScreenState
    extends State<ProfileSetupCompleteScreen> {
  String _academicPath = 'Student';
  String _academicDetails = '';
  bool _isLoading = true;

  Timer? _autoNavigateTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 10;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadAcademicPath();
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAcademicPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('academic_path');
    final grade = prefs.getString('selected_grade') ?? prefs.getString('grade');
    final stream =
        prefs.getString('selected_stream') ?? prefs.getString('stream');

    final generation =
        prefs.getString('selected_generation') ?? prefs.getString('generation');
    final university =
        prefs.getString('selected_university') ?? prefs.getString('university');
    final universityYear = prefs.getString('selected_year');
    final semester = prefs.getString('semester');
    final track = prefs.getString('selected_track');

    if (!mounted) return;

    setState(() {
      if (path == 'UNIVERSITY') {
        if (universityYear == 'freshman') {
          if (semester == '1') {
            _academicPath = 'University Freshman - Semester 1';
            _academicDetails =
                stream == 'social' ? 'Social Science' : 'Natural Science';
          } else if (semester == '2') {
            _academicPath = 'University Freshman - Semester 2';
            _academicDetails = _formatTrack(track);
          } else {
            _academicPath = 'University Student';
            _academicDetails = '';
          }
        } else {
          _academicPath = 'University Senior Student';
          _academicDetails = generation != null && university != null
              ? '$generation - ${_extractUniversityName(university)}'
              : '';
        }
      } else if (grade != null && grade.isNotEmpty) {
        _academicPath = 'Grade $grade';
        if (grade == '11' || grade == '12') {
          _academicDetails =
              stream == 'social' ? 'Social Science' : 'Natural Science';
        } else {
          _academicDetails = 'General Program';
        }
      } else {
        _academicPath = 'Student';
        _academicDetails = '';
      }

      _isLoading = false;
    });

    _startAutoNavigation();
  }

  void _startAutoNavigation() {
    _autoNavigateTimer?.cancel();
    _countdownTimer?.cancel();

    _secondsRemaining = 10;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isNavigating) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });

    _autoNavigateTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _goToDashboard();
      }
    });
  }

  String _formatTrack(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _extractUniversityName(String value) {
    final parts = value.split(' - ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' - ').trim();
    }
    return value;
  }

  void _goToDashboard() {
    if (_isNavigating || !mounted) return;

    _isNavigating = true;
    _autoNavigateTimer?.cancel();
    _countdownTimer?.cancel();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        color: Colors.green.withAlpha(((255 * 0.1)).toInt()),
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
                  Text(
                    'Account Created Successfully!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your academic path has been set',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                          AppColors.primary.withAlpha(((255 * 0.05)).toInt()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(((255 * 0.2)).toInt()),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(((255 * 0.15)).toInt()),
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
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(((255 * 0.15)).toInt()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withAlpha(((255 * 0.3)).toInt()),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.amber[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This path is permanently locked and cannot be changed',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(((255 * 0.08)).toInt()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withAlpha(((255 * 0.18)).toInt()),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can now continue to your dashboard and explore your personalized learning experience.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.blue[900],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _secondsRemaining > 0
                                    ? 'Auto-redirecting to dashboard in $_secondsRemaining seconds...'
                                    : 'Redirecting to dashboard...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    text: 'GO TO DASHBOARD NOW',
                    onPressed: _goToDashboard,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
