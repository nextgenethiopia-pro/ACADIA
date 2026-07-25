import 'package:isar/isar.dart';

part 'question_answer.g.dart';

@embedded
class QuestionAnswer {
  int? questionId;
  int? selectedAnswer;
  bool? isCorrect;
  String? explanation;
}
