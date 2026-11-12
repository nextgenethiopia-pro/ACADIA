import '../../domain/repositories/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// [ProgressRepository] implementation backed by local shared preferences.
/// Progress is stored locally only, never uploaded to Firestore.
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl();

  @override
  Future<void> saveUnitProgress({
    required String unitName,
    required String subjectId,
    required double progress,
    required bool isCompleted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'progress_${subjectId}_$unitName';
    final encoded = json.encode({
      'unit_name': unitName,
      'subject_id': subjectId,
      'progress': progress,
      'is_completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(key, encoded);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('progress_'));
    final List<Map<String, dynamic>> allProgress = [];
    for (final key in keys) {
      final str = prefs.getString(key);
      if (str != null) {
        try {
          final map = json.decode(str) as Map<String, dynamic>;
          allProgress.add(map);
        } catch (_) {}
      }
    }
    return allProgress;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserActivity() async {
    // Activity tracking is local-only via OfflineDatabase
    return [];
  }

  @override
  Future<void> logActivity(String action, String details) async {
    // Activity logging is local-only via OfflineDatabase
    // No-op for now as activity is tracked in OfflineDatabase separately
  }

  @override
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    // Achievements are stored in OfflineDatabase
    return [];
  }

  @override
  Future<Map<String, int>> getWeeklyActivity() async {
    // Weekly activity is stored in OfflineDatabase
    return {};
  }
}
