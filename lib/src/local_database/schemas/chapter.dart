import 'package:isar/isar.dart';

part 'chapter.g.dart';

@collection
class Chapter {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  String? chapterId;
  
  @Index()
  String? subject;
  
  @Index()
  String? grade;
  
  String? name;
  DateTime? createdAt;
}