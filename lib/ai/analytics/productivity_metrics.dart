import 'metric_inputs.dart';

/// A bundle of deterministic productivity metrics computed by application code
/// (never by the LLM). Each field is either a value or null when there is no
/// basis to compute it (e.g. no planned work). The LLM interprets these; it
/// does not invent them.
class ProductivityMetrics {
  const ProductivityMetrics({
    required this.sampleCount,
    required this.planningAccuracy,
    required this.executionRate,
    required this.focusEfficiency,
    required this.estimationBias,
    required this.rescheduleRate,
    required this.deadlineMissRate,
    required this.workloadScore,
  });

  /// Number of planned-vs-actual units the metrics were computed over.
  final int sampleCount;

  /// Fraction of units executed close to plan (|actual-planned|/planned within
  /// tolerance). In [0,1]; null when no unit had a plan to compare.
  final double? planningAccuracy;

  /// Fraction of units completed. In [0,1]; null when there are no units.
  final double? executionRate;

  /// Total actual minutes / total planned minutes. >= 0; null when nothing was
  /// planned. Values < 1 mean less focus than planned; > 1 means more.
  final double? focusEfficiency;

  /// Mean signed estimation error across units with a plan. Positive means work
  /// tends to take longer than planned (chronic under-estimation). Null when no
  /// unit had a plan.
  final double? estimationBias;

  /// Fraction of units that were rescheduled. In [0,1]; null when no units.
  final double? rescheduleRate;

  /// Fraction of units with a deadline that missed it. In [0,1]; null when no
  /// unit had a deadline.
  final double? deadlineMissRate;

  /// Planned minutes / available minutes for the period. >= 0; null when
  /// capacity is unknown/zero. > 1 means over-committed.
  final double? workloadScore;

  Map<String, dynamic> toJson() => {
        'sampleCount': sampleCount,
        'planningAccuracy': _round(planningAccuracy),
        'executionRate': _round(executionRate),
        'focusEfficiency': _round(focusEfficiency),
        'estimationBias': _round(estimationBias),
        'rescheduleRate': _round(rescheduleRate),
        'deadlineMissRate': _round(deadlineMissRate),
        'workloadScore': _round(workloadScore),
      };

  static double? _round(double? v) =>
      v == null ? null : double.parse(v.toStringAsFixed(4));
}

/// Computes [ProductivityMetrics] deterministically from normalized inputs.
/// Pure and fully unit-testable; no I/O, no LLM.
class ProductivityMetricsService {
  const ProductivityMetricsService({this.accuracyTolerance = 0.25});

  /// A unit counts as "accurately planned" when its estimation error magnitude
  /// is within this fraction (default 25%).
  final double accuracyTolerance;

  ProductivityMetrics compute(
    List<PlannedVsActual> units, {
    Capacity? capacity,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final n = units.length;

    // Units that have a plan to compare against.
    final planned = units.where((u) => u.plannedMinutes > 0).toList();

    // Planning accuracy: fraction of planned units within tolerance.
    double? planningAccuracy;
    if (planned.isNotEmpty) {
      final withinTolerance = planned.where((u) {
        final err = u.estimationError!;
        return err.abs() <= accuracyTolerance;
      }).length;
      planningAccuracy = withinTolerance / planned.length;
    }

    // Execution rate: fraction completed.
    final double? executionRate =
        n == 0 ? null : units.where((u) => u.completed).length / n;

    // Focus efficiency: total actual / total planned.
    final totalPlanned =
        planned.fold<int>(0, (s, u) => s + u.plannedMinutes);
    final totalActual =
        planned.fold<int>(0, (s, u) => s + u.actualMinutes);
    final double? focusEfficiency =
        totalPlanned == 0 ? null : totalActual / totalPlanned;

    // Estimation bias: mean signed error over planned units.
    double? estimationBias;
    if (planned.isNotEmpty) {
      final sum =
          planned.fold<double>(0, (s, u) => s + u.estimationError!);
      estimationBias = sum / planned.length;
    }

    // Reschedule rate: fraction rescheduled.
    final double? rescheduleRate =
        n == 0 ? null : units.where((u) => u.wasRescheduled).length / n;

    // Deadline miss rate: over units that have a deadline.
    final withDeadline = units.where((u) => u.dueAt != null).toList();
    final double? deadlineMissRate = withDeadline.isEmpty
        ? null
        : withDeadline.where((u) => u.missedDeadline(ref)).length /
            withDeadline.length;

    // Workload score: planned minutes / available minutes.
    double? workloadScore;
    if (capacity != null && capacity.availableMinutes > 0) {
      final plannedForPeriod =
          units.fold<int>(0, (s, u) => s + u.plannedMinutes);
      workloadScore = plannedForPeriod / capacity.availableMinutes;
    }

    return ProductivityMetrics(
      sampleCount: n,
      planningAccuracy: planningAccuracy,
      executionRate: executionRate,
      focusEfficiency: focusEfficiency,
      estimationBias: estimationBias,
      rescheduleRate: rescheduleRate,
      deadlineMissRate: deadlineMissRate,
      workloadScore: workloadScore,
    );
  }
}
