import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';
import 'package:my_time_manager/domain/repositories/learning_repository.dart';

/// In-memory [LearningRepository] for widget tests. Applies the same progress
/// transitions as the SQLite DAO and records opened / completed lesson ids.
class FakeLearningRepository implements LearningRepository {
  final Map<String, Course> courses = {};
  final Map<String, CourseModule> modules = {};
  final Map<String, Lesson> lessons = {};
  final Map<String, LessonProgress> progress = {};
  final List<String> opened = [];
  final List<String> completed = [];

  int _order<T>(T a, T b, int Function(T) sort, DateTime Function(T) created) {
    final c = sort(a).compareTo(sort(b));
    return c != 0 ? c : created(a).compareTo(created(b));
  }

  // --- Courses ---
  @override
  Future<List<Course>> getCourses() async {
    final list =
        courses.values.where((c) => !c.isDeleted && !c.isArchived).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<Course?> getCourse(String id) async => courses[id];
  @override
  Future<void> createCourse(Course course) async => courses[course.id] = course;
  @override
  Future<void> updateCourse(Course course) async => courses[course.id] = course;

  @override
  Future<void> deleteCourse(String id) async {
    courses.remove(id);
    for (final m in modules.values.where((m) => m.courseId == id).toList()) {
      await deleteModule(m.id);
    }
  }

  Course _flag(Course c, {bool? deleted, bool? archived}) => Course(
        id: c.id,
        title: c.title,
        description: c.description,
        color: c.color,
        source: c.source,
        status: c.status,
        createdAt: c.createdAt,
        updateTimeStamp: c.updateTimeStamp,
        isDeleted: deleted ?? c.isDeleted,
        deletedAt: (deleted ?? c.isDeleted) ? DateTime.now() : null,
        isArchived: archived ?? c.isArchived,
        archivedAt: (archived ?? c.isArchived) ? DateTime.now() : null,
      );

  @override
  Future<void> softDeleteCourse(String id) async =>
      courses[id] = _flag(courses[id]!, deleted: true);
  @override
  Future<void> restoreCourse(String id) async =>
      courses[id] = _flag(courses[id]!, deleted: false);
  @override
  Future<void> permanentlyDeleteCourse(String id) => deleteCourse(id);
  @override
  Future<void> archiveCourse(String id) async =>
      courses[id] = _flag(courses[id]!, archived: true);
  @override
  Future<void> unarchiveCourse(String id) async =>
      courses[id] = _flag(courses[id]!, archived: false);

  // --- Modules ---
  @override
  Future<List<CourseModule>> getModules(String courseId) async {
    final list = modules.values.where((m) => m.courseId == courseId).toList();
    list.sort((a, b) => _order(a, b, (m) => m.sortOrder, (m) => m.createdAt));
    return list;
  }

  @override
  Future<CourseModule?> getModule(String id) async => modules[id];

  @override
  Future<void> createModule(CourseModule module) async {
    if (!courses.containsKey(module.courseId)) {
      throw ArgumentError.value(module.courseId, 'courseId');
    }
    modules[module.id] = module;
  }

  @override
  Future<void> updateModule(CourseModule module) async =>
      modules[module.id] = module;

  @override
  Future<void> deleteModule(String id) async {
    modules.remove(id);
    for (final l in lessons.values.where((l) => l.moduleId == id).toList()) {
      await deleteLesson(l.id);
    }
  }

  @override
  Future<void> reorderModules(String courseId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final m = modules[orderedIds[i]];
      if (m != null && m.courseId == courseId) {
        modules[m.id] = m.copyWith(sortOrder: i);
      }
    }
  }

  // --- Lessons ---
  @override
  Future<List<Lesson>> getLessons(String moduleId) async {
    final list = lessons.values.where((l) => l.moduleId == moduleId).toList();
    list.sort((a, b) => _order(a, b, (l) => l.sortOrder, (l) => l.createdAt));
    return list;
  }

  @override
  Future<List<Lesson>> getLessonsOfCourse(String courseId) async => [
        for (final m in await getModules(courseId)) ...await getLessons(m.id),
      ];

  @override
  Future<Lesson?> getLesson(String id) async => lessons[id];

  @override
  Future<void> createLesson(Lesson lesson) async {
    if (!modules.containsKey(lesson.moduleId)) {
      throw ArgumentError.value(lesson.moduleId, 'moduleId');
    }
    lessons[lesson.id] = lesson;
  }

  @override
  Future<void> updateLesson(Lesson lesson) async => lessons[lesson.id] = lesson;

  @override
  Future<void> deleteLesson(String id) async {
    lessons.remove(id);
    progress.remove(id);
  }

  @override
  Future<void> reorderLessons(String moduleId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final l = lessons[orderedIds[i]];
      if (l != null && l.moduleId == moduleId) {
        lessons[l.id] = l.copyWith(sortOrder: i);
      }
    }
  }

  // --- Progress ---
  @override
  Future<LessonProgress?> getLessonProgress(String lessonId) async =>
      progress[lessonId];

  @override
  Future<List<LessonProgress>> getProgressForCourse(String courseId) async {
    final ids = {for (final l in await getLessonsOfCourse(courseId)) l.id};
    return progress.values.where((p) => ids.contains(p.lessonId)).toList();
  }

  void _require(String lessonId) {
    if (!lessons.containsKey(lessonId)) {
      throw ArgumentError.value(lessonId, 'lessonId');
    }
  }

  @override
  Future<LessonProgress> markLessonOpened(String lessonId) async {
    _require(lessonId);
    opened.add(lessonId);
    final now = DateTime.now();
    final existing = progress[lessonId];
    final next = existing == null
        ? LessonProgress(
            lessonId: lessonId,
            status: LessonStatus.inProgress,
            startedAt: now,
            lastOpenedAt: now,
            updateTimeStamp: now)
        : existing.copyWith(
            status: existing.status == LessonStatus.notStarted
                ? LessonStatus.inProgress
                : existing.status,
            startedAt: existing.startedAt ?? now,
            lastOpenedAt: now,
            updateTimeStamp: now);
    return progress[lessonId] = next;
  }

  @override
  Future<LessonProgress> markLessonCompleted(String lessonId) async {
    _require(lessonId);
    completed.add(lessonId);
    final now = DateTime.now();
    final base = progress[lessonId] ?? LessonProgress(lessonId: lessonId);
    return progress[lessonId] = base.copyWith(
        status: LessonStatus.completed,
        completedAt: now,
        startedAt: base.startedAt ?? now,
        updateTimeStamp: now);
  }

  @override
  Future<LessonProgress> markLessonIncomplete(String lessonId) async {
    _require(lessonId);
    final existing = progress[lessonId];
    if (existing == null) return LessonProgress.notStarted(lessonId);
    return progress[lessonId] = existing.copyWith(
        status: LessonStatus.inProgress,
        clearCompletedAt: true,
        updateTimeStamp: DateTime.now());
  }
}
