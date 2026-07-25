import 'package:isar/isar.dart';
import 'question_answer.dart';

part 'exam_result.g.dart';

@collection
class ExamResult {
  Id id = Isar.autoIncrement;
  String? userId;
  String? examId;
  String? examTitle;
  String? subject;
  String? grade;
  String? chapter;
  List<QuestionAnswer> answers = [];
  int score = 0;
  int totalQuestions = 0;
  int correctCount = 0;
  int wrongCount = 0;
  int unansweredCount = 0;
  double percentage = 0.0;
  int timeTaken = 0;
  bool passed = false;
  bool autoSubmitted = false;
  DateTime? createdAt;
}
