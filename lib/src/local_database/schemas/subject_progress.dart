import 'package:isar/isar.dart';

part 'subject_progress.g.dart';

@collection
class SubjectProgress {
  Id id = Isar.autoIncrement;
  String? userId;
  String? subject;
  int? lessonsCompleted;
  int? totalLessons;
  double? completionPercentage;
}
