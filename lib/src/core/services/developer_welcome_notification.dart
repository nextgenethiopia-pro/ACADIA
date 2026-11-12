/// Idempotent developer welcome notification for newly created accounts.
///
/// The document ID is deterministic and user-scoped so retries can never
/// create a second developer message for the same account. The Firestore
/// existence check and write are injected to keep the guarantee testable
/// without a live Firebase project.
class DeveloperWelcomeNotification {
  static String documentId(String userId) => 'welcome_${userId.trim()}';

  /// Returns true when a new notification was written, false when one already
  /// existed (or the user ID was empty).
  static Future<bool> ensureCreated({
    required String userId,
    required Future<bool> Function(String documentId) exists,
    required Future<void> Function(String documentId) create,
  }) async {
    if (userId.trim().isEmpty) return false;
    final id = documentId(userId);
    if (await exists(id)) return false;
    await create(id);
    return true;
  }
}
