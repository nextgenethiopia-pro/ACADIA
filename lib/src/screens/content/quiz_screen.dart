import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class QuizScreen extends StatefulWidget {
  final String contentId;
  final String title;

  const QuizScreen({
    super.key,
    required this.contentId,
    required this.title,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestion = 1;
  int _totalQuestions = 0;
  String? _selectedAnswer;
  final Map<int, String> _answers = {};
  final Map<int, bool> _showingExplanation = {};
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showQuestionGrid = false;

  // Feedback mode: true = immediate, false = review at end
  bool _immediateFeedback = true;
  final Map<int, bool> _answerResults = {};

  String _quizTitle = '';

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;

      final result = await db.query(
        'offline_content',
        where: 'content_id = ?',
        whereArgs: [widget.contentId],
      );

      if (result.isNotEmpty) {
        final filePath = result.first['local_path'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final data = json.decode(jsonString) as Map<String, dynamic>;

          final questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);

          if (mounted) {
            setState(() {
              _quizTitle = data['title']?.toString() ?? widget.title;
              _questions = questions;
              _totalQuestions = questions.length;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz file not found. Please download it first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading quiz: $e');
    }
  }

  /// Normalises a question's `options` (a JSON array of strings, or a legacy
  /// A/B/C/D map) into an ordered list of option texts.
  List<String> _optionTexts(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is Map) return raw.values.map((e) => e.toString()).toList();
    return const [];
  }

  void _selectAnswer(String answer) {
    if (_answers[_currentQuestion] != null) return; // Already answered

    setState(() {
      _selectedAnswer = answer;
      _answers[_currentQuestion] = answer;

      if (_immediateFeedback) {
        final question = _questions[_currentQuestion - 1];
        final correctAnswer = question['correct_answer']?.toString() ?? '';
        _answerResults[_currentQuestion] = (answer == correctAnswer);
      }
    });
  }

  void _toggleExplanation() {
    setState(() {
      _showingExplanation[_currentQuestion] = !(_showingExplanation[_currentQuestion] ?? false);
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _totalQuestions) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = _answers[_currentQuestion];
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 1) {
      setState(() {
        _currentQuestion--;
        _selectedAnswer = _answers[_currentQuestion];
      });
    }
  }

  void _jumpToQuestion(int question) {
    setState(() {
      _currentQuestion = question;
      _selectedAnswer = _answers[_currentQuestion];
    });
    setState(() => _showQuestionGrid = false);
  }

  void _toggleQuestionGrid() {
    setState(() => _showQuestionGrid = !_showQuestionGrid);
  }

  Future<void> _submitQuiz() async {
    final unanswered = _totalQuestions - _answers.length;
    if (unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Quiz?'),
          content: Text(
              'You have $unanswered unanswered question(s). Unanswered questions will be marked as wrong. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSubmitting = true);

    int correct = 0;
    int wrong = 0;

    for (int i = 0; i < _totalQuestions; i++) {
      final questionNum = i + 1;
      final userAnswer = _answers[questionNum];
      if (userAnswer == null) {
        wrong++;
      } else {
        final question = _questions[i];
        final correctAnswer = question['correct_answer']?.toString() ?? '';
        if (userAnswer == correctAnswer) {
          correct++;
        } else {
          wrong++;
        }
      }
    }

    final score = correct;
    final timeTaken = 0;

    if (mounted) {
      context.pushReplacement('/quiz-result', extra: {
        'score': score,
        'total': _totalQuestions,
        'correct': correct,
        'wrong': wrong,
        'timeTaken': timeTaken,
        'title': _quizTitle,
        'contentId': widget.contentId,
        'questions': _questions,
        'userAnswers': _answers,
        'correctAnswers': _questions.map((q) => q['correct_answer']).toList(),
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return true;
    
    // Check if any progress has been made
    if (_answers.isNotEmpty) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit Quiz?'),
          content: Text(
              'You have answered ${_answers.length} of $_totalQuestions questions. Your progress will not be saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Quiz...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No quiz available', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Download the quiz file first', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final progress = _currentQuestion / _totalQuestions;
    final currentQuestion = _questions[_currentQuestion - 1];
    final questionText = currentQuestion['question']?.toString() ?? '';
    final options = _optionTexts(currentQuestion['options']);
    final optionLabels = ['A', 'B', 'C', 'D'];
    final hasAnswered = _answers[_currentQuestion] != null;
    final isCorrect = _immediateFeedback && _answerResults[_currentQuestion] == true;
    final isWrong = _immediateFeedback && _answerResults[_currentQuestion] == false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_quizTitle, style: const TextStyle(fontSize: 16)),
          leading: IconButton(
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) context.pop();
            },
            icon: const Icon(Icons.close),
          ),
          actions: [
            // Question grid toggle
            IconButton(
              onPressed: _toggleQuestionGrid,
              icon: Icon(_showQuestionGrid ? Icons.grid_view : Icons.grid_view_outlined),
              tooltip: 'Question Grid',
            ),
            // Feedback mode toggle
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _immediateFeedback ? 'Immediate' : 'Review',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: _immediateFeedback,
                    onChanged: (value) {
                      setState(() => _immediateFeedback = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Progress Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question $_currentQuestion of $_totalQuestions',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_answers.length}/$_totalQuestions',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),

                // Question Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Question $_currentQuestion',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    if (_immediateFeedback && hasAnswered)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isCorrect ? Icons.check_circle : Icons.cancel,
                                              color: isCorrect ? Colors.green : Colors.red,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isCorrect ? 'Correct!' : 'Wrong',
                                              style: TextStyle(
                                                color: isCorrect ? Colors.green : Colors.red,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  questionText,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Select your answer:',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 12),

                        // Options
                        ...options.asMap().entries.map((entry) {
                          final optionIndex = entry.key;
                          final label = optionIndex < optionLabels.length
                              ? optionLabels[optionIndex]
                              : '${optionIndex + 1}';
                          final optionText = entry.value;
                          final isSelected = _selectedAnswer == optionText;

                          // Immediate feedback colors
                          Color? optionColor;
                          IconData? feedbackIcon;
                          Color? feedbackColor;

                          if (_immediateFeedback && hasAnswered) {
                            final correctAnswer = currentQuestion['correct_answer']?.toString() ?? '';
                            final isCorrectOption = (optionText == correctAnswer);

                            if (isSelected && isCorrectOption) {
                              optionColor = Colors.green.withOpacity(0.15);
                              feedbackIcon = Icons.check_circle;
                              feedbackColor = Colors.green;
                            } else if (isSelected && !isCorrectOption) {
                              optionColor = Colors.red.withOpacity(0.15);
                              feedbackIcon = Icons.cancel;
                              feedbackColor = Colors.red;
                            } else if (!isSelected && isCorrectOption) {
                              optionColor = Colors.green.withOpacity(0.08);
                              feedbackIcon = Icons.check_circle_outline;
                              feedbackColor = Colors.green;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: hasAnswered && _immediateFeedback ? null : () => _selectAnswer(optionText),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: optionColor ?? (isSelected ? AppColors.primary.withOpacity(0.08) : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey[200]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isSelected ? AppColors.primary : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (feedbackIcon != null)
                                      Icon(feedbackIcon, color: feedbackColor, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Show Explanation Button (Immediate Feedback Mode)
                        if (_immediateFeedback && hasAnswered)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _toggleExplanation,
                                  icon: Icon(
                                    _showingExplanation[_currentQuestion] == true
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _showingExplanation[_currentQuestion] == true
                                        ? 'Hide Explanation'
                                        : 'Show Explanation',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.primary.withOpacity(0.05),
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                                if (_showingExplanation[_currentQuestion] == true)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Explanation',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          currentQuestion['explanation']?.toString() ?? 'No explanation available.',
                                          style: const TextStyle(fontSize: 14, height: 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Previous button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _currentQuestion > 1 ? _previousQuestion : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _currentQuestion > 1 ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: _currentQuestion > 1 ? AppColors.primary : Colors.grey[400],
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _currentQuestion == _totalQuestions
                              ? GradientButton(
                                  text: 'SUBMIT QUIZ',
                                  onPressed: _isSubmitting ? () {} : _submitQuiz,
                                  isLoading: _isSubmitting,
                                )
                              : ElevatedButton(
                                  onPressed: _selectedAnswer != null ? _nextQuestion : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedAnswer != null ? AppColors.primary : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text('NEXT QUESTION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Question Grid Overlay
            if (_showQuestionGrid)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Column(
                    children: [
                      AppBar(
                        title: const Text('Questions', style: TextStyle(color: Colors.white)),
                        leading: IconButton(
                          onPressed: () => setState(() => _showQuestionGrid = false),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: List.generate(_totalQuestions, (index) {
                              final qNum = index + 1;
                              final isAnswered = _answers.containsKey(qNum);
                              final isCurrent = qNum == _currentQuestion;
                              final isCorrectAnswer = _immediateFeedback && _answerResults[qNum] == true;
                              final isWrongAnswer = _immediateFeedback && _answerResults[qNum] == false;
                              
                              Color? bgColor;
                              if (isCurrent) {
                                bgColor = AppColors.primary;
                              } else if (isCorrectAnswer) {
                                bgColor = Colors.green;
                              } else if (isWrongAnswer) {
                                bgColor = Colors.red;
                              } else if (isAnswered) {
                                bgColor = Colors.green.withOpacity(0.5);
                              } else {
                                bgColor = Colors.grey[700];
                              }
                              
                              return GestureDetector(
                                onTap: () => _jumpToQuestion(qNum),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrent ? Colors.white : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$qNum',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}