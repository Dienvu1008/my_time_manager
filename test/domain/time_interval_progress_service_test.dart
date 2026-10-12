import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/domain/services/time_interval_progress_service.dart';

/// Records intervals passed to updateTimeInterval so we can assert the domain
/// service's behaviour without SQLite.
class _FakeTimeIntervalRepository implements TimeIntervalRepository {
  final List<TimeInterval> updated = [];

  @override
  Future<void> updateTimeInterval(TimeInterval timeInterval) async =>
      updated.add(timeInterval);

  // --- Unused by these tests ---
  @override
  Future<void> createTimeInterval(TimeInterval timeInterval) async {}
  @override
  Future<void> deleteTimeInterval(String id) async {}
  @override
  Future<void> rescheduleAllReminders() async {}
  @override
  Future<TimeInterval> getTimeInterval(String id) => throw UnimplementedError();
  @override
  Future<List<TimeInterval>> getTimeIntervals() async => const [];
  @override
  Future<List<TimeInterval>> getTimeIntervalsOfTask(String taskId) async =>
      const [];
  @override
  Future<List<TimeInterval>> getAllTimeIntervalsOfTask(String taskId) async =>
      const [];
  @override
  Future<List<TimeInterval>> getTimeIntervalsOfSubtask(
          String subtaskId) async =>
      const [];
}

TimeInterval _interval({bool completed = false, double done = 0}) {
  return TimeInterval(
    title: 'X',
    startDate: DateTime(2026, 1, 1),
    isStartTimeUndefined: true,
    isEndDateUndefined: true,
    isCompleted: completed,
    howMuchHasBeenDone: done,
  );
}

void main() {
  late _FakeTimeIntervalRepository repo;
  late TimeIntervalProgressService service;

  setUp(() {
    repo = _FakeTimeIntervalRepository();
    service = TimeIntervalProgressService(repo);
  });

  test('toggleCompleted flips completion and persists', () async {
    final ti = _interval(completed: false);

    final result = await service.toggleCompleted(ti);

    expect(result.isCompleted, isTrue);
    expect(repo.updated, hasLength(1));
    expect(repo.updated.single.id, ti.id);
    expect(repo.updated.single.isCompleted, isTrue);
  });

  test('toggleCompleted flips a completed interval back', () async {
    final ti = _interval(completed: true);

    final result = await service.toggleCompleted(ti);

    expect(result.isCompleted, isFalse);
    expect(repo.updated.single.isCompleted, isFalse);
  });

  test('updateMeasurableProgress sets amount and persists', () async {
    final ti = _interval(done: 1);

    final result = await service.updateMeasurableProgress(ti, 7.5);

    expect(result.howMuchHasBeenDone, 7.5);
    expect(repo.updated.single.howMuchHasBeenDone, 7.5);
  });
}
