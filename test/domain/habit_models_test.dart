import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';

void main() {
  group('RepeatRule serialization', () {
    test('round-trips every field', () {
      final r = RepeatRule(
        frequency: RepeatFrequency.weekly,
        interval: 2,
        weekdays: const {5, 1, 3},
        endMode: RepeatEndMode.onDate,
        endDate: DateTime(2027, 3, 4),
        occurrences: 7,
      );
      final back = RepeatRule.fromJson(r.toJson());
      expect(back, r);
      expect(r.toMap()['weekdays'], [1, 3, 5]);
      expect(r.toMap()['endDate'], '2027-03-04');
    });

    test('corrupt / unknown values fall back to defaults', () {
      expect(RepeatRule.fromJson(null), RepeatRule.none);
      expect(RepeatRule.fromJson('not json'), RepeatRule.none);
      final r = RepeatRule.fromMap(const {
        'frequency': 'hourly',
        'interval': 0,
        'weekdays': [0, 8, 'x', 2],
        'endMode': '??',
      });
      expect(r.frequency, RepeatFrequency.none);
      expect(r.interval, 1);
      expect(r.weekdays, {2});
      expect(r.endMode, RepeatEndMode.never);
    });
  });

  group('RepeatRule day queries', () {
    final anchor = DateTime(2026, 1, 1); // Thursday

    test('daily interval', () {
      const r = RepeatRule(frequency: RepeatFrequency.daily, interval: 3);
      expect(r.occursOn(anchor, DateTime(2026, 1, 4)), isTrue);
      expect(r.occursOn(anchor, DateTime(2026, 1, 5)), isFalse);
      expect(r.occursOn(anchor, DateTime(2025, 12, 29)), isFalse);
    });

    test('weekly weekdays with interval', () {
      const r = RepeatRule(
          frequency: RepeatFrequency.weekly, interval: 2, weekdays: {1, 4});
      final days = r.occurrencesBetween(
          anchor, DateTime(2026, 1, 1), DateTime(2026, 1, 31));
      expect(days, [
        DateTime(2026, 1, 1), // Thu, week 0
        DateTime(2026, 1, 12), // Mon, week 2
        DateTime(2026, 1, 15), // Thu, week 2
        DateTime(2026, 1, 26),
        DateTime(2026, 1, 29),
      ]);
    });

    test('monthly clamps like generateStartDates', () {
      const r = RepeatRule(frequency: RepeatFrequency.monthly);
      final a = DateTime(2026, 1, 31);
      expect(r.occursOn(a, DateTime(2026, 2, 28)), isTrue);
      expect(r.occursOn(a, DateTime(2026, 3, 31)), isTrue);
      final viaGenerate = const RepeatRule(
              frequency: RepeatFrequency.monthly,
              endMode: RepeatEndMode.afterOccurrences,
              occurrences: 6)
          .generateStartDates(a);
      expect(
          const RepeatRule(
                  frequency: RepeatFrequency.monthly,
                  endMode: RepeatEndMode.afterOccurrences,
                  occurrences: 6)
              .occurrencesBetween(a, a, DateTime(2027, 1, 1)),
          viaGenerate);
    });

    test('end conditions: onDate and afterOccurrences', () {
      final onDate = RepeatRule(
          frequency: RepeatFrequency.daily,
          endMode: RepeatEndMode.onDate,
          endDate: DateTime(2026, 1, 3));
      expect(
          onDate.occurrencesBetween(anchor, anchor, DateTime(2026, 2, 1)),
          hasLength(3));
      const after = RepeatRule(
          frequency: RepeatFrequency.daily,
          endMode: RepeatEndMode.afterOccurrences,
          occurrences: 4);
      expect(after.occursOn(anchor, DateTime(2026, 1, 4)), isTrue);
      expect(after.occursOn(anchor, DateTime(2026, 1, 5)), isFalse);
    });

    test('daily over > 1000 days is not capped', () {
      const r = RepeatRule(frequency: RepeatFrequency.daily);
      expect(r.occursOn(anchor, DateTime(2030, 6, 1)), isTrue);
    });
  });

  group('Habit model', () {
    test('toMap / fromMap round-trip', () {
      final h = Habit(
        title: 'Read',
        description: 'pages',
        color: const Color(0xFF112233),
        recurrence: const RepeatRule(
            frequency: RepeatFrequency.weekly, weekdays: {1, 3, 5}),
        targetAmount: 20,
        unit: 'pages',
        partialCountsTowardStreak: true,
        startDate: DateTime(2026, 1, 5, 13, 30),
        endDate: DateTime(2026, 12, 31),
        reminderTime: '7:05',
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      final map = h.toMap();
      expect(map['startDate'], '2026-01-05');
      expect(map['endDate'], '2026-12-31');
      expect(map['reminderTime'], '07:05');
      expect(map['partialCountsTowardStreak'], 1);
      expect(map.containsKey('isArchived'), isFalse);
      expect(Habit.fromMap(map), h);
    });

    test('defaults: daily, no target, invalid reminder dropped', () {
      final h = Habit(title: 'X', reminderTime: '25:00');
      expect(h.recurrence.frequency, RepeatFrequency.daily);
      expect(h.hasTarget, isFalse);
      expect(h.reminderTime, isNull);
      final back = Habit.fromMap({'id': 'h', 'title': 'T'});
      expect(back.recurrence, Habit.defaultRecurrence);
    });

    test('archive bounds the schedule', () {
      final h = Habit.fromMap({
        'id': 'h',
        'title': 'T',
        'startDate': '2026-01-01',
        'isArchived': 1,
        'archivedAt': '2026-01-10T08:00:00.000',
      });
      expect(h.isScheduledOn(DateTime(2026, 1, 10)), isTrue);
      expect(h.isScheduledOn(DateTime(2026, 1, 11)), isFalse);
    });
  });

  group('HabitOccurrence model', () {
    test('round-trip + deterministic id', () {
      final o = HabitOccurrence(
        habitId: 'h1',
        localDate: DateTime(2026, 2, 3, 22, 10),
        outcome: HabitOutcome.partial,
        amount: 2.5,
        note: 'n',
        recordedAt: DateTime(2026, 2, 3, 22, 11),
      );
      expect(o.id, 'h1:2026-02-03');
      expect(o.localDate, DateTime(2026, 2, 3));
      expect(o.toMap()['localDate'], '2026-02-03');
      expect(HabitOccurrence.fromMap(o.toMap()), o);
    });

    test('exactly five outcomes; unknown parses as pending', () {
      expect(HabitOutcome.values.map((o) => o.name),
          ['completed', 'partial', 'skipped', 'missed', 'pending']);
      expect(HabitOutcome.parse('exploded'), HabitOutcome.pending);
      expect(HabitOutcome.parse(null), HabitOutcome.pending);
      expect(HabitOutcome.tryParse('exploded'), isNull);
      final o = HabitOccurrence.fromMap(const {
        'id': 'x',
        'habitId': 'h',
        'localDate': '2026-01-01',
        'outcome': 'future_state',
      });
      expect(o.outcome, HabitOutcome.pending);
    });
  });

  test('entity type constants', () {
    expect(GoalEntityType.habit, 'habit');
    expect(ProjectEntityType.habit, 'habit');
    expect(ProjectEntityType.supported, isNot(contains('habit')));
  });
}
