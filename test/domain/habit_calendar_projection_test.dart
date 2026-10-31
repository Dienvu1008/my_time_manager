import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/services/habit_calendar_projection.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';

import '../shared/fake_repositories.dart' show FakeHabitRepository;

/// Pure tests for [HabitCalendarProjection] (Phase H3).
void main() {
  const projection = HabitCalendarProjection();
  // "Now" = Tue Mar 10 2026, 12:00 local.
  final now = DateTime(2026, 3, 10, 12);

  Habit daily(String id,
          {String? time, DateTime? start, DateTime? end, String? title}) =>
      Habit(
        id: id,
        title: title ?? id,
        color: const Color(0xFF2196F3),
        startDate: start ?? DateTime(2026, 3, 1),
        endDate: end,
        reminderTime: time,
      );

  HabitOccurrence rec(String habitId, int day, HabitOutcome o) =>
      HabitOccurrence(
          habitId: habitId, localDate: DateTime(2026, 3, day), outcome: o);

  List<HabitCalendarEntry> run(List<Habit> habits, List<HabitOccurrence> occ,
          {int from = 9, int to = 11}) =>
      projection.project(habits, occ,
          from: DateTime(2026, 3, from), to: DateTime(2026, 3, to), now: now);

  test('scheduled days get derived outcomes; recorded days are as recorded',
      () {
    final out = run([daily('h', time: '07:30')], [
      rec('h', 9, HabitOutcome.completed),
    ]);
    expect(out.map((e) => e.localDate.day), [9, 10, 11]);
    expect(out[0].outcome, HabitOutcome.completed);
    expect(out[0].isRecorded, isTrue);
    expect(out[1].outcome, HabitOutcome.pending); // today, unrecorded
    expect(out[1].isRecorded, isFalse);
    expect(out[2].outcome, HabitOutcome.pending); // future
    for (final e in out) {
      expect(e.habitId, 'h');
      expect(e.title, 'h');
      expect(e.color, const Color(0xFF2196F3));
      expect(e.reminderTime, '07:30');
      expect(e.isScheduled, isTrue);
    }
  });

  test('past unrecorded scheduled day resolves to missed', () {
    final out = run([daily('h')], const [], from: 8, to: 8);
    expect(out.single.outcome, HabitOutcome.missed);
    expect(out.single.isRecorded, isFalse);
    expect(out.single.reminderTime, isNull);
  });

  test('recorded day the rule no longer schedules is still projected', () {
    // Mondays only (Mar 9 2026 is a Monday); a record on Wed Mar 11.
    final h = Habit(
      id: 'h',
      title: 'Mon',
      startDate: DateTime(2026, 3, 2),
      recurrence: const RepeatRule(
          frequency: RepeatFrequency.weekly, weekdays: {DateTime.monday}),
    );
    final out = run([h], [rec('h', 11, HabitOutcome.skipped)]);
    expect(out.map((e) => e.localDate.day), [9, 11]);
    expect(out[1].outcome, HabitOutcome.skipped);
    expect(out[1].isScheduled, isFalse);
    expect(out[1].isRecorded, isTrue);
  });

  test('archived habits are excluded', () {
    final archived = Habit.fromMap({
      ...daily('a').toMap(),
      'isArchived': 1,
      'archivedAt': DateTime(2026, 3, 20).toIso8601String(),
    });
    final out = run([archived, daily('h')], [rec('a', 9, HabitOutcome.completed)]);
    expect(out.map((e) => e.habitId).toSet(), {'h'});
  });

  test('range bounds: startDate, endDate and the [from, to] window', () {
    final out = run([
      daily('late', start: DateTime(2026, 3, 11)),
      daily('ended', end: DateTime(2026, 3, 9)),
    ], [
      rec('late', 8, HabitOutcome.completed), // outside window
    ]);
    expect(
        out.map((e) => '${e.habitId}:${e.localDate.day}'), ['ended:9', 'late:11']);
    expect(run([daily('h')], const [], from: 12, to: 11), isEmpty);
  });

  test('ordering is deterministic: day, all-day first, time, title, id', () {
    final habits = [
      daily('z', time: '09:00', title: 'B'),
      daily('y', title: 'Zeta'),
      daily('x', time: '06:00', title: 'C'),
      daily('w', time: '09:00', title: 'A'),
    ];
    final a = run(habits, const [], from: 10, to: 10);
    final b = run(habits.reversed.toList(), const [], from: 10, to: 10);
    expect(a.map((e) => e.habitId), ['y', 'x', 'w', 'z']);
    expect(b, a);
  });

  test('load() reads active habits + occurrences from the repository',
      () async {
    final repo = FakeHabitRepository();
    await repo.createHabit(daily('h', time: '08:00'));
    await repo.createHabit(daily('gone'));
    await repo.archiveHabit('gone');
    await repo.recordOutcome('h', DateTime(2026, 3, 10), HabitOutcome.partial);
    final out = await projection.load(repo,
        from: DateTime(2026, 3, 10), to: DateTime(2026, 3, 10), now: now);
    expect(out, hasLength(1));
    expect(out.single.outcome, HabitOutcome.partial);
    expect(out.single.isRecorded, isTrue);
  });
}
