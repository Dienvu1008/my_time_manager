@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test: the SQLite-backed repositories are thin adapters over the real
/// [DatabaseManager]. We run against an in-memory sqflite (FFI) database to
/// verify they round-trip domain objects and preserve DatabaseManager semantics
/// (visibility filters, trash/archive) without mocking the DB.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Each test gets a fresh, uniquely-named in-memory DB (resetForTesting
    // closes any previous handle first). We intentionally do NOT tear the DB
    // down afterwards: `flutter test` shares one process across all test files,
    // and closing/nulling the shared DatabaseManager singleton between tests
    // created races when the whole suite runs together. Letting the next test's
    // setUp swap in a fresh DB is sufficient and race-free.
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  test('createTask + getTask round-trips a task', () async {
    final repo = SqliteTaskRepository();
    final task = Task(title: 'Write tests', isImportant: true);

    await repo.createTask(task);
    final fetched = await repo.getTask(task.id);

    expect(fetched.id, task.id);
    expect(fetched.title, 'Write tests');
    expect(fetched.isImportant, isTrue);
  });

  test('getTasks excludes soft-deleted tasks (trash semantics preserved)',
      () async {
    final repo = SqliteTaskRepository();
    final a = Task(title: 'A');
    final b = Task(title: 'B');
    await repo.createTask(a);
    await repo.createTask(b);

    await repo.softDeleteTask(a.id);

    final visible = await repo.getTasks();
    expect(visible.map((t) => t.id), isNot(contains(a.id)));
    expect(visible.map((t) => t.id), contains(b.id));
  });

  test('restoreTask brings a task back into the visible list', () async {
    final repo = SqliteTaskRepository();
    final a = Task(title: 'A');
    await repo.createTask(a);
    await repo.softDeleteTask(a.id);
    await repo.restoreTask(a.id);

    final visible = await repo.getTasks();
    expect(visible.map((t) => t.id), contains(a.id));
  });

  test('getTasks excludes archived tasks; unarchive restores them', () async {
    final repo = SqliteTaskRepository();
    final a = Task(title: 'A');
    await repo.createTask(a);

    await repo.archiveTask(a.id);
    var visible = await repo.getTasks();
    expect(visible.map((t) => t.id), isNot(contains(a.id)));

    await repo.unarchiveTask(a.id);
    visible = await repo.getTasks();
    expect(visible.map((t) => t.id), contains(a.id));
  });

  test('getTasksOfTaskList / getTasksWithoutTaskList partition by list',
      () async {
    final listRepo = SqliteTaskListRepository();
    final taskRepo = SqliteTaskRepository();
    final list = TaskList(title: 'Work');
    await listRepo.createTaskList(list);

    final inList = Task(title: 'In list', taskListId: list.id);
    final loose = Task(title: 'Loose');
    await taskRepo.createTask(inList);
    await taskRepo.createTask(loose);

    final ofList = await taskRepo.getTasksOfTaskList(list.id);
    final without = await taskRepo.getTasksWithoutTaskList();

    expect(ofList.map((t) => t.id), contains(inList.id));
    expect(ofList.map((t) => t.id), isNot(contains(loose.id)));
    expect(without.map((t) => t.id), contains(loose.id));
    expect(without.map((t) => t.id), isNot(contains(inList.id)));
  });

  test('moveTask reassigns the owning list', () async {
    final listRepo = SqliteTaskListRepository();
    final taskRepo = SqliteTaskRepository();
    final list = TaskList(title: 'Work');
    await listRepo.createTaskList(list);
    final t = Task(title: 'Move me');
    await taskRepo.createTask(t);

    await taskRepo.moveTask(t.id, list.id);

    final ofList = await taskRepo.getTasksOfTaskList(list.id);
    expect(ofList.map((e) => e.id), contains(t.id));
  });
}
