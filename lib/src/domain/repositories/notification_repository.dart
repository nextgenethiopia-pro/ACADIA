/// Contract for in-app notifications.
///
/// Implemented by [NotificationRepositoryImpl] over `FirebaseService`.
abstract class NotificationRepository {
  /// Creates a notification (broadcast or targeted by user/grade).
  Future<void> createNotification({
    required String title,
    required String message,
    String? targetUserId,
    String? targetGrade,
    required String type,
  });

  /// Notifications visible to the current user (newest first).
  Future<List<Map<String, dynamic>>> getUserNotifications();

  /// Marks a notification as read.
  Future<void> markNotificationRead(String notificationId);
}
