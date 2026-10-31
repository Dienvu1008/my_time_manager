@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_milestone.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/data/repositories/sqlite_archive_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_trash_repository.dart';
import 'package:my_time_manager/screen_archive/model_archived_item.dart';
import 'package:my_time_manager/screen_trash/model_trashed_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract tests for the cross-entity Trash and Archive repositories, verifying
/// the aggregate list + type-dispatched restore/unarchive/moveToTrash behaviour
/// against an in-memory database.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Fresh unique in-memory DB per test. No tearDown: closing/nulling the
    // shared DatabaseManager singleton between tests races when the whole suite
    // runs in one `flutter test` process. setUp swapping in a fresh DB suffices.
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  group('TrashRepository', () {
    test('getTrashedItems lists a soft-deleted task; restore removes it',
        () async {
      final tasks = SqliteTaskRepository();
      final trash = SqliteTrashRepository();
      final t = Task(title: 'Trash me');
      await tasks.createTask(t);
      await tasks.softDeleteTask(t.id);

      var items = await trash.getTrashedItems();
      expect(items.any((i) => i.id == t.id), isTrue);

      final item =
          items.firstWhere((i) => i.id == t.id);
      await trash.restore(item);

      items = await trash.getTrashedItems();
      expect(items.any((i) => i.id == t.id), isFalse);
      // Restored task is visible again.
      expect((await tasks.getTasks()).map((e) => e.id), contains(t.id));
    });

    test('permanentlyDelete removes the item from trash', () async {
      final tasks = SqliteTaskRepository();
      final trash = SqliteTrashRepository();
      final t = Task(title: 'Gone');
      await tasks.createTask(t);
      await tasks.softDeleteTask(t.id);

      final item = (await trash.getTrashedItems())
          .firstWhere((i) => i.id == t.id);
      await trash.permanentlyDelete(item);

      expect((await trash.getTrashedItems()).any((i) => i.id == t.id), isFalse);
    });

    test('emptyTrash clears all trashed items', () async {
      final tasks = SqliteTaskRepository();
      final trash = SqliteTrashRepository();
      final a = Task(title: 'A');
      final b = Task(title: 'B');
      await tasks.createTask(a);
      await tasks.createTask(b);
      await tasks.softDeleteTask(a.id);
      await tasks.softDeleteTask(b.id);

      await trash.emptyTrash();

      expect(await trash.getTrashedItems(), isEmpty);
    });

    test('_ item type is task for a trashed task', () async {
      final tasks = SqliteTaskRepository();
      final trash = SqliteTrashRepository();
      final t = Task(title: 'A');
      await tasks.createTask(t);
      await tasks.softDeleteTask(t.id);

      final item = (await trash.getTrashedItems())
          .firstWhere((i) => i.id == t.id);
      expect(item.type, TrashedItemType.task);
    });
  });

  group('ArchiveRepository', () {
    test('getArchivedItems lists an archived task; unarchive removes it',
        () async {
      final tasks = SqliteTaskRepository();
      final archive = SqliteArchiveRepository();
      final t = Task(title: 'Archive me');
      await tasks.createTask(t);
      await tasks.archiveTask(t.id);

      var items = await archive.getArchivedItems();
      expect(items.any((i) => i.id == t.id), isTrue);
      expect(items.firstWhere((i) => i.id == t.id).type,
          ArchivedItemType.task);

      await archive.unarchive(items.firstWhere((i) => i.id == t.id));

      items = await archive.getArchivedItems();
      expect(items.any((i) => i.id == t.id), isFalse);
      expect((await tasks.getTasks()).map((e) => e.id), contains(t.id));
    });

    test('moveToTrash unarchives then soft-deletes (item lands in trash)',
        () async {
      final tasks = SqliteTaskRepository();
      final archive = SqliteArchiveRepository();
      final trash = SqliteTrashRepository();
      final t = Task(title: 'A');
      await tasks.createTask(t);
      await tasks.archiveTask(t.id);

      final archived =
          (await archive.getArchivedItems()).firstWhere((i) => i.id == t.id);
      await archive.moveToTrash(archived);

      // No longer archived, now in trash.
      expect((await archive.getArchivedItems()).any((i) => i.id == t.id),
          isFalse);
      expect(
          (await trash.getTrashedItems()).any((i) => i.id == t.id), isTrue);
    });
  });

  group('Goal in Trash/Archive', () {
    Future<int> count(String table) async {
      final db = await DatabaseManager().database;
      final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
      return r.first['c'] as int;
    }

    Future<(Goal, Milestone)> seedGoal(SqliteGoalRepository goals) async {
      final tasks = SqliteTaskRepository();
      final g = Goal(title: 'Goal');
      await goals.createGoal(g);
      final m = Milestone(goalId: g.id, title: 'M');
      await goals.createMilestone(m);
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await goals.linkTask(g.id, t.id, milestoneId: m.id);
      return (g, m);
    }

    test('soft-deleted goal listed as goal; restore makes it visible',
        () async {
      final goals = SqliteGoalRepository();
      final trash = SqliteTrashRepository();
      final (g, _) = await seedGoal(goals);
      await goals.softDeleteGoal(g.id);

      final item =
          (await trash.getTrashedItems()).firstWhere((i) => i.id == g.id);
      expect(item.type, TrashedItemType.goal);
      expect(item.title, 'Goal');
      expect(await goals.getGoals(), isEmpty);

      await trash.restore(item);
      expect((await goals.getGoals()).map((e) => e.id), [g.id]);
      expect(await goals.getMilestones(g.id), hasLength(1));
    });

    test('permanentlyDelete via trash removes goal + milestones + links',
        () async {
      final goals = SqliteGoalRepository();
      final trash = SqliteTrashRepository();
      final (g, m) = await seedGoal(goals);
      await goals.softDeleteGoal(g.id);

      final item =
          (await trash.getTrashedItems()).firstWhere((i) => i.id == g.id);
      await trash.permanentlyDelete(item);

      expect(await goals.getGoal(g.id), isNull);
      expect(await goals.getMilestone(m.id), isNull);
      expect(await count('goal_links'), 0);
    });

    test('emptyTrash removes a trashed goal and its milestones/links',
        () async {
      final goals = SqliteGoalRepository();
      final trash = SqliteTrashRepository();
      final (g, _) = await seedGoal(goals);
      await goals.softDeleteGoal(g.id);

      await trash.emptyTrash();

      expect(await trash.getTrashedItems(), isEmpty);
      expect(await count('goals'), 0);
      expect(await count('milestones'), 0);
      expect(await count('goal_links'), 0);
    });

    test('archived goal listed as goal; unarchive works', () async {
      final goals = SqliteGoalRepository();
      final archive = SqliteArchiveRepository();
      final (g, _) = await seedGoal(goals);
      await goals.archiveGoal(g.id);

      final item =
          (await archive.getArchivedItems()).firstWhere((i) => i.id == g.id);
      expect(item.type, ArchivedItemType.goal);

      await archive.unarchive(item);
      expect(await archive.getArchivedItems(), isEmpty);
      expect((await goals.getGoals()).map((e) => e.id), [g.id]);
    });

    test('moveToTrash on an archived goal lands it in trash', () async {
      final goals = SqliteGoalRepository();
      final archive = SqliteArchiveRepository();
      final trash = SqliteTrashRepository();
      final (g, _) = await seedGoal(goals);
      await goals.archiveGoal(g.id);

      final item =
          (await archive.getArchivedItems()).firstWhere((i) => i.id == g.id);
      await archive.moveToTrash(item);

      expect((await archive.getArchivedItems()).any((i) => i.id == g.id),
          isFalse);
      final trashed =
          (await trash.getTrashedItems()).firstWhere((i) => i.id == g.id);
      expect(trashed.type, TrashedItemType.goal);
      final back = await goals.getGoal(g.id);
      expect(back!.isArchived, isFalse);
      expect(back.isDeleted, isTrue);
    });
  });
}
