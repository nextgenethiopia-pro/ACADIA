/// Contract for user study progress, activity, and achievements.
///
/// Implemented by [ProgressRepositoryImpl] over `FirebaseService`.
abstract class ProgressRepository {
  /// Saves per-unit progress for the current user.
  Future<void> saveUnitProgress({
    required String unitName,
    required String subjectId,
    required double progress,
    required bool isCompleted,
  });

  /// All progress records for the current user.
  Future<List<Map<String, dynamic>>> getUserProgress();

  /// Recent activity log (most recent first).
  Future<List<Map<String, dynamic>>> getUserActivity();

  /// Appends an activity log entry.
  Future<void> logActivity(String action, String details);

  /// Earned achievements for the current user.
  Future<List<Map<String, dynamic>>> getUserAchievements();

  /// Activity counts keyed by day for the last week.
  Future<Map<String, int>> getWeeklyActivity();
}
