import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'schemas/schemas.dart';

// ============================================
// FIX: Export schemas for other files
// ============================================
export 'schemas/schemas.dart';

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
  // UserProgress Methods
  // ===========================================
  Future<UserProgress> _getOrInitUserProgress(Isar db, String userId) async {
    var progress =
        await db.userProgress.filter().userIdEqualTo(userId).findFirst();
    if (progress == null) {
      progress = UserProgress()
        ..userId = userId
        ..totalStudyTime = 0
        ..lessonsCompleted = 0
        ..quizzesPassed = 0
        ..averageScore = 0.0
        ..currentStreak = 1
        ..longestStreak = 1
        ..lastStudyDate = DateTime.now();
      await db.userProgress.put(progress);

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
    }
    return progress;
  }

  Future<void> initializeUserProgress(String userId) async {
    final db = await isar;
    await db.writeTxn(() async {
      await _getOrInitUserProgress(db, userId);
    });
  }

  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final db = await isar;
    var progress =
        await db.userProgress.filter().userIdEqualTo(userId).findFirst();
    if (progress == null) {
      await db.writeTxn(() async {
        progress = await _getOrInitUserProgress(db, userId);
      });
    }
    return {
      'total_study_time': progress?.totalStudyTime ?? 0,
      'lessons_completed': progress?.lessonsCompleted ?? 0,
      'quizzes_passed': progress?.quizzesPassed ?? 0,
      'average_score': progress?.averageScore ?? 0.0,
      'current_streak': progress?.currentStreak ?? 1,
      'longest_streak': progress?.longestStreak ?? 1,
      'last_study_date': progress?.lastStudyDate?.toIso8601String(),
    };
  }

  Future<void> updateStudyTime(String userId, int seconds) async {
    final db = await isar;
    await db.writeTxn(() async {
      final progress = await _getOrInitUserProgress(db, userId);
      progress.totalStudyTime += seconds;
      progress.lastStudyDate = DateTime.now();
      await db.userProgress.put(progress);
    });
    await updateStreak(userId);
  }

  Future<void> updateStreak(String userId) async {
    final db = await isar;
    UserProgress? progress;
    await db.writeTxn(() async {
      progress = await _getOrInitUserProgress(db, userId);
      final lastStudyDateStr = progress?.lastStudyDate?.toIso8601String();
      if (lastStudyDateStr != null) {
        final lastDate = DateTime.parse(lastStudyDateStr).toLocal();
        final today = DateTime.now().toLocal();
        final difference = today.difference(lastDate).inDays;

        if (difference == 1) {
          final newStreak = (progress!.currentStreak) + 1;
          final newLongest = newStreak > progress!.longestStreak
              ? newStreak
              : progress!.longestStreak;
          progress!.currentStreak = newStreak;
          progress!.longestStreak = newLongest;
          await db.userProgress.put(progress!);
        } else if (difference > 1) {
          progress!.currentStreak = 1;
          await db.userProgress.put(progress!);
        } else if (progress!.currentStreak == 0) {
          progress!.currentStreak = 1;
          progress!.longestStreak =
              progress!.longestStreak < 1 ? 1 : progress!.longestStreak;
          await db.userProgress.put(progress!);
        }
      }
    });
    if ((progress?.currentStreak ?? 0) >= 7) {
      await unlockAchievement(userId, 'Perfect Week');
    }
  }

  Future<void> incrementLessonsCompleted(String userId) async {
    final db = await isar;
    await db.writeTxn(() async {
      final progress = await _getOrInitUserProgress(db, userId);
      progress.lessonsCompleted += 1;
      await db.userProgress.put(progress);
    });
    final currentProgress = await getUserProgress(userId);
    if ((currentProgress['lessons_completed'] as int? ?? 0) >= 1) {
      await unlockAchievement(userId, 'First Steps');
    }
  }

  Future<void> updateQuizScore(String userId, int score) async {
    final db = await isar;
    int updatedQuizzes = 0;
    await db.writeTxn(() async {
      final progress = await _getOrInitUserProgress(db, userId);
      final currentAvg = progress.averageScore;
      final currentQuizzesPassed = progress.quizzesPassed;
      final newAvg = ((currentAvg * currentQuizzesPassed) + score) /
          (currentQuizzesPassed + 1);
      progress.averageScore = newAvg;
      progress.quizzesPassed = currentQuizzesPassed + 1;
      updatedQuizzes = progress.quizzesPassed;
      await db.userProgress.put(progress);
    });
    await updateStreak(userId);
    if (updatedQuizzes >= 10) {
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
        // Study sessions on the same day accumulate instead of overwriting.
        existing.hoursStudied = (existing.hoursStudied ?? 0) + hours;
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
    var achievements =
        await db.achievements.filter().userIdEqualTo(userId).findAll();
    if (achievements.isEmpty) {
      await initializeUserProgress(userId);
      achievements =
          await db.achievements.filter().userIdEqualTo(userId).findAll();
    }
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
    await db.writeTxn(() async {
      // Re-downloading the same content must replace the previous record,
      // not append a duplicate row for the same contentId/user pair.
      if (content.contentId != null && content.userId != null) {
        final existing = await db.downloadedContents
            .filter()
            .contentIdEqualTo(content.contentId!)
            .and()
            .userIdEqualTo(content.userId!)
            .findFirst();
        if (existing != null) {
          content.id = existing.id;
        }
      }
      await db.downloadedContents.put(content);
    });
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

  Future<List<DownloadedContent>> getDownloadedContentByContext({
    required String userId,
    String? subject,
    String? grade,
    String? chapter,
  }) async {
    final db = await isar;
    final all = await db.downloadedContents
        .filter()
        .userIdEqualTo(userId)
        .sortByDownloadedAtDesc()
        .findAll();
    return all.where((item) {
      if (subject != null && subject.isNotEmpty && item.subject != subject)
        return false;
      if (grade != null && grade.isNotEmpty && item.grade != grade)
        return false;
      if (chapter != null && chapter.isNotEmpty && item.chapter != chapter)
        return false;
      return true;
    }).toList(growable: false);
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
    // Implementation if needed
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
  // ===========================================
  Future<ContentEntry?> getContentEntry(String key) async {
    final db = await isar;
    return await db.contentEntrys.filter().keyEqualTo(key).findFirst();
  }

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

  Future<void> deleteContentEntry(String key) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.contentEntrys.filter().keyEqualTo(key).deleteAll();
    });
  }

  Future<void> deleteContentEntriesByPrefix(String prefix) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.contentEntrys.filter().keyStartsWith(prefix).deleteAll();
    });
  }

  Future<int> getContentEntryCount() async {
    final db = await isar;
    return await db.contentEntrys.count();
  }

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
    // Storage is reported across all download records; filtering by an empty
    // userId always matched nothing and reported 0 bytes.
    final contents = await db.downloadedContents.where().findAll();
    final totalStorageBytes =
        contents.fold<int>(0, (sum, c) => sum + c.fileSize);
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
