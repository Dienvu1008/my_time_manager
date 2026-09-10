import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/tools/domain/domain_tools.dart';
import 'package:my_time_manager/ai/tools/tool.dart';
import 'package:my_time_manager/ai/tools/tool_executor.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';
import 'package:my_time_manager/ai/tools/tool_result.dart';
import 'package:my_time_manager/data/models/model_calendar_event.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/focus_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/domain/services/focus_statistics_service.dart';
import 'package:my_time_manager/domain/services/task_completion_service.dart';
import 'package:my_time_manager/screen_focus_timer/data/model_focus_session.dart';

// ---- Fakes (headless; no SQLite, no NotificationService) --------------------

class _FakeTaskRepo implements TaskRepository {
  final Map<String, Task> store = {};
  @override
  Future<void> createTask(Task t) async => store[t.id] = t;
  @override
  Future<void> updateTask(Task t) async => store[t.id] = t;
  @override
  Future<Task> getTask(String id) async =>
      store[id] ?? (throw StateError('nf'));
  @override
  Future<List<Task>> getTasks() async => store.values.toList();
  @override
  Future<List<Task>> getTasksOfTaskList(String id) async =>
      store.values.where((t) => t.taskListId == id).toList();
  @override
  Future<List<Task>> getTasksWithoutTaskList() async =>
      store.values.where((t) => t.taskListId == null).toList();
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<void> moveTask(String a, String? b) async {}
  @override
  Future<void> softDeleteTask(String id) async {}
  @override
  Future<void> restoreTask(String id) async {}
  @override
  Future<void> permanentlyDeleteTask(String id) async {}
  @override
  Future<void> archiveTask(String id) async {}
  @override
  Future<void> unarchiveTask(String id) async {}
}

class _FakeCalendarRepo implements CalendarRepository {
  final Map<String, CalendarEvent> store = {};
  @override
  Future<void> createCalendarEvent(CalendarEvent e) async => store[e.id] = e;
  @override
  Future<void> updateCalendarEvent(CalendarEvent e) async => store[e.id] = e;
  @override
  Future<CalendarEvent?> getCalendarEvent(String id) async => store[id];
  @override
  Future<List<CalendarEvent>> getCalendarEvents() async => store.values.toList();
  @override
  Future<List<CalendarEvent>> getCalendarEventsOfTaskList(String id) async =>
      store.values.where((e) => e.taskListId == id).toList();
  @override
  Future<List<CalendarEvent>> getCalendarEventsWithoutTaskList() async =>
      store.values.where((e) => e.taskListId == null).toList();
  @override
  Future<void> deleteCalendarEvent(String id) async {}
  @override
  Future<void> moveCalendarEvent(String a, String? b) async {}
  @override
  Future<void> softDeleteCalendarEvent(String id) async {}
  @override
  Future<void> restoreCalendarEvent(String id) async {}
  @override
  Future<void> archiveCalendarEvent(String id) async {}
  @override
  Future<void> unarchiveCalendarEvent(String id) async {}
  @override
  Future<List<CalendarEvent>> getEventsPendingSync() async => const [];
  @override
  Future<CalendarEvent?> getEventByGoogleId(String id) async => null;
  @override
  Future<void> markSynced(String id,
      {String? googleEventId, String? etag, String? calendarId, String? iCalUID}) async {}
}

class _FakeTimeRepo implements TimeIntervalRepository {
  final Map<String, TimeInterval> store = {};
  @override
  Future<void> createTimeInterval(TimeInterval t) async => store[t.id] = t;
  @override
  Future<void> updateTimeInterval(TimeInterval t) async => store[t.id] = t;
  @override
  Future<TimeInterval> getTimeInterval(String id) async =>
      store[id] ?? (throw StateError('nf'));
  @override
  Future<List<TimeInterval>> getTimeIntervals() async => store.values.toList();
  @override
  Future<List<TimeInterval>> getTimeIntervalsOfTask(String id) async =>
      store.values.where((t) => t.taskId == id).toList();
  @override
  Future<List<TimeInterval>> getAllTimeIntervalsOfTask(String id) async =>
      store.values.where((t) => t.taskId == id).toList();
  @override
  Future<List<TimeInterval>> getTimeIntervalsOfSubtask(String id) async =>
      store.values.where((t) => t.subtaskId == id).toList();
  @override
  Future<void> deleteTimeInterval(String id) async {}
  @override
  Future<void> rescheduleAllReminders() async {}
}

class _FakeFocusRepo implements FocusRepository {
  final List<FocusSession> sessions;
  _FakeFocusRepo([this.sessions = const []]);
  @override
  Future<List<FocusSession>> allSessions() async => sessions;
  @override
  Future<List<FocusSession>> sessionsBetween(DateTime s, DateTime e) async =>
      sessions
          .where((x) => !x.startTime.isBefore(s) && x.startTime.isBefore(e))
          .toList();
  @override
  Future<void> saveSession(FocusSession s) async {}
  @override
  Future<void> syncPending() async {}
}

// ---- Helpers ----------------------------------------------------------------

ToolExecutor buildExecutor({
  TaskRepository? tasks,
  CalendarRepository? calendar,
  TimeIntervalRepository? time,
  FocusRepository? focus,
}) {
  final t = tasks ?? _FakeTaskRepo();
  final f = focus ?? _FakeFocusRepo();
  final registry = ToolRegistry(buildDomainTools(
    tasks: t,
    taskCompletion: TaskCompletionService(t),
    calendar: calendar ?? _FakeCalendarRepo(),
    timeIntervals: time ?? _FakeTimeRepo(),
    focus: f,
    focusStats: FocusStatisticsService(f),
  ));
  return ToolExecutor(registry);
}

FocusSession _session({
  String? taskId,
  String title = '',
  required DateTime start,
  required int minutes,
  bool completed = true,
}) =>
    FocusSession(
      taskId: taskId,
      taskType: taskId == null ? FocusTaskType.none : FocusTaskType.task,
      taskTitle: title,
      startTime: start,
      endTime: start.add(Duration(minutes: minutes)),
      focusDurationSeconds: minutes * 60,
      completed: completed,
    );

void main() {
  test('registry exposes exactly the expected tool set', () {
    final t = _FakeTaskRepo();
    final f = _FakeFocusRepo();
    final tools = buildDomainTools(
      tasks: t,
      taskCompletion: TaskCompletionService(t),
      calendar: _FakeCalendarRepo(),
      timeIntervals: _FakeTimeRepo(),
      focus: f,
      focusStats: FocusStatisticsService(f),
    );
    expect(tools.map((e) => e.name).toSet(), {
      'list_tasks', 'get_task', 'create_task', 'update_task', 'complete_task',
      'list_calendar_events', 'get_calendar_event', 'create_calendar_event',
      'update_calendar_event',
      'list_time_intervals', 'create_time_interval', 'update_time_interval',
      'list_focus_sessions', 'get_focus_statistics',
      'get_focus_summary', 'get_productivity_summary',
      'get_productivity_metrics',
    });
    // No tool is destructive in this initial set.
    expect(tools.every((t) => t.risk != ToolRisk.destructive), isTrue);
  });

  group('calendar tools', () {
    test('create + get round-trips a timed event', () async {
      final cal = _FakeCalendarRepo();
      final exec = buildExecutor(calendar: cal);
      final created = await exec.execute('create_calendar_event', {
        'title': 'Standup',
        'start': '2026-03-02T09:00:00',
        'end': '2026-03-02T09:30:00',
      });
      expect(created.success, isTrue);
      final id = (created.data as Map)['id'] as String;
      final got = await exec.execute('get_calendar_event', {'id': id});
      expect((got.data as Map)['title'], 'Standup');
      expect((got.data as Map)['isAllDay'], false);
    });

    test('create rejects end <= start', () async {
      final exec = buildExecutor();
      final r = await exec.execute('create_calendar_event', {
        'title': 'Bad',
        'start': '2026-03-02T10:00:00',
        'end': '2026-03-02T09:00:00',
      });
      expect(r.errorCode, ToolResult.codeInvalidArguments);
    });

    test('all-day event maps to date-only', () async {
      final exec = buildExecutor();
      final r = await exec.execute('create_calendar_event', {
        'title': 'Holiday',
        'start': '2026-03-02',
        'end': '2026-03-03',
        'isAllDay': true,
      });
      expect((r.data as Map)['isAllDay'], true);
    });

    test('get unknown -> not_found', () async {
      final r = await buildExecutor().execute('get_calendar_event', {'id': 'x'});
      expect(r.errorCode, ToolResult.codeNotFound);
    });
  });

  group('time planning tools', () {
    test('create date-only interval', () async {
      final time = _FakeTimeRepo();
      final exec = buildExecutor(time: time);
      final r = await exec.execute('create_time_interval', {
        'title': 'Study',
        'startDate': '2026-03-02',
      });
      expect(r.success, isTrue);
      expect((r.data as Map)['isStartTimeUndefined'], true);
      expect(time.store, hasLength(1));
    });

    test('create timed interval keeps times', () async {
      final exec = buildExecutor();
      final r = await exec.execute('create_time_interval', {
        'title': 'Deep work',
        'startDate': '2026-03-02',
        'endDate': '2026-03-02',
        'startTime': '09:00',
        'endTime': '11:00',
      });
      expect(r.success, isTrue);
      expect((r.data as Map)['startTime'], '09:00');
      expect((r.data as Map)['endTime'], '11:00');
    });

    test('rejects malformed time string', () async {
      final r = await buildExecutor().execute('create_time_interval', {
        'startDate': '2026-03-02',
        'startTime': '9 oclock',
        'endTime': '11:00',
      });
      expect(r.errorCode, ToolResult.codeInvalidArguments);
    });

    test('rejects end before start (domain ArgumentError surfaced)', () async {
      final r = await buildExecutor().execute('create_time_interval', {
        'startDate': '2026-03-02',
        'endDate': '2026-03-02',
        'startTime': '11:00',
        'endTime': '09:00',
      });
      expect(r.errorCode, ToolResult.codeInvalidArguments);
    });

    test('list filters by taskId', () async {
      final time = _FakeTimeRepo();
      await time.createTimeInterval(TimeInterval(
        title: 'x',
        taskId: 'T1',
        startDate: DateTime(2026, 3, 2),
        isStartTimeUndefined: true,
        isEndDateUndefined: true,
      ));
      final exec = buildExecutor(time: time);
      final r = await exec.execute('list_time_intervals', {'taskId': 'T1'});
      expect((r.data as Map)['count'], 1);
    });

    test('update unknown id -> not_found', () async {
      final r = await buildExecutor()
          .execute('update_time_interval', {'id': 'nope'});
      expect(r.errorCode, ToolResult.codeNotFound);
    });
  });

  group('focus + analytics tools', () {
    _FakeFocusRepo focusFixture() => _FakeFocusRepo([
          _session(taskId: 't1', title: 'Write', start: DateTime(2026, 3, 1, 9), minutes: 25),
          _session(taskId: 't1', title: 'Write', start: DateTime(2026, 3, 1, 10), minutes: 50),
          _session(start: DateTime(2026, 3, 2, 9), minutes: 15, completed: false),
        ]);

    test('list_focus_sessions honours limit', () async {
      final exec = buildExecutor(focus: focusFixture());
      final r = await exec.execute('list_focus_sessions', {'limit': 2});
      expect((r.data as Map)['count'], 2);
    });

    test('get_focus_statistics computes totals over a range', () async {
      final exec = buildExecutor(focus: focusFixture());
      final r = await exec.execute('get_focus_statistics', {
        'start': '2026-03-01',
        'end': '2026-03-03',
      });
      final d = r.data as Map;
      expect(d['sessionCount'], 3);
      expect(d['totalFocusMinutes'], 90);
      expect(d['completedCount'], 2);
    });

    test('get_focus_summary returns top tasks by focus', () async {
      final exec = buildExecutor(focus: focusFixture());
      final r = await exec.execute('get_focus_summary',
          {'days': 100000}); // wide window to include fixture dates
      final top = (r.data as Map)['topTasks'] as List;
      expect(top.first, containsPair('taskTitle', 'Write'));
    });

    test('get_productivity_summary combines tasks + focus', () async {
      final tasks = _FakeTaskRepo();
      await tasks.createTask(Task(title: 'A', isCompleted: true));
      await tasks.createTask(Task(title: 'B'));
      final exec = buildExecutor(tasks: tasks, focus: focusFixture());
      final r = await exec.execute('get_productivity_summary', {'days': 100000});
      final d = r.data as Map;
      expect((d['tasks'] as Map)['total'], 2);
      expect((d['tasks'] as Map)['completed'], 1);
      expect((d['tasks'] as Map)['outstanding'], 1);
    });
  });
}
