@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/backup/backup_service.dart';
import 'package:my_time_manager/data/backup/import_service.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_milestone.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Backup (JSON export) + import of the C5 tables goals / milestones /
/// goal_links. Import of these tables is update-first (not REPLACE) so that
/// overwriting a goal/milestone never fires ON DELETE CASCADE / SET NULL.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  test('export contains goals, milestones and goal_links', () async {
    final goals = SqliteGoalRepository();
    final g = Goal(title: 'G');
    await goals.createGoal(g);
    await goals.createMilestone(Milestone(goalId: g.id, title: 'M1'));

    final (json, _) = await BackupService().buildContent(ExportFormat.json);
    final data = (jsonDecode(json) as Map)['data'] as Map;
    expect((data['goals'] as List), hasLength(1));
    expect((data['milestones'] as List), hasLength(1));
    expect(data.containsKey('goal_links'), isTrue);
  });

  test('keepIncoming import overwrites goal without cascading', () async {
    final goals = SqliteGoalRepository();
    final tasks = SqliteTaskRepository();
    final g = Goal(title: 'Original');
    await goals.createGoal(g);
    final m1 = Milestone(goalId: g.id, title: 'M1', sortOrder: 1);
    final m2 = Milestone(goalId: g.id, title: 'M2', sortOrder: 2);
    await goals.createMilestone(m1);
    await goals.createMilestone(m2);
    final t = Task(title: 'T');
    await tasks.createTask(t);
    final link = await goals.linkTask(g.id, t.id, milestoneId: m1.id);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    // Local edits after the backup.
    await goals.updateGoal(g.copyWith(title: 'Local edit'));
    await goals.updateMilestone(m1.copyWith(title: 'M1 local'));
    final localOnly = Milestone(goalId: g.id, title: 'Local only');
    await goals.createMilestone(localOnly);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    expect((await goals.getGoal(g.id))!.title, 'Original');
    expect((await goals.getMilestone(m1.id))!.title, 'M1');
    final ms = await goals.getMilestones(g.id);
    expect(ms.map((m) => m.id), containsAll([m1.id, m2.id, localOnly.id]));
    final links = await goals.getLinks(g.id);
    expect(links, hasLength(1));
    expect(links.single.id, link.id);
    expect(links.single.milestoneId, m1.id);
  });

  test('import into a fresh DB restores all three tables', () async {
    final goals = SqliteGoalRepository();
    final tasks = SqliteTaskRepository();
    final g = Goal(title: 'G', status: GoalStatus.paused);
    await goals.createGoal(g);
    final m = Milestone(goalId: g.id, title: 'M');
    await goals.createMilestone(m);
    final t = Task(title: 'T');
    await tasks.createTask(t);
    await goals.linkTask(g.id, t.id, milestoneId: m.id);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    await DatabaseManager().resetForTesting(inMemory: true);
    expect(await goals.getGoal(g.id), isNull);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    final back = await goals.getGoal(g.id);
    expect(back, isNotNull);
    expect(back!.status, GoalStatus.paused);
    expect(await goals.getMilestones(g.id), hasLength(1));
    final links = await goals.getLinks(g.id);
    expect(links.single.milestoneId, m.id);
    expect(links.single.entityId, t.id);
  });
}
