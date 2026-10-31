@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/backup/backup_service.dart';
import 'package:my_time_manager/data/backup/import_service.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_habit_repository.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Backup (JSON export) + import of the Phase H1 tables habits /
/// habit_occurrences. Import is update-first (not REPLACE) so overwriting a
/// habit never cascades away its local occurrence history.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  Habit sample() => Habit(
        title: 'Original',
        recurrence: const RepeatRule(
            frequency: RepeatFrequency.weekly, weekdays: {2, 4}),
        targetAmount: 3,
        unit: 'x',
        partialCountsTowardStreak: true,
        startDate: DateTime(2026, 1, 1),
        reminderTime: '08:00',
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 1),
      );

  test('export contains habits and habit_occurrences', () async {
    final habits = SqliteHabitRepository();
    final h = sample();
    await habits.createHabit(h);
    await habits.recordOutcome(
        h.id, DateTime(2026, 1, 6), HabitOutcome.completed);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);
    final data = (jsonDecode(json) as Map)['data'] as Map;
    expect((data['habits'] as List), hasLength(1));
    expect((data['habit_occurrences'] as List), hasLength(1));
  });

  test('import into a fresh DB restores both tables', () async {
    final habits = SqliteHabitRepository();
    final h = sample();
    await habits.createHabit(h);
    await habits.recordOutcome(h.id, DateTime(2026, 1, 6),
        HabitOutcome.partial,
        amount: 1.5, note: 'n');
    await habits.recordOutcome(
        h.id, DateTime(2026, 1, 8), HabitOutcome.skipped);
    await habits.archiveHabit(h.id);
    final archivedBefore = (await habits.getHabit(h.id))!;

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    await DatabaseManager().resetForTesting(inMemory: true);
    expect(await habits.getHabit(h.id), isNull);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    final back = (await habits.getHabit(h.id))!;
    expect(back, archivedBefore);
    expect(back.isArchived, isTrue);
    final occ = await habits.occurrencesOf(h.id);
    expect(occ.map((o) => o.outcome),
        [HabitOutcome.partial, HabitOutcome.skipped]);
    expect(occ.first.amount, 1.5);
    expect(occ.first.note, 'n');
  });

  test('keepIncoming overwrites habit without cascading local history',
      () async {
    final habits = SqliteHabitRepository();
    final h = sample();
    await habits.createHabit(h);
    await habits.recordOutcome(
        h.id, DateTime(2026, 1, 6), HabitOutcome.completed);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    // Local edits after the backup.
    await habits.updateHabit(h.copyWith(
        title: 'Local edit', updateTimeStamp: DateTime(2026, 3, 1)));
    await habits.recordOutcome(
        h.id, DateTime(2026, 1, 6), HabitOutcome.missed); // same day, changed
    await habits.recordOutcome(
        h.id, DateTime(2026, 1, 13), HabitOutcome.completed); // local only

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    expect((await habits.getHabit(h.id))!.title, 'Original');
    final occ = await habits.occurrencesOf(h.id);
    // Same-day row merged by deterministic id (incoming wins), local-only
    // row survives (no REPLACE cascade).
    expect(occ.map((o) => (o.localDate.day, o.outcome)), [
      (6, HabitOutcome.completed),
      (13, HabitOutcome.completed),
    ]);
  });

  test('keepNewest for occurrences compares recordedAt', () async {
    final habits = SqliteHabitRepository();
    final h = sample();
    await habits.createHabit(h);
    await habits.recordOutcome(
        h.id, DateTime(2026, 1, 6), HabitOutcome.completed);
    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    // Newer local record on the same day → kept under keepNewest.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await habits.recordOutcome(
        h.id, DateTime(2026, 1, 6), HabitOutcome.skipped);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepNewest);
    expect(summary.failed, 0);
    expect((await habits.getOccurrence(h.id, DateTime(2026, 1, 6)))!.outcome,
        HabitOutcome.skipped);
  });
}
