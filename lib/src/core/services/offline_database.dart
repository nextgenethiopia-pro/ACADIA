import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineDatabase {
  static final OfflineDatabase instance = OfflineDatabase._init();
  static Database? _database;

  OfflineDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'acadia_offline.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createProgressTables(db);
        }
        if (oldVersion < 3) {
          await _createAdditionalTables(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Content table
    await db.execute('''
      CREATE TABLE offline_content (
        content_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        chapter TEXT NOT NULL,
        content_type TEXT NOT NULL,
        download_url TEXT NOT NULL,
        local_path TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        file_format TEXT NOT NULL,
        page_count INTEGER,
        total_questions INTEGER,
        total_cards INTEGER,
        is_completed INTEGER DEFAULT 0,
        download_date TEXT NOT NULL,
        last_accessed TEXT NOT NULL,
        status TEXT DEFAULT 'downloaded'
      )
    ''');

    await _createProgressTables(db);
    await _createAdditionalTables(db);
  }

  Future<void> _createProgressTables(Database db) async {
    // User progress table
    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        total_study_time INTEGER DEFAULT 0,
        lessons_completed INTEGER DEFAULT 0,
        quizzes_passed INTEGER DEFAULT 0,
        average_score REAL DEFAULT 0.0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        last_study_date TEXT,
        UNIQUE(user_id)
      )
    ''');

    // Subject progress table
    await db.execute('''
      CREATE TABLE subject_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        subject TEXT NOT NULL,
        lessons_completed INTEGER DEFAULT 0,
        total_lessons INTEGER DEFAULT 0,
        completion_percentage REAL DEFAULT 0.0,
        UNIQUE(user_id, subject)
      )
    ''');
  }

  Future<void> _createAdditionalTables(Database db) async {
    // Weekly activity table
    await db.execute('''
      CREATE TABLE weekly_activity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        hours_studied REAL DEFAULT 0.0,
        date TEXT NOT NULL,
        UNIQUE(user_id, date)
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        badge_name TEXT NOT NULL,
        is_unlocked INTEGER DEFAULT 0,
        unlocked_date TEXT,
        UNIQUE(user_id, badge_name)
      )
    ''');

    // Chapters table
    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        grade TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT,
        UNIQUE(subject, grade, name)
      )
    ''');

    // User chapter progress table
    await db.execute('''
      CREATE TABLE user_chapter_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        completed_at TEXT,
        UNIQUE(user_id, chapter_id)
      )
    ''');
  }

  // ============================================================
  // CONTENT METHODS
  // ============================================================

  Future<bool> isContentDownloaded(String contentId) async {
    final db = await database;
    final result = await db.query('offline_content', where: 'content_id = ?', whereArgs: [contentId]);
    return result.isNotEmpty;
  }

  Future<void> saveDownloadRecord({required Map<String, dynamic> data}) async {
    final db = await database;
    await db.insert('offline_content', {
      ...data,
      'status': 'downloaded',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDownloadRecord(String contentId) async {
    final db = await database;
    final result = await db.query('offline_content', where: 'content_id = ?', whereArgs: [contentId]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<void> deleteDownload(String contentId) async {
    final db = await database;
    await db.delete('offline_content', where: 'content_id = ?', whereArgs: [contentId]);
  }

  Future<void> deleteAllDownloads() async {
    final db = await database;
    await db.delete('offline_content');
  }

  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final db = await database;
    return await db.query('offline_content', orderBy: 'download_date DESC');
  }

  Future<List<Map<String, dynamic>>> getDownloadsByType(String contentType) async {
    final db = await database;
    return await db.query(
      'offline_content',
      where: 'content_type = ?',
      whereArgs: [contentType],
      orderBy: 'download_date DESC',
    );
  }

  Future<int> getTotalStorageUsed() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(file_size_bytes) as total FROM offline_content');
    return result.first['total'] as int? ?? 0;
  }

  Future<void> markContentCompleted(String contentId) async {
    final db = await database;
    await db.update(
      'offline_content',
      {'is_completed': 1},
      where: 'content_id = ?',
      whereArgs: [contentId],
    );
  }

  Future<void> updateLastAccessed(String contentId) async {
    final db = await database;
    await db.update(
      'offline_content',
      {'last_accessed': DateTime.now().toIso8601String()},
      where: 'content_id = ?',
      whereArgs: [contentId],
    );
  }

  // ============================================================
  // CHAPTER METHODS
  // ============================================================

  Future<void> saveChapter(Map<String, dynamic> chapter) async {
    final db = await database;
    await db.insert('chapters', chapter, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getChapters(String subject, String grade) async {
    final db = await database;
    return await db.query(
      'chapters',
      where: 'subject = ? AND grade = ?',
      whereArgs: [subject, grade],
      orderBy: 'name ASC',
    );
  }

  Future<void> markChapterCompleted(String userId, String chapterId) async {
    final db = await database;
    await db.insert(
      'user_chapter_progress',
      {
        'user_id': userId,
        'chapter_id': chapterId,
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isChapterCompleted(String userId, String chapterId) async {
    final db = await database;
    final result = await db.query(
      'user_chapter_progress',
      where: 'user_id = ? AND chapter_id = ? AND is_completed = 1',
      whereArgs: [userId, chapterId],
    );
    return result.isNotEmpty;
  }

  Future<int> getCompletedChaptersCount(String userId, String subject) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM user_chapter_progress ucp
      JOIN chapters c ON ucp.chapter_id = c.id
      WHERE ucp.user_id = ? AND c.subject = ? AND ucp.is_completed = 1
    ''', [userId, subject]);
    return (result.first['count'] as int?) ?? 0;
  }

  // ============================================================
  // PROGRESS TRACKING METHODS
  // ============================================================

  Future<void> initializeUserProgress(String userId) async {
    final db = await database;
    await db.insert('user_progress', {
      'user_id': userId,
      'total_study_time': 0,
      'lessons_completed': 0,
      'quizzes_passed': 0,
      'average_score': 0.0,
      'current_streak': 0,
      'longest_streak': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Initialize achievements
    final badges = ['First Steps', 'Perfect Week', 'Quiz Master', 'Dedicated'];
    for (final badge in badges) {
      await db.insert('achievements', {
        'user_id': userId,
        'badge_name': badge,
        'is_unlocked': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final db = await database;
    final result = await db.query('user_progress', where: 'user_id = ?', whereArgs: [userId]);
    if (result.isNotEmpty) return result.first;
    return {};
  }

  /// Upsert the local user_progress row using data restored from Firebase.
  ///
  /// Only known columns are copied; unknown keys are ignored so the schema
  /// stays authoritative.
  Future<void> updateUserProgressFromFirebase(
    String userId,
    Map<String, dynamic> progress,
  ) async {
    final db = await database;
    final row = <String, dynamic>{'user_id': userId};

    void copyInt(String key) {
      final value = progress[key];
      if (value is num) row[key] = value.toInt();
    }

    void copyDouble(String key) {
      final value = progress[key];
      if (value is num) row[key] = value.toDouble();
    }

    copyInt('total_study_time');
    copyInt('lessons_completed');
    copyInt('quizzes_passed');
    copyDouble('average_score');
    copyInt('current_streak');
    copyInt('longest_streak');
    final lastStudyDate = progress['last_study_date'];
    if (lastStudyDate is String) row['last_study_date'] = lastStudyDate;

    await db.insert(
      'user_progress',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStudyTime(String userId, int seconds) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE user_progress 
      SET total_study_time = total_study_time + ?, last_study_date = ?
      WHERE user_id = ?
    ''', [seconds, DateTime.now().toIso8601String(), userId]);
    
    // Update streak
    await updateStreak(userId);
  }

  Future<void> incrementLessonsCompleted(String userId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE user_progress 
      SET lessons_completed = lessons_completed + 1
      WHERE user_id = ?
    ''', [userId]);
    
    // Check for First Steps achievement
    final progress = await getUserProgress(userId);
    if ((progress['lessons_completed'] as int? ?? 0) >= 1) {
      await unlockAchievement(userId, 'First Steps');
    }
  }

  Future<void> updateQuizScore(String userId, int score) async {
    final db = await database;
    final progress = await getUserProgress(userId);
    final currentAvg = progress['average_score'] as double? ?? 0.0;
    final quizzesPassed = progress['quizzes_passed'] as int? ?? 0;
    
    final newAvg = ((currentAvg * quizzesPassed) + score) / (quizzesPassed + 1);
    
    await db.rawUpdate('''
      UPDATE user_progress 
      SET average_score = ?, quizzes_passed = quizzes_passed + 1
      WHERE user_id = ?
    ''', [newAvg, userId]);

    // Check for Quiz Master achievement (10 quizzes passed)
    if (quizzesPassed + 1 >= 10) {
      await unlockAchievement(userId, 'Quiz Master');
    }
  }

  Future<void> updateStreak(String userId) async {
    final db = await database;
    final progress = await getUserProgress(userId);
    final lastStudyDate = progress['last_study_date'] as String?;
    
    if (lastStudyDate != null) {
      final lastDate = DateTime.parse(lastStudyDate);
      final today = DateTime.now();
      final difference = today.difference(lastDate).inDays;
      
      if (difference == 1) {
        final currentStreak = progress['current_streak'] as int? ?? 0;
        final newStreak = currentStreak + 1;
        final longestStreak = progress['longest_streak'] as int? ?? 0;
        
        await db.rawUpdate('''
          UPDATE user_progress 
          SET current_streak = ?, longest_streak = ?
          WHERE user_id = ?
        ''', [newStreak, newStreak > longestStreak ? newStreak : longestStreak, userId]);

        if (newStreak >= 7) {
          await unlockAchievement(userId, 'Perfect Week');
        }
      } else if (difference > 1) {
        await db.rawUpdate('''
          UPDATE user_progress 
          SET current_streak = 1
          WHERE user_id = ?
        ''', [userId]);
      }
    }
  }

  Future<void> updateSubjectProgress(
    String userId,
    String subject,
    int totalLessons, {
    int? lessonsCompleted,
  }) async {
    final db = await database;
    final result = await db.query('subject_progress',
        where: 'user_id = ? AND subject = ?',
        whereArgs: [userId, subject]);

    final safeTotal = totalLessons <= 0 ? 1 : totalLessons;

    if (result.isNotEmpty) {
      final existingCompleted = result.first['lessons_completed'] as int? ?? 0;
      // When an explicit value is supplied (e.g. syncing from Firebase) use it
      // directly; otherwise increment the local count by one.
      final newCompleted = lessonsCompleted ?? (existingCompleted + 1);
      final percentage = (newCompleted / safeTotal) * 100;

      await db.update('subject_progress', {
        'lessons_completed': newCompleted,
        'total_lessons': totalLessons,
        'completion_percentage': percentage,
      }, where: 'user_id = ? AND subject = ?',
      whereArgs: [userId, subject]);
    } else {
      final newCompleted = lessonsCompleted ?? 1;
      await db.insert('subject_progress', {
        'user_id': userId,
        'subject': subject,
        'lessons_completed': newCompleted,
        'total_lessons': totalLessons,
        'completion_percentage': (newCompleted / safeTotal) * 100,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Check for Dedicated achievement (50 hours of study)
    final progress = await getUserProgress(userId);
    final totalStudyTime = progress['total_study_time'] as int? ?? 0;
    if (totalStudyTime >= 180000) { // 50 hours in seconds
      await unlockAchievement(userId, 'Dedicated');
    }
  }

  Future<void> recordWeeklyActivity(String userId, double hours) async {
    final db = await database;
    final now = DateTime.now();
    final date = now.toIso8601String().split('T')[0];
    final dayOfWeek = now.weekday;
    
    await db.insert('weekly_activity', {
      'user_id': userId,
      'day_of_week': dayOfWeek,
      'hours_studied': hours,
      'date': date,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivity(String userId) async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return await db.query('weekly_activity',
        where: 'user_id = ? AND date >= ?',
        whereArgs: [userId, weekAgo.toIso8601String().split('T')[0]],
        orderBy: 'date ASC');
  }

  Future<List<Map<String, dynamic>>> getSubjectProgress(String userId) async {
    final db = await database;
    return await db.query('subject_progress',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'completion_percentage DESC');
  }

  Future<List<Map<String, dynamic>>> getAchievements(String userId) async {
    final db = await database;
    return await db.query('achievements',
        where: 'user_id = ?',
        whereArgs: [userId]);
  }

  Future<void> unlockAchievement(String userId, String badgeName) async {
    final db = await database;
    final result = await db.query('achievements',
        where: 'user_id = ? AND badge_name = ?',
        whereArgs: [userId, badgeName]);
    
    if (result.isNotEmpty && (result.first['is_unlocked'] as int? ?? 0) == 0) {
      await db.update('achievements', {
        'is_unlocked': 1,
        'unlocked_date': DateTime.now().toIso8601String(),
      }, where: 'user_id = ? AND badge_name = ?',
      whereArgs: [userId, badgeName]);
    }
  }

  // ============================================================
  // CLEANUP METHODS
  // ============================================================

  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('user_progress', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('subject_progress', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('weekly_activity', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('achievements', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('user_chapter_progress', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('offline_content');
    await db.delete('user_progress');
    await db.delete('subject_progress');
    await db.delete('weekly_activity');
    await db.delete('achievements');
    await db.delete('chapters');
    await db.delete('user_chapter_progress');
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    final contentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM offline_content')) ?? 0;
    final storageUsed = await getTotalStorageUsed();
    final userProgressCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM user_progress')) ?? 0;
    
    return {
      'content_count': contentCount,
      'storage_used_mb': storageUsed / (1024 * 1024),
      'user_progress_count': userProgressCount,
    };
  }
}