import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic>? resultData;

  const QuizResultScreen({super.key, this.resultData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Get data from result or use defaults
    final score = resultData?['score'] ?? 0;
    final total = resultData?['total'] ?? 0;
    final correct = resultData?['correct'] ?? 0;
    final wrong = resultData?['wrong'] ?? 0;
    final timeTaken = resultData?['timeTaken'] ?? 0;
    final quizTitle = resultData?['title']?.toString() ?? 'Quiz';
    final subject = resultData?['subject']?.toString() ?? '';
    final chapter = resultData?['chapter']?.toString() ?? '';
    final contentId = resultData?['contentId']?.toString() ?? '';

    final percentage = total > 0 ? ((score / total) * 100).toInt() : 0;
    final passed = percentage >= 60;

    // Format time
    final minutes = (timeTaken ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeTaken % 60).toString().padLeft(2, '0');
    final timeDisplay = '$minutes:$seconds';

    // Get performance level
    String performanceLevel;
    IconData performanceIcon;
    Color performanceColor;
    String performanceMessage;
    
    if (percentage >= 90) {
      performanceLevel = 'Excellent!';
      performanceIcon = Icons.emoji_events;
      performanceColor = Colors.amber;
      performanceMessage = 'Outstanding performance! You\'re a star!';
    } else if (percentage >= 75) {
      performanceLevel = 'Very Good!';
      performanceIcon = Icons.sentiment_very_satisfied;
      performanceColor = Colors.green;
      performanceMessage = 'Great job! Keep up the good work!';
    } else if (percentage >= 60) {
      performanceLevel = 'Good!';
      performanceIcon = Icons.sentiment_satisfied;
      performanceColor = Colors.green;
      performanceMessage = 'You passed! Review the explanations to learn more.';
    } else if (percentage >= 40) {
      performanceLevel = 'Needs Improvement';
      performanceIcon = Icons.sentiment_neutral;
      performanceColor = Colors.orange;
      performanceMessage = 'Review the material and try again.';
    } else {
      performanceLevel = 'Keep Studying';
      performanceIcon = Icons.sentiment_dissatisfied;
      performanceColor = Colors.red;
      performanceMessage = 'Don\'t give up! Review and try again.';
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quiz Results'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Animated Score Circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percentage / 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  final currentPercentage = (value * 100).toInt();
                  return Container(
                    width: size.width * 0.45,
                    height: size.width * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: passed 
                            ? [Colors.green.shade400, Colors.green.shade700]
                            : [Colors.red.shade400, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (passed ? Colors.green : Colors.red).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$score/$total',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$currentPercentage%',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Pass/Fail Message with Animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: Column(
                  children: [
                    Text(
                      passed ? '🎉 Congratulations! 🎉' : '📚 Keep Practicing! 📚',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: passed ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      passed ? performanceMessage : 'You need 60% to pass. Review the material and try again.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Performance Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: performanceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: performanceColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(performanceIcon, color: performanceColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      performanceLevel,
                      style: TextStyle(
                        color: performanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats Cards
              Row(
                children: [
                  _buildStatCard(
                    'Correct', 
                    '$correct', 
                    '${total > 0 ? (correct / total * 100).toInt() : 0}%', 
                    Colors.green, 
                    Icons.check_circle,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Wrong', 
                    '$wrong', 
                    '${total > 0 ? (wrong / total * 100).toInt() : 0}%', 
                    Colors.red, 
                    Icons.cancel,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Time', 
                    timeDisplay, 
                    'total time', 
                    Colors.blue, 
                    Icons.timer,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quiz Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (quizTitle.isNotEmpty && quizTitle != 'Quiz') ...[
                        _buildDetailRow('Quiz', quizTitle),
                        const Divider(),
                      ],
                      if (subject.isNotEmpty) ...[
                        _buildDetailRow('Subject', subject),
                        const Divider(),
                      ],
                      if (chapter.isNotEmpty) ...[
                        _buildDetailRow('Chapter', chapter),
                        const Divider(),
                      ],
                      _buildDetailRow('Total Questions', '$total'),
                      const Divider(),
                      _buildDetailRow('Passing Score', '60%'),
                      const Divider(),
                      _buildDetailRow('Your Score', '$percentage%', isHighlight: true),
                      const Divider(),
                      _buildDetailRow('Time Taken', timeDisplay),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // View Answers Button
              if (contentId.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('/quiz-review', extra: {
                      'contentId': contentId,
                      'answers': resultData?['userAnswers'],
                      'questions': resultData?['questions'],
                      'correctAnswers': resultData?['correctAnswers'],
                    });
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Review All Answers'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 12),

              // Retry Button (if failed)
              if (!passed && contentId.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Quiz'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (!passed && contentId.isNotEmpty) const SizedBox(height: 12),

              // Back to Dashboard Button
              GradientButton(
                text: 'Back to Dashboard',
                onPressed: () => context.go('/dashboard'),
              ),
              const SizedBox(height: 24),

              // Achievement Banner (if passed)
              if (passed)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, opacity, child) {
                    return Opacity(opacity: opacity, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Achievement Unlocked! 🏆',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quiz Master: Successfully passed ${quizTitle != 'Quiz' ? quizTitle : 'your quiz'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),

              // Share Results Button (optional)
              if (passed)
                TextButton.icon(
                  onPressed: () {
                    // Share results functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share results feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Your Results'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subValue, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AppColors.primary : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}