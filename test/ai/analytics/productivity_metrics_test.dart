import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/analytics/metric_inputs.dart';
import 'package:my_time_manager/ai/analytics/productivity_metrics.dart';

PlannedVsActual unit({
  int planned = 60,
  int actual = 60,
  bool completed = true,
  bool rescheduled = false,
  DateTime? due,
  DateTime? finished,
}) =>
    PlannedVsActual(
      plannedMinutes: planned,
      actualMinutes: actual,
      completed: completed,
      wasRescheduled: rescheduled,
      dueAt: due,
      finishedAt: finished,
    );

void main() {
  const service = ProductivityMetricsService();
  final now = DateTime(2026, 3, 10, 12);

  group('empty / no-basis cases', () {
    test('empty input yields nulls and zero count', () {
      final m = service.compute(const [], now: now);
      expect(m.sampleCount, 0);
      expect(m.planningAccuracy, isNull);
      expect(m.executionRate, isNull);
      expect(m.focusEfficiency, isNull);
      expect(m.estimationBias, isNull);
      expect(m.rescheduleRate, isNull);
      expect(m.deadlineMissRate, isNull);
      expect(m.workloadScore, isNull);
    });

    test('no planned minutes -> plan-based metrics are null but execution is not',
        () {
      final m = service.compute([unit(planned: 0, actual: 30)], now: now);
      expect(m.planningAccuracy, isNull);
      expect(m.focusEfficiency, isNull);
      expect(m.estimationBias, isNull);
      expect(m.executionRate, 1.0); // 1/1 completed
    });
  });

  group('executionRate', () {
    test('fraction completed', () {
      final m = service.compute([
        unit(completed: true),
        unit(completed: false),
        unit(completed: true),
        unit(completed: false),
      ], now: now);
      expect(m.executionRate, 0.5);
    });
  });

  group('focusEfficiency', () {
    test('total actual / total planned', () {
      final m = service.compute([
        unit(planned: 60, actual: 30),
        unit(planned: 60, actual: 90),
      ], now: now);
      // (30+90) / (60+60) = 120/120 = 1.0
      expect(m.focusEfficiency, 1.0);
    });

    test('less focus than planned is < 1', () {
      final m = service.compute([unit(planned: 100, actual: 50)], now: now);
      expect(m.focusEfficiency, 0.5);
    });
  });

  group('estimationBias', () {
    test('positive when work takes longer than planned', () {
      // errors: (95-60)/60 = 0.5833..., (120-60)/60 = 1.0 -> mean ~0.79
      final m = service.compute([
        unit(planned: 60, actual: 95),
        unit(planned: 60, actual: 120),
      ], now: now);
      expect(m.estimationBias, closeTo((35 / 60 + 60 / 60) / 2, 1e-9));
      expect(m.estimationBias! > 0, isTrue);
    });

    test('negative when work finishes faster than planned', () {
      final m = service.compute([unit(planned: 100, actual: 50)], now: now);
      expect(m.estimationBias, closeTo(-0.5, 1e-9));
    });
  });

  group('planningAccuracy', () {
    test('counts units within the 25% tolerance', () {
      final m = service.compute([
        unit(planned: 100, actual: 110), // 10% -> accurate
        unit(planned: 100, actual: 130), // 30% -> not accurate
        unit(planned: 100, actual: 80), // 20% -> accurate
      ], now: now);
      expect(m.planningAccuracy, closeTo(2 / 3, 1e-9));
    });

    test('custom tolerance changes the count', () {
      const strict = ProductivityMetricsService(accuracyTolerance: 0.05);
      final m = strict.compute([
        unit(planned: 100, actual: 110), // 10% -> NOT accurate at 5%
        unit(planned: 100, actual: 103), // 3% -> accurate
      ], now: now);
      expect(m.planningAccuracy, 0.5);
    });
  });

  group('rescheduleRate', () {
    test('fraction rescheduled', () {
      final m = service.compute([
        unit(rescheduled: true),
        unit(rescheduled: false),
      ], now: now);
      expect(m.rescheduleRate, 0.5);
    });
  });

  group('deadlineMissRate', () {
    test('null when no unit has a deadline', () {
      final m = service.compute([unit(), unit()], now: now);
      expect(m.deadlineMissRate, isNull);
    });

    test('finished after due counts as missed', () {
      final m = service.compute([
        unit(due: DateTime(2026, 3, 9), finished: DateTime(2026, 3, 10)), // missed
        unit(due: DateTime(2026, 3, 12), finished: DateTime(2026, 3, 11)), // on time
      ], now: now);
      expect(m.deadlineMissRate, 0.5);
    });

    test('past due and not completed counts as missed', () {
      final m = service.compute([
        unit(completed: false, due: DateTime(2026, 3, 9)), // past due, not done
      ], now: now);
      expect(m.deadlineMissRate, 1.0);
    });

    test('not-yet-due and incomplete does not count as missed', () {
      final m = service.compute([
        unit(completed: false, due: DateTime(2026, 3, 20)),
      ], now: now);
      expect(m.deadlineMissRate, 0.0);
    });
  });

  group('workloadScore', () {
    test('planned / available; > 1 means over-committed', () {
      final m = service.compute(
        [unit(planned: 300), unit(planned: 300)], // 600 planned
        capacity: const Capacity(availableMinutes: 480), // 8h
        now: now,
      );
      expect(m.workloadScore, closeTo(600 / 480, 1e-9));
      expect(m.workloadScore! > 1, isTrue);
    });

    test('null when capacity is not provided', () {
      final m = service.compute([unit(planned: 100)], now: now);
      expect(m.workloadScore, isNull);
    });
  });

  test('toJson rounds and includes all keys', () {
    final m = service.compute([unit(planned: 60, actual: 90)], now: now);
    final json = m.toJson();
    expect(json.keys, containsAll([
      'sampleCount',
      'planningAccuracy',
      'executionRate',
      'focusEfficiency',
      'estimationBias',
      'rescheduleRate',
      'deadlineMissRate',
      'workloadScore',
    ]));
    expect(json['sampleCount'], 1);
  });
}
