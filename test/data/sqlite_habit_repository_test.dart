@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_archive_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_habit_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_project_repository.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';
import 'package:my_time_manager/screen_archive/model_archived_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract tests for [SqliteHabitRepository] (Phase H1) against an in-memory
/// DB with the production schema (v18).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  late SqliteHabitRepository habits;
  setUp(() => habits = SqliteHabitRepository());

  Future<int> count(String table) async {
    final db = await DatabaseManager().database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return r.first['c'] as int;
  }

  Habit sample({String title = 'Run'}) => Habit(
        title: title,
        description: 'd',
        color: const Color(0xFF00FF00),
        recurrence: const RepeatRule(
            frequency: RepeatFrequency.weekly, weekdays: {1, 3}),
        targetAmount: 5,
        unit: 'km',
        partialCountsTowardStreak: true,
        startDate: DateTime(2026, 1, 1),
        reminderTime: '06:30',
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 1),
      );

  group('habits CRUD', () {
    test('create / get / update round-trip', () async {
      final h = sample();
      await habits.createHabit(h);
      expect(await habits.getHabit(h.id), h);
      expect(await habits.getHabits(), [h]);

      final updated = h.copyWith(
        title: 'Run more',
        recurrence: const RepeatRule(frequency: RepeatFrequency.daily),
        clearTarget: true,
        endDate: DateTime(2026, 6, 30),
        updateTimeStamp: DateTime(2026, 2, 1),
      );
      await habits.updateHabit(updated);
      final back = (await habits.getHabit(h.id))!;
      expect(back, updated);
      expect(back.targetAmount, isNull);
      expect(back.unit, isNull);
      expect(await habits.getHabit('nope'), isNull);
    });

    test('archive / unarchive keeps occurrences', () async {
      final h = sample();
      await habits.createHabit(h);
      await habits.recordOutcome(h.id, DateTime(2026, 1, 5),
          HabitOutcome.completed);

      await habits.archiveHabit(h.id);
      expect(await habits.getHabits(), isEmpty);
      final archived = await habits.getArchivedHabits();
      expect(archived.single.id, h.id);
      expect(archived.single.isArchived, isTrue);
      expect(archived.single.archivedAt, isNotNull);
      expect(await habits.occurrencesOf(h.id), hasLength(1));

      // Listed by the cross-table archive query; no trash for habits.
      final archive = SqliteArchiveRepository();
      final item = (await archive.getArchivedItems()).single;
      expect(item.type, ArchivedItemType.habit);
      expect(item.type.supportsTrash, isFalse);
      expect(item.title, 'Run');
      expect(() => archive.moveToTrash(item), throwsUnsupportedError);

      await archive.unarchive(item);
      final back = (await habits.getHabit(h.id))!;
      expect(back.isArchived, isFalse);
      expect(back.archivedAt, isNull);
      expect(await habits.occurrencesOf(h.id), hasLength(1));

      await habits.archiveHabit(h.id);
      await habits.unarchiveHabit(h.id);
      expect(await habits.getHabits(), hasLength(1));
    });
  });

  group('occurrences', () {
    test('recordOutcome upserts without REPLACE (one row per day)', () async {
      final h = sample();
      await habits.createHabit(h);
      final day = DateTime(2026, 1, 5, 23, 59);
      final first =
          await habits.recordOutcome(h.id, day, HabitOutcome.partial,
              amount: 2, note: 'tired');
      expect(first.id, HabitOccurrence.idFor(h.id, day));
      expect(first.localDate, DateTime(2026, 1, 5));

      final second = await habits.recordOutcome(
          h.id, DateTime(2026, 1, 5), HabitOutcome.completed,
          amount: 5);
      expect(second.id, first.id);
      expect(second.outcome, HabitOutcome.completed);
      expect(second.amount, 5);
      expect(second.note, isNull);
      expect(await count('habit_occurrences'), 1);
      expect((await habits.getOccurrence(h.id, day))!.outcome,
          HabitOutcome.completed);
    });

    test('UNIQUE (habitId, localDate) enforced at DB level', () async {
      final h = sample();
      await habits.createHabit(h);
      await habits.recordOutcome(h.id, DateTime(2026, 1, 5),
          HabitOutcome.completed);
      final db = await DatabaseManager().database;
      await expectLater(
        db.insert('habit_occurrences', {
          'id': 'other',
          'habitId': h.id,
          'localDate': '2026-01-05',
          'outcome': 'missed',
        }),
        throwsA(isA<DatabaseException>()),
      );
      // CHECK constraint: only the five outcomes.
      await expectLater(
        db.insert('habit_occurrences', {
          'id': 'bad',
          'habitId': h.id,
          'localDate': '2026-01-06',
          'outcome': 'exploded',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('recordOutcome on unknown habit throws ArgumentError', () async {
      expect(
          () => habits.recordOutcome(
              'ghost', DateTime(2026, 1, 1), HabitOutcome.completed),
          throwsArgumentError);
    });

    test('clearOutcome and occurrencesOf range', () async {
      final h = sample();
      await habits.createHabit(h);
      for (final d in [5, 7, 12, 14]) {
        await habits.recordOutcome(
            h.id, DateTime(2026, 1, d), HabitOutcome.completed);
      }
      final all = await habits.occurrencesOf(h.id);
      expect(all.map((o) => o.localDate.day), [5, 7, 12, 14]);
      final ranged = await habits.occurrencesOf(h.id,
          from: DateTime(2026, 1, 7), to: DateTime(2026, 1, 12));
      expect(ranged.map((o) => o.localDate.day), [7, 12]);

      await habits.clearOutcome(h.id, DateTime(2026, 1, 7));
      await habits.clearOutcome(h.id, DateTime(2026, 1, 8)); // no-op
      expect((await habits.occurrencesOf(h.id)).map((o) => o.localDate.day),
          [5, 12, 14]);
      expect(await habits.getOccurrence(h.id, DateTime(2026, 1, 7)), isNull);
    });

    test('updating the rule never rewrites recorded rows', () async {
      final h = sample();
      await habits.createHabit(h);
      await habits.recordOutcome(
          h.id, DateTime(2026, 1, 5), HabitOutcome.skipped);
      final before = await habits.occurrencesOf(h.id);
      await habits.updateHabit(h.copyWith(
          recurrence: const RepeatRule(
              frequency: RepeatFrequency.weekly, weekdays: {6})));
      expect(await habits.occurrencesOf(h.id), before);
    });
  });

  group('hard delete', () {
    test('cascades occurrences and fires goal_links / project_items triggers',
        () async {
      final h = sample();
      final keep = sample(title: 'Keep');
      await habits.createHabit(h);
      await habits.createHabit(keep);
      await habits.recordOutcome(
          h.id, DateTime(2026, 1, 5), HabitOutcome.completed);
      await habits.recordOutcome(
          keep.id, DateTime(2026, 1, 5), HabitOutcome.completed);

      final goal = Goal(title: 'G');
      await SqliteGoalRepository().createGoal(goal);
      final project = Project(title: 'P');
      final projects = SqliteProjectRepository();
      await projects.createProject(project);
      final db = await DatabaseManager().database;
      for (final id in [h.id, keep.id]) {
        await db.insert('goal_links', {
          'id': 'gl-$id',
          'goalId': goal.id,
          'entityType': GoalEntityType.habit,
          'entityId': id,
        });
      }
      await projects.addItem(project.id, ProjectEntityType.habit, h.id);
      await projects.addItem(project.id, ProjectEntityType.habit, keep.id);

      await habits.deleteHabitPermanently(h.id);

      expect(await habits.getHabit(h.id), isNull);
      expect(await habits.occurrencesOf(h.id), isEmpty);
      expect(await habits.occurrencesOf(keep.id), hasLength(1));
      final links = await SqliteGoalRepository().getLinks(goal.id);
      expect(links.map((l) => l.entityId), [keep.id]);
      final items = await projects.getItems(project.id);
      expect(items.map((i) => i.entityId), [keep.id]);
    });
  });
}
