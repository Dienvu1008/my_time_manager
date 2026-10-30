@TestOn('vm')
library;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_time_interval_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test for the SQLite-backed [TimeIntervalRepository], run against an
/// in-memory sqflite (FFI) database.
///
/// The headline test (`updateTimeInterval persists the UPDATED object`) is a
/// REGRESSION GUARD for the write-consistency invariant that the now-deleted
/// legacy `DataController.update(event, updated)` violated: it persisted the
/// OLD `event` while mutating only in-memory display state with `updated`,
/// causing DB/memory divergence.
///
/// Since Phase C3, [SqliteTimeIntervalRepository] injects [NoOpReminderScheduler]
/// by default, so these tests no longer need Flutter platform bindings or
/// channel mocks — they are pure Dart + FFI SQLite.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Fresh in-memory DB per test.
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  // A time interval must belong to a task (FK), so create one first.
  Future<Task> seedTask() async {
    final task = Task(title: 'Owner task');
    await SqliteTaskRepository().createTask(task);
    return task;
  }

  test('createTimeInterval + getTimeInterval round-trips', () async {
    final repo = SqliteTimeIntervalRepository();
    final task = await seedTask();
    final ti = TimeInterval(
      taskId: task.id,
      title: 'Study ML',
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 1, 10),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
    );

    await repo.createTimeInterval(ti);
    final fetched = await repo.getTimeInterval(ti.id);

    expect(fetched.id, ti.id);
    expect(fetched.title, 'Study ML');
  });

  test('updateTimeInterval persists the UPDATED object (write-consistency)',
      () async {
    final repo = SqliteTimeIntervalRepository();
    final task = await seedTask();
    final original = TimeInterval(
      taskId: task.id,
      title: 'Before',
      isCompleted: false,
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 1, 10),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
    );
    await repo.createTimeInterval(original);

    // The classic bug shape: build an updated copy and persist IT (not the
    // original). Keep the same id so it updates in place.
    final updated = original.copyWith(
      title: 'After',
      isCompleted: true,
      howMuchHasBeenDone: 42,
    );
    await repo.updateTimeInterval(updated);

    // Re-read from the DB: the persisted row must reflect the UPDATED values.
    final reloaded = await repo.getTimeInterval(original.id);
    expect(reloaded.id, original.id);
    expect(reloaded.title, 'After');
    expect(reloaded.isCompleted, isTrue);
    expect(reloaded.howMuchHasBeenDone, 42);
  });

  test('deleteTimeInterval removes it from the store', () async {
    final repo = SqliteTimeIntervalRepository();
    final task = await seedTask();
    final ti = TimeInterval(
      taskId: task.id,
      title: 'Doomed',
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 1, 10),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
    );
    await repo.createTimeInterval(ti);

    await repo.deleteTimeInterval(ti.id);

    final all = await repo.getTimeIntervals();
    expect(all.map((e) => e.id), isNot(contains(ti.id)));
  });

  test('getTimeIntervalsOfTask returns the task\'s own intervals', () async {
    final repo = SqliteTimeIntervalRepository();
    final task = await seedTask();
    final a = TimeInterval(
      taskId: task.id,
      title: 'A',
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 1, 10),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
    );
    final b = TimeInterval(
      taskId: task.id,
      title: 'B',
      startDate: DateTime(2026, 1, 11),
      endDate: DateTime(2026, 1, 11),
      startTime: const TimeOfDay(hour: 11, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
    );
    await repo.createTimeInterval(a);
    await repo.createTimeInterval(b);

    final ofTask = await repo.getTimeIntervalsOfTask(task.id);
    expect(ofTask.map((e) => e.id), containsAll([a.id, b.id]));
  });
}
