import 'package:isar/isar.dart';

part 'chapter.g.dart';

@collection
class Chapter {
  Id id = Isar.autoIncrement;
  @Index(unique: true, composite: [CompositeIndex('subject'), CompositeIndex('grade'), CompositeIndex('name')])
  String? chapterId;
  String? subject;
  String? grade;
  String? name;
  DateTime? createdAt;
}
