import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final String id;
  final String name;
  final String color;
  final String? iconAssetPath;
  final int chapterCount;
  final double progress;
  final bool isLocked;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.color,
    this.iconAssetPath,
    required this.chapterCount,
    this.progress = 0.0,
    this.isLocked = false,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['subject']?.toString() ?? '',
      color: json['color']?.toString() ?? '#607D8B',
      iconAssetPath: json['icon_asset_path']?.toString() ?? json['icon_url']?.toString(),
      chapterCount: json['chapter_count'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  factory SubjectModel.fromName(String name, {required String color, int chapterCount = 0}) {
    return SubjectModel(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      color: color,
      chapterCount: chapterCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon_asset_path': iconAssetPath,
      'chapter_count': chapterCount,
      'progress': progress,
      'is_locked': isLocked,
    };
  }

  @override
  List<Object?> get props => [id, name, color, chapterCount, progress, isLocked];
}