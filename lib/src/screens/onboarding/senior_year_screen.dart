import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';

class SeniorYearScreen extends StatefulWidget {
  const SeniorYearScreen({super.key});

  @override
  State<SeniorYearScreen> createState() => _SeniorYearScreenState();
}

class _SeniorYearScreenState extends State<SeniorYearScreen> {
  bool _isNavigating = false;

  Future<void> _goBackToWelcome() async {
    if (_isNavigating) return;
    
    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_year', 'senior');
    await prefs.setString('university_year', 'senior');
    
    // Clear any partial selections from freshman flow
    await prefs.remove('semester');
    await prefs.remove('selected_stream');
    await prefs.remove('stream');
    await prefs.remove('selected_track');
    await prefs.remove('track');
    
    if (mounted) {
      context.go('/welcome');
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
        title: const Text('Senior Year'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withAlpha(((255 * 0.1)).toInt()), Colors.blue.withAlpha(((255 * 0.05)).toInt())],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.withAlpha(((255 * 0.3)).toInt()), width: 2),
                  ),
                  child: const Icon(Icons.construction, size: 56, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Content Being Prepared',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Content for Senior years (Year 2, 3, 4) is currently being prepared by the admin team. '
                  'Your selection has been saved and you will be notified when content becomes available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 32),

              // What's coming section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(((255 * 0.05)).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withAlpha(((255 * 0.1)).toInt())),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upcoming, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Full course materials for Year 2, 3, and 4\n'
                      '• Past papers and exam preparation\n'
                      '• Video lectures and study guides\n'
                      '• Practice quizzes and mock exams',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Go Back button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isNavigating ? null : _goBackToWelcome,
                  icon: _isNavigating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_back),
                  label: Text(
                    _isNavigating ? 'Redirecting...' : 'GO BACK TO WELCOME SCREEN',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notification info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(((255 * 0.1)).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withAlpha(((255 * 0.2)).toInt())),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(((255 * 0.2)).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active, color: Colors.amber[700], size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will be notified when Senior content becomes available.',
                        style: TextStyle(color: Colors.amber[800], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}