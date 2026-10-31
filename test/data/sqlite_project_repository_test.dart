@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_note_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_project_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_note.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract tests for [SqliteProjectRepository] (C6) against an in-memory DB
/// with the production schema (v14).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Fresh unique in-memory DB per test. No tearDown (see other repo tests).
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  late SqliteProjectRepository projects;
  late SqliteTaskRepository tasks;
  late SqliteTaskListRepository lists;
  late SqliteNoteRepository notes;
  late SqliteCalendarRepository calendar;
  late SqliteGoalRepository goals;

  setUp(() {
    projects = SqliteProjectRepository();
    tasks = SqliteTaskRepository();
    lists = SqliteTaskListRepository();
    notes = SqliteNoteRepository();
    calendar = SqliteCalendarRepository();
    goals = SqliteGoalRepository();
  });

  Future<int> count(String table) async {
    final db = await DatabaseManager().database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return r.first['c'] as int;
  }

  Future<Project> newProject([String title = 'P']) async {
    final p = Project(title: title);
    await projects.createProject(p);
    return p;
  }

  CalendarEvent newEvent(String title) => CalendarEvent(
        title: title,
        start: EventDateTime(dateTime: DateTime(2026, 5, 1, 9)),
        end: EventDateTime(dateTime: DateTime(2026, 5, 1, 10)),
      );

  group('projects CRUD', () {
    test('create / get / update round-trip all fields', () async {
      final p = Project(
        title: 'Website',
        description: 'Relaunch',
        color: const Color(0xFF00FF00),
        status: ProjectStatus.onHold,
        startDate: DateTime(2026, 2, 1),
        targetDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      await projects.createProject(p);
      expect(await projects.getProject(p.id), p);

      final updated = p.copyWith(
          title: 'Website v2',
          status: ProjectStatus.completed,
          clearStartDate: true);
      await projects.updateProject(updated);
      final back = await projects.getProject(p.id);
      expect(back, updated);
      expect(back!.startDate, isNull);
      expect(back.targetDate, DateTime(2026, 9, 1));
      expect(back.status, ProjectStatus.completed);
    });

    test('getProject unknown id → null', () async {
      expect(await projects.getProject('nope'), isNull);
    });

    test('getProjects excludes trashed and archived', () async {
      final a = await newProject('A');
      final b = await newProject('B');
      final c = await newProject('C');
      await projects.softDeleteProject(b.id);
      await projects.archiveProject(c.id);
      expect((await projects.getProjects()).map((p) => p.id), [a.id]);
    });

    test('softDelete → restore keeps items; linked task stays visible',
        () async {
      final p = await newProject();
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await projects.addItem(p.id, ProjectEntityType.task, t.id);

      await projects.softDeleteProject(p.id);
      final trashed = await projects.getProject(p.id);
      expect(trashed!.isDeleted, isTrue);
      expect(trashed.deletedAt, isNotNull);
      expect(await projects.getItems(p.id), hasLength(1));
      expect((await tasks.getTasks()).map((e) => e.id), contains(t.id));

      await projects.restoreProject(p.id);
      final back = await projects.getProject(p.id);
      expect(back!.isDeleted, isFalse);
      expect(back.deletedAt, isNull);
      expect(await projects.getItems(p.id), hasLength(1));
    });

    test('archive → unarchive keeps items; linked task stays visible',
        () async {
      final p = await newProject();
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await projects.addItem(p.id, ProjectEntityType.task, t.id);

      await projects.archiveProject(p.id);
      expect((await projects.getProject(p.id))!.isArchived, isTrue);
      expect(await projects.getItems(p.id), hasLength(1));
      expect((await tasks.getTasks()).map((e) => e.id), contains(t.id));

      await projects.unarchiveProject(p.id);
      final back = await projects.getProject(p.id);
      expect(back!.isArchived, isFalse);
      expect(back.archivedAt, isNull);
      expect(await projects.getItems(p.id), hasLength(1));
    });

    test('permanentlyDeleteProject removes items only, never entities',
        () async {
      final p = await newProject();
      final list = TaskList(title: 'L');
      await lists.createTaskList(list);
      final t = Task(title: 'T');
      await tasks.createTask(t);
      final n = Note(title: 'N');
      await notes.createNote(n);
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      await projects.addItem(p.id, ProjectEntityType.taskList, list.id);
      await projects.addItem(p.id, ProjectEntityType.task, t.id);
      await projects.addItem(p.id, ProjectEntityType.note, n.id);
      await projects.addItem(p.id, ProjectEntityType.goal, g.id);
      expect(await count('project_items'), 4);

      await projects.permanentlyDeleteProject(p.id);
      expect(await projects.getProject(p.id), isNull);
      expect(await count('project_items'), 0);
      expect(await count('tasklists'), 1);
      expect(await count('tasks'), 1);
      expect(await count('notes'), 1);
      expect(await count('goals'), 1);
    });
  });

  group('items', () {
    test('addItem is an upsert; sortOrder updated when given', () async {
      final p = await newProject();
      final first = await projects.addItem(p.id, ProjectEntityType.task, 't1');
      final second =
          await projects.addItem(p.id, ProjectEntityType.task, 't1');
      expect(second.id, first.id);
      expect(await count('project_items'), 1);

      final third = await projects
          .addItem(p.id, ProjectEntityType.task, 't1', sortOrder: 5);
      expect(third.id, first.id);
      expect(third.sortOrder, 5);
      expect((await projects.getItems(p.id)).single.sortOrder, 5);
    });

    test('unique index rejects a raw duplicate triple', () async {
      final p = await newProject();
      await projects.addItem(p.id, ProjectEntityType.note, 'n1');
      final db = await DatabaseManager().database;
      await expectLater(
        db.insert('project_items', {
          'id': 'dup',
          'projectId': p.id,
          'entityType': ProjectEntityType.note,
          'entityId': 'n1',
          'sortOrder': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('an entity may belong to several projects', () async {
      final a = await newProject('A');
      final b = await newProject('B');
      await projects.addItem(a.id, ProjectEntityType.task, 't1');
      await projects.addItem(b.id, ProjectEntityType.task, 't1');
      final forEntity =
          await projects.getItemsForEntity(ProjectEntityType.task, 't1');
      expect(forEntity.map((i) => i.projectId).toSet(), {a.id, b.id});
    });

    test('getItems ordered by sortOrder', () async {
      final p = await newProject();
      final i3 = await projects.addItem(p.id, ProjectEntityType.task, 'c',
          sortOrder: 3);
      final i1 = await projects.addItem(p.id, ProjectEntityType.task, 'a',
          sortOrder: 1);
      final i2 = await projects.addItem(p.id, ProjectEntityType.note, 'b',
          sortOrder: 2);
      expect((await projects.getItems(p.id)).map((i) => i.id),
          [i1.id, i2.id, i3.id]);
    });

    test('addItem validates project and entityType', () async {
      await expectLater(
          projects.addItem('missing', ProjectEntityType.task, 't1'),
          throwsArgumentError);
      final p = await newProject();
      await expectLater(
          projects.addItem(p.id, '  ', 't1'), throwsArgumentError);
      expect(await count('project_items'), 0);
    });

    test('removeItem / removeEntity', () async {
      final p = await newProject();
      final i1 = await projects.addItem(p.id, ProjectEntityType.task, 't1');
      await projects.addItem(p.id, ProjectEntityType.note, 'n1');
      await projects.removeItem(i1.id);
      await projects.removeEntity(p.id, ProjectEntityType.note, 'n1');
      expect(await projects.getItems(p.id), isEmpty);
    });
  });

  group('entity delete triggers', () {
    test('hard delete of task / note / event / goal removes its item',
        () async {
      final p = await newProject();
      final t = Task(title: 'T');
      await tasks.createTask(t);
      final n = Note(title: 'N');
      await notes.createNote(n);
      final e = newEvent('E');
      await calendar.createCalendarEvent(e);
      final g = Goal(title: 'G');
      await goals.createGoal(g);
      await projects.addItem(p.id, ProjectEntityType.task, t.id);
      await projects.addItem(p.id, ProjectEntityType.note, n.id);
      await projects.addItem(p.id, ProjectEntityType.calendarEvent, e.id);
      await projects.addItem(p.id, ProjectEntityType.goal, g.id);

      await tasks.deleteTask(t.id);
      expect((await projects.getItems(p.id)).map((i) => i.entityType),
          isNot(contains(ProjectEntityType.task)));
      await notes.deleteNote(n.id);
      expect((await projects.getItems(p.id)).map((i) => i.entityType),
          isNot(contains(ProjectEntityType.note)));
      await calendar.deleteCalendarEvent(e.id);
      expect((await projects.getItems(p.id)).map((i) => i.entityType),
          isNot(contains(ProjectEntityType.calendarEvent)));
      await goals.deleteGoal(g.id);
      expect(await projects.getItems(p.id), isEmpty);
    });

    test('tasklist hard delete removes list item and child task item',
        () async {
      final p = await newProject();
      final list = TaskList(title: 'L');
      await lists.createTaskList(list);
      final t = Task(title: 'Child', taskListId: list.id);
      await tasks.createTask(t);
      await projects.addItem(p.id, ProjectEntityType.taskList, list.id);
      await projects.addItem(p.id, ProjectEntityType.task, t.id);

      await lists.deleteTaskList(list.id);
      expect(await projects.getItems(p.id), isEmpty);
    });

    test('task soft-delete keeps its item row', () async {
      final p = await newProject();
      final t = Task(title: 'T');
      await tasks.createTask(t);
      await projects.addItem(p.id, ProjectEntityType.task, t.id);

      await tasks.softDeleteTask(t.id);
      expect(await projects.getItems(p.id), hasLength(1));
    });
  });
}
