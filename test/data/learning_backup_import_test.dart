@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/backup/backup_service.dart';
import 'package:my_time_manager/data/backup/import_service.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_learning_repository.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Backup (JSON export) + import of the C7 tables courses / course_modules /
/// lessons / lesson_progress. Import of these tables is update-first (not
/// REPLACE) so that overwriting a course never cascades to its local children.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  Future<(Course, CourseModule, Lesson)> seed(
      SqliteLearningRepository repo) async {
    final c = Course(
        title: 'Course',
        status: CourseStatus.paused,
        source: CourseSource.aiGenerated);
    await repo.createCourse(c);
    final m = CourseModule(courseId: c.id, title: 'M', sortOrder: 3);
    await repo.createModule(m);
    final l = Lesson(
      moduleId: m.id,
      title: 'L',
      contentJson: '{"document":{"type":"page","children":[]}}',
      links: const [LessonLink(title: 'Dart', url: 'https://dart.dev')],
      noteIds: const ['note-1'],
      sortOrder: 2,
    );
    await repo.createLesson(l);
    await repo.markLessonCompleted(l.id);
    return (c, m, l);
  }

  test('export contains the 4 learning tables', () async {
    await seed(SqliteLearningRepository());
    final (json, _) = await BackupService().buildContent(ExportFormat.json);
    final data = (jsonDecode(json) as Map)['data'] as Map;
    for (final t in ['courses', 'course_modules', 'lessons', 'lesson_progress']) {
      expect((data[t] as List), hasLength(1), reason: t);
    }
  });

  test('import into a fresh DB restores the whole tree', () async {
    final repo = SqliteLearningRepository();
    final (c, m, l) = await seed(repo);
    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    await DatabaseManager().resetForTesting(inMemory: true);
    expect(await repo.getCourse(c.id), isNull);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    final course = await repo.getCourse(c.id);
    expect(course!.status, CourseStatus.paused);
    expect(course.source, CourseSource.aiGenerated);
    expect((await repo.getModules(c.id)).single.sortOrder, 3);
    final lesson = await repo.getLesson(l.id);
    expect(lesson, l);
    expect(lesson!.contentJson, l.contentJson);
    expect(lesson.links.single.url, 'https://dart.dev');
    expect(lesson.noteIds, ['note-1']);
    expect((await repo.getLessonProgress(l.id))!.status,
        LessonStatus.completed);
    expect(m.id, isNotEmpty);
  });

  test('keepIncoming overwrite of a course keeps local children', () async {
    final repo = SqliteLearningRepository();
    final (c, m, l) = await seed(repo);
    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    // Local edits after the backup.
    await repo.updateCourse(c.copyWith(title: 'Local edit'));
    final localModule = CourseModule(courseId: c.id, title: 'Local module');
    await repo.createModule(localModule);
    await repo.markLessonIncomplete(l.id);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    expect((await repo.getCourse(c.id))!.title, 'Course');
    final modules = await repo.getModules(c.id);
    expect(modules.map((e) => e.id), containsAll([m.id, localModule.id]));
    expect(await repo.getLesson(l.id), isNotNull);
    expect((await repo.getLessonProgress(l.id))!.status,
        LessonStatus.completed);
  });
}
