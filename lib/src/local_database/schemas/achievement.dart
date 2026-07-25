import 'package:isar/isar.dart';

part 'achievement.g.dart';

@collection
class Achievement {
  Id id = Isar.autoIncrement;
  String? userId;
  String? badgeName;
  bool? isUnlocked;
  DateTime? unlockedDate;
}
