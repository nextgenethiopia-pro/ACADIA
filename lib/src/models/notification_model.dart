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

enum NotificationType { payment, content, quiz, exam, achievement, system }

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['message']?.toString() ?? json['body']?.toString() ?? '',
      type: _parseNotificationType(json['type']?.toString() ?? ''),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'payment': return NotificationType.payment;
      case 'content': return NotificationType.content;
      case 'quiz': return NotificationType.quiz;
      case 'exam': return NotificationType.exam;
      case 'achievement': return NotificationType.achievement;
      case 'system': return NotificationType.system;
      default: return NotificationType.system;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, title, type, isRead];
}