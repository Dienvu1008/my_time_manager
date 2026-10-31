import '../../domain/models/model_course.dart';
import '../../domain/models/model_course_module.dart';
import '../../domain/models/model_lesson.dart';
import '../../domain/models/model_lesson_progress.dart';
import '../../domain/repositories/learning_repository.dart';
import '../database/daos/learning_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [LearningRepository] (Core Track C7) over [LearningDao].
class SqliteLearningRepository implements LearningRepository {
  SqliteLearningRepository({DatabaseManager? databaseManager})
      : _dao =
            LearningDao(() => (databaseManager ?? DatabaseManager()).database);

  final LearningDao _dao;

  // --- Courses ---

  @override
  Future<List<Course>> getCourses() => _dao.getAll();

  @override
  Future<Course?> getCourse(String id) => _dao.getById(id);

  @override
  Future<void> createCourse(Course course) => _dao.insert(course);

  @override
  Future<void> updateCourse(Course course) => _dao.update(course);

  @override
  Future<void> deleteCourse(String id) => _dao.delete(id);

  @override
  Future<void> softDeleteCourse(String id) => _dao.softDelete(id);

  @override
  Future<void> restoreCourse(String id) => _dao.restore(id);

  @override
  Future<void> permanentlyDeleteCourse(String id) =>
      _dao.permanentlyDelete(id);

  @override
  Future<void> archiveCourse(String id) => _dao.archive(id);

  @override
  Future<void> unarchiveCourse(String id) => _dao.unarchive(id);

  // --- Modules ---

  @override
  Future<List<CourseModule>> getModules(String courseId) =>
      _dao.modulesOf(courseId);

  @override
  Future<CourseModule?> getModule(String id) => _dao.getModule(id);

  @override
  Future<void> createModule(CourseModule module) async {
    if (await _dao.getById(module.courseId) == null) {
      throw ArgumentError.value(
          module.courseId, 'courseId', 'Course does not exist');
    }
    await _dao.insertModule(module);
  }

  @override
  Future<void> updateModule(CourseModule module) => _dao.updateModule(module);

  @override
  Future<void> deleteModule(String id) => _dao.deleteModule(id);

  @override
  Future<void> reorderModules(String courseId, List<String> orderedIds) =>
      _dao.reorderModules(courseId, orderedIds);

  // --- Lessons ---

  @override
  Future<List<Lesson>> getLessons(String moduleId) => _dao.lessonsOf(moduleId);

  @override
  Future<List<Lesson>> getLessonsOfCourse(String courseId) =>
      _dao.lessonsOfCourse(courseId);

  @override
  Future<Lesson?> getLesson(String id) => _dao.getLesson(id);

  @override
  Future<void> createLesson(Lesson lesson) async {
    if (await _dao.getModule(lesson.moduleId) == null) {
      throw ArgumentError.value(
          lesson.moduleId, 'moduleId', 'Module does not exist');
    }
    await _dao.insertLesson(lesson);
  }

  @override
  Future<void> updateLesson(Lesson lesson) => _dao.updateLesson(lesson);

  @override
  Future<void> deleteLesson(String id) => _dao.deleteLesson(id);

  @override
  Future<void> reorderLessons(String moduleId, List<String> orderedIds) =>
      _dao.reorderLessons(moduleId, orderedIds);

  // --- Progress ---

  @override
  Future<LessonProgress?> getLessonProgress(String lessonId) =>
      _dao.progressOf(lessonId);

  @override
  Future<List<LessonProgress>> getProgressForCourse(String courseId) =>
      _dao.progressOfCourse(courseId);

  @override
  Future<LessonProgress> markLessonOpened(String lessonId) async {
    await _requireLesson(lessonId);
    return _dao.markOpened(lessonId, DateTime.now());
  }

  @override
  Future<LessonProgress> markLessonCompleted(String lessonId) async {
    await _requireLesson(lessonId);
    return _dao.markCompleted(lessonId, DateTime.now());
  }

  @override
  Future<LessonProgress> markLessonIncomplete(String lessonId) async {
    await _requireLesson(lessonId);
    return _dao.markIncomplete(lessonId, DateTime.now());
  }

  Future<void> _requireLesson(String lessonId) async {
    if (await _dao.getLesson(lessonId) == null) {
      throw ArgumentError.value(lessonId, 'lessonId', 'Lesson does not exist');
    }
  }
}
