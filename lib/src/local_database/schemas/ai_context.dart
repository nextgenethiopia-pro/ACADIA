import 'package:isar/isar.dart';

part 'ai_context.g.dart';

@collection
class AIContext {
  Id id = Isar.autoIncrement;
  String? userId;
  String? topic;
  String? question;
  String? answer;
  int relevanceScore = 0;
  DateTime? createdAt;
}
