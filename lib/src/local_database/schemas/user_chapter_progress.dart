import 'package:isar/isar.dart';

part 'user_chapter_progress.g.dart';

@collection
class UserChapterProgress {
  Id id = Isar.autoIncrement;
  String? userId;
  String? chapterId;
  bool? isCompleted;
  DateTime? completedAt;
}
