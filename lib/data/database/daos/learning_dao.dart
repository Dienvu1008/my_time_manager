import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_course.dart';
import '../../../domain/models/model_course_module.dart';
import '../../../domain/models/model_lesson.dart';
import '../../../domain/models/model_lesson_progress.dart';
import '../device_id_helper.dart';

/// DAO cho aggregate Học tập (Core Track C7): sở hữu 4 bảng `courses`,
/// `course_modules`, `lessons`, `lesson_progress`.
///
/// Quy tắc:
/// - courses → course_modules → lessons → lesson_progress, mỗi con có FK
///   ON DELETE CASCADE tới cha: xóa cứng khóa học xóa toàn bộ cây con.
/// - Soft-delete / archive của Course KHÔNG cascade: chương/bài/tiến độ giữ
///   nguyên và hiện lại khi khôi phục.
/// - Trigger `delete_goal_links_of_course` / `delete_project_items_of_course`
///   xóa liên kết mục tiêu / mục dự án trỏ tới khóa học bị xóa cứng.
/// - Insert dùng ConflictAlgorithm.abort mặc định (KHÔNG replace): REPLACE =
///   DELETE + INSERT sẽ kích hoạt CASCADE và xóa mất cây con.
/// - `lesson_progress.id == lessonId` (một hàng / bài); các thao tác tiến độ
///   là query-rồi-update/insert trong một transaction.
class LearningDao {
  LearningDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ------------------------------------------------------------------
  // SCHEMA (v15) — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade`
  // ------------------------------------------------------------------

  /// Tạo toàn bộ schema của aggregate (4 bảng + index + trigger). Hàm DUY NHẤT
  /// được gọi từ cả `_onCreate` và nhánh `_onUpgrade` v15 nên SQL luôn giống
  /// hệt nhau. Yêu cầu các bảng `goal_links` và `project_items` đã tồn tại
  /// (cho trigger).
  static Future<void> createSchema(Database db) async {
    await createCoursesTable(db);
    await createCourseModulesTable(db);
    await createLessonsTable(db);
    await createLessonProgressTable(db);
    await createLearningTriggers(db);
  }

  static Future<void> createCoursesTable(Database db) async {
    await db.execute('''
    CREATE TABLE courses (
      id TEXT PRIMARY KEY,
      title TEXT,
      description TEXT,
      color INTEGER,
      source TEXT NOT NULL DEFAULT 'manual',
      status TEXT NOT NULL DEFAULT 'active',
      createdAt TEXT,
      updateTimeStamp TEXT,
      isDeleted INTEGER NOT NULL DEFAULT 0,
      deletedAt TEXT,
      isArchived INTEGER NOT NULL DEFAULT 0,
      archivedAt TEXT,
      deviceId TEXT
      )
    ''');
  }

  static Future<void> createCourseModulesTable(Database db) async {
    await db.execute('''
    CREATE TABLE course_modules (
      id TEXT PRIMARY KEY,
      courseId TEXT NOT NULL,
      title TEXT,
      description TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT,
      updateTimeStamp TEXT,
      deviceId TEXT,
      FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_course_modules_courseId ON course_modules(courseId)');
  }

  static Future<void> createLessonsTable(Database db) async {
    await db.execute('''
    CREATE TABLE lessons (
      id TEXT PRIMARY KEY,
      moduleId TEXT NOT NULL,
      title TEXT,
      contentJson TEXT,
      links TEXT,
      noteIds TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT,
      updateTimeStamp TEXT,
      deviceId TEXT,
      FOREIGN KEY (moduleId) REFERENCES course_modules(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_lessons_moduleId ON lessons(moduleId)');
  }

  static Future<void> createLessonProgressTable(Database db) async {
    await db.execute('''
    CREATE TABLE lesson_progress (
      id TEXT PRIMARY KEY,
      lessonId TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL DEFAULT 'notStarted',
      startedAt TEXT,
      completedAt TEXT,
      lastOpenedAt TEXT,
      updateTimeStamp TEXT,
      deviceId TEXT,
      FOREIGN KEY (lessonId) REFERENCES lessons(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Trigger: xóa cứng một khóa học → xóa liên kết mục tiêu / mục dự án trỏ
  /// tới nó (chương/bài/tiến độ đã bị xóa theo FK cascade).
  static Future<void> createLearningTriggers(Database db) async {
    const triggers = {
      'delete_goal_links_of_course': 'goal_links',
      'delete_project_items_of_course': 'project_items',
    };
    for (final entry in triggers.entries) {
      await db.execute('''
    CREATE TRIGGER ${entry.key}
    AFTER DELETE ON courses
    BEGIN
      DELETE FROM ${entry.value} WHERE entityType = 'course' AND entityId = OLD.id;
    END;
    ''');
    }
  }

  // ------------------------------------------------------------------
  // COURSES
  // ------------------------------------------------------------------

  /// Các khóa học đang hiển thị (bỏ mục trong thùng rác và đã lưu trữ).
  Future<List<Course>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('courses',
        where: 'isDeleted = 0 AND isArchived = 0', orderBy: 'createdAt ASC');
    return maps.map(Course.fromMap).toList();
  }

  /// Một khóa học theo id (không lọc trạng thái), hoặc null nếu không có.
  Future<Course?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('courses', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  Future<void> insert(Course course) async {
    final db = await _getDatabase();
    await db.insert('courses', withDeviceId(course.toMap()));
  }

  Future<void> update(Course course) async {
    final db = await _getDatabase();
    await db.update('courses', course.toMap(),
        where: 'id = ?', whereArgs: [course.id]);
  }

  /// Xóa cứng (chương → bài → tiến độ bị xóa theo qua FK cascade).
  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  /// Soft-delete: chỉ đánh dấu khóa học (KHÔNG cascade).
  Future<void> softDelete(String id) async {
    final db = await _getDatabase();
    await db.update(
      'courses',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _getDatabase();
    await db.update(
      'courses',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa vĩnh viễn (= [delete]).
  Future<void> permanentlyDelete(String id) => delete(id);

  /// Lưu trữ: chỉ đánh dấu khóa học (KHÔNG cascade).
  Future<void> archive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'courses',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'courses',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------------
  // MODULES
  // ------------------------------------------------------------------

  /// Các chương của một khóa học, theo sortOrder rồi createdAt.
  Future<List<CourseModule>> modulesOf(String courseId) async {
    final db = await _getDatabase();
    final maps = await db.query('course_modules',
        where: 'courseId = ?',
        whereArgs: [courseId],
        orderBy: 'sortOrder ASC, createdAt ASC');
    return maps.map(CourseModule.fromMap).toList();
  }

  Future<CourseModule?> getModule(String id) async {
    final db = await _getDatabase();
    final maps =
        await db.query('course_modules', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return CourseModule.fromMap(maps.first);
  }

  Future<void> insertModule(CourseModule module) async {
    final db = await _getDatabase();
    await db.insert('course_modules', withDeviceId(module.toMap()));
  }

  Future<void> updateModule(CourseModule module) async {
    final db = await _getDatabase();
    await db.update('course_modules', module.toMap(),
        where: 'id = ?', whereArgs: [module.id]);
  }

  /// Xóa cứng một chương (bài → tiến độ bị xóa theo FK cascade).
  Future<void> deleteModule(String id) async {
    final db = await _getDatabase();
    await db.delete('course_modules', where: 'id = ?', whereArgs: [id]);
  }

  /// Đặt `sortOrder = index` theo [orderedIds] (chỉ các chương thuộc
  /// [courseId]) trong một transaction.
  Future<void> reorderModules(String courseId, List<String> orderedIds) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update('course_modules', {'sortOrder': i},
            where: 'id = ? AND courseId = ?',
            whereArgs: [orderedIds[i], courseId]);
      }
    });
  }

  // ------------------------------------------------------------------
  // LESSONS
  // ------------------------------------------------------------------

  /// Các bài của một chương, theo sortOrder rồi createdAt.
  Future<List<Lesson>> lessonsOf(String moduleId) async {
    final db = await _getDatabase();
    final maps = await db.query('lessons',
        where: 'moduleId = ?',
        whereArgs: [moduleId],
        orderBy: 'sortOrder ASC, createdAt ASC');
    return maps.map(Lesson.fromMap).toList();
  }

  /// Mọi bài của một khóa học, theo thứ tự chương rồi thứ tự bài.
  Future<List<Lesson>> lessonsOfCourse(String courseId) async {
    final db = await _getDatabase();
    final maps = await db.rawQuery(
        'SELECT l.* FROM lessons l '
        'JOIN course_modules m ON l.moduleId = m.id '
        'WHERE m.courseId = ? '
        'ORDER BY m.sortOrder, m.createdAt, l.sortOrder, l.createdAt',
        [courseId]);
    return maps.map(Lesson.fromMap).toList();
  }

  Future<Lesson?> getLesson(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('lessons', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Lesson.fromMap(maps.first);
  }

  Future<void> insertLesson(Lesson lesson) async {
    final db = await _getDatabase();
    await db.insert('lessons', withDeviceId(lesson.toMap()));
  }

  Future<void> updateLesson(Lesson lesson) async {
    final db = await _getDatabase();
    await db.update('lessons', lesson.toMap(),
        where: 'id = ?', whereArgs: [lesson.id]);
  }

  /// Xóa cứng một bài (tiến độ bị xóa theo FK cascade).
  Future<void> deleteLesson(String id) async {
    final db = await _getDatabase();
    await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }

  /// Đặt `sortOrder = index` theo [orderedIds] (chỉ các bài thuộc
  /// [moduleId]) trong một transaction.
  Future<void> reorderLessons(String moduleId, List<String> orderedIds) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update('lessons', {'sortOrder': i},
            where: 'id = ? AND moduleId = ?',
            whereArgs: [orderedIds[i], moduleId]);
      }
    });
  }

  // ------------------------------------------------------------------
  // LESSON PROGRESS
  // ------------------------------------------------------------------

  Future<LessonProgress?> progressOf(String lessonId) async {
    final db = await _getDatabase();
    final maps = await db.query('lesson_progress',
        where: 'lessonId = ?', whereArgs: [lessonId]);
    if (maps.isEmpty) return null;
    return LessonProgress.fromMap(maps.first);
  }

  /// Mọi hàng tiến độ của các bài thuộc một khóa học.
  Future<List<LessonProgress>> progressOfCourse(String courseId) async {
    final db = await _getDatabase();
    final maps = await db.rawQuery(
        'SELECT p.* FROM lesson_progress p '
        'JOIN lessons l ON p.lessonId = l.id '
        'JOIN course_modules m ON l.moduleId = m.id '
        'WHERE m.courseId = ?',
        [courseId]);
    return maps.map(LessonProgress.fromMap).toList();
  }

  /// Mở bài: chưa có hàng → inProgress (startedAt = lastOpenedAt = now);
  /// notStarted → inProgress, `startedAt ??= now`; inProgress/completed giữ
  /// nguyên trạng thái. Luôn đặt `lastOpenedAt = now`.
  Future<LessonProgress> markOpened(String lessonId, DateTime now) {
    return _upsertProgress(lessonId, (existing) {
      if (existing == null) {
        return LessonProgress(
          lessonId: lessonId,
          status: LessonStatus.inProgress,
          startedAt: now,
          lastOpenedAt: now,
          updateTimeStamp: now,
        );
      }
      final status = existing.status == LessonStatus.notStarted
          ? LessonStatus.inProgress
          : existing.status;
      return existing.copyWith(
        status: status,
        startedAt: existing.startedAt ?? now,
        lastOpenedAt: now,
        updateTimeStamp: now,
      );
    });
  }

  /// Đánh dấu hoàn thành: `completedAt = now`, `startedAt ??= now`.
  Future<LessonProgress> markCompleted(String lessonId, DateTime now) {
    return _upsertProgress(lessonId, (existing) {
      final base = existing ?? LessonProgress(lessonId: lessonId);
      return base.copyWith(
        status: LessonStatus.completed,
        completedAt: now,
        startedAt: base.startedAt ?? now,
        updateTimeStamp: now,
      );
    });
  }

  /// Bỏ hoàn thành: hàng có sẵn → inProgress, `completedAt = null`. Chưa có
  /// hàng → không ghi gì, trả về giá trị notStarted.
  Future<LessonProgress> markIncomplete(String lessonId, DateTime now) {
    return _upsertProgress(lessonId, (existing) {
      if (existing == null) return null;
      return existing.copyWith(
        status: LessonStatus.inProgress,
        clearCompletedAt: true,
        updateTimeStamp: now,
      );
    }, fallback: LessonProgress.notStarted(lessonId));
  }

  /// Query-rồi-update/insert trong một transaction. [build] trả về null =
  /// không ghi; khi đó trả về [fallback].
  Future<LessonProgress> _upsertProgress(
    String lessonId,
    LessonProgress? Function(LessonProgress? existing) build, {
    LessonProgress? fallback,
  }) async {
    final db = await _getDatabase();
    return db.transaction((txn) async {
      final rows = await txn.query('lesson_progress',
          where: 'lessonId = ?', whereArgs: [lessonId]);
      final existing =
          rows.isEmpty ? null : LessonProgress.fromMap(rows.first);
      final next = build(existing);
      if (next == null) return fallback ?? LessonProgress.notStarted(lessonId);
      if (existing == null) {
        await txn.insert('lesson_progress', withDeviceId(next.toMap()));
      } else {
        await txn.update('lesson_progress', next.toMap(),
            where: 'lessonId = ?', whereArgs: [lessonId]);
      }
      return next;
    });
  }
}
