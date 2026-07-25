import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'schemas/schemas.dart';

class IsarService {
  IsarService._internal();
  static final IsarService instance = IsarService._internal();

  Isar? _isar;

  Future<Isar> get isar async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    _isar = await _initIsar();
    return _isar!;
  }

  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [
        UserProgressSchema,
        DownloadedContentSchema,
        QuizResultSchema,
        ExamResultSchema,
        FlashcardProgressSchema,
        StudyStreakSchema,
        ContentCacheSchema,
        AIContextSchema,
        WeeklyActivitySchema,
        SubjectProgressSchema,
        AchievementSchema,
        ChapterSchema,
        UserChapterProgressSchema,
        ContentEntrySchema,
      ],
      directory: dir.path,
      name: 'acadia_isar',
    );
  }

  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }

  // ===========================================
  // UserProgress Methods (matches OfflineDatabase)
  // ===========================================
  Future<void> initializeUserProgress(String userId) async {
    final db = await isar;
    await db.writeTxn(() async {
      // Create or update UserProgress
      final existing =
          await db.userProgress.filter().userIdEqualTo(userId).findFirst();
      if (existing == null) {
        await db.userProgress.put(UserProgress()
          ..userId = userId
          ..totalStudyTime = 0
          ..lessonsCompleted = 0
          ..quizzesPassed = 0
          ..averageScore = 0.0
          ..currentStreak = 0
          ..longestStreak = 0);
      }
      // Initialize achievements
      const badges = [
        'First Steps',
        'Perfect Week',
        'Quiz Master',
        'Dedicated'
      ];
      for (final badge in badges) {
        final existingAchievement = await db.achievements
            .filter()
            .userIdEqualTo(userId)
            .and()
            .badgeNameEqualTo(badge)
            .findFirst();
        if (existingAchievement == null) {
          await db.achievements.put(Achievement()
            ..userId = userId
            ..badgeName = badge
            ..isUnlocked = false);
        }
      }
    });
  }

  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final db = await isar;
    final progress =
        await db.userProgress.filter().userIdEqualTo(userId).findFirst();
    if (progress == null) return {};
    return {
      'total_study_time': progress.totalStudyTime,
      'lessons_completed': progress.lessonsCompleted,
      'quizzes_passed': progress.quizzesPassed,
      'average_score': progress.averageScore,
      'current_streak': progress.currentStreak,
      'longest_streak': progress.longestStreak,
      'last_study_date': progress.lastStudyDate?.toIso8601String(),
    };
  }

  Future<void> updateStudyTime(String userId, int seconds) async {
    final db = await isar;
    await db.writeTxn(() async {
      final progress =
          await db.userProgress.filter().userIdEqualTo(userId).findFirst();
      if (progress != null) {
        progress.totalStudyTime += seconds;
        progress.lastStudyDate = DateTime.now();
        await db.userProgress.put(progress);
      }
    });
    await updateStreak(userId);
  }

  Future<void> updateStreak(String userId) async {
    final db = await isar;
    final progress =
        await db.userProgress.filter().userIdEqualTo(userId).findFirst();
    if (progress == null) return;

    final lastStudyDateStr = progress.lastStudyDate?.toIso8601String();
    if (lastStudyDateStr != null) {
      final lastDate = DateTime.parse(lastStudyDateStr).toLocal();
      final today = DateTime.now().toLocal();
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        final newStreak = progress.currentStreak + 1;
        final newLongest = newStreak > progress.longestStreak
            ? newStreak
            : progress.longestStreak;
        await db.writeTxn(() async {
          progress.currentStreak = newStreak;
          progress.longestStreak = newLongest;
          await db.userProgress.put(progress);
        });
        if (newStreak >= 7) {
          await unlockAchievement(userId, 'Perfect Week');
        }
      } else if (difference > 1) {
        await db.writeTxn(() async {
          progress.currentStreak = 1;
          await db.userProgress.put(progress);
        });
      }
    }
  }

  Future<void> incrementLessonsCompleted(String userId) async {
    final db = await isar;
    await db.writeTxn(() async {
      final progress =
          await db.userProgress.filter().userIdEqualTo(userId).findFirst();
      if (progress != null) {
        progress.lessonsCompleted += 1;
        await db.userProgress.put(progress);
      }
    });
    // Check for First Steps achievement
    final currentProgress = await getUserProgress(userId);
    if ((currentProgress['lessons_completed'] as int? ?? 0) >= 1) {
      await unlockAchievement(userId, 'First Steps');
    }
  }

  Future<void> updateQuizScore(String userId, int score) async {
    final db = await isar;
    final currentProgress = await getUserProgress(userId);
    final currentAvg = currentProgress['average_score'] as double? ?? 0.0;
    final currentQuizzesPassed = currentProgress['quizzes_passed'] as int? ?? 0;

    final newAvg = ((currentAvg * currentQuizzesPassed) + score) /
        (currentQuizzesPassed + 1);
    await db.writeTxn(() async {
      final progress =
          await db.userProgress.filter().userIdEqualTo(userId).findFirst();
      if (progress != null) {
        progress.averageScore = newAvg;
        progress.quizzesPassed = currentQuizzesPassed + 1;
        await db.userProgress.put(progress);
      }
    });
    await updateStreak(userId);
    // Check for Quiz Master (10 quizzes passed)
    if ((currentQuizzesPassed + 1) >= 10) {
      await unlockAchievement(userId, 'Quiz Master');
    }
  }

  // ===========================================
  // SubjectProgress Methods
  // ===========================================
  Future<List<Map<String, dynamic>>> getSubjectProgress(String userId) async {
    final db = await isar;
    final subjects =
        await db.subjectProgress.filter().userIdEqualTo(userId).findAll();
    return subjects
        .map((s) => {
              'subject': s.subject,
              'lessons_completed': s.lessonsCompleted,
              'total_lessons': s.totalLessons,
              'completion_percentage': s.completionPercentage,
            })
        .toList();
  }

  Future<void> updateSubjectProgress(
      String userId, String subject, int totalLessons,
      {int? lessonsCompleted}) async {
    final db = await isar;
    await db.writeTxn(() async {
      final existing = await db.subjectProgress
          .filter()
          .userIdEqualTo(userId)
          .and()
          .subjectEqualTo(subject)
          .findFirst();
      if (existing != null) {
        final completed =
            lessonsCompleted ?? (existing.lessonsCompleted ?? 0) + 1;
        existing.lessonsCompleted = completed;
        existing.totalLessons = totalLessons;
        existing.completionPercentage = (completed / totalLessons) * 100;
        await db.subjectProgress.put(existing);
      } else {
        final completed = lessonsCompleted ?? 1;
        await db.subjectProgress.put(SubjectProgress()
          ..userId = userId
          ..subject = subject
          ..lessonsCompleted = completed
          ..totalLessons = totalLessons
          ..completionPercentage = (completed / totalLessons) * 100);
      }
    });
    // Check for Dedicated (50 hours study time)
    final up = await getUserProgress(userId);
    if ((up['total_study_time'] as int? ?? 0) >= 180000) {
      await unlockAchievement(userId, 'Dedicated');
    }
  }

  // ===========================================
  // WeeklyActivity Methods
  // ===========================================
  Future<void> recordWeeklyActivity(String userId, double hours) async {
    final db = await isar;
    final now = DateTime.now().toLocal();
    final dateStr = DateTime(now.year, now.month, now.day).toIso8601String();
    final dayOfWeek = now.weekday;

    await db.writeTxn(() async {
      final existing = await db.weeklyActivitys
          .filter()
          .userIdEqualTo(userId)
          .and()
          .dateEqualTo(DateTime.parse(dateStr))
          .findFirst();
      if (existing != null) {
        existing.hoursStudied = hours;
        await db.weeklyActivitys.put(existing);
      } else {
        await db.weeklyActivitys.put(WeeklyActivity()
          ..userId = userId
          ..dayOfWeek = dayOfWeek
          ..hoursStudied = hours
          ..date = DateTime.parse(dateStr));
      }
    });
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivity(String userId) async {
    final db = await isar;
    final weekAgo = DateTime.now().toLocal().subtract(const Duration(days: 7));
    final activities = await db.weeklyActivitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .dateGreaterThan(weekAgo)
        .findAll();

    return activities
        .map((a) => {
              'day_of_week': a.dayOfWeek,
              'hours_studied': a.hoursStudied,
              'date': a.date?.toIso8601String(),
            })
        .toList();
  }

  // ===========================================
  // Achievements Methods
  // ===========================================
  Future<List<Map<String, dynamic>>> getAchievements(String userId) async {
    final db = await isar;
    final achievements =
        await db.achievements.filter().userIdEqualTo(userId).findAll();
    return achievements
        .map((a) => {
              'badge_name': a.badgeName,
              'is_unlocked': a.isUnlocked,
              'unlocked_date': a.unlockedDate?.toIso8601String(),
            })
        .toList();
  }

  Future<void> unlockAchievement(String userId, String badgeName) async {
    final db = await isar;
    final achievement = await db.achievements
        .filter()
        .userIdEqualTo(userId)
        .and()
        .badgeNameEqualTo(badgeName)
        .findFirst();
    if (achievement != null && !(achievement.isUnlocked ?? false)) {
      await db.writeTxn(() async {
        achievement.isUnlocked = true;
        achievement.unlockedDate = DateTime.now();
        await db.achievements.put(achievement);
      });
    }
  }

  // ===========================================
  // Chapter Methods
  // ===========================================
  Future<void> saveChapter(Map<String, dynamic> chapterData) async {
    final db = await isar;
    await db.writeTxn(() async {
      final chapter = Chapter()
        ..chapterId = chapterData['id'] as String?
        ..subject = chapterData['subject'] as String?
        ..grade = chapterData['grade'] as String?
        ..name = chapterData['name'] as String?
        ..createdAt = chapterData['created_at'] != null
            ? DateTime.tryParse(chapterData['created_at'] as String)
            : null;
      await db.chapters.put(chapter);
    });
  }

  Future<List<Map<String, dynamic>>> getChapters(
      String subject, String grade) async {
    final db = await isar;
    final chapters = await db.chapters
        .filter()
        .subjectEqualTo(subject)
        .and()
        .gradeEqualTo(grade)
        .sortByName()
        .findAll();
    return chapters
        .map((c) => {
              'id': c.chapterId,
              'subject': c.subject,
              'grade': c.grade,
              'name': c.name,
              'created_at': c.createdAt?.toIso8601String(),
            })
        .toList();
  }

  // ===========================================
  // UserChapterProgress Methods
  // ===========================================
  Future<void> markChapterCompleted(String userId, String chapterId) async {
    final db = await isar;
    await db.writeTxn(() async {
      final existing = await db.userChapterProgress
          .filter()
          .userIdEqualTo(userId)
          .and()
          .chapterIdEqualTo(chapterId)
          .findFirst();
      if (existing != null) {
        existing.isCompleted = true;
        existing.completedAt = DateTime.now();
        await db.userChapterProgress.put(existing);
      } else {
        await db.userChapterProgress.put(UserChapterProgress()
          ..userId = userId
          ..chapterId = chapterId
          ..isCompleted = true
          ..completedAt = DateTime.now());
      }
    });
  }

  Future<bool> isChapterCompleted(String userId, String chapterId) async {
    final db = await isar;
    final progress = await db.userChapterProgress
        .filter()
        .userIdEqualTo(userId)
        .and()
        .chapterIdEqualTo(chapterId)
        .and()
        .isCompletedEqualTo(true)
        .findFirst();
    return progress != null;
  }

  Future<int> getCompletedChaptersCount(String userId, String subject) async {
    final db = await isar;
    final chapterIds =
        (await db.chapters.filter().subjectEqualTo(subject).findAll())
            .map((c) => c.chapterId)
            .whereType<String>()
            .toList();
    final completed = await db.userChapterProgress
        .filter()
        .userIdEqualTo(userId)
        .and()
        .anyOf(chapterIds, (q, id) => q.chapterIdEqualTo(id))
        .and()
        .isCompletedEqualTo(true)
        .count();
    return completed;
  }

  // ===========================================
  // DownloadedContent Methods
  // ===========================================
  Future<void> saveDownloadedContent(DownloadedContent content) async {
    final db = await isar;
    await db.writeTxn(() async => await db.downloadedContents.put(content));
  }

  Future<DownloadedContent?> getDownloadedContentById(
      String contentId, String userId) async {
    final db = await isar;
    return await db.downloadedContents
        .filter()
        .contentIdEqualTo(contentId)
        .and()
        .userIdEqualTo(userId)
        .findFirst();
  }

  Future<bool> isContentDownloaded(String contentId, String userId) async {
    final db = await isar;
    final count = await db.downloadedContents
        .filter()
        .contentIdEqualTo(contentId)
        .and()
        .userIdEqualTo(userId)
        .and()
        .isDownloadedEqualTo(true)
        .count();
    return count > 0;
  }

  Future<List<DownloadedContent>> getAllDownloadedContent(String userId) async {
    final db = await isar;
    return await db.downloadedContents
        .filter()
        .userIdEqualTo(userId)
        .sortByDownloadedAtDesc()
        .findAll();
  }

  Future<List<DownloadedContent>> getDownloadedContentByType(
      String userId, String contentType) async {
    final db = await isar;
    return await db.downloadedContents
        .filter()
        .userIdEqualTo(userId)
        .and()
        .contentTypeEqualTo(contentType)
        .sortByDownloadedAtDesc()
        .findAll();
  }

  Future<int> getTotalStorageUsed(String userId) async {
    final db = await isar;
    final contents =
        await db.downloadedContents.filter().userIdEqualTo(userId).findAll();
    return contents.fold<int>(0, (sum, c) => sum + c.fileSize);
  }

  Future<void> deleteDownloadedContent(String contentId, String userId) async {
    final db = await isar;
    final content = await getDownloadedContentById(contentId, userId);
    if (content != null) {
      await db
          .writeTxn(() async => await db.downloadedContents.delete(content.id));
    }
  }

  Future<void> markContentCompleted(String contentId, String userId) async {
    final content = await getDownloadedContentById(contentId, userId);
    if (content != null) {
      // Note: DownloadedContent doesn't have isCompleted field, so we'll skip for now
    }
  }

  // ===========================================
  // QuizResult Methods
  // ===========================================
  Future<void> saveQuizResult(QuizResult result) async {
    final db = await isar;
    await db.writeTxn(() async => await db.quizResults.put(result));
  }

  Future<List<QuizResult>> getQuizResultsByUser(String userId) async {
    final db = await isar;
    return await db.quizResults
        .filter()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  // ===========================================
  // ExamResult Methods
  // ===========================================
  Future<void> saveExamResult(ExamResult result) async {
    final db = await isar;
    await db.writeTxn(() async => await db.examResults.put(result));
  }

  Future<List<ExamResult>> getExamResultsByUser(String userId) async {
    final db = await isar;
    return await db.examResults
        .filter()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  // ===========================================
  // FlashcardProgress Methods
  // ===========================================
  Future<void> saveFlashcardProgress(FlashcardProgress progress) async {
    final db = await isar;
    await db.writeTxn(() async => await db.flashcardProgress.put(progress));
  }

  Future<FlashcardProgress?> getFlashcardProgress(
      String userId, String deckId, String cardId) async {
    final db = await isar;
    return await db.flashcardProgress
        .filter()
        .userIdEqualTo(userId)
        .and()
        .deckIdEqualTo(deckId)
        .and()
        .cardIdEqualTo(cardId)
        .findFirst();
  }

  // ===========================================
  // StudyStreak Methods
  // ===========================================
  Future<void> saveStudyStreak(StudyStreak streak) async {
    final db = await isar;
    await db.writeTxn(() async => await db.studyStreaks.put(streak));
  }

  Future<StudyStreak?> getStudyStreakByUser(String userId) async {
    final db = await isar;
    return await db.studyStreaks.filter().userIdEqualTo(userId).findFirst();
  }

  // ===========================================
  // ContentCache Methods
  // ===========================================
  Future<void> saveContentCache(ContentCache cache) async {
    final db = await isar;
    await db.writeTxn(() async => await db.contentCaches.put(cache));
  }

  Future<ContentCache?> getContentCacheByUrl(String url) async {
    final db = await isar;
    return await db.contentCaches.filter().urlEqualTo(url).findFirst();
  }

  // ===========================================
  // ContentEntry Methods (offline-first cache)
  // Single source of truth for cached network payloads (GitHub catalog,
  // settings docs). Replaces ad-hoc SharedPreferences content caches.
  // ===========================================

  /// Returns the cached payload row for [key], or null if absent.
  Future<ContentEntry?> getContentEntry(String key) async {
    final db = await isar;
    return await db.contentEntrys.filter().keyEqualTo(key).findFirst();
  }

  /// Upserts a cache row by [key] (replaces payload if the key already exists).
  Future<void> putContentEntry(ContentEntry entry) async {
    final db = await isar;
    await db.writeTxn(() async {
      final existing =
          await db.contentEntrys.filter().keyEqualTo(entry.key).findFirst();
      if (existing != null) {
        entry.id = existing.id;
      }
      await db.contentEntrys.put(entry);
    });
  }

  /// Deletes a single cache row by [key].
  Future<void> deleteContentEntry(String key) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.contentEntrys.filter().keyEqualTo(key).deleteAll();
    });
  }

  /// Deletes every cache row whose key starts with [prefix]
  /// (e.g. all GitHub catalog rows on a content version bump).
  Future<void> deleteContentEntriesByPrefix(String prefix) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.contentEntrys.filter().keyStartsWith(prefix).deleteAll();
    });
  }

  /// Total number of cached payload rows (diagnostics / cache-size screen).
  Future<int> getContentEntryCount() async {
    final db = await isar;
    return await db.contentEntrys.count();
  }

  /// Removes every cache row regardless of source.
  Future<void> clearContentEntries() async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.contentEntrys.clear();
    });
  }

  // ===========================================
  // AIContext Methods
  // ===========================================
  Future<void> saveAIContext(AIContext context) async {
    final db = await isar;
    await db.writeTxn(() async => await db.aIContexts.put(context));
  }

  Future<List<AIContext>> getAIContextByUser(String userId) async {
    final db = await isar;
    return await db.aIContexts
        .filter()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  // ===========================================
  // Database Stats
  // ===========================================
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await isar;
    final contentCount = await db.downloadedContents.count();
    final totalStorageBytes =
        await getTotalStorageUsed(''); // Not ideal, but placeholder
    final userProgressCount = await db.userProgress.count();

    return {
      'content_count': contentCount,
      'storage_used_mb': totalStorageBytes / (1024 * 1024),
      'user_progress_count': userProgressCount,
    };
  }

  // ===========================================
  // Clear Data
  // ===========================================
  Future<void> clearUserData(String userId) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.userProgress.filter().userIdEqualTo(userId).deleteAll();
      await db.downloadedContents.filter().userIdEqualTo(userId).deleteAll();
      await db.quizResults.filter().userIdEqualTo(userId).deleteAll();
      await db.examResults.filter().userIdEqualTo(userId).deleteAll();
      await db.flashcardProgress.filter().userIdEqualTo(userId).deleteAll();
      await db.studyStreaks.filter().userIdEqualTo(userId).deleteAll();
      await db.aIContexts.filter().userIdEqualTo(userId).deleteAll();
      await db.weeklyActivitys.filter().userIdEqualTo(userId).deleteAll();
      await db.subjectProgress.filter().userIdEqualTo(userId).deleteAll();
      await db.achievements.filter().userIdEqualTo(userId).deleteAll();
      await db.userChapterProgress.filter().userIdEqualTo(userId).deleteAll();
    });
  }

  Future<void> clearAllData() async {
    final db = await isar;
    await db.writeTxn(() async => await db.clear());
  }
}
