import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';
import 'package:my_time_manager/domain/repositories/learning_repository.dart';
import 'package:my_time_manager/domain/services/learning_progress_service.dart';

/// In-memory fake: only the read members used by [LearningProgressService]
/// are meaningful. [all] = every course (any state); [hidden] = trashed /
/// archived ids (excluded from [getCourses]).
class _FakeLearning implements LearningRepository {
  final Map<String, Course> all = {};
  final Set<String> hidden = {};
  final List<CourseModule> modules = [];
  final List<Lesson> lessons = [];
  final List<LessonProgress> progress = [];

  @override
  Future<List<Course>> getCourses() async =>
      all.values.where((c) => !hidden.contains(c.id)).toList();
  @override
  Future<Course?> getCourse(String id) async => all[id];
  @override
  Future<List<CourseModule>> getModules(String courseId) async =>
      modules.where((m) => m.courseId == courseId).toList();
  @override
  Future<List<Lesson>> getLessonsOfCourse(String courseId) async {
    final ids = {for (final m in modules) if (m.courseId == courseId) m.id};
    return lessons.where((l) => ids.contains(l.moduleId)).toList();
  }

  @override
  Future<List<LessonProgress>> getProgressForCourse(String courseId) async =>
      progress;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LessonProgress _p(String lessonId, LessonStatus s) =>
    LessonProgress(lessonId: lessonId, status: s);

void main() {
  final course = Course(id: 'c', title: 'C');
  final m1 = CourseModule(id: 'm1', courseId: 'c', title: 'M1');
  final m2 = CourseModule(id: 'm2', courseId: 'c', title: 'M2');
  Lesson lesson(String id, String moduleId) =>
      Lesson(id: id, moduleId: moduleId, title: id);

  group('pure compute', () {
    test('course with 0 modules → 0.0, not done', () {
      final p = LearningProgressService.computeCourse(
          course, const [], const [], const {});
      expect(p.ratio, 0.0);
      expect(p.isDone, isFalse);
      expect(p.totalModules, 0);
      expect(p.totalLessons, 0);
    });

    test('empty module → 0.0, not done', () {
      final p = LearningProgressService.computeModule(m1, const [], const {});
      expect(p.ratio, 0.0);
      expect(p.isDone, isFalse);
      expect(p.totalLessons, 0);
    });

    test('partial: 1 of 4 completed, 1 in progress → 0.25', () {
      final lessons = [
        lesson('a', 'm1'),
        lesson('b', 'm1'),
        lesson('c', 'm2'),
        lesson('d', 'm2'),
      ];
      final p = LearningProgressService.computeCourse(course, [m1, m2],
          lessons, {'a': LessonStatus.completed, 'c': LessonStatus.inProgress});
      expect(p.ratio, 0.25);
      expect(p.completedLessons, 1);
      expect(p.inProgressLessons, 1);
      expect(p.totalLessons, 4);
      expect(p.doneModules, 0);
      expect(p.isDone, isFalse);
      expect(p.modules.map((m) => m.ratio), [0.5, 0.0]);
    });

    test('ratio is weighted by lesson, not module average', () {
      // m1: 1/1 done, m2: 0/3 → 1/4, not (1.0 + 0.0) / 2.
      final lessons = [
        lesson('a', 'm1'),
        lesson('b', 'm2'),
        lesson('c', 'm2'),
        lesson('d', 'm2'),
      ];
      final p = LearningProgressService.computeCourse(
          course, [m1, m2], lessons, {'a': LessonStatus.completed});
      expect(p.ratio, 0.25);
      expect(p.doneModules, 1);
    });

    test('all completed → 1.0, done, doneModules == totalModules', () {
      final lessons = [lesson('a', 'm1'), lesson('b', 'm2')];
      final p = LearningProgressService.computeCourse(course, [m1, m2],
          lessons, {'a': LessonStatus.completed, 'b': LessonStatus.completed});
      expect(p.ratio, 1.0);
      expect(p.isDone, isTrue);
      expect(p.doneModules, 2);
      expect(p.totalModules, 2);
    });

    test('one module done + one empty module → not done', () {
      final p = LearningProgressService.computeCourse(course, [m1, m2],
          [lesson('a', 'm1')], {'a': LessonStatus.completed});
      // Every existing lesson is completed (ratio 1.0) but the empty module
      // keeps the course not done.
      expect(p.ratio, 1.0);
      expect(p.doneModules, 1);
      expect(p.totalModules, 2);
      expect(p.isDone, isFalse);
      expect(p.modules[1].isDone, isFalse);
    });

    test('progress rows / lessons of foreign modules are ignored', () {
      final lessons = [lesson('a', 'm1'), lesson('x', 'other')];
      final p = LearningProgressService.computeCourse(course, [m1], lessons, {
        'a': LessonStatus.inProgress,
        'x': LessonStatus.completed,
        'ghost': LessonStatus.completed,
      });
      expect(p.totalLessons, 1);
      expect(p.completedLessons, 0);
      expect(p.ratio, 0.0);
      final mp = LearningProgressService.computeModule(m1, lessons,
          LearningProgressService.statusById([_p('x', LessonStatus.completed)]));
      expect(mp.totalLessons, 1);
      expect(mp.completedLessons, 0);
    });
  });

  group('service (through repository)', () {
    late _FakeLearning repo;
    late LearningProgressService service;

    setUp(() {
      repo = _FakeLearning();
      service = LearningProgressService(repo);
    });

    test('courseProgressOf missing → null', () async {
      expect(await service.courseProgressOf('missing'), isNull);
    });

    test('courseProgressOf end-to-end; works for hidden courses', () async {
      repo.all[course.id] = course;
      repo.hidden.add(course.id);
      repo.modules.addAll([m1, m2]);
      repo.lessons.addAll([lesson('a', 'm1'), lesson('b', 'm2')]);
      repo.progress.add(_p('a', LessonStatus.completed));

      final p = (await service.courseProgressOf(course.id))!;
      expect(p.courseId, 'c');
      expect(p.ratio, 0.5);
      expect(p.modules.map((m) => m.moduleId), ['m1', 'm2']);
    });

    test('progressOfLiveCourses excludes trashed / archived', () async {
      repo.all['c'] = course;
      repo.all['t'] = Course(id: 't', title: 'Trashed');
      repo.all['a'] = Course(id: 'a', title: 'Archived');
      repo.hidden.addAll(['t', 'a']);

      final map = await service.progressOfLiveCourses();
      expect(map.keys, ['c']);
      expect(map['c']!.ratio, 0.0);
    });
  });
}
