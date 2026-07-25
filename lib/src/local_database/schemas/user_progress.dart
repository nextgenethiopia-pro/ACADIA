import 'package:isar/isar.dart';

part 'user_progress.g.dart';

@collection
class UserProgress {
  Id id = Isar.autoIncrement;
  @Index()
  String? userId;
  int totalStudyTime = 0;
  int lessonsCompleted = 0;
  int quizzesPassed = 0;
  double averageScore = 0.0;
  int currentStreak = 0;
  int longestStreak = 0;
  DateTime? lastStudyDate;
}
