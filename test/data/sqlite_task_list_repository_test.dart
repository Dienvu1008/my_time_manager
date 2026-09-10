@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test for [SqliteTaskListRepository]. Focuses on the non-trivial
/// cascade invariants that no other test covers: soft-delete and archive of a
/// list cascade to its child tasks, and restore/unarchive bring back only the
/// children that were removed *together with the list* (timestamp-matched) —
/// not children the user had already deleted/archived on their own.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late SqliteTaskListRepository lists;
  late SqliteTaskRepository tasks;

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
    lists = SqliteTaskListRepository();
    tasks = SqliteTaskRepository();
  });

  test('create + getTaskList round-trips; getTaskLists lists it', () async {
    final list = TaskList(title: 'Work');
    await lists.createTaskList(list);

    expect((await lists.getTaskList(list.id)).title, 'Work');
    expect((await lists.getTaskLists()).map((l) => l.id), contains(list.id));
  });

  test('updateTaskList persists changes', () async {
    final list = TaskList(title: 'Old');
    await lists.createTaskList(list);

    final renamed = list.copyWith(title: 'New');
    await lists.updateTaskList(renamed);

    expect((await lists.getTaskList(list.id)).title, 'New');
  });

  test('getTaskLists excludes trashed and archived lists', () async {
    final trashed = TaskList(title: 'Trashed');
    final archived = TaskList(title: 'Archived');
    final visible = TaskList(title: 'Visible');
    await lists.createTaskList(trashed);
    await lists.createTaskList(archived);
    await lists.createTaskList(visible);

    await lists.softDeleteTaskList(trashed.id);
    await lists.archiveTaskList(archived.id);

    final visibleIds = (await lists.getTaskLists()).map((l) => l.id).toSet();
    expect(visibleIds, contains(visible.id));
    expect(visibleIds, isNot(contains(trashed.id)));
    expect(visibleIds, isNot(contains(archived.id)));
  });

  test('softDeleteTaskList cascades to children; restore brings the cluster back',
      () async {
    final list = TaskList(title: 'Project');
    await lists.createTaskList(list);
    final child = Task(title: 'Child', taskListId: list.id);
    await tasks.createTask(child);

    await lists.softDeleteTaskList(list.id);

    // Both list and child are hidden from the visible views.
    expect((await lists.getTaskLists()).any((l) => l.id == list.id), isFalse);
    expect((await tasks.getTasks()).any((t) => t.id == child.id), isFalse);

    await lists.restoreTaskList(list.id);

    // Restoring the list restores the child it took down with it.
    expect((await lists.getTaskLists()).any((l) => l.id == list.id), isTrue);
    expect((await tasks.getTasksOfTaskList(list.id)).any((t) => t.id == child.id),
        isTrue);
  });

  test(
      'restoreTaskList does NOT restore a child the user had deleted separately '
      'earlier', () async {
    final list = TaskList(title: 'Project');
    await lists.createTaskList(list);
    final soloDeleted = Task(title: 'Solo', taskListId: list.id);
    final cascaded = Task(title: 'Cascaded', taskListId: list.id);
    await tasks.createTask(soloDeleted);
    await tasks.createTask(cascaded);

    // User trashes one child on its own first.
    await tasks.softDeleteTask(soloDeleted.id);
    // Ensure a distinct deletedAt so the timestamp-match restore can tell them
    // apart (deletedAt has millisecond resolution).
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // Then trashes the whole list (cascades to the still-visible child).
    await lists.softDeleteTaskList(list.id);

    await lists.restoreTaskList(list.id);

    final visibleChildIds =
        (await tasks.getTasksOfTaskList(list.id)).map((t) => t.id).toSet();
    // The cascaded child comes back; the separately-deleted one stays in trash.
    expect(visibleChildIds, contains(cascaded.id));
    expect(visibleChildIds, isNot(contains(soloDeleted.id)));
  });

  test('archiveTaskList cascades to children; unarchive brings the cluster back',
      () async {
    final list = TaskList(title: 'Project');
    await lists.createTaskList(list);
    final child = Task(title: 'Child', taskListId: list.id);
    await tasks.createTask(child);

    await lists.archiveTaskList(list.id);

    expect((await lists.getTaskLists()).any((l) => l.id == list.id), isFalse);
    expect((await tasks.getTasks()).any((t) => t.id == child.id), isFalse);

    await lists.unarchiveTaskList(list.id);

    expect((await lists.getTaskLists()).any((l) => l.id == list.id), isTrue);
    expect((await tasks.getTasksOfTaskList(list.id)).any((t) => t.id == child.id),
        isTrue);
  });

  test(
      'unarchiveTaskList does NOT unarchive a child the user had archived '
      'separately earlier', () async {
    final list = TaskList(title: 'Project');
    await lists.createTaskList(list);
    final soloArchived = Task(title: 'Solo', taskListId: list.id);
    final cascaded = Task(title: 'Cascaded', taskListId: list.id);
    await tasks.createTask(soloArchived);
    await tasks.createTask(cascaded);

    await tasks.archiveTask(soloArchived.id);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await lists.archiveTaskList(list.id);

    await lists.unarchiveTaskList(list.id);

    final visibleChildIds =
        (await tasks.getTasksOfTaskList(list.id)).map((t) => t.id).toSet();
    expect(visibleChildIds, contains(cascaded.id));
    expect(visibleChildIds, isNot(contains(soloArchived.id)));
  });

  test('permanentlyDeleteTaskList removes the list entirely', () async {
    final list = TaskList(title: 'Gone');
    await lists.createTaskList(list);
    await lists.softDeleteTaskList(list.id);

    await lists.permanentlyDeleteTaskList(list.id);

    expect((await lists.getTaskLists()).any((l) => l.id == list.id), isFalse);
    // The row is gone: fetching it should not return a live list.
    await expectLater(lists.getTaskList(list.id), throwsA(anything));
  });
}
