import 'package:isar/isar.dart';

part 'downloaded_content.g.dart';

@collection
class DownloadedContent {
  Id id = Isar.autoIncrement;
  String? userId;
  String? contentId;
  String? title;
  String? contentPath;
  String? contentType;
  String? subject;
  String? grade;
  String? chapter;
  int? pageCount;
  int? totalQuestions;
  int? totalCards;
  double downloadProgress = 0.0;
  bool isDownloaded = false;
  bool isCompleted = false;
  int fileSize = 0;
  DateTime? downloadedAt;
  DateTime? lastAccessed;
}
