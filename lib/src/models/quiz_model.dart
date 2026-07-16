import 'package:equatable/equatable.dart';

class QuizModel extends Equatable {
  final String id;
  final String contentId;
  final String title;
  final List<QuestionModel> questions;
  final int timeLimitMinutes;
  final bool isCompleted;
  final int? score;
  final int? totalQuestions;

  const QuizModel({
    required this.id,
    required this.contentId,
    required this.title,
    required this.questions,
    this.timeLimitMinutes = 15,
    this.isCompleted = false,
    this.score,
    this.totalQuestions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final questionsList = json['questions'] as List<dynamic>? ?? [];
    return QuizModel(
      id: json['content_id']?.toString() ?? json['id']?.toString() ?? '',
      contentId: json['content_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      questions: questionsList.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList(),
      timeLimitMinutes: json['time_limit_minutes'] as int? ?? 15,
      totalQuestions: json['total_questions'] as int? ?? questionsList.length,
    );
  }

  factory QuizModel.fromLocalFile(Map<String, dynamic> data, String contentId) {
    final questionsList = data['questions'] as List<dynamic>? ?? [];
    return QuizModel(
      id: contentId,
      contentId: contentId,
      title: data['title']?.toString() ?? '',
      questions: questionsList.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList(),
      timeLimitMinutes: data['time_limit_minutes'] as int? ?? 15,
      totalQuestions: data['total_questions'] as int? ?? questionsList.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'title': title,
      'time_limit_minutes': timeLimitMinutes,
      'total_questions': totalQuestions ?? questions.length,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, contentId, title, questions.length, isCompleted, score];
}

class QuestionModel extends Equatable {
  final String id;
  final String questionText;
  final Map<String, String> options;
  final String correctAnswer;
  final String? explanation;

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Parse options — can be Map<String, String> or List<String>
    Map<String, String> optionsMap = {};
    final optionsData = json['options'];
    if (optionsData is Map) {
      optionsMap = optionsData.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (optionsData is List) {
      final labels = ['A', 'B', 'C', 'D'];
      for (int i = 0; i < optionsData.length && i < labels.length; i++) {
        optionsMap[labels[i]] = optionsData[i].toString();
      }
    }

    return QuestionModel(
      id: json['id']?.toString() ?? '',
      questionText: json['question']?.toString() ?? '',
      options: optionsMap,
      correctAnswer: json['correct_answer']?.toString() ?? json['correct']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
    };
  }

  List<String> get optionLabels => options.keys.toList()..sort();
  
  String? getOptionText(String label) => options[label];

  bool isCorrect(String answer) => answer == correctAnswer;

  @override
  List<Object?> get props => [id, questionText, options, correctAnswer];
}

class FlashcardModel extends Equatable {
  final String id;
  final String contentId;
  final String frontText;
  final String backText;
  final bool isMastered;

  const FlashcardModel({
    required this.id,
    required this.contentId,
    required this.frontText,
    required this.backText,
    this.isMastered = false,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id']?.toString() ?? '',
      contentId: json['content_id']?.toString() ?? '',
      frontText: json['front']?.toString() ?? json['question']?.toString() ?? '',
      backText: json['back']?.toString() ?? json['answer']?.toString() ?? '',
      isMastered: json['is_mastered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': frontText,
      'back': backText,
    };
  }

  @override
  List<Object?> get props => [id, contentId, frontText, backText, isMastered];
}