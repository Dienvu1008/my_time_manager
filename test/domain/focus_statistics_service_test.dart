import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/repositories/focus_repository.dart';
import 'package:my_time_manager/domain/services/focus_statistics_service.dart';
import 'package:my_time_manager/domain/models/model_focus_session.dart';

/// In-memory fake of [FocusRepository]. `sessionsBetween` returns a fixed list
/// so we can test the aggregation deterministically without SQLite (and without
/// the NotificationService platform coupling that the real DB path carries).
class _FakeFocusRepository implements FocusRepository {
  _FakeFocusRepository(this._sessions);

  final List<FocusSession> _sessions;

  @override
  Future<List<FocusSession>> sessionsBetween(DateTime start, DateTime end) async =>
      _sessions
          .where((s) => !s.startTime.isBefore(start) && s.startTime.isBefore(end))
          .toList();

  // --- Unused by these tests ---
  @override
  Future<List<FocusSession>> allSessions() async => _sessions;
  @override
  Future<void> saveSession(FocusSession session) async {}
  @override
  Future<void> syncPending() async {}
}

FocusSession _session({
  String? taskId,
  String taskTitle = '',
  required DateTime start,
  required int minutes,
  bool completed = true,
}) {
  return FocusSession(
    taskId: taskId,
    taskType: taskId == null ? FocusTaskType.none : FocusTaskType.task,
    taskTitle: taskTitle,
    startTime: start,
    endTime: start.add(Duration(minutes: minutes)),
    focusDurationSeconds: minutes * 60,
    completed: completed,
  );
}

void main() {
  final rangeStart = DateTime(2026, 3, 1);
  final rangeEnd = DateTime(2026, 3, 8);

  test('empty data yields zeroed, safe statistics', () async {
    final service = FocusStatisticsService(_FakeFocusRepository([]));

    final stats = await service.statisticsBetween(rangeStart, rangeEnd);

    expect(stats.sessionCount, 0);
    expect(stats.completedCount, 0);
    expect(stats.totalFocusMinutes, 0);
    expect(stats.completionRate, 0);
    expect(stats.averageSessionMinutes, 0);
    expect(stats.activeDays, 0);
    expect(stats.perTask, isEmpty);
    expect(stats.perDayMinutes, isEmpty);
  });

  test('totals, completion rate, and average are computed correctly', () async {
    final service = FocusStatisticsService(_FakeFocusRepository([
      _session(start: DateTime(2026, 3, 1, 9), minutes: 25),
      _session(start: DateTime(2026, 3, 1, 10), minutes: 50),
      _session(start: DateTime(2026, 3, 2, 9), minutes: 25, completed: false),
    ]));

    final stats = await service.statisticsBetween(rangeStart, rangeEnd);

    expect(stats.sessionCount, 3);
    expect(stats.completedCount, 2);
    expect(stats.totalFocusMinutes, 100);
    expect(stats.completionRate, closeTo(2 / 3, 1e-9));
    expect(stats.averageSessionMinutes, closeTo(100 / 3, 1e-9));
  });

  test('per-day breakdown groups sessions by calendar day', () async {
    final service = FocusStatisticsService(_FakeFocusRepository([
      _session(start: DateTime(2026, 3, 1, 9), minutes: 25),
      _session(start: DateTime(2026, 3, 1, 22), minutes: 50),
      _session(start: DateTime(2026, 3, 2, 8), minutes: 30),
    ]));

    final stats = await service.statisticsBetween(rangeStart, rangeEnd);

    expect(stats.activeDays, 2);
    expect(stats.perDayMinutes[DateTime(2026, 3, 1)], 75);
    expect(stats.perDayMinutes[DateTime(2026, 3, 2)], 30);
  });

  test('per-task breakdown aggregates by taskId and keeps untitled separate',
      () async {
    final service = FocusStatisticsService(_FakeFocusRepository([
      _session(taskId: 't1', taskTitle: 'Write', start: DateTime(2026, 3, 1, 9), minutes: 25),
      _session(taskId: 't1', taskTitle: 'Write', start: DateTime(2026, 3, 1, 10), minutes: 25),
      _session(taskId: 't2', taskTitle: 'Read', start: DateTime(2026, 3, 2, 9), minutes: 50),
      _session(start: DateTime(2026, 3, 3, 9), minutes: 15), // no task
    ]));

    final stats = await service.statisticsBetween(rangeStart, rangeEnd);

    final t1 = stats.perTask.firstWhere((t) => t.taskId == 't1');
    expect(t1.sessionCount, 2);
    expect(t1.focusMinutes, 50);
    expect(t1.taskTitle, 'Write');

    final t2 = stats.perTask.firstWhere((t) => t.taskId == 't2');
    expect(t2.focusMinutes, 50);

    final noTask = stats.perTask.firstWhere((t) => t.taskId == null);
    expect(noTask.sessionCount, 1);
    expect(noTask.focusMinutes, 15);
  });

  test('recent() derives a window ending at the given now', () async {
    // Two sessions: one inside the last 7 days, one older.
    final now = DateTime(2026, 3, 10, 12);
    final service = FocusStatisticsService(_FakeFocusRepository([
      _session(start: DateTime(2026, 3, 9, 9), minutes: 40), // inside window
      _session(start: DateTime(2026, 3, 1, 9), minutes: 40), // older than 7 days
    ]));

    final stats = await service.recent(days: 7, now: now);

    expect(stats.sessionCount, 1);
    expect(stats.totalFocusMinutes, 40);
  });
}
