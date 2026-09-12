import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/models/model_calendar_event.dart';
import 'package:my_time_manager/screen_calendar/recurrence_expander.dart';

CalendarEvent _event({
  required DateTime start,
  Duration duration = const Duration(hours: 1),
  List<String> recurrence = const [],
  bool allDay = false,
}) {
  return CalendarEvent(
    id: 'master',
    title: 'Machine Learning',
    start: allDay
        ? EventDateTime(date: DateTime(start.year, start.month, start.day))
        : EventDateTime(dateTime: start),
    end: allDay
        ? EventDateTime(
            date: DateTime(start.year, start.month, start.day)
                .add(const Duration(days: 1)))
        : EventDateTime(dateTime: start.add(duration)),
    recurrence: recurrence,
  );
}

void main() {
  group('expandRecurringEvent', () {
    final windowStart = DateTime(2026, 1, 1);
    final windowEnd = DateTime(2027, 1, 1);

    test('non-recurring event inside window passes through unchanged', () {
      final e = _event(start: DateTime(2026, 9, 18, 13));
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out, hasLength(1));
      expect(out.first.id, 'master');
      expect(out.first.start.effective, DateTime(2026, 9, 18, 13));
    });

    test('non-recurring event outside window is dropped', () {
      final e = _event(start: DateTime(2030, 1, 1, 13));
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out, isEmpty);
    });

    test('weekly repeats land on the same weekday every 7 days', () {
      final e = _event(
        start: DateTime(2026, 9, 18, 13), // a Friday
        recurrence: const ['RRULE:FREQ=WEEKLY'],
      );
      final out = expandRecurringEvent(
          e, DateTime(2026, 9, 1), DateTime(2026, 10, 16));
      final starts = out.map((x) => x.start.effective).toList();
      expect(starts, [
        DateTime(2026, 9, 18, 13),
        DateTime(2026, 9, 25, 13),
        DateTime(2026, 10, 2, 13),
        DateTime(2026, 10, 9, 13),
      ]);
      // Instances carry the master id + a unique suffix and no recurrence.
      expect(out.first.recurringEventId, 'master');
      expect(out.first.recurrence, isEmpty);
      expect(out.first.id, startsWith('master#'));
    });

    test('daily with COUNT stops after N occurrences (incl. the first)', () {
      final e = _event(
        start: DateTime(2026, 9, 18, 9),
        recurrence: const ['RRULE:FREQ=DAILY;COUNT=3'],
      );
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out.map((x) => x.start.effective), [
        DateTime(2026, 9, 18, 9),
        DateTime(2026, 9, 19, 9),
        DateTime(2026, 9, 20, 9),
      ]);
    });

    test('INTERVAL skips periods', () {
      final e = _event(
        start: DateTime(2026, 9, 18, 9),
        recurrence: const ['RRULE:FREQ=DAILY;INTERVAL=2;COUNT=3'],
      );
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out.map((x) => x.start.effective), [
        DateTime(2026, 9, 18, 9),
        DateTime(2026, 9, 20, 9),
        DateTime(2026, 9, 22, 9),
      ]);
    });

    test('UNTIL bounds the series (inclusive)', () {
      final e = _event(
        start: DateTime(2026, 9, 18, 9),
        recurrence: const ['RRULE:FREQ=DAILY;UNTIL=20260920T235900'],
      );
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out.map((x) => x.start.effective), [
        DateTime(2026, 9, 18, 9),
        DateTime(2026, 9, 19, 9),
        DateTime(2026, 9, 20, 9),
      ]);
    });

    test('weekly BYDAY generates each listed weekday', () {
      final e = _event(
        start: DateTime(2026, 9, 14, 13), // Monday
        recurrence: const ['RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;COUNT=1'],
      );
      // COUNT=1 -> one week block; BYDAY expands within that block.
      final out = expandRecurringEvent(
          e, DateTime(2026, 9, 1), DateTime(2026, 9, 30));
      final days = out.map((x) => x.start.effective.day).toList()..sort();
      expect(days, [14, 16, 18]); // Mon 14, Wed 16, Fri 18
    });

    test('monthly clamps to shorter months', () {
      final e = _event(
        start: DateTime(2026, 1, 31, 10),
        recurrence: const ['RRULE:FREQ=MONTHLY;COUNT=3'],
      );
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out.map((x) => x.start.effective), [
        DateTime(2026, 1, 31, 10),
        DateTime(2026, 2, 28, 10), // Feb clamped
        DateTime(2026, 3, 31, 10),
      ]);
    });

    test('EXDATE removes a specific occurrence', () {
      final e = _event(
        start: DateTime(2026, 9, 18, 13),
        recurrence: const [
          'RRULE:FREQ=WEEKLY;COUNT=3',
          'EXDATE:20260925T130000',
        ],
      );
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out.map((x) => x.start.effective), [
        DateTime(2026, 9, 18, 13),
        DateTime(2026, 10, 2, 13),
      ]);
    });

    test('only occurrences overlapping the window are returned', () {
      final e = _event(
        start: DateTime(2026, 1, 1, 9),
        recurrence: const ['RRULE:FREQ=DAILY'],
      );
      final out = expandRecurringEvent(
          e, DateTime(2026, 6, 1), DateTime(2026, 6, 4));
      expect(out.map((x) => x.start.effective), [
        DateTime(2026, 6, 1, 9),
        DateTime(2026, 6, 2, 9),
        DateTime(2026, 6, 3, 9),
      ]);
    });

    test('all-day recurring instance keeps the all-day shape', () {
      final e = _event(
        start: DateTime(2026, 9, 18),
        allDay: true,
        recurrence: const ['RRULE:FREQ=WEEKLY;COUNT=2'],
      );
      final out = expandRecurringEvent(e, windowStart, windowEnd);
      expect(out, hasLength(2));
      expect(out.first.isAllDay, isTrue);
    });
  });
}
