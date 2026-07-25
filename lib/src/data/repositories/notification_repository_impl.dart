import '../../core/services/firebase_service.dart';
import '../../domain/repositories/notification_repository.dart';

/// [NotificationRepository] implementation delegating to [FirebaseService].
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._service);

  final FirebaseService _service;

  @override
  Future<void> createNotification({
    required String title,
    required String message,
    String? targetUserId,
    String? targetGrade,
    required String type,
  }) =>
      _service.createNotification(
        title: title,
        message: message,
        targetUserId: targetUserId,
        targetGrade: targetGrade,
        type: type,
      );

  @override
  Future<List<Map<String, dynamic>>> getUserNotifications() =>
      _service.getUserNotifications();

  @override
  Future<void> markNotificationRead(String notificationId) =>
      _service.markNotificationRead(notificationId);
}
