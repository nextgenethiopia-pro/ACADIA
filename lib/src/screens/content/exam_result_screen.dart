import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class ExamResultScreen extends StatefulWidget {
  final Map<String, dynamic>? resultData;

  const ExamResultScreen({super.key, this.resultData});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  bool _showReview = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Get data from result or use defaults
    final score = widget.resultData?['score'] ?? 0;
    final total = widget.resultData?['total'] ?? 0;
    final correct = widget.resultData?['correct'] ?? 0;
    final wrong = widget.resultData?['wrong'] ?? 0;
    final unanswered = widget.resultData?['unanswered'] ?? 0;
    final timeTaken = widget.resultData?['timeTaken'] ?? 0;
    final subject = widget.resultData?['subject']?.toString() ?? '';
    final chapter = widget.resultData?['chapter']?.toString() ?? '';
    final examTitle = widget.resultData?['title']?.toString() ?? 'Exam';
    final contentId = widget.resultData?['contentId']?.toString() ?? '';

    final questions = widget.resultData?['questions'] as List<Map<String, dynamic>>? ?? [];
    final userAnswers = widget.resultData?['userAnswers'] as Map<int, String>? ?? {};
    final correctAnswers = widget.resultData?['correctAnswers'] as List<String>? ?? [];

    final percentage = total > 0 ? ((score / total) * 100).toInt() : 0;
    final passed = percentage >= 60;

    // Format time
    final minutes = (timeTaken ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeTaken % 60).toString().padLeft(2, '0');
    final hours = (timeTaken ~/ 3600);
    final timeDisplay = hours > 0
        ? '${hours}h ${minutes}m ${seconds}s'
        : '$minutes:$seconds';

    // Get performance level
    String performanceLevel;
    IconData performanceIcon;
    Color performanceColor;
    
    if (percentage >= 90) {
      performanceLevel = 'Excellent!';
      performanceIcon = Icons.emoji_events;
      performanceColor = Colors.amber;
    } else if (percentage >= 75) {
      performanceLevel = 'Very Good!';
      performanceIcon = Icons.sentiment_very_satisfied;
      performanceColor = Colors.green;
    } else if (percentage >= 60) {
      performanceLevel = 'Good!';
      performanceIcon = Icons.sentiment_satisfied;
      performanceColor = Colors.green;
    } else if (percentage >= 40) {
      performanceLevel = 'Needs Improvement';
      performanceIcon = Icons.sentiment_neutral;
      performanceColor = Colors.orange;
    } else {
      performanceLevel = 'Keep Studying';
      performanceIcon = Icons.sentiment_dissatisfied;
      performanceColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_showReview ? 'Review Answers' : 'Exam Results'),
        leading: IconButton(
          onPressed: () {
            if (_showReview) {
              setState(() => _showReview = false);
            } else {
              context.go('/dashboard');
            }
          },
          icon: Icon(_showReview ? Icons.arrow_back : Icons.arrow_back),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_showReview && questions.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _showReview = true),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Review'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
      body: _showReview
          ? _buildReviewList(questions, userAnswers, correctAnswers)
          : SafeArea(
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

                    // Pass/Fail Message
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, opacity, child) {
                        return Opacity(opacity: opacity, child: child);
                      },
                      child: Column(
                        children: [
                          Text(
                            passed ? '🎉 Congratulations! 🎉' : '😔 Exam Failed',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: passed ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            passed
                                ? 'You have successfully passed the exam!'
                                : 'You need 60% to pass. Keep studying and try again.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

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
                          'total', 
                          Colors.blue, 
                          Icons.timer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Unanswered (if any)
                    if (unanswered > 0)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Unanswered', 
                              '$unanswered', 
                              '${total > 0 ? (unanswered / total * 100).toInt() : 0}%', 
                              Colors.orange, 
                              Icons.help_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    const SizedBox(height: 32),

                    // Exam Details Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (examTitle.isNotEmpty && examTitle != 'Exam') ...[
                              _buildDetailRow('Exam', examTitle),
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

                    // Action Buttons
                    if (questions.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _showReview = true),
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
                        onPressed: () {
                          context.pop(); // Go back to exam
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Exam'),
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
                                      'Exam Champion: Successfully passed ${examTitle != 'Exam' ? examTitle : 'your exam'}',
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

  Widget _buildReviewList(
    List<Map<String, dynamic>> questions,
    Map<int, String> userAnswers,
    List<String> correctAnswers,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final questionNum = index + 1;
        final question = questions[index];
        final userAnswer = userAnswers[questionNum];
        final correctAnswer = correctAnswers.length > index ? correctAnswers[index] : '';
        final isCorrect = userAnswer == correctAnswer;

        // Get options
        final options = question['options'] as Map<String, dynamic>? ?? {};
        final optionEntries = options.entries.toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCorrect ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCorrect ? 'Correct' : 'Wrong',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Q$questionNum',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question['question']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ...optionEntries.map((entry) {
                  final optionText = entry.value?.toString() ?? '';
                  final optionIndex = optionEntries.indexOf(entry);
                  final label = String.fromCharCode(65 + optionIndex);
                  final isUserAnswer = userAnswer == optionText;
                  final isCorrectOption = correctAnswer == optionText;

                  Color? bgColor;
                  if (isCorrectOption) {
                    bgColor = Colors.green.withOpacity(0.1);
                  } else if (isUserAnswer && !isCorrect) {
                    bgColor = Colors.red.withOpacity(0.1);
                  }

                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrectOption
                            ? Colors.green
                            : isUserAnswer && !isCorrect
                                ? Colors.red
                                : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$label.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrectOption
                                ? Colors.green
                                : isUserAnswer && !isCorrect
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              color: isCorrectOption
                                  ? Colors.green
                                  : isUserAnswer && !isCorrect
                                      ? Colors.red
                                      : Colors.black87,
                            ),
                          ),
                        ),
                        if (isCorrectOption)
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        if (isUserAnswer && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red, size: 16),
                      ],
                    ),
                  );
                }).toList(),
                if (question['explanation'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Explanation',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question['explanation']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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