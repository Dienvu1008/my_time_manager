@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/backup/backup_service.dart';
import 'package:my_time_manager/data/backup/import_service.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_project_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Backup (JSON export) + import of the C6 tables projects / project_items.
/// Import of these tables is update-first (not REPLACE) so that overwriting a
/// project never fires ON DELETE CASCADE on its items.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  test('export contains projects and project_items', () async {
    final projects = SqliteProjectRepository();
    final p = Project(title: 'P');
    await projects.createProject(p);
    await projects.addItem(p.id, ProjectEntityType.task, 't1');

    final (json, _) = await BackupService().buildContent(ExportFormat.json);
    final data = (jsonDecode(json) as Map)['data'] as Map;
    expect((data['projects'] as List), hasLength(1));
    expect((data['project_items'] as List), hasLength(1));
  });

  test('keepIncoming import overwrites project without cascading', () async {
    final projects = SqliteProjectRepository();
    final tasks = SqliteTaskRepository();
    final p = Project(title: 'Original');
    await projects.createProject(p);
    final t = Task(title: 'T');
    await tasks.createTask(t);
    final item = await projects.addItem(p.id, ProjectEntityType.task, t.id);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    // Local edits after the backup.
    await projects.updateProject(p.copyWith(title: 'Local edit'));
    final local =
        await projects.addItem(p.id, ProjectEntityType.note, 'local-note');

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    expect((await projects.getProject(p.id))!.title, 'Original');
    final items = await projects.getItems(p.id);
    expect(items.map((i) => i.id), containsAll([item.id, local.id]));
    expect(items, hasLength(2));
  });

  test('import into a fresh DB restores project and items', () async {
    final projects = SqliteProjectRepository();
    final tasks = SqliteTaskRepository();
    final p = Project(
      title: 'P',
      status: ProjectStatus.onHold,
      startDate: DateTime(2026, 3, 1),
    );
    await projects.createProject(p);
    final t = Task(title: 'T');
    await tasks.createTask(t);
    await projects.addItem(p.id, ProjectEntityType.task, t.id, sortOrder: 2);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    await DatabaseManager().resetForTesting(inMemory: true);
    expect(await projects.getProject(p.id), isNull);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    final back = await projects.getProject(p.id);
    expect(back, isNotNull);
    expect(back!.status, ProjectStatus.onHold);
    expect(back.startDate, DateTime(2026, 3, 1));
    final items = await projects.getItems(p.id);
    expect(items.single.entityId, t.id);
    expect(items.single.sortOrder, 2);
    expect((await tasks.getTasks()).map((e) => e.id), [t.id]);
  });
}
