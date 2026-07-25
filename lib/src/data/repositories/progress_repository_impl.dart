import '../../core/services/firebase_service.dart';
import '../../domain/repositories/progress_repository.dart';

/// [ProgressRepository] implementation delegating to [FirebaseService].
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._service);

  final FirebaseService _service;

  @override
  Future<void> saveUnitProgress({
    required String unitName,
    required String subjectId,
    required double progress,
    required bool isCompleted,
  }) =>
      _service.saveUnitProgress(
        unitName: unitName,
        subjectId: subjectId,
        progress: progress,
        isCompleted: isCompleted,
      );

  @override
  Future<List<Map<String, dynamic>>> getUserProgress() =>
      _service.getUserProgress();

  @override
  Future<List<Map<String, dynamic>>> getUserActivity() =>
      _service.getUserActivity();

  @override
  Future<void> logActivity(String action, String details) =>
      _service.logActivity(action, details);

  @override
  Future<List<Map<String, dynamic>>> getUserAchievements() =>
      _service.getUserAchievements();

  @override
  Future<Map<String, int>> getWeeklyActivity() => _service.getWeeklyActivity();
}
