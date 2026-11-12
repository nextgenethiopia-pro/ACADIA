import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/quiz_content_parser.dart';

class QuizScreen extends StatefulWidget {
  final String contentId;
  final String title;
  final String? downloadUrl;
  final int? expectedQuestionCount;
  final int? expectedTimeLimitMinutes;

  const QuizScreen({
    super.key,
    required this.contentId,
    required this.title,
    this.downloadUrl,
    this.expectedQuestionCount,
    this.expectedTimeLimitMinutes,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final IsarService _isarService = IsarService.instance;
  final Dio _dio = Dio();

  int _currentQuestion = 1;
  int _totalQuestions = 0;
  String? _selectedAnswer;
  final Map<int, String> _answers = {};
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showQuestionGrid = false;

  // Immediate feedback toggle
  bool _immediateFeedback = true;
  final Map<int, bool> _answerResults = {};

  // Timer support
  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
  bool _hasTimer = false;

  String _quizTitle = '';

  @override
  void initState() {
    super.initState();
    _quizTitle = widget.title;
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    if (minutes <= 0) return;
    _timer?.cancel();
    _totalSeconds = minutes * 60;
    _secondsRemaining = _totalSeconds;
    _hasTimer = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time is Up! ⏰'),
        content: const Text(
          'The time limit for this quiz has expired. Your answers will now be submitted automatically.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitQuiz(force: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  String _formatTimer() {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      // Offline cached quizzes remain readable even if auth is temporarily
      // unavailable; signed-in users additionally get their Isar download path.
      String? userId;
      try {
        userId = FirebaseAuth.instance.currentUser?.uid;
      } catch (e) {
        debugPrint('⚠️ Auth unavailable while loading quiz: $e');
      }

      Map<String, dynamic>? quizData;
      String? localFilePath;

      // 1. Check local Isar records
      if (userId != null) {
        final downloaded = await _isarService.getDownloadedContentById(
          widget.contentId,
          userId,
        );
        if (downloaded?.contentPath != null) {
          final file = File(downloaded!.contentPath!);
          if (await file.exists()) {
            localFilePath = downloaded.contentPath;
          }
        }
      }

      // 2. Check local json_content storage directory
      if (localFilePath == null) {
        final directory = await getApplicationDocumentsDirectory();
        final possible = '${directory.path}/json_content/${widget.contentId}.json';
        if (await File(possible).exists()) {
          localFilePath = possible;
        }
      }

      // 3. Read from local file if found
      if (localFilePath != null) {
        final file = File(localFilePath);
        final content = await file.readAsString();
        quizData = json.decode(content.replaceFirst('\uFEFF', ''))
            as Map<String, dynamic>;
      }

      // 4. If not stored locally, fetch live from GitHub / downloadUrl
      if (quizData == null && widget.downloadUrl != null && widget.downloadUrl!.isNotEmpty) {
        try {
          debugPrint('🌐 Fetching quiz JSON from URL: ${widget.downloadUrl}');
          final res = await _dio.get<String>(widget.downloadUrl!);
          if (res.data != null) {
            quizData = json.decode(res.data!.replaceFirst('\uFEFF', ''))
                as Map<String, dynamic>;
            // Cache locally for offline use
            final directory = await getApplicationDocumentsDirectory();
            final jsonDir = Directory('${directory.path}/json_content');
            if (!await jsonDir.exists()) await jsonDir.create(recursive: true);
            final cachedPath = '${jsonDir.path}/${widget.contentId}.json';
            await File(cachedPath).writeAsString(res.data!);
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching live quiz: $e');
        }
      }

      if (quizData != null) {
        _parseQuizData(quizData);
        return;
      }

      // If still not found
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load quiz content. Please connect to the internet or download it first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading quiz: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _parseQuizData(Map<String, dynamic> data) {
    final parsed = QuizContentParser.parse(
      data,
      fallbackTitle: widget.title,
      expectedTimeLimitMinutes: widget.expectedTimeLimitMinutes,
    );

    if (parsed.timeLimitMinutes > 0) {
      _startTimer(parsed.timeLimitMinutes);
    }

    if (mounted) {
      setState(() {
        _quizTitle = parsed.title;
        _questions = parsed.questions;
        _totalQuestions = parsed.questions.length;
        _isLoading = false;
      });
    }

    if (parsed.questions.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quiz file contains no questions.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _selectAnswer(String answerText) {
    if (_answers[_currentQuestion] != null) return; // Already answered

    setState(() {
      _selectedAnswer = answerText;
      _answers[_currentQuestion] = answerText;

      if (_immediateFeedback && _currentQuestion <= _questions.length) {
        final question = _questions[_currentQuestion - 1];
        final correctAnswer = QuizContentParser.correctAnswerText(question);
        _answerResults[_currentQuestion] = (answerText == correctAnswer);
      }
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
      _showQuestionGrid = false;
    });
  }

  Future<void> _submitQuiz({bool force = false}) async {
    final unanswered = _totalQuestions - _answers.length;
    if (!force && unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Quiz?'),
          content: Text(
            'You have $unanswered unanswered question(s). Unanswered questions will be scored as incorrect. Are you sure you want to finish?',
          ),
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

    _timer?.cancel();
    setState(() => _isSubmitting = true);

    final score = QuizContentParser.computeScore(
      questions: _questions,
      answers: _answers,
    );

    final timeTaken = _hasTimer ? (_totalSeconds - _secondsRemaining) : 0;

    // Persist result in Isar for progress tracking
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final result = QuizContentParser.buildResult(
          userId: user.uid,
          quizId: widget.contentId,
          quizTitle: _quizTitle,
          questions: _questions,
          answers: _answers,
          timeTaken: timeTaken,
        );

        await _isarService.saveQuizResult(result);
      }
    } catch (e) {
      debugPrint('⚠️ Error saving quiz result: $e');
    }

    if (mounted) {
      context.pushReplacement('/quiz-result', extra: {
        'score': score.correct,
        'total': score.totalQuestions,
        'correct': score.correct,
        'wrong': score.wrong,
        'timeTaken': timeTaken,
        'title': _quizTitle,
        'contentId': widget.contentId,
        'questions': _questions,
        'userAnswers': _answers,
        'correctAnswers': score.correctAnswers,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text('No questions found in this quiz.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final currentQ = _questions[_currentQuestion - 1];
    final questionText = currentQ['question']?.toString() ?? currentQ['text']?.toString() ?? '';
    final options = QuizContentParser.optionTexts(currentQ);
    final correctAnswer = QuizContentParser.correctAnswerText(currentQ);
    final isAnswered = _answers[_currentQuestion] != null;
    final explanation = currentQ['explanation']?.toString();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _quizTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          // Timer Widget
          if (_hasTimer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondsRemaining < 60 ? Colors.red[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _secondsRemaining < 60 ? Colors.red : AppColors.primary,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: _secondsRemaining < 60 ? Colors.red : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimer(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining < 60 ? Colors.red : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Question Grid toggle
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Question Overview',
            onPressed: () => setState(() => _showQuestionGrid = !_showQuestionGrid),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: _totalQuestions > 0 ? _currentQuestion / _totalQuestions : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),

            // Main Content Area
            Expanded(
              child: _showQuestionGrid
                  ? _buildQuestionGrid()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question numbering & status row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Question $_currentQuestion of $_totalQuestions',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              if (isAnswered && _immediateFeedback)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (_answers[_currentQuestion] == correctAnswer)
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        (_answers[_currentQuestion] == correctAnswer)
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 14,
                                        color: (_answers[_currentQuestion] == correctAnswer)
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (_answers[_currentQuestion] == correctAnswer)
                                            ? 'Correct'
                                            : 'Incorrect',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: (_answers[_currentQuestion] == correctAnswer)
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Question Text Card
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                questionText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Answer choices
                          ...options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final optionText = entry.value;
                            final optionLabel = String.fromCharCode(65 + idx);
                            final isSelected = _selectedAnswer == optionText ||
                                _answers[_currentQuestion] == optionText;
                            final isCorrect = optionText == correctAnswer;

                            Color cardBorder = Colors.grey.shade300;
                            Color cardBg = Colors.white;
                            Color textCol = Colors.black87;

                            if (isAnswered && _immediateFeedback) {
                              if (isCorrect) {
                                cardBorder = Colors.green;
                                cardBg = Colors.green.withOpacity(0.08);
                                textCol = Colors.green.shade800;
                              } else if (isSelected) {
                                cardBorder = Colors.red;
                                cardBg = Colors.red.withOpacity(0.08);
                                textCol = Colors.red.shade800;
                              }
                            } else if (isSelected) {
                              cardBorder = AppColors.primary;
                              cardBg = AppColors.primary.withOpacity(0.05);
                              textCol = AppColors.primary;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: isAnswered ? null : () => _selectAnswer(optionText),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder, width: isSelected ? 2 : 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        alignment: pwAlignmentCenter(isCorrect, isSelected, isAnswered),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isAnswered && !isCorrect ? Colors.red : AppColors.primary)
                                              : Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          optionLabel,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textCol,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Explanation (shown in immediate feedback or upon tap)
                          if (isAnswered && explanation != null && explanation.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.withOpacity(0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Explanation',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    explanation,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),

            // Bottom Navigation & Submit Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous button
                  OutlinedButton.icon(
                    onPressed: _currentQuestion > 1 ? _previousQuestion : null,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text('Prev'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const Spacer(),
                  // Next or Submit button
                  if (_currentQuestion < _totalQuestions)
                    ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _submitQuiz(),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Finish Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Alignment pwAlignmentCenter(bool isCorrect, bool isSelected, bool isAnswered) {
    return Alignment.center;
  }

  Widget _buildQuestionGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Question Navigator',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showQuestionGrid = false),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Close'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: _totalQuestions,
              itemBuilder: (context, index) {
                final qNum = index + 1;
                final isAnswered = _answers[qNum] != null;
                final isCurrent = qNum == _currentQuestion;

                return InkWell(
                  onTap: () => _jumpToQuestion(qNum),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primary
                          : isAnswered
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : isAnswered
                                ? AppColors.primary
                                : Colors.grey.shade300,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '$qNum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isCurrent
                            ? Colors.white
                            : isAnswered
                                ? AppColors.primary
                                : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}