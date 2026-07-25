import 'package:isar/isar.dart';

part 'flashcard_progress.g.dart';

@collection
class FlashcardProgress {
  Id id = Isar.autoIncrement;
  String? userId;
  String? deckId;
  String? cardId;
  bool mastered = false;
  int reviewCount = 0;
  int correctCount = 0;
  int wrongCount = 0;
  DateTime? lastReviewed;
}
