import '../../data/models/model_time_interval.dart';
import '../../domain/repositories/focus_repository.dart';
import '../../domain/repositories/time_interval_repository.dart';
import 'metric_inputs.dart';

/// Builds normalized [PlannedVsActual] samples from the domain layer so the
/// deterministic metrics can be computed over real data.
///
/// Mapping (documented, deterministic):
/// - One sample per time interval that has a defined start+end (the *plan*).
/// - plannedMinutes = (endTimestamp - startTimestamp) / 60000.
/// - actualMinutes  = focus minutes attributed to the interval's task, split
///   evenly across that task's intervals in range (focus is tracked per task,
///   not per interval, so we distribute it — an approximation, stated openly).
/// - completed      = the interval's isCompleted flag.
/// - dueAt          = the interval's end (its scheduled deadline).
/// - finishedAt     = end when completed, else null.
///
/// Reschedule is NOT tracked in the schema, so [PlannedVsActual.wasRescheduled]
/// is always false here — the metric is exposed but reports 0 until the app
/// records rescheduling. We do not fabricate it.
class MetricsSampleBuilder {
  MetricsSampleBuilder({
    required TimeIntervalRepository timeIntervals,
    required FocusRepository focus,
  })  : _intervals = timeIntervals,
        _focus = focus;

  final TimeIntervalRepository _intervals;
  final FocusRepository _focus;

  /// Build samples for intervals whose start falls in [start, end).
  Future<List<PlannedVsActual>> build(DateTime start, DateTime end) async {
    final allIntervals = await _intervals.getTimeIntervals();
    final sessions = await _focus.sessionsBetween(start, end);

    // Focus minutes per task in range.
    final focusByTask = <String, int>{};
    for (final s in sessions) {
      final tid = s.taskId;
      if (tid == null) continue;
      focusByTask[tid] = (focusByTask[tid] ?? 0) + s.focusMinutes;
    }

    // Intervals in range with a concrete start+end.
    final inRange = allIntervals.where((ti) {
      final st = ti.startTimestamp;
      final et = ti.endTimestamp;
      if (st == null || et == null) return false;
      final startDt = DateTime.fromMillisecondsSinceEpoch(st);
      return !startDt.isBefore(start) && startDt.isBefore(end) && et > st;
    }).toList();

    // Count intervals per task to split focus evenly.
    final intervalsPerTask = <String, int>{};
    for (final ti in inRange) {
      final tid = ti.taskId;
      if (tid != null) {
        intervalsPerTask[tid] = (intervalsPerTask[tid] ?? 0) + 1;
      }
    }

    return [
      for (final ti in inRange)
        _sample(ti, focusByTask, intervalsPerTask),
    ];
  }

  PlannedVsActual _sample(
    TimeInterval ti,
    Map<String, int> focusByTask,
    Map<String, int> intervalsPerTask,
  ) {
    final st = ti.startTimestamp!;
    final et = ti.endTimestamp!;
    final plannedMinutes = ((et - st) / 60000).round();

    final tid = ti.taskId;
    int actualMinutes = 0;
    if (tid != null && focusByTask.containsKey(tid)) {
      final count = intervalsPerTask[tid] ?? 1;
      actualMinutes = (focusByTask[tid]! / count).round();
    }

    final end = DateTime.fromMillisecondsSinceEpoch(et);
    final completed = ti.isCompleted;

    return PlannedVsActual(
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
      completed: completed,
      dueAt: end,
      finishedAt: completed ? end : null,
    );
  }
}
