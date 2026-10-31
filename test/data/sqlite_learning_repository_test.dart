@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_archive_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_learning_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_project_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_trash_repository.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/screen_archive/model_archived_item.dart';
import 'package:my_time_manager/screen_trash/model_trashed_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract tests for [SqliteLearningRepository] (C7) against an in-memory DB
/// with the production schema (v15).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Fresh unique in-memory DB per test. No tearDown (see other repo tests).
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  late SqliteLearningRepository repo;

  setUp(() {
    repo = SqliteLearningRepository();
  });

  Future<int> count(String table) async {
    final db = await DatabaseManager().database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return r.first['c'] as int;
  }

  /// Course with 2 modules × 2 lessons, one lesson completed.
  Future<(Course, List<CourseModule>, List<Lesson>)> seed() async {
    final c = Course(title: 'C');
    await repo.createCourse(c);
    final m1 = CourseModule(courseId: c.id, title: 'M1', sortOrder: 0);
    final m2 = CourseModule(courseId: c.id, title: 'M2', sortOrder: 1);
    await repo.createModule(m1);
    await repo.createModule(m2);
    final lessons = [
      Lesson(moduleId: m1.id, title: 'L1', sortOrder: 0),
      Lesson(moduleId: m1.id, title: 'L2', sortOrder: 1),
      Lesson(moduleId: m2.id, title: 'L3', sortOrder: 0),
      Lesson(moduleId: m2.id, title: 'L4', sortOrder: 1),
    ];
    for (final l in lessons) {
      await repo.createLesson(l);
    }
    await repo.markLessonCompleted(lessons.first.id);
    return (c, [m1, m2], lessons);
  }

  group('courses CRUD', () {
    test('create / get / update round-trip all fields', () async {
      final c = Course(
        title: 'Flutter',
        description: 'desc',
        color: const Color(0xFF123456),
        source: CourseSource.aiGenerated,
        status: CourseStatus.paused,
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      await repo.createCourse(c);
      expect(await repo.getCourse(c.id), c);

      final updated = c.copyWith(
          title: 'Flutter 2',
          status: CourseStatus.active,
          updateTimeStamp: DateTime(2026, 2, 1));
      await repo.updateCourse(updated);
      expect(await repo.getCourse(c.id), updated);
      expect((await repo.getCourse(c.id))!.source, CourseSource.aiGenerated);
    });

    test('getCourse unknown id → null; getCourses oldest first', () async {
      expect(await repo.getCourse('nope'), isNull);
      final b = Course(title: 'B', createdAt: DateTime(2026, 2, 1));
      final a = Course(title: 'A', createdAt: DateTime(2026, 1, 1));
      await repo.createCourse(b);
      await repo.createCourse(a);
      expect((await repo.getCourses()).map((c) => c.id), [a.id, b.id]);
    });

    test('insert stamps deviceId', () async {
      DatabaseManager.setCurrentDeviceId('dev-1');
      final c = Course(title: 'C');
      await repo.createCourse(c);
      final db = await DatabaseManager().database;
      final row = (await db.query('courses')).single;
      expect(row['deviceId'], 'dev-1');
    });
  });

  group('modules & lessons', () {
    test('module / lesson round-trip incl. JSON columns', () async {
      final c = Course(title: 'C');
      await repo.createCourse(c);
      final m = CourseModule(courseId: c.id, title: 'M', description: 'd');
      await repo.createModule(m);
      expect(await repo.getModule(m.id), m);

      final l = Lesson(
        moduleId: m.id,
        title: 'L',
        contentJson: '{"document":{"type":"page","children":[]}}',
        links: const [LessonLink(title: 'Docs', url: 'https://dart.dev')],
        noteIds: const ['n1', 'n2'],
      );
      await repo.createLesson(l);
      expect(await repo.getLesson(l.id), l);

      final m2 = m.copyWith(title: 'M*');
      await repo.updateModule(m2);
      expect((await repo.getModule(m.id))!.title, 'M*');
      final l2 = l.copyWith(title: 'L*', links: const [], noteIds: const ['x']);
      await repo.updateLesson(l2);
      expect(await repo.getLesson(l.id), l2);
    });

    test('ordering: sortOrder then createdAt; reorder', () async {
      final c = Course(title: 'C');
      await repo.createCourse(c);
      final a = CourseModule(
          courseId: c.id, title: 'A', sortOrder: 1, createdAt: DateTime(2026, 1, 2));
      final b = CourseModule(
          courseId: c.id, title: 'B', sortOrder: 1, createdAt: DateTime(2026, 1, 1));
      final z = CourseModule(courseId: c.id, title: 'Z', sortOrder: 0);
      for (final m in [a, b, z]) {
        await repo.createModule(m);
      }
      expect((await repo.getModules(c.id)).map((m) => m.title), ['Z', 'B', 'A']);

      await repo.reorderModules(c.id, [a.id, z.id, b.id]);
      expect((await repo.getModules(c.id)).map((m) => m.title), ['A', 'Z', 'B']);

      final l1 = Lesson(moduleId: a.id, title: 'l1', sortOrder: 2);
      final l2 = Lesson(moduleId: a.id, title: 'l2', sortOrder: 0);
      final l3 = Lesson(moduleId: z.id, title: 'l3');
      for (final l in [l1, l2, l3]) {
        await repo.createLesson(l);
      }
      expect((await repo.getLessons(a.id)).map((l) => l.title), ['l2', 'l1']);
      await repo.reorderLessons(a.id, [l1.id, l2.id]);
      expect((await repo.getLessons(a.id)).map((l) => l.title), ['l1', 'l2']);

      // Across modules: module order, then lesson order.
      expect((await repo.getLessonsOfCourse(c.id)).map((l) => l.title),
          ['l1', 'l2', 'l3']);
    });

    test('create with missing parent throws ArgumentError', () async {
      await expectLater(
          repo.createModule(CourseModule(courseId: 'nope', title: 'M')),
          throwsArgumentError);
      await expectLater(
          repo.createLesson(Lesson(moduleId: 'nope', title: 'L')),
          throwsArgumentError);
      await expectLater(repo.markLessonOpened('nope'), throwsArgumentError);
      await expectLater(repo.markLessonCompleted('nope'), throwsArgumentError);
      await expectLater(repo.markLessonIncomplete('nope'), throwsArgumentError);
      expect(await count('course_modules'), 0);
      expect(await count('lessons'), 0);
      expect(await count('lesson_progress'), 0);
    });
  });

  group('delete / cascade', () {
    test('hard delete course cascades modules, lessons, progress', () async {
      final (c, _, _) = await seed();
      expect(await count('lesson_progress'), 1);
      await repo.deleteCourse(c.id);
      expect(await repo.getCourse(c.id), isNull);
      for (final t in ['course_modules', 'lessons', 'lesson_progress']) {
        expect(await count(t), 0, reason: t);
      }
    });

    test('deleteModule cascades only its lessons and progress', () async {
      final (c, modules, lessons) = await seed();
      await repo.deleteModule(modules.first.id);
      expect((await repo.getModules(c.id)).map((m) => m.id), [modules[1].id]);
      expect((await repo.getLessonsOfCourse(c.id)).map((l) => l.id),
          [lessons[2].id, lessons[3].id]);
      expect(await count('lesson_progress'), 0);
    });

    test('deleteLesson cascades its progress', () async {
      final (_, _, lessons) = await seed();
      await repo.deleteLesson(lessons.first.id);
      expect(await repo.getLesson(lessons.first.id), isNull);
      expect(await count('lessons'), 3);
      expect(await count('lesson_progress'), 0);
    });

    test('softDelete hides course, keeps children; restore', () async {
      final (c, _, _) = await seed();
      await repo.softDeleteCourse(c.id);
      expect(await repo.getCourses(), isEmpty);
      final trashed = await repo.getCourse(c.id);
      expect(trashed!.isDeleted, isTrue);
      expect(trashed.deletedAt, isNotNull);
      expect(await count('course_modules'), 2);
      expect(await count('lessons'), 4);
      expect(await count('lesson_progress'), 1);

      await repo.restoreCourse(c.id);
      final back = await repo.getCourse(c.id);
      expect(back!.isDeleted, isFalse);
      expect(back.deletedAt, isNull);
      expect((await repo.getCourses()).map((e) => e.id), [c.id]);
    });

    test('archive hides course, keeps children; unarchive', () async {
      final (c, _, _) = await seed();
      await repo.archiveCourse(c.id);
      expect(await repo.getCourses(), isEmpty);
      expect((await repo.getCourse(c.id))!.isArchived, isTrue);
      expect(await count('lessons'), 4);

      await repo.unarchiveCourse(c.id);
      final back = await repo.getCourse(c.id);
      expect(back!.isArchived, isFalse);
      expect(back.archivedAt, isNull);
      expect(await repo.getCourses(), hasLength(1));
    });
  });

  group('progress transitions', () {
    late Lesson lesson;

    setUp(() async {
      final (_, _, lessons) = await seed();
      lesson = lessons[1]; // no progress row yet
    });

    test('open twice: inProgress, startedAt kept, lastOpenedAt updated',
        () async {
      expect(await repo.getLessonProgress(lesson.id), isNull);
      final first = await repo.markLessonOpened(lesson.id);
      expect(first.status, LessonStatus.inProgress);
      expect(first.startedAt, isNotNull);
      expect(first.lastOpenedAt, first.startedAt);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await repo.markLessonOpened(lesson.id);
      expect(second.startedAt, first.startedAt);
      expect(second.lastOpenedAt!.isAfter(first.lastOpenedAt!), isTrue);
      expect(await repo.getLessonProgress(lesson.id), second);
      expect(await count('lesson_progress'), 2); // seed + this one
    });

    test('complete then open keeps completed', () async {
      await repo.markLessonOpened(lesson.id);
      final done = await repo.markLessonCompleted(lesson.id);
      expect(done.status, LessonStatus.completed);
      expect(done.completedAt, isNotNull);
      final opened = await repo.markLessonOpened(lesson.id);
      expect(opened.status, LessonStatus.completed);
      expect(opened.completedAt, done.completedAt);
    });

    test('complete without a row sets startedAt; id == lessonId', () async {
      final done = await repo.markLessonCompleted(lesson.id);
      expect(done.startedAt, isNotNull);
      final db = await DatabaseManager().database;
      final row = (await db.query('lesson_progress',
              where: 'lessonId = ?', whereArgs: [lesson.id]))
          .single;
      expect(row['id'], lesson.id);
    });

    test('incomplete clears completedAt; without a row writes nothing',
        () async {
      final none = await repo.markLessonIncomplete(lesson.id);
      expect(none.status, LessonStatus.notStarted);
      expect(await repo.getLessonProgress(lesson.id), isNull);

      await repo.markLessonCompleted(lesson.id);
      final undone = await repo.markLessonIncomplete(lesson.id);
      expect(undone.status, LessonStatus.inProgress);
      expect(undone.completedAt, isNull);
      expect((await repo.getLessonProgress(lesson.id))!.completedAt, isNull);
    });

    test('getProgressForCourse returns only that course\'s rows', () async {
      final other = Course(title: 'Other');
      await repo.createCourse(other);
      final m = CourseModule(courseId: other.id, title: 'M');
      await repo.createModule(m);
      final l = Lesson(moduleId: m.id, title: 'L');
      await repo.createLesson(l);
      await repo.markLessonOpened(l.id);

      final rows = await repo.getProgressForCourse(other.id);
      expect(rows.map((p) => p.lessonId), [l.id]);
    });
  });

  group('cleanup triggers (goal_links / project_items)', () {
    test('soft delete keeps links; hard delete removes only course rows',
        () async {
      final c = Course(title: 'C');
      await repo.createCourse(c);
      final goals = SqliteGoalRepository();
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      await goals.linkCourse(g.id, c.id);
      await goals.linkCourse(g.id, 'other-course');
      final projects = SqliteProjectRepository();
      final p = Project(title: 'P');
      await projects.createProject(p);
      await projects.addItem(p.id, ProjectEntityType.course, c.id);
      // Same id but another entity type must survive.
      await projects.addItem(p.id, ProjectEntityType.note, c.id);

      await repo.softDeleteCourse(c.id);
      expect(await goals.getLinksForEntity(GoalEntityType.course, c.id),
          hasLength(1));
      expect(await projects.getItems(p.id), hasLength(2));

      await repo.permanentlyDeleteCourse(c.id);
      expect(await goals.getLinksForEntity(GoalEntityType.course, c.id),
          isEmpty);
      expect((await goals.getLinks(g.id)).single.entityId, 'other-course');
      final items = await projects.getItems(p.id);
      expect(items.single.entityType, ProjectEntityType.note);
    });
  });

  group('trash / archive integration', () {
    test('trashed course is listed; restore works', () async {
      final (c, _, _) = await seed();
      await repo.softDeleteCourse(c.id);
      final trash = SqliteTrashRepository();
      final items = await trash.getTrashedItems();
      final item = items.singleWhere((i) => i.id == c.id);
      expect(item.type, TrashedItemType.course);
      expect(item.title, 'C');

      await trash.restore(item);
      expect(await repo.getCourses(), hasLength(1));
      expect(await trash.getTrashedItems(), isEmpty);
    });

    test('permanentlyDelete from trash cascades', () async {
      final (c, _, _) = await seed();
      await repo.softDeleteCourse(c.id);
      final trash = SqliteTrashRepository();
      final item = (await trash.getTrashedItems()).single;
      await trash.permanentlyDelete(item);
      expect(await count('courses'), 0);
      expect(await count('lessons'), 0);
      expect(await count('lesson_progress'), 0);
    });

    test('emptyTrash and purgeExpiredTrash remove course and children',
        () async {
      final (c, _, _) = await seed();
      await repo.softDeleteCourse(c.id);
      final trash = SqliteTrashRepository();
      await trash.emptyTrash();
      expect(await count('courses'), 0);
      expect(await count('course_modules'), 0);

      final (c2, _, _) = await seed();
      await repo.softDeleteCourse(c2.id);
      final db = await DatabaseManager().database;
      await db.update('courses',
          {'deletedAt': DateTime(2000, 1, 1).toIso8601String()},
          where: 'id = ?', whereArgs: [c2.id]);
      expect(await trash.purgeExpiredTrash(30), 1);
      expect(await count('courses'), 0);
      expect(await count('lessons'), 0);
    });

    test('archive listing, unarchive and moveToTrash', () async {
      final (c, _, _) = await seed();
      await repo.archiveCourse(c.id);
      final archive = SqliteArchiveRepository();
      final item = (await archive.getArchivedItems()).single;
      expect(item.type, ArchivedItemType.course);

      await archive.unarchive(item);
      expect(await repo.getCourses(), hasLength(1));

      await repo.archiveCourse(c.id);
      final again = (await archive.getArchivedItems()).single;
      await archive.moveToTrash(again);
      final back = await repo.getCourse(c.id);
      expect(back!.isArchived, isFalse);
      expect(back.isDeleted, isTrue);
      expect(await archive.getArchivedItems(), isEmpty);
      expect((await SqliteTrashRepository().getTrashedItems()).single.type,
          TrashedItemType.course);
      expect(await count('lessons'), 4);
    });
  });
}
