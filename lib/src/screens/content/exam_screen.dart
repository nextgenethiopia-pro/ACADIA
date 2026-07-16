import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class ExamScreen extends StatefulWidget {
  final String contentId;
  final String title;

  const ExamScreen({
    super.key,
    required this.contentId,
    required this.title,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _currentQuestion = 1;
  int _totalQuestions = 0;
  String? _selectedAnswer;
  final Map<int, String> _answers = {};
  bool _isPaused = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Feedback mode: true = immediate feedback, false = review at end
  bool _immediateFeedback = false;
  final Map<int, bool> _answerResults = {}; // Store correct/incorrect for each question
  final Map<int, bool> _showingExplanation = {}; // Track which explanations are shown

  int _remainingSeconds = 0;
  int _totalTimeSeconds = 0;
  Timer? _timer;
  bool _showQuestionGrid = true;
  int? _hoveredQuestion;

  List<Map<String, dynamic>> _questions = [];
  String _examTitle = '';
  int _timeLimitMinutes = 30;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadExam() async {
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
          final timeLimit = data['time_limit_minutes'] ?? 30;

          if (mounted) {
            setState(() {
              _examTitle = data['title']?.toString() ?? widget.title;
              _questions = questions;
              _totalQuestions = questions.length;
              _timeLimitMinutes = timeLimit is int ? timeLimit : 30;
              _totalTimeSeconds = _timeLimitMinutes * 60;
              _remainingSeconds = _totalTimeSeconds;
              _isLoading = false;
            });
            _startTimer();
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam file not found. Please download it first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading exam: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
      }
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoSubmit();
      }
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _toggleQuestionGrid() {
    setState(() => _showQuestionGrid = !_showQuestionGrid);
  }

  void _selectAnswer(String answer) {
    if (_isPaused) return;
    if (_answers[_currentQuestion] != null && _immediateFeedback) return; // Already answered in immediate mode

    setState(() {
      _selectedAnswer = answer;
      _answers[_currentQuestion] = answer;

      // Immediate feedback mode: show result right away
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
  }

  void _autoSubmit() {
    _submitExam(isAutoSubmit: true);
  }

  Future<void> _submitExam({bool isAutoSubmit = false}) async {
    final unanswered = _totalQuestions - _answers.length;

    if (!isAutoSubmit && unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Exam?'),
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
    _timer?.cancel();

    int correct = 0;
    int wrong = 0;
    int unansweredCount = 0;

    for (int i = 0; i < _totalQuestions; i++) {
      final questionNum = i + 1;
      final userAnswer = _answers[questionNum];
      if (userAnswer == null) {
        unansweredCount++;
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
    final timeTaken = _totalTimeSeconds - _remainingSeconds;

    if (mounted) {
      context.pushReplacement('/exam-result', extra: {
        'score': score,
        'total': _totalQuestions,
        'correct': correct,
        'wrong': wrong,
        'unanswered': unansweredCount,
        'timeTaken': timeTaken,
        'title': _examTitle,
        'contentId': widget.contentId,
        'questions': _questions,
        'userAnswers': _answers,
        'correctAnswers': _questions.map((q) => q['correct_answer']).toList(),
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Exam?'),
        content: const Text('Your progress will not be saved. Are you sure you want to exit?'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Exam...')),
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
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No questions available', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Download the exam file first', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final progress = _currentQuestion / _totalQuestions;
    final isWarning = _remainingSeconds < 300;
    final isDanger = _remainingSeconds < 60;
    final answeredCount = _answers.length;

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
          title: Text(_examTitle, style: const TextStyle(fontSize: 16)),
          leading: IconButton(
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) context.pop();
            },
            icon: const Icon(Icons.close),
          ),
          actions: [
            // Feedback mode toggle
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _immediateFeedback ? 'Immediate' : 'Review at End',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: _immediateFeedback,
                    onChanged: (value) {
                      setState(() {
                        _immediateFeedback = value;
                        // Clear any selected answer when switching modes
                        _selectedAnswer = null;
                      });
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
                // Timer Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDanger
                      ? Colors.red.withOpacity(0.1)
                      : isWarning
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.grey[50],
                  child: Row(
                    children: [
                      Icon(Icons.timer,
                          color: isDanger
                              ? Colors.red
                              : isWarning
                                  ? Colors.orange
                                  : AppColors.primary,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDanger
                              ? Colors.red
                              : isWarning
                                  ? Colors.orange
                                  : AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Question count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$answeredCount/$_totalQuestions',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _togglePause,
                        icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                        label: Text(_isPaused ? 'Resume' : 'Pause', style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPaused ? Colors.green : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Question $_currentQuestion of $_totalQuestions',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${(progress * 100).toInt()}%',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                ),

                // Question area (hidden when paused)
                if (!_isPaused)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _currentQuestion <= _questions.length
                          ? _buildQuestionCard(_questions[_currentQuestion - 1])
                          : const SizedBox(),
                    ),
                  ),

                // Question Grid Toggle Button
                if (!_isPaused && _totalQuestions > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _toggleQuestionGrid,
                          icon: Icon(_showQuestionGrid ? Icons.grid_view : Icons.grid_view_outlined, size: 18),
                          label: Text(_showQuestionGrid ? 'Hide Grid' : 'Show Grid'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Question Grid
                if (!_isPaused && _showQuestionGrid && _totalQuestions > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -2))
                      ],
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(_totalQuestions, (index) {
                        final qNum = index + 1;
                        final isAnswered = _answers.containsKey(qNum);
                        final isCurrent = qNum == _currentQuestion;
                        final isCorrect = _immediateFeedback && _answerResults[qNum] == true;
                        final isWrong = _immediateFeedback && _answerResults[qNum] == false;
                        
                        Color? bgColor;
                        if (isCurrent) {
                          bgColor = AppColors.primary;
                        } else if (isCorrect) {
                          bgColor = Colors.green;
                        } else if (isWrong) {
                          bgColor = Colors.red;
                        } else if (isAnswered) {
                          bgColor = Colors.green.withOpacity(0.2);
                        } else {
                          bgColor = Colors.grey[100];
                        }
                        
                        return GestureDetector(
                          onTap: () => _jumpToQuestion(qNum),
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hoveredQuestion = qNum),
                            onExit: (_) => setState(() => _hoveredQuestion = null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : _hoveredQuestion == qNum
                                          ? AppColors.primary
                                          : Colors.grey[300]!,
                                  width: isCurrent || _hoveredQuestion == qNum ? 2 : 1,
                                ),
                                boxShadow: _hoveredQuestion == qNum
                                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$qNum',
                                  style: TextStyle(
                                    color: isCurrent || isCorrect == true
                                        ? Colors.white
                                        : isAnswered
                                            ? Colors.green
                                            : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                // Bottom Navigation
                if (!_isPaused)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -2))
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _currentQuestion > 1 ? _previousQuestion : null,
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('PREV', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: GradientButton(
                              text: 'SUBMIT EXAM',
                              onPressed: () => _submitExam(),
                              isLoading: _isSubmitting,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _currentQuestion < _totalQuestions ? _nextQuestion : null,
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('NEXT', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Pause Overlay - Hides questions when exam is paused (as per ACADIA spec)
            if (_isPaused)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pause_circle_outline,
                          size: 100,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Exam Paused',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Time remaining: ${_formatTime(_remainingSeconds)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your questions are hidden. Timer continues in background.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _togglePause,
                          icon: const Icon(Icons.play_arrow, size: 24),
                          label: const Text(
                            'Resume Exam',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final options = question['options'] as Map<String, dynamic>? ?? {};
    final optionLabels = ['A', 'B', 'C', 'D'];
    final hasAnswered = _answers[_currentQuestion] != null;
    final isCorrectAnswer = _immediateFeedback && hasAnswered && _answerResults[_currentQuestion] == true;
    final isWrongAnswer = _immediateFeedback && hasAnswered && _answerResults[_currentQuestion] == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Question $_currentQuestion',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 12),
                Text(question['question']?.toString() ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
                // Result badge for immediate feedback
                if (_immediateFeedback && hasAnswered)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCorrectAnswer ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCorrectAnswer ? Icons.check_circle : Icons.cancel,
                            color: isCorrectAnswer ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCorrectAnswer ? 'Correct!' : 'Wrong',
                            style: TextStyle(
                              color: isCorrectAnswer ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        Text('Select your answer:',
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 12),
        
        ...options.entries.toList().asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final optionEntry = entry.value;
          final label = optionLabels[optionIndex];
          final optionText = optionEntry.value?.toString() ?? '';
          final isSelected = _selectedAnswer == optionText;

          // Immediate feedback colors
          Color? optionColor;
          IconData? feedbackIcon;
          Color? feedbackColor;

          if (_immediateFeedback && hasAnswered) {
            final correctAnswer = question['correct_answer']?.toString() ?? '';
            final isCorrect = (optionText == correctAnswer);

            if (isSelected && isCorrect) {
              optionColor = Colors.green.withOpacity(0.15);
              feedbackIcon = Icons.check_circle;
              feedbackColor = Colors.green;
            } else if (isSelected && !isCorrect) {
              optionColor = Colors.red.withOpacity(0.15);
              feedbackIcon = Icons.cancel;
              feedbackColor = Colors.red;
            } else if (!isSelected && isCorrect) {
              optionColor = Colors.green.withOpacity(0.1);
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
                        child: Text(label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(optionText,
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected ? AppColors.primary : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ),
                    if (feedbackIcon != null)
                      Icon(feedbackIcon, color: feedbackColor, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),

        // Show Explanation Button (only in Immediate Feedback Mode)
        // According to ACADIA spec, explanation appears on the same screen when "Show Explanation" is tapped
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
                          question['explanation']?.toString() ?? 'No explanation available.',
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}