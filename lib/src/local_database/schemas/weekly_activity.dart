import 'package:isar/isar.dart';

part 'weekly_activity.g.dart';

@collection
class WeeklyActivity {
  Id id = Isar.autoIncrement;
  String? userId;
  int? dayOfWeek;
  double? hoursStudied;
  DateTime? date;
}
