import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:acadia/src/local_database/isar_service.dart';

/// Progress Tracking Service
///
/// Tracks user learning progress including:
/// - Total study time
/// - Lessons completed
/// - Quizzes passed
/// - Average score
/// - Current streak
/// - Longest streak
/// - Subject progress
/// - Weekly activity
/// - Achievements
///
/// Data is stored locally in Isar and synced with Firebase when connected.
class ProgressTrackingService {
  final IsarService _isarService = IsarService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sync queue for offline activities
  final List<Map<String, dynamic>> _pendingSyncQueue = [];

  /// Initialize progress tracking for a new user
  Future<void> initializeUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _isarService.initializeUserProgress(user.uid);
    await _initializeUserDocument(user.uid);
  }

  /// Initialize user document in Firebase
  Future<void> _initializeUserDocument(String userId) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'progress': {
            'total_study_time': 0,
            'lessons_completed': 0,
            'quizzes_passed': 0,
            'average_score': 0.0,
            'current_streak': 0,
            'longest_streak': 0,
          },
          'created_at': FieldValue.serverTimestamp(),
          'last_sync': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error initializing user document: $e');
    }
  }

  /// Get all progress stats in one call (for Progress Tab)
  Future<Map<String, dynamic>> getAllStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final progress = await _isarService.getUserProgress(user.uid);
    final subjectProgress = await _isarService.getSubjectProgress(user.uid);
    final weeklyActivity = await _isarService.getWeeklyActivity(user.uid);
    final achievements = await _isarService.getAchievements(user.uid);

    // Calculate hours from seconds
    final totalSeconds = progress['total_study_time'] as int? ?? 0;
    final totalHours = totalSeconds / 3600;

    // Calculate completion percentages
    final lessonsCompleted = progress['lessons_completed'] as int? ?? 0;
    final quizzesPassed = progress['quizzes_passed'] as int? ?? 0;

    // Format weekly activity for chart
    final weeklyData = <String, double>{};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final activity in weeklyActivity) {
      final dayIndex = activity['day_of_week'] as int? ?? 0;
      if (dayIndex >= 1 && dayIndex <= 7) {
        weeklyData[days[dayIndex - 1]] =
            (activity['hours_studied'] as double? ?? 0);
      }
    }

    return {
      'total_study_hours': totalHours.toStringAsFixed(1),
      'total_study_seconds': totalSeconds,
      'lessons_completed': lessonsCompleted,
      'quizzes_passed': quizzesPassed,
      'average_score':
          (progress['average_score'] as double? ?? 0).toStringAsFixed(0),
      'current_streak': progress['current_streak'] ?? 0,
      'longest_streak': progress['longest_streak'] ?? 0,
      'last_study_date': progress['last_study_date'],
      'subject_progress': subjectProgress,
      'weekly_activity': weeklyData,
      'achievements': achievements,
      'total_lessons': await _getTotalLessons(),
      'total_quizzes': await _getTotalQuizzes(),
    };
  }

  /// Get total lessons available
  Future<int> _getTotalLessons() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final downloads = await _isarService.getAllDownloadedContent(user.uid);
    return downloads.length;
  }

  /// Get total quizzes available
  Future<int> _getTotalQuizzes() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final downloads = await _isarService.getAllDownloadedContent(user.uid);
    return downloads
        .where(
            (d) => d.contentType == 'quiz' || d.contentType == 'exam')
        .length;
  }

  /// Get user progress data
  Future<Map<String, dynamic>> getUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    return await _isarService.getUserProgress(user.uid);
  }

  /// Get progress for a specific subject
  Future<Map<String, dynamic>?> getSubjectProgressByName(String subject) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final progress = await _isarService.getSubjectProgress(user.uid);
    return progress.firstWhere(
      (p) => p['subject'] == subject,
      orElse: () => {},
    );
  }

  /// Record study time (in seconds)
  Future<void> recordStudyTime(int seconds) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _isarService.updateStudyTime(user.uid, seconds);

    // Record weekly activity (convert seconds to hours)
    final hours = seconds / 3600;
    await _isarService.recordWeeklyActivity(user.uid, hours);

    await _syncProgressToFirebase();
  }

  /// Mark a lesson as completed
  Future<void> completeLesson(String subject, int totalLessons) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _isarService.incrementLessonsCompleted(user.uid);
    await _isarService.updateSubjectProgress(user.uid, subject, totalLessons);
    await _syncProgressToFirebase();
  }

  /// Mark a chapter as completed
  Future<void> completeChapter(String chapterId, String subject) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _isarService.markChapterCompleted(user.uid, chapterId);
    await completeLesson(subject, 1); // Increment lesson count
  }

  /// Record quiz score (0-100)
  Future<void> recordQuizScore(int score) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _isarService.updateQuizScore(user.uid, score);
    await _syncProgressToFirebase();
  }

  /// Record exam score (0-100)
  Future<void> recordExamScore(int score) async {
    await recordQuizScore(score); // Same logic as quiz
  }

  /// Record weekly activity
  Future<void> recordWeeklyActivity(double hours) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _isarService.recordWeeklyActivity(user.uid, hours);
    await _syncProgressToFirebase();
  }

  /// Get subject progress list
  Future<List<Map<String, dynamic>>> getSubjectProgress() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return await _isarService.getSubjectProgress(user.uid);
  }

  /// Get weekly activity data for chart
  Future<Map<String, double>> getWeeklyActivityForChart() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final weeklyActivity = await _isarService.getWeeklyActivity(user.uid);
    final result = <String, double>{};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      result[days[i]] = 0.0;
    }

    for (final activity in weeklyActivity) {
      final dayIndex = activity['day_of_week'] as int? ?? 0;
      if (dayIndex >= 1 && dayIndex <= 7) {
        result[days[dayIndex - 1]] = activity['hours_studied'] as double? ?? 0;
      }
    }

    return result;
  }

  /// Get achievements list with unlock status
  Future<List<Map<String, dynamic>>> getAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return await _isarService.getAchievements(user.uid);
  }

  /// Get current streak
  Future<int> getCurrentStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final progress = await _isarService.getUserProgress(user.uid);
    return progress['current_streak'] as int? ?? 0;
  }

  /// Get longest streak
  Future<int> getLongestStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final progress = await _isarService.getUserProgress(user.uid);
    return progress['longest_streak'] as int? ?? 0;
  }

  /// Get overall completion percentage
  Future<double> getOverallCompletionPercentage() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    final progress = await _isarService.getUserProgress(user.uid);
    final lessonsCompleted = progress['lessons_completed'] as int? ?? 0;
    final totalLessons = await _getTotalLessons();

    if (totalLessons == 0) return 0.0;
    return lessonsCompleted / totalLessons;
  }

  /// Sync local progress to Firebase
  Future<void> _syncProgressToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final progress = await _isarService.getUserProgress(user.uid);
      final subjectProgress = await _isarService.getSubjectProgress(user.uid);
      final achievements = await _isarService.getAchievements(user.uid);

      await _firestore.collection('users').doc(user.uid).update({
        'progress': {
          'total_study_time': progress['total_study_time'] ?? 0,
          'lessons_completed': progress['lessons_completed'] ?? 0,
          'quizzes_passed': progress['quizzes_passed'] ?? 0,
          'average_score': progress['average_score'] ?? 0.0,
          'current_streak': progress['current_streak'] ?? 0,
          'longest_streak': progress['longest_streak'] ?? 0,
          'last_study_date': progress['last_study_date'],
        },
        'subject_progress': subjectProgress,
        'achievements': achievements,
        'last_sync': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Add to pending sync queue for later retry
      _addToPendingSyncQueue();
      debugPrint('Progress sync failed: $e');
    }
  }

  /// Add current progress to pending sync queue
  void _addToPendingSyncQueue() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final progress = await _isarService.getUserProgress(user.uid);
    _pendingSyncQueue.add({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'progress': progress,
    });
  }

  /// Retry pending syncs
  Future<void> retryPendingSyncs() async {
    if (_pendingSyncQueue.isEmpty) return;

    for (final item in _pendingSyncQueue) {
      try {
        final user = _auth.currentUser;
        if (user == null) continue;

        await _firestore.collection('users').doc(user.uid).update({
          'progress': item['progress'],
          'last_sync': FieldValue.serverTimestamp(),
        });
        _pendingSyncQueue.remove(item);
      } catch (e) {
        debugPrint('Retry sync failed: $e');
      }
    }
  }

  /// Sync progress from Firebase to local database (on new device login)
  Future<void> syncProgressFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      // TODO: Implement restore progress from Firebase to local Isar
      // Restore subject progress
      final subjectProgress = data['subject_progress'] as List? ?? [];
      for (final subject in subjectProgress) {
        await _isarService.updateSubjectProgress(
          user.uid,
          subject['subject'] as String,
          subject['total_lessons'] as int,
          lessonsCompleted: subject['lessons_completed'] as int,
        );
      }
    } catch (e) {
      debugPrint('Progress sync from Firebase failed: $e');
    }
  }

  /// Reset progress for a user (for testing or user request)
  Future<void> resetProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _isarService.clearUserData(user.uid);
    await initializeUserProgress();
    await _syncProgressToFirebase();
  }

  /// Get total storage used for downloaded content (in MB)
  Future<double> getTotalStorageUsedMB() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;
    final bytes = await _isarService.getTotalStorageUsed(user.uid);
    return bytes / (1024 * 1024);
  }

  /// Get downloaded content count
  Future<int> getDownloadedContentCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final downloads = await _isarService.getAllDownloadedContent(user.uid);
    return downloads.length;
  }

  /// Check if content is downloaded
  Future<bool> isContentDownloaded(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return await _isarService.isContentDownloaded(contentId, user.uid);
  }
}
