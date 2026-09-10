/// One planned unit of work compared against what actually happened. This is
/// the normalized input the metrics operate on, so the maths stays pure and
/// deterministic and does not have to know about TimeInterval/FocusSession
/// shapes. Callers (a domain-facing builder or an AI tool) populate it.
class PlannedVsActual {
  const PlannedVsActual({
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.completed,
    this.wasRescheduled = false,
    this.dueAt,
    this.finishedAt,
  });

  /// Minutes the work was planned to take (e.g. a time interval's duration).
  final int plannedMinutes;

  /// Minutes actually spent (e.g. focus time attributed to it). 0 if none.
  final int actualMinutes;

  /// Whether the work was completed.
  final bool completed;

  /// Whether this unit was moved/rescheduled at least once.
  final bool wasRescheduled;

  /// A deadline for the work, if any.
  final DateTime? dueAt;

  /// When the work actually finished, if it did.
  final DateTime? finishedAt;

  /// Missed the deadline: has both a due date and a finish after it, OR is
  /// past due and still not completed. Uses [now] for the not-completed case.
  bool missedDeadline(DateTime now) {
    final due = dueAt;
    if (due == null) return false;
    if (finishedAt != null) return finishedAt!.isAfter(due);
    return !completed && now.isAfter(due);
  }

  /// Signed estimation error fraction: (actual - planned) / planned.
  /// Positive means it took longer than planned (under-estimated).
  /// Null when [plannedMinutes] is 0 (no basis to compare).
  double? get estimationError {
    if (plannedMinutes <= 0) return null;
    return (actualMinutes - plannedMinutes) / plannedMinutes;
  }
}

/// The capacity side of a workload comparison: how many minutes are available.
class Capacity {
  const Capacity({required this.availableMinutes});
  final int availableMinutes;
}
