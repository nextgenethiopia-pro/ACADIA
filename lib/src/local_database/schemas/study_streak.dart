import 'package:isar/isar.dart';

part 'study_streak.g.dart';

@collection
class StudyStreak {
  Id id = Isar.autoIncrement;
  String? userId;
  int currentStreak = 0;
  int longestStreak = 0;
  DateTime? lastStudyDate;
  List<DateTime> studyHistory = [];
  int totalStudyDays = 0;
}
