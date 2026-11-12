import 'package:acadia/src/local_database/schemas/quiz_result.dart';

/// Pure parsing and scoring helpers for quiz JSON files.
///
/// Kept separate from the quiz screen so the schema handling can be exercised
/// deterministically without Firebase, Isar, or HTTP plugins.
class ParsedQuiz {
  const ParsedQuiz({
    required this.title,
    required this.questions,
    required this.timeLimitMinutes,
  });

  final String title;
  final List<Map<String, dynamic>> questions;
  final int timeLimitMinutes;
}

class QuizScore {
  const QuizScore({
    required this.correct,
    required this.wrong,
    required this.totalQuestions,
    required this.percentage,
    required this.passed,
    required this.correctAnswers,
  });

  final int correct;
  final int wrong;
  final int totalQuestions;
  final double percentage;
  final bool passed;
  final List<String> correctAnswers;
}

class QuizContentParser {
  static ParsedQuiz parse(
    Map<String, dynamic> data, {
    required String fallbackTitle,
    int? expectedTimeLimitMinutes,
  }) {
    final nestedItem = _nestedItem(data);
    final questions = _extractQuestions(data);

    final title = nestedItem?['title']?.toString() ??
        data['title']?.toString() ??
        fallbackTitle;

    final timeLimit = _asInt(data['time_limit_minutes']) ??
        _asInt(nestedItem?['time_limit_minutes']) ??
        expectedTimeLimitMinutes ??
        _asInt(data['time_limit']) ??
        _asInt(data['duration_minutes']) ??
        0;

    return ParsedQuiz(
      title: title,
      questions: questions,
      timeLimitMinutes: timeLimit,
    );
  }

  static Map<String, dynamic>? _nestedItem(Map<String, dynamic> data) {
    if (data['questions'] != null) return null;
    final items = data['items'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map && first.containsKey('questions')) {
        return Map<String, dynamic>.from(first);
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> _extractQuestions(
      Map<String, dynamic> data) {
    if (data['questions'] is List) {
      return (data['questions'] as List)
          .whereType<Map>()
          .map((q) => Map<String, dynamic>.from(q))
          .toList();
    }
    final items = data['items'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map && first['questions'] is List) {
        return (first['questions'] as List)
            .whereType<Map>()
            .map((q) => Map<String, dynamic>.from(q))
            .toList();
      }
      return items
          .whereType<Map>()
          .map((q) => Map<String, dynamic>.from(q))
          .toList();
    }
    return const [];
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String correctAnswerText(Map<String, dynamic> question) {
    final correctKey = question['correct_answer']?.toString() ??
        question['answer']?.toString() ??
        '';
    if (correctKey.isEmpty) return '';

    final options = question['options'];
    if (options is Map) {
      return options[correctKey]?.toString() ?? correctKey;
    }
    if (options is List) {
      final idx = correctKey.toUpperCase().codeUnitAt(0) - 65;
      if (idx >= 0 && idx < options.length) {
        return options[idx].toString();
      }
    }
    return correctKey;
  }

  static List<String> optionTexts(Map<String, dynamic> question) {
    final options = question['options'];
    if (options is Map) {
      return options.values.map((v) => v.toString()).toList();
    }
    if (options is List) {
      return options.map((v) => v.toString()).toList();
    }
    return const [];
  }

  static QuizScore computeScore({
    required List<Map<String, dynamic>> questions,
    required Map<int, String> answers,
  }) {
    final total = questions.length;
    final correctAnswers =
        questions.map(correctAnswerText).toList(growable: false);

    var correct = 0;
    for (var i = 0; i < total; i++) {
      final userAnswer = answers[i + 1];
      if (userAnswer != null && userAnswer == correctAnswers[i]) {
        correct++;
      }
    }

    final wrong = total - correct;
    final percentage = total > 0 ? (correct / total) * 100 : 0.0;

    return QuizScore(
      correct: correct,
      wrong: wrong,
      totalQuestions: total,
      percentage: percentage,
      passed: total > 0 && (correct / total) >= 0.6,
      correctAnswers: correctAnswers,
    );
  }

  static QuizResult buildResult({
    required String userId,
    required String quizId,
    required String quizTitle,
    required List<Map<String, dynamic>> questions,
    required Map<int, String> answers,
    required int timeTaken,
  }) {
    final score = computeScore(questions: questions, answers: answers);
    return QuizResult()
      ..userId = userId
      ..quizId = quizId
      ..quizTitle = quizTitle
      ..score = score.correct
      ..totalQuestions = score.totalQuestions
      ..percentage = score.percentage
      ..passed = score.passed
      ..timeTaken = timeTaken
      ..createdAt = DateTime.now();
  }
}
