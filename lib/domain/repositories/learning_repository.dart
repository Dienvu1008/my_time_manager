import '../models/model_course.dart';
import '../models/model_course_module.dart';
import '../models/model_lesson.dart';
import '../models/model_lesson_progress.dart';

/// Domain boundary for the **learning system** (Core Track C7): courses, their
/// modules, lessons and per-lesson progress.
///
/// Hierarchy: Course → CourseModule → Lesson (each child ordered by
/// `sortOrder`, ties broken by `createdAt`). Progress is stored ONLY per
/// lesson (one row per lesson); module and course progress are derived by
/// LearningProgressService, never stored.
///
/// Callers depend on this interface, never on [DatabaseManager] / SQLite
/// directly. Implementations live in `lib/data/repositories/`.
///
/// Trash and archive of a course do NOT cascade (modules, lessons and progress
/// are kept and reappear on restore). Hard delete cascades course → modules →
/// lessons → progress, and removes goal links / project items pointing to the
/// course.
abstract class LearningRepository {
  // --- Courses ---

  /// All visible courses (excludes trashed and archived), oldest first.
  Future<List<Course>> getCourses();

  /// A single course by id (any state), or null if it does not exist.
  Future<Course?> getCourse(String id);

  Future<void> createCourse(Course course);

  Future<void> updateCourse(Course course);

  /// Hard-delete a course (cascades to modules, lessons and progress). Prefer
  /// [softDeleteCourse] for user-facing deletes.
  Future<void> deleteCourse(String id);

  /// Move a course to trash (children are kept untouched).
  Future<void> softDeleteCourse(String id);

  /// Restore a course from trash.
  Future<void> restoreCourse(String id);

  /// Permanently delete a course (same as [deleteCourse]).
  Future<void> permanentlyDeleteCourse(String id);

  /// Archive a course (children are kept untouched).
  Future<void> archiveCourse(String id);

  /// Unarchive a course.
  Future<void> unarchiveCourse(String id);

  // --- Modules ---

  /// Modules of a course, ordered by sortOrder then createdAt.
  Future<List<CourseModule>> getModules(String courseId);

  Future<CourseModule?> getModule(String id);

  /// Create a module. Throws [ArgumentError] if its course does not exist.
  Future<void> createModule(CourseModule module);

  Future<void> updateModule(CourseModule module);

  /// Hard-delete a module (cascades to its lessons and their progress).
  Future<void> deleteModule(String id);

  /// Set `sortOrder = index` for the given module ids of [courseId].
  Future<void> reorderModules(String courseId, List<String> orderedIds);

  // --- Lessons ---

  /// Lessons of a module, ordered by sortOrder then createdAt.
  Future<List<Lesson>> getLessons(String moduleId);

  /// All lessons of a course, in module order then lesson order.
  Future<List<Lesson>> getLessonsOfCourse(String courseId);

  Future<Lesson?> getLesson(String id);

  /// Create a lesson. Throws [ArgumentError] if its module does not exist.
  Future<void> createLesson(Lesson lesson);

  Future<void> updateLesson(Lesson lesson);

  /// Hard-delete a lesson (cascades to its progress).
  Future<void> deleteLesson(String id);

  /// Set `sortOrder = index` for the given lesson ids of [moduleId].
  Future<void> reorderLessons(String moduleId, List<String> orderedIds);

  // --- Progress ---

  /// The stored progress of a lesson, or null if it has none (= not started).
  Future<LessonProgress?> getLessonProgress(String lessonId);

  /// All stored progress rows of the lessons of a course.
  Future<List<LessonProgress>> getProgressForCourse(String courseId);

  /// Record that a lesson was opened (notStarted → inProgress; completed is
  /// kept; `lastOpenedAt` always updated). Throws [ArgumentError] if the
  /// lesson does not exist.
  Future<LessonProgress> markLessonOpened(String lessonId);

  /// Mark a lesson completed. Throws [ArgumentError] if it does not exist.
  Future<LessonProgress> markLessonCompleted(String lessonId);

  /// Undo completion (back to inProgress). Writes nothing when the lesson has
  /// no progress yet. Throws [ArgumentError] if it does not exist.
  Future<LessonProgress> markLessonIncomplete(String lessonId);
}
