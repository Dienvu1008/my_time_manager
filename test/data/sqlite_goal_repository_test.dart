@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_milestone.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract tests for [SqliteGoalRepository] (C5) against an in-memory DB with
/// the production schema (v13).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Fresh unique in-memory DB per test. No tearDown (see other repo tests).
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  late SqliteGoalRepository goals;
  late SqliteTaskRepository tasks;

  setUp(() {
    goals = SqliteGoalRepository();
    tasks = SqliteTaskRepository();
  });

  Future<int> linkRowCount() async {
    final db = await DatabaseManager().database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM goal_links');
    return r.first['c'] as int;
  }

  group('goals CRUD', () {
    test('create / get / update round-trip all fields', () async {
      final g = Goal(
        title: 'Learn Dart',
        description: 'deep',
        color: const Color(0xFF00FF00),
        status: GoalStatus.paused,
        targetDate: DateTime(2027, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      await goals.createGoal(g);
      expect(await goals.getGoal(g.id), g);

      final updated = g.copyWith(
          title: 'Learn Dart 3',
          status: GoalStatus.completed,
          clearTargetDate: true);
      await goals.updateGoal(updated);
      final back = await goals.getGoal(g.id);
      expect(back, updated);
      expect(back!.targetDate, isNull);
      expect(back.status, GoalStatus.completed);
    });

    test('getGoal unknown id → null', () async {
      expect(await goals.getGoal('nope'), isNull);
    });

    test('getGoals excludes trashed and archived', () async {
      final a = Goal(title: 'A');
      final b = Goal(title: 'B');
      final c = Goal(title: 'C');
      for (final g in [a, b, c]) {
        await goals.createGoal(g);
      }
      await goals.softDeleteGoal(b.id);
      await goals.archiveGoal(c.id);
      expect((await goals.getGoals()).map((g) => g.id), [a.id]);
    });

    test('softDelete → restore keeps milestones and links (no cascade)',
        () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final m = Milestone(goalId: g.id, title: 'M');
      await goals.createMilestone(m);
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await goals.linkTask(g.id, t.id, milestoneId: m.id);

      await goals.softDeleteGoal(g.id);
      final trashed = await goals.getGoal(g.id);
      expect(trashed!.isDeleted, isTrue);
      expect(trashed.deletedAt, isNotNull);
      expect(await goals.getMilestones(g.id), hasLength(1));
      expect(await goals.getLinks(g.id), hasLength(1));

      await goals.restoreGoal(g.id);
      expect((await goals.getGoals()).map((e) => e.id), contains(g.id));
      expect(await goals.getMilestones(g.id), hasLength(1));
      expect((await goals.getLinks(g.id)).single.milestoneId, m.id);
    });

    test('archive → unarchive keeps milestones and links', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      await goals.createMilestone(Milestone(goalId: g.id, title: 'M'));
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await goals.linkTask(g.id, t.id);

      await goals.archiveGoal(g.id);
      expect((await goals.getGoal(g.id))!.isArchived, isTrue);
      expect(await goals.getMilestones(g.id), hasLength(1));
      expect(await goals.getLinks(g.id), hasLength(1));

      await goals.unarchiveGoal(g.id);
      final back = await goals.getGoal(g.id);
      expect(back!.isArchived, isFalse);
      expect(back.archivedAt, isNull);
      expect(await goals.getMilestones(g.id), hasLength(1));
      expect(await goals.getLinks(g.id), hasLength(1));
    });

    test('permanentlyDeleteGoal cascades milestones and links', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final m = Milestone(goalId: g.id, title: 'M');
      await goals.createMilestone(m);
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await goals.linkTask(g.id, t.id, milestoneId: m.id);

      await goals.permanentlyDeleteGoal(g.id);
      expect(await goals.getGoal(g.id), isNull);
      expect(await goals.getMilestone(m.id), isNull);
      expect(await linkRowCount(), 0);
      // Task itself untouched.
      expect((await tasks.getTasks()).map((e) => e.id), contains(t.id));
    });
  });

  group('milestones', () {
    test('ordered by sortOrder then title; update round-trip', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final m2 = Milestone(goalId: g.id, title: 'B', sortOrder: 2);
      final m1b = Milestone(goalId: g.id, title: 'Z', sortOrder: 1);
      final m1a = Milestone(goalId: g.id, title: 'A', sortOrder: 1);
      for (final m in [m2, m1b, m1a]) {
        await goals.createMilestone(m);
      }
      expect((await goals.getMilestones(g.id)).map((m) => m.id),
          [m1a.id, m1b.id, m2.id]);

      final upd = m2.copyWith(title: 'B2', dueDate: DateTime(2026, 9, 1));
      await goals.updateMilestone(upd);
      expect(await goals.getMilestone(m2.id), upd);
    });

    test('setMilestoneCompleted sets and clears completedAt', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final m = Milestone(goalId: g.id, title: 'M');
      await goals.createMilestone(m);

      await goals.setMilestoneCompleted(m.id, true);
      var back = await goals.getMilestone(m.id);
      expect(back!.isCompleted, isTrue);
      expect(back.completedAt, isNotNull);

      await goals.setMilestoneCompleted(m.id, false);
      back = await goals.getMilestone(m.id);
      expect(back!.isCompleted, isFalse);
      expect(back.completedAt, isNull);
    });

    test('deleteMilestone sets link.milestoneId to null (SET NULL)',
        () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final m = Milestone(goalId: g.id, title: 'M');
      await goals.createMilestone(m);
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await goals.linkTask(g.id, t.id, milestoneId: m.id);

      await goals.deleteMilestone(m.id);
      final links = await goals.getLinks(g.id);
      expect(links, hasLength(1));
      expect(links.single.milestoneId, isNull);
      expect(links.single.entityId, t.id);
    });
  });

  group('links', () {
    test('linkTask is an upsert per (goal, task)', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final m1 = Milestone(goalId: g.id, title: 'M1');
      final m2 = Milestone(goalId: g.id, title: 'M2');
      await goals.createMilestone(m1);
      await goals.createMilestone(m2);
      final t = Task(title: 'T');
      await tasks.createTask(t);

      final first = await goals.linkTask(g.id, t.id, milestoneId: m1.id);
      final second = await goals.linkTask(g.id, t.id, milestoneId: m2.id);
      expect(second.id, first.id);
      final links = await goals.getLinks(g.id);
      expect(links, hasLength(1));
      expect(links.single.milestoneId, m2.id);
      expect(links.single.entityType, GoalEntityType.task);

      final forTask =
          await goals.getLinksForEntity(GoalEntityType.task, t.id);
      expect(forTask.single.id, first.id);
    });

    test('a task may be linked to several goals', () async {
      final a = Goal(title: 'A');
      final b = Goal(title: 'B');
      await goals.createGoal(a);
      await goals.createGoal(b);
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await goals.linkTask(a.id, t.id);
      await goals.linkTask(b.id, t.id);
      expect(await goals.getLinksForEntity(GoalEntityType.task, t.id),
          hasLength(2));
    });

    test('linkTask with a milestone of another goal throws', () async {
      final a = Goal(title: 'A');
      final b = Goal(title: 'B');
      await goals.createGoal(a);
      await goals.createGoal(b);
      final mb = Milestone(goalId: b.id, title: 'MB');
      await goals.createMilestone(mb);
      final t = Task(title: 'T');
      await tasks.createTask(t);

      await expectLater(goals.linkTask(a.id, t.id, milestoneId: mb.id),
          throwsArgumentError);
      await expectLater(goals.linkTask(a.id, t.id, milestoneId: 'missing'),
          throwsArgumentError);
      expect(await linkRowCount(), 0);
    });

    test('unlink / unlinkTask remove links', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final t1 = Task(title: 'T1');
      final t2 = Task(title: 'T2');
      await tasks.createTask(t1);
      await tasks.createTask(t2);
      final l1 = await goals.linkTask(g.id, t1.id);
      await goals.linkTask(g.id, t2.id);

      await goals.unlink(l1.id);
      await goals.unlinkTask(g.id, t2.id);
      expect(await goals.getLinks(g.id), isEmpty);
    });

    test('task hard delete removes its links (trigger)', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final t = Task(title: 'T');
      final keep = Task(title: 'Keep');
      await tasks.createTask(t);
      await tasks.createTask(keep);
      await goals.linkTask(g.id, t.id);
      await goals.linkTask(g.id, keep.id);

      await tasks.deleteTask(t.id);
      final links = await goals.getLinks(g.id);
      expect(links.map((l) => l.entityId), [keep.id]);
    });

    test('tasklist hard delete removes links of its child tasks', () async {
      final lists = SqliteTaskListRepository();
      final list = TaskList(title: 'L');
      await lists.createTaskList(list);
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final t = Task(title: 'Child', taskListId: list.id);
      await tasks.createTask(t);
      await goals.linkTask(g.id, t.id);

      await lists.deleteTaskList(list.id);
      expect(await goals.getLinks(g.id), isEmpty);
    });

    test('task soft-delete keeps the link row', () async {
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await goals.linkTask(g.id, t.id);

      await tasks.softDeleteTask(t.id);
      expect(await goals.getLinks(g.id), hasLength(1));
    });
  });
}
