import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/daily_review/daily_review.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/services/time_interval_progress_service.dart';

import 'daily_review_fixtures.dart';

void main() {
  group('DailyReviewService categorization', () {
    Env seeded({bool reversed = false}) {
      final env = Env();
      env.tasks.visible
        ..add(Task(id: 't2', title: 'done', isCompleted: true))
        ..add(Task(id: 'tImp', title: 'important', isImportant: true));
      final list = [
        timed('o1', at(10, 9), at(10, 10)),
        timed('o2', at(11, 8), at(11, 9)),
        timed('o3', at(9, 9), at(9, 10), important: true),
        timed('oTask', at(9, 11), at(9, 12), taskId: 'tImp'),
        timed('s1', at(11, 9, 30), at(11, 11)),
        timed('s2', at(11, 9), at(12, 10)),
        timed('d1', at(11, 14), at(11, 15)),
        untimed('d2', at(11, 0)),
        untimed('oUntimed', at(10, 0)),
        timed('future', at(12, 9), at(12, 10)),
        timed('done', at(11, 12), at(11, 13), completed: true),
        timed('ofDoneTask', at(11, 12), at(11, 13), taskId: 't2'),
        timed('ofTrashedTask', at(11, 12), at(11, 13), taskId: 'gone'),
      ];
      for (final i in reversed ? list.reversed : list) {
        env.intervals.put(i);
      }
      return env;
    }

    test('categorizes overdue / started / due today with stable order',
        () async {
      final r = await seeded().review();
      expect(r.overdue.map((i) => i.id),
          ['o3', 'oTask', 'o1', 'oUntimed', 'o2']);
      expect(r.startedIncomplete.map((i) => i.id), ['s2', 's1']);
      expect(r.dueToday.map((i) => i.id), ['d2', 'd1']);
      expect(r.overdueCount, 5);
      expect(r.startedCount, 2);
      expect(r.dueTodayCount, 2);
      expect(r.isAllClear, isFalse);
      expect(r.items.first.category, ReviewCategory.overdue);
    });

    test('is deterministic regardless of repository order', () async {
      final a = await seeded().review();
      final b = await seeded(reversed: true).review();
      expect(b.items.map((i) => i.id), a.items.map((i) => i.id));
      expect(b.items.map((i) => i.fingerprint),
          a.items.map((i) => i.fingerprint));
    });

    test('deadline flag and duration', () async {
      final r = await seeded().review();
      ReviewItem item(String id) => r.itemById(id)!;
      expect(item('o1').isDeadline, isTrue);
      expect(item('d1').isDeadline, isTrue);
      expect(item('s1').isDeadline, isTrue);
      expect(item('s2').isDeadline, isFalse, reason: 'ends tomorrow');
      expect(item('o1').duration, const Duration(hours: 1));
      expect(item('d2').duration, isNull, reason: 'unknown duration');
      expect(item('oTask').isImportant, isTrue, reason: 'task is important');
    });

    test('positive empty state; unscheduled tasks are informational', () async {
      final env = Env(); // t1 has no interval
      env.intervals.put(timed('x', at(11, 8), at(11, 9), taskId: 'tDone'));
      env.tasks.visible.add(Task(id: 'tDone', title: 'x', isCompleted: true));
      final r = await env.review();
      expect(r.isAllClear, isTrue);
      expect(r.items, isEmpty);
      expect(r.unscheduledTasks.map((t) => t.id), ['t1']);
    });

    test('habits pending / missed today are reported', () async {
      final env = Env();
      final start = at(1, 0);
      final pending = Habit(id: 'h1', title: 'A read', startDate: start);
      final missed = Habit(id: 'h2', title: 'B run', startDate: start);
      final done = Habit(id: 'h3', title: 'C done', startDate: start);
      final notToday = Habit(id: 'h4', title: 'D later', startDate: at(12, 0));
      for (final h in [pending, missed, done, notToday]) {
        env.habits.habits[h.id] = h;
      }
      await env.habits.recordOutcome('h2', at(11, 0), HabitOutcome.missed);
      await env.habits.recordOutcome('h3', at(11, 0), HabitOutcome.completed);
      final r = await env.review();
      expect(r.habitsPending.map((h) => h.habit.id), ['h1']);
      expect(r.habitsMissed.map((h) => h.habit.id), ['h2']);
      expect(r.habitsOpenCount, 2);
      expect(r.isAllClear, isFalse);
    });

    test('free time today respects events, intervals and working hours',
        () async {
      final env = Env();
      env.intervals.put(timed('d1', at(11, 14), at(11, 15)));
      env.calendar.visible
        ..add(event('busy', at(11, 12), at(11, 13)))
        ..add(event('free', at(11, 15), at(11, 16),
            transparency: EventTransparency.transparent));
      final r = await env.review();
      // 10:00–18:00 = 8h, minus 12–13 and 14–15.
      expect(r.freeTimeToday, const Duration(hours: 6));
      expect(r.knownWorkload, const Duration(hours: 1));
    });
  });

  group('TimeIntervalProgressService.isStartedButIncomplete', () {
    test('timed and in progress', () {
      expect(
          TimeIntervalProgressService.isStartedButIncomplete(
              timed('a', at(11, 9), at(11, 11)), kNow),
          isTrue);
      expect(
          TimeIntervalProgressService.isStartedButIncomplete(
              timed('a', at(11, 9), at(11, 11), completed: true), kNow),
          isFalse);
      expect(
          TimeIntervalProgressService.isStartedButIncomplete(
              timed('a', at(11, 11), at(11, 12)), kNow),
          isFalse);
      expect(
          TimeIntervalProgressService.isStartedButIncomplete(
              untimed('a', at(11, 0)), kNow),
          isFalse,
          reason: 'date-only start is never "started"');
    });
  });

  group('AvailabilityCalculator', () {
    const availability = Availability();
    final calc = AvailabilityCalculator(availability, expander: realExpander);
    TimeRange? slot(List<BusyBlock> busy,
            {DateTime? from,
            DateTime? until,
            Duration d = const Duration(hours: 1),
            AvailabilityCalculator? c}) =>
        (c ?? calc).findSlot(
            from: from ?? at(11, 7),
            until: until ?? at(12, 0),
            duration: d,
            busy: busy);
    List<BusyBlock> busyOf({
      List<CalendarEvent> events = const [],
      List intervals = const [],
      AvailabilityCalculator? c,
    }) =>
        (c ?? calc).busyBlocks(
          window: TimeRange(at(1, 0), at(31, 0)),
          events: events,
          intervals: intervals.cast(),
        );

    test('working hours: default Mon–Fri 09:00–18:00', () {
      expect(slot(const [])!.start, at(11, 9));
      // Saturday 14 → next slot Monday 16 09:00.
      expect(slot(const [], from: at(14, 7), until: at(17, 0))!.start,
          at(16, 9));
      expect(slot(const [], from: at(14, 7), until: at(16, 0)), isNull);
      expect(slot(const [], from: at(11, 17, 30)), isNull,
          reason: 'only 30 min left today');
      final custom = AvailabilityCalculator(const Availability(
          workingHours: {DateTime.wednesday: WorkingHours.hm(13, 0, 15, 0)}));
      expect(slot(const [], c: custom)!.start, at(11, 13));
    });

    test('opaque events block; transparent / cancelled do not', () {
      expect(slot(busyOf(events: [event('e', at(11, 9), at(11, 12))]))!.start,
          at(11, 12));
      expect(
          slot(busyOf(events: [
            event('e', at(11, 9), at(11, 12),
                transparency: EventTransparency.transparent)
          ]))!
              .start,
          at(11, 9));
      expect(
          slot(busyOf(events: [
            event('e', at(11, 9), at(11, 12), status: EventStatus.cancelled)
          ]))!
              .start,
          at(11, 9));
    });

    test('recurring event occurrences block (expander), all-day blocks day',
        () {
      final daily = event('r', at(1, 9), at(1, 12),
          recurrence: const ['RRULE:FREQ=DAILY']);
      expect(slot(busyOf(events: [daily]))!.start, at(11, 12));
      final noExpander = AvailabilityCalculator(availability);
      expect(
          slot(busyOf(events: [daily], c: noExpander), c: noExpander)!.start,
          at(11, 9),
          reason: 'without expander only the base occurrence blocks');
      expect(
          slot(busyOf(events: [allDayEvent('ad', at(11, 0))]),
                  until: at(13, 0))!
              .start,
          at(12, 9));
    });

    test('existing incomplete intervals block; completed do not', () {
      expect(
          slot(busyOf(intervals: [timed('i', at(11, 9), at(11, 11))]))!.start,
          at(11, 11));
      expect(
          slot(busyOf(intervals: [
            timed('i', at(11, 9), at(11, 11), completed: true)
          ]))!
              .start,
          at(11, 9));
      expect(
          slot(busyOf(intervals: [untimed('u', at(11, 0))]))!.start,
          at(11, 9),
          reason: 'date-only intervals have no duration and do not block');
    });

    test('minimum slot length', () {
      final busy = busyOf(events: [
        event('a', at(11, 9), at(11, 9, 10)),
        event('b', at(11, 9, 20), at(11, 18)),
      ]);
      expect(slot(busy, d: const Duration(minutes: 5)), isNull,
          reason: '10-min gap < 15-min minSlot');
      final small = AvailabilityCalculator(
          const Availability(minSlot: Duration(minutes: 5)));
      expect(slot(busy, d: const Duration(minutes: 5), c: small)!.start,
          at(11, 9, 10));
    });

    test('buffer around busy blocks and start rounding', () {
      final buffered = AvailabilityCalculator(
          const Availability(buffer: Duration(minutes: 15)));
      final busy = busyOf(events: [event('a', at(11, 9), at(11, 10))]);
      expect(slot(busy, c: buffered)!.start, at(11, 10, 15));
      expect(slot(const [], from: at(11, 10, 2))!.start, at(11, 10, 5));
    });
  });

  group('feature flag', () {
    test('default on; explicit false disables', () {
      expect(isDailyReviewEnabled((_) => null), isTrue);
      expect(isDailyReviewEnabled((k) => k == dailyReviewEnabledKey ? false : null),
          isFalse);
      expect(isDailyReviewEnabled((_) => 'garbage'), isTrue);
    });
  });
}
