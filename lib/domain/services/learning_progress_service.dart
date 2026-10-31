import '../models/model_course.dart';
import '../models/model_course_module.dart';
import '../models/model_lesson.dart';
import '../models/model_lesson_progress.dart';
import '../repositories/learning_repository.dart';

/// Derived progress of one module.
class ModuleProgress {
  const ModuleProgress({
    required this.moduleId,
    required this.totalLessons,
    required this.completedLessons,
    required this.inProgressLessons,
    required this.ratio,
    required this.isDone,
  });

  final String moduleId;
  final int totalLessons;
  final int completedLessons;

  /// Reported only; never enters [ratio].
  final int inProgressLessons;

  /// 0.0 … 1.0 (completed / total; 0 lessons → 0.0).
  final double ratio;

  /// True iff the module has ≥1 lesson and every lesson is completed.
  final bool isDone;
}

/// Derived progress of one course.
class CourseProgress {
  const CourseProgress({
    required this.courseId,
    required this.totalLessons,
    required this.completedLessons,
    required this.inProgressLessons,
    required this.totalModules,
    required this.doneModules,
    required this.ratio,
    required this.isDone,
    required this.modules,
  });

  final String courseId;
  final int totalLessons;
  final int completedLessons;

  /// Reported only; never enters [ratio].
  final int inProgressLessons;
  final int totalModules;
  final int doneModules;

  /// 0.0 … 1.0 (completed lessons / total lessons across all modules).
  final double ratio;

  /// True iff the course has ≥1 lesson, every lesson is completed and no
  /// module is empty (every module [ModuleProgress.isDone]).
  final bool isDone;

  /// Per-module breakdown, in the order the modules were given.
  final List<ModuleProgress> modules;
}

/// Pure, deterministic progress rules for courses and modules (Core Track C7).
/// Progress is always DERIVED from per-lesson progress rows — never stored, no
/// manual override:
///
///     UI / AI Tool → LearningProgressService → LearningRepository
///
/// Lesson status = its progress row's status; no row → notStarted. Progress
/// rows of lessons outside the module / course are ignored.
///
/// Module: ratio = completed / total lessons (0 lessons → 0.0); done iff
/// total > 0 and completed == total.
///
/// Course: ratio = completed lessons / total lessons across ALL modules
/// (weighted by lesson, not by module average, so tiny modules do not skew
/// it); 0 lessons → 0.0 and not done. Done iff ≥1 lesson, every lesson is
/// completed AND every module is done — an empty module (no lessons yet)
/// keeps the course not done even though the ratio may read 1.0. Done
/// modules / total modules and in-progress counts are reported but never
/// enter the ratio.
///
/// [courseProgressOf] works for a course in any state (trashed / archived
/// included) and returns null when the course is missing;
/// [progressOfLiveCourses] covers only [LearningRepository.getCourses]
/// (trashed and archived courses excluded).
class LearningProgressService {
  LearningProgressService(this._learning);

  final LearningRepository _learning;

  /// Progress of one course, or null if it does not exist.
  Future<CourseProgress?> courseProgressOf(String courseId) async {
    final course = await _learning.getCourse(courseId);
    if (course == null) return null;
    return _load(course);
  }

  /// Progress of every live course, keyed by course id.
  Future<Map<String, CourseProgress>> progressOfLiveCourses() async {
    final courses = await _learning.getCourses();
    final result = <String, CourseProgress>{};
    for (final c in courses) {
      result[c.id] = await _load(c);
    }
    return result;
  }

  Future<CourseProgress> _load(Course course) async {
    final modules = await _learning.getModules(course.id);
    final lessons = await _learning.getLessonsOfCourse(course.id);
    final progress = await _learning.getProgressForCourse(course.id);
    return computeCourse(course, modules, lessons, statusById(progress));
  }

  /// Lesson id → stored status.
  static Map<String, LessonStatus> statusById(List<LessonProgress> rows) => {
        for (final p in rows) p.lessonId: p.status,
      };

  /// Progress of [module], counting only [lessons] whose moduleId matches.
  static ModuleProgress computeModule(CourseModule module,
      List<Lesson> lessons, Map<String, LessonStatus> statusById) {
    var total = 0;
    var completed = 0;
    var inProgress = 0;
    final seen = <String>{};
    for (final l in lessons) {
      if (l.moduleId != module.id || !seen.add(l.id)) continue;
      total++;
      switch (statusById[l.id] ?? LessonStatus.notStarted) {
        case LessonStatus.completed:
          completed++;
        case LessonStatus.inProgress:
          inProgress++;
        case LessonStatus.notStarted:
          break;
      }
    }
    return ModuleProgress(
      moduleId: module.id,
      totalLessons: total,
      completedLessons: completed,
      inProgressLessons: inProgress,
      ratio: total == 0 ? 0.0 : completed / total,
      isDone: total > 0 && completed == total,
    );
  }

  /// Progress of [course] over [modules] (only those of the course) and their
  /// [lessons].
  static CourseProgress computeCourse(
    Course course,
    List<CourseModule> modules,
    List<Lesson> lessons,
    Map<String, LessonStatus> statusById,
  ) {
    final ownModules = modules.where((m) => m.courseId == course.id).toList();
    final perModule = [
      for (final m in ownModules) computeModule(m, lessons, statusById),
    ];
    var total = 0;
    var completed = 0;
    var inProgress = 0;
    for (final mp in perModule) {
      total += mp.totalLessons;
      completed += mp.completedLessons;
      inProgress += mp.inProgressLessons;
    }
    return CourseProgress(
      courseId: course.id,
      totalLessons: total,
      completedLessons: completed,
      inProgressLessons: inProgress,
      totalModules: perModule.length,
      doneModules: perModule.where((m) => m.isDone).length,
      ratio: total == 0 ? 0.0 : completed / total,
      // Chương rỗng = chưa xong (chưa có nội dung) → khóa học chưa xong.
      isDone: total > 0 &&
          completed == total &&
          perModule.every((m) => m.isDone),
      modules: perModule,
    );
  }
}
