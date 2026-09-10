import '../../screen_focus_timer/data/model_focus_session.dart';
import '../repositories/focus_repository.dart';

/// Aggregated focus statistics for a time range. All fields are computed
/// deterministically by application code (never by an LLM), so they can be
/// trusted and unit-tested.
class FocusStatistics {
  const FocusStatistics({
    required this.start,
    required this.end,
    required this.sessionCount,
    required this.completedCount,
    required this.totalFocusMinutes,
    required this.perDayMinutes,
    required this.perTask,
  });

  /// The (half-open) range these statistics were computed over.
  final DateTime start;
  final DateTime end;

  /// Number of focus sessions in the range.
  final int sessionCount;

  /// Sessions that ran to completion (not reset/cancelled).
  final int completedCount;

  /// Total minutes actually focused (sum of each session's focus minutes).
  final int totalFocusMinutes;

  /// Focus minutes keyed by calendar day (`DateTime(y, m, d)` at local midnight).
  final Map<DateTime, int> perDayMinutes;

  /// Per-task aggregates, keyed by a stable task key (taskId, or the
  /// denormalized title for sessions without a taskId).
  final List<FocusTaskStat> perTask;

  /// Fraction of sessions that completed, in [0, 1]. 0 when there are none.
  double get completionRate =>
      sessionCount == 0 ? 0 : completedCount / sessionCount;

  /// Average focus minutes per session (0 when there are none).
  double get averageSessionMinutes =>
      sessionCount == 0 ? 0 : totalFocusMinutes / sessionCount;

  /// Number of distinct days that had at least one session.
  int get activeDays => perDayMinutes.length;
}

/// Focus totals for a single task within a range.
class FocusTaskStat {
  const FocusTaskStat({
    required this.taskId,
    required this.taskTitle,
    required this.sessionCount,
    required this.focusMinutes,
  });

  /// The task id, or null for sessions not attached to a task.
  final String? taskId;

  /// The task title as recorded on the sessions (denormalized).
  final String taskTitle;

  final int sessionCount;
  final int focusMinutes;
}

/// Read-only domain service that turns raw focus sessions into aggregated
/// statistics. It depends only on [FocusRepository] — no SQL, no new table —
/// and performs the maths in Dart so results are deterministic and testable.
///
/// This is the domain API behind the future `get_focus_statistics` /
/// `get_focus_summary` AI tools, and can also back the (currently disabled)
/// "My statistics" screen.
class FocusStatisticsService {
  FocusStatisticsService(this._focus);

  final FocusRepository _focus;

  /// Compute [FocusStatistics] over the half-open range [start, end).
  Future<FocusStatistics> statisticsBetween(DateTime start, DateTime end) async {
    final sessions = await _focus.sessionsBetween(start, end);
    return _aggregate(sessions, start, end);
  }

  /// Convenience: statistics for the last [days] days up to now (defaults to a
  /// 7-day window ending at the current moment).
  Future<FocusStatistics> recent({int days = 7, DateTime? now}) {
    final end = now ?? DateTime.now();
    final start = end.subtract(Duration(days: days));
    return statisticsBetween(start, end);
  }

  /// Pure aggregation, separated so it is trivially unit-testable.
  FocusStatistics _aggregate(
    List<FocusSession> sessions,
    DateTime start,
    DateTime end,
  ) {
    var completed = 0;
    var totalMinutes = 0;
    final perDay = <DateTime, int>{};

    // Preserve first-seen order of task keys for a stable perTask list.
    final taskOrder = <String>[];
    final taskAgg = <String, _MutableTaskStat>{};

    for (final s in sessions) {
      final minutes = s.focusMinutes;
      totalMinutes += minutes;
      if (s.completed) completed++;

      final day = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      perDay[day] = (perDay[day] ?? 0) + minutes;

      final key = s.taskId ?? 'title:${s.taskTitle}';
      final agg = taskAgg[key];
      if (agg == null) {
        taskOrder.add(key);
        taskAgg[key] = _MutableTaskStat(
          taskId: s.taskId,
          taskTitle: s.taskTitle,
          sessionCount: 1,
          focusMinutes: minutes,
        );
      } else {
        agg.sessionCount++;
        agg.focusMinutes += minutes;
      }
    }

    final perTask = [
      for (final key in taskOrder)
        FocusTaskStat(
          taskId: taskAgg[key]!.taskId,
          taskTitle: taskAgg[key]!.taskTitle,
          sessionCount: taskAgg[key]!.sessionCount,
          focusMinutes: taskAgg[key]!.focusMinutes,
        ),
    ];

    return FocusStatistics(
      start: start,
      end: end,
      sessionCount: sessions.length,
      completedCount: completed,
      totalFocusMinutes: totalMinutes,
      perDayMinutes: perDay,
      perTask: perTask,
    );
  }
}

class _MutableTaskStat {
  _MutableTaskStat({
    required this.taskId,
    required this.taskTitle,
    required this.sessionCount,
    required this.focusMinutes,
  });

  final String? taskId;
  final String taskTitle;
  int sessionCount;
  int focusMinutes;
}
