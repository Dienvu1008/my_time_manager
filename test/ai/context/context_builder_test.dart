import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/context/context_builder.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/focus_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/domain/services/focus_statistics_service.dart';
import 'package:my_time_manager/domain/models/model_focus_session.dart';

// ---- Fakes ------------------------------------------------------------------

class _FakeTasks implements TaskRepository {
  _FakeTasks(this._tasks);
  final List<Task> _tasks;
  @override
  Future<List<Task>> getTasks() async => _tasks;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeCalendar implements CalendarRepository {
  _FakeCalendar(this._events);
  final List<CalendarEvent> _events;
  @override
  Future<List<CalendarEvent>> getCalendarEvents() async => _events;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeIntervals implements TimeIntervalRepository {
  _FakeIntervals(this._items);
  final List<TimeInterval> _items;
  @override
  Future<List<TimeInterval>> getTimeIntervals() async => _items;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeFocus implements FocusRepository {
  _FakeFocus(this._sessions);
  final List<FocusSession> _sessions;
  @override
  Future<List<FocusSession>> sessionsBetween(DateTime s, DateTime e) async =>
      _sessions
          .where((x) => !x.startTime.isBefore(s) && x.startTime.isBefore(e))
          .toList();
  @override
  Future<List<FocusSession>> allSessions() async => _sessions;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---- Helpers ----------------------------------------------------------------

final _now = DateTime(2026, 3, 2, 9, 0); // Monday 09:00

CalendarEvent _event(String title, DateTime start, {Duration? len}) =>
    CalendarEvent(
      title: title,
      start: EventDateTime(dateTime: start),
      end: EventDateTime(dateTime: start.add(len ?? const Duration(hours: 1))),
    );

TimeInterval _dateOnlyInterval(String title, DateTime day) => TimeInterval(
      title: title,
      startDate: day,
      isStartTimeUndefined: true,
      isEndDateUndefined: true,
    );

FocusSession _session(DateTime start, int minutes) => FocusSession(
      startTime: start,
      endTime: start.add(Duration(minutes: minutes)),
      focusDurationSeconds: minutes * 60,
    );

ContextBuilder _builder({
  List<Task> tasks = const [],
  List<CalendarEvent> events = const [],
  List<TimeInterval> intervals = const [],
  List<FocusSession> focus = const [],
  ContextOptions options = const ContextOptions(),
}) {
  final f = _FakeFocus(focus);
  return ContextBuilder(
    tasks: _FakeTasks(tasks),
    calendar: _FakeCalendar(events),
    timeIntervals: _FakeIntervals(intervals),
    focusStats: FocusStatisticsService(f),
    options: options,
  );
}

void main() {
  test('empty data yields a safe, empty context', () async {
    final ctx = await _builder().build(now: _now);
    expect(ctx.totalOutstanding, 0);
    expect(ctx.outstandingTasks, isEmpty);
    expect(ctx.todaySchedule, isEmpty);
    expect(ctx.upcoming, isEmpty);
    expect(ctx.focus!.totalMinutes, 0);
    // Render must not throw and should mention the date.
    expect(ctx.render(), contains('2026-03-02'));
  });

  test('outstanding tasks exclude completed and sort important-first', () async {
    final ctx = await _builder(tasks: [
      Task(title: 'Zeta', isImportant: false),
      Task(title: 'Alpha', isImportant: true),
      Task(title: 'Done', isCompleted: true),
    ]).build(now: _now);

    expect(ctx.totalOutstanding, 2);
    expect(ctx.outstandingTasks.map((t) => t.title), ['Alpha', 'Zeta']);
    expect(ctx.outstandingTasks.first.isImportant, isTrue);
  });

  test('outstanding tasks are capped, but total reflects the true count',
      () async {
    final many = [for (var i = 0; i < 25; i++) Task(title: 'T$i')];
    final ctx = await _builder(
      tasks: many,
      options: const ContextOptions(maxOutstandingTasks: 5),
    ).build(now: _now);

    expect(ctx.outstandingTasks, hasLength(5));
    expect(ctx.totalOutstanding, 25);
    expect(ctx.render(), contains('showing 5'));
  });

  test('today schedule includes only today, sorted by start', () async {
    final ctx = await _builder(events: [
      _event('Late', DateTime(2026, 3, 2, 15)),
      _event('Early', DateTime(2026, 3, 2, 8)),
      _event('Tomorrow', DateTime(2026, 3, 3, 9)),
      _event('Yesterday', DateTime(2026, 3, 1, 9)),
    ]).build(now: _now);

    expect(ctx.todaySchedule.map((s) => s.title), ['Early', 'Late']);
  });

  test('upcoming includes items after today within the horizon, capped',
      () async {
    final events = [
      _event('In 1 day', DateTime(2026, 3, 3, 9)),
      _event('In 3 days', DateTime(2026, 3, 5, 9)),
      _event('In 30 days', DateTime(2026, 4, 1, 9)), // beyond 7-day horizon
    ];
    final ctx = await _builder(
      events: events,
      options: const ContextOptions(upcomingHorizon: Duration(days: 7)),
    ).build(now: _now);

    expect(ctx.upcoming.map((s) => s.title), ['In 1 day', 'In 3 days']);
  });

  test('date-only intervals are treated as all-day blocks for today', () async {
    final ctx = await _builder(intervals: [
      _dateOnlyInterval('Study block', DateTime(2026, 3, 2)),
    ]).build(now: _now);

    expect(ctx.todaySchedule, hasLength(1));
    final item = ctx.todaySchedule.single;
    expect(item.kind, 'interval');
    expect(item.allDay, isTrue);
  });

  test('focus summary reflects sessions in the window', () async {
    final ctx = await _builder(focus: [
      _session(DateTime(2026, 3, 1, 9), 25),
      _session(DateTime(2026, 3, 1, 10), 50),
    ]).build(now: _now);

    expect(ctx.focus!.sessionCount, 2);
    expect(ctx.focus!.totalMinutes, 75);
  });

  test('focus can be disabled via options', () async {
    final ctx = await _builder(
      options: const ContextOptions(includeFocus: false),
    ).build(now: _now);
    expect(ctx.focus, isNull);
  });

  test('toJson is structured and inspectable', () async {
    final ctx = await _builder(
      tasks: [Task(title: 'A', isImportant: true)],
      events: [_event('Meeting', DateTime(2026, 3, 2, 10))],
    ).build(now: _now);

    final json = ctx.toJson();
    expect(json['totalOutstanding'], 1);
    expect((json['todaySchedule'] as List).single['title'], 'Meeting');
    expect((json['outstandingTasks'] as List).single['important'], true);
  });

  test('render produces a deterministic compact block', () async {
    final ctx = await _builder(
      tasks: [Task(title: 'Write report', isImportant: true)],
      events: [_event('Standup', DateTime(2026, 3, 2, 9, 30))],
      focus: [_session(DateTime(2026, 3, 1, 9), 25)],
    ).build(now: _now);

    final text = ctx.render();
    expect(text, contains('Outstanding tasks: 1'));
    expect(text, contains('Write report [important]'));
    expect(text, contains('Standup'));
    expect(text, contains('Focus (last 7d): 25 min'));
  });

  test('timezone is surfaced in render and toJson when provided', () async {
    final ctx = await _builder()
        .build(now: _now, timezone: 'Asia/Ho_Chi_Minh');
    expect(ctx.timezone, 'Asia/Ho_Chi_Minh');
    expect(ctx.render(), contains('User timezone: Asia/Ho_Chi_Minh'));
    expect(ctx.toJson()['timezone'], 'Asia/Ho_Chi_Minh');
  });

  test('no timezone omits the line and the json key', () async {
    final ctx = await _builder().build(now: _now);
    expect(ctx.timezone, isNull);
    expect(ctx.render(), isNot(contains('User timezone')));
    expect(ctx.toJson().containsKey('timezone'), isFalse);
  });
}
