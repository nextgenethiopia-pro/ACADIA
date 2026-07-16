import 'package:equatable/equatable.dart';

class ChapterModel extends Equatable {
  final String id;
  final String subjectId;
  final String title;
  final int unitNumber;
  final int contentCount;
  final double progress;
  final bool isCompleted;

  const ChapterModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.unitNumber,
    this.contentCount = 0,
    this.progress = 0.0,
    this.isCompleted = false,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      unitNumber: json['unit_number'] as int? ?? 1,
      contentCount: json['content_count'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'unit_number': unitNumber,
      'content_count': contentCount,
      'progress': progress,
      'is_completed': isCompleted,
    };
  }

  @override
  List<Object?> get props => [id, subjectId, title, unitNumber, progress, isCompleted];
}