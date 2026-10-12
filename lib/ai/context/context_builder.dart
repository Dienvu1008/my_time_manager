import '../../domain/models/model_calendar_event.dart';
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/time_interval_repository.dart';
import '../../domain/services/focus_statistics_service.dart';
import 'agent_context.dart';

/// Tunable limits for context building. Keeping these explicit makes the
/// context size predictable and testable.
class ContextOptions {
  const ContextOptions({
    this.maxOutstandingTasks = 10,
    this.maxUpcoming = 8,
    this.upcomingHorizon = const Duration(days: 7),
    this.focusWindowDays = 7,
    this.includeFocus = true,
  });

  final int maxOutstandingTasks;
  final int maxUpcoming;
  final Duration upcomingHorizon;
  final int focusWindowDays;
  final bool includeFocus;
}

/// Builds a targeted [AgentContext] from the domain layer. It reads only what
/// the agent needs to start reasoning (outstanding tasks, today's schedule,
/// near-term upcoming items, a focus summary) — never the whole database. The
/// agent requests more detail through tools when needed.
///
/// Deterministic: pass an explicit `now` in tests. It touches data ONLY through
/// domain repositories/services — no DatabaseManager/SQLite.
class ContextBuilder {
  ContextBuilder({
    required TaskRepository tasks,
    required CalendarRepository calendar,
    required TimeIntervalRepository timeIntervals,
    FocusStatisticsService? focusStats,
    ContextOptions options = const ContextOptions(),
  })  : _tasks = tasks,
        _calendar = calendar,
        _intervals = timeIntervals,
        _focusStats = focusStats,
        _options = options;

  final TaskRepository _tasks;
  final CalendarRepository _calendar;
  final TimeIntervalRepository _intervals;
  final FocusStatisticsService? _focusStats;
  final ContextOptions _options;

  /// Build the context. [timezone] is the user's effective IANA timezone
  /// (resolved by the caller from config/device); it is surfaced to the model
  /// so it uses local time. [now] is injectable for deterministic tests.
  Future<AgentContext> build({DateTime? now, String? timezone}) async {
    final ref = now ?? DateTime.now();
    final dayStart = DateTime(ref.year, ref.month, ref.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final horizonEnd = dayStart.add(_options.upcomingHorizon);

    // --- Outstanding tasks (incomplete, visible) ---
    final allTasks = await _tasks.getTasks();
    final outstanding = allTasks.where((t) => !t.isCompleted).toList();
    // Deterministic order: important first, then title.
    outstanding.sort((a, b) {
      if (a.isImportant != b.isImportant) return a.isImportant ? -1 : 1;
      return a.title.compareTo(b.title);
    });
    final cappedTasks = outstanding
        .take(_options.maxOutstandingTasks)
        .map((t) => ContextTask(
              id: t.id,
              title: t.title,
              isImportant: t.isImportant,
            ))
        .toList();

    // --- Schedule items: calendar events + planned time intervals ---
    final events = await _calendar.getCalendarEvents();
    final intervals = await _intervals.getTimeIntervals();

    final schedule = <ContextScheduleItem>[
      for (final e in events)
        if (_eventStart(e) != null)
          ContextScheduleItem(
            id: e.id,
            title: e.title,
            kind: 'event',
            start: _eventStart(e)!,
            end: e.end.effective,
            allDay: e.start.isAllDay,
          ),
      for (final ti in intervals)
        if (_intervalStart(ti) != null)
          ContextScheduleItem(
            id: ti.id,
            title: ti.title.isEmpty ? '(untitled block)' : ti.title,
            kind: 'interval',
            start: _intervalStart(ti)!,
            end: ti.calendarEndDateTime,
            allDay: ti.isStartTimeUndefined,
          ),
    ];

    final today = schedule
        .where((s) => !s.start.isBefore(dayStart) && s.start.isBefore(dayEnd))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final upcoming = schedule
        .where((s) => !s.start.isBefore(dayEnd) && s.start.isBefore(horizonEnd))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    // --- Focus summary (optional) ---
    ContextFocus? focus;
    final focusStats = _focusStats;
    if (_options.includeFocus && focusStats != null) {
      final stats =
          await focusStats.recent(days: _options.focusWindowDays, now: ref);
      focus = ContextFocus(
        windowDays: _options.focusWindowDays,
        totalMinutes: stats.totalFocusMinutes,
        sessionCount: stats.sessionCount,
      );
    }

    return AgentContext(
      now: ref,
      timezone: timezone,
      outstandingTasks: cappedTasks,
      totalOutstanding: outstanding.length,
      todaySchedule: today,
      upcoming: upcoming.take(_options.maxUpcoming).toList(),
      focus: focus,
    );
  }

  /// The effective start of an event, or null if it has none usable.
  static DateTime? _eventStart(CalendarEvent e) => e.start.effective;

  /// The effective start of a planned interval, or null when the interval has
  /// no defined start date.
  static DateTime? _intervalStart(TimeInterval ti) {
    if (ti.isStartDateUndefined) return null;
    return ti.calendarStartDateTime ?? ti.startDate;
  }
}
