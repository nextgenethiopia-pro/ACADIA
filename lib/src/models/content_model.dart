import 'package:equatable/equatable.dart';

DateTime? _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is DateTime) return timestamp;
  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
  try {
    return timestamp.toDate();
  } catch (e) {
    return null;
  }
}

enum ContentType { video, shortNote, quiz, exam, flashcard, pastPaper }

class ContentModel extends Equatable {
  final String id;
  final String chapterId;
  final String title;
  final ContentType type;
  final String? downloadUrl;
  final String? description;
  final int? durationSeconds;
  final int? pageCount;
  final int? totalQuestions;
  final int? totalCards;
  final int? timeLimitMinutes;
  final int downloadCount;
  final bool isCompleted;
  final bool isFree;
  final bool isDownloaded;
  final DateTime? uploadDate;

  const ContentModel({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.type,
    this.downloadUrl,
    this.description,
    this.durationSeconds,
    this.pageCount,
    this.totalQuestions,
    this.totalCards,
    this.timeLimitMinutes,
    this.downloadCount = 0,
    this.isCompleted = false,
    this.isFree = false,
    this.isDownloaded = false,
    this.uploadDate,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? json['chapter']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: _parseContentType(json['content_type']?.toString() ?? json['type']?.toString() ?? ''),
      downloadUrl: json['download_url']?.toString() ?? json['cloud_storage_url']?.toString(),
      description: json['description']?.toString(),
      durationSeconds: json['duration_seconds'] as int? ?? json['duration'] as int?,
      pageCount: json['page_count'] as int?,
      totalQuestions: json['total_questions'] as int? ?? json['question_count'] as int?,
      totalCards: json['total_cards'] as int?,
      timeLimitMinutes: json['time_limit_minutes'] as int?,
      downloadCount: json['download_count'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      isFree: json['free_content'] as bool? ?? json['is_free'] as bool? ?? false,
      isDownloaded: json['is_downloaded'] as bool? ?? false,
      uploadDate: _parseTimestamp(json['upload_date'] ?? json['created_at']),
    );
  }

  static ContentType _parseContentType(String type) {
    switch (type.toLowerCase()) {
      case 'video': return ContentType.video;
      case 'short_note': return ContentType.shortNote;
      case 'quiz': return ContentType.quiz;
      case 'exam': return ContentType.exam;
      case 'flashcard': return ContentType.flashcard;
      case 'past_paper': return ContentType.pastPaper;
      default: return ContentType.video;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'title': title,
      'content_type': type.name,
      'download_url': downloadUrl,
      'description': description,
      'duration_seconds': durationSeconds,
      'page_count': pageCount,
      'total_questions': totalQuestions,
      'total_cards': totalCards,
      'time_limit_minutes': timeLimitMinutes,
      'download_count': downloadCount,
      'is_completed': isCompleted,
      'free_content': isFree,
      'is_downloaded': isDownloaded,
      'upload_date': uploadDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, chapterId, title, type, isCompleted, isDownloaded];
}