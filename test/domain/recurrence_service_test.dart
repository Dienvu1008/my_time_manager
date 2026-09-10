import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/domain/services/recurrence_service.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';

/// Records every interval passed to createTimeInterval so we can assert the
/// number and shape of the occurrences the service generates.
class _FakeTimeIntervalRepository implements TimeIntervalRepository {
  final List<TimeInterval> created = [];

  @override
  Future<void> createTimeInterval(TimeInterval timeInterval) async =>
      created.add(timeInterval);

  // --- Unused by these tests ---
  @override
  Future<void> updateTimeInterval(TimeInterval timeInterval) async {}
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

void main() {
  late _FakeTimeIntervalRepository repo;
  late RecurrenceService service;

  setUp(() {
    repo = _FakeTimeIntervalRepository();
    service = RecurrenceService(repo);
  });

  // A valid date-only interval: start date set (time undefined), end undefined.
  TimeInterval dateOnly(DateTime start) => TimeInterval(
        title: 'X',
        startDate: start,
        isStartTimeUndefined: true,
        isEndDateUndefined: true,
      );

  test('non-repeating rule saves exactly one interval', () async {
    final base = dateOnly(DateTime(2026, 1, 1));

    final count = await service.saveWithRepeat(base, RepeatRule.none);

    expect(count, 1);
    expect(repo.created, hasLength(1));
  });

  test('missing start date saves exactly one interval even if repeating',
      () async {
    // No start date to anchor on (both date fields undefined).
    final base = TimeInterval(
      title: 'X',
      isStartDateUndefined: true,
      isEndDateUndefined: true,
    );
    const rule = RepeatRule(
      frequency: RepeatFrequency.daily,
      endMode: RepeatEndMode.afterOccurrences,
      occurrences: 5,
    );

    final count = await service.saveWithRepeat(base, rule);

    expect(count, 1);
    expect(repo.created, hasLength(1));
  });

  test('daily rule with N occurrences creates N intervals with unique ids',
      () async {
    final base = dateOnly(DateTime(2026, 1, 1));
    const rule = RepeatRule(
      frequency: RepeatFrequency.daily,
      endMode: RepeatEndMode.afterOccurrences,
      occurrences: 4,
    );

    final count = await service.saveWithRepeat(base, rule);

    expect(count, 4);
    expect(repo.created, hasLength(4));
    final ids = repo.created.map((e) => e.id).toSet();
    expect(ids, hasLength(4), reason: 'each occurrence must have a unique id');
    // Occurrences fall on consecutive days starting from the base date.
    final dates = repo.created.map((e) => e.startDate).toList();
    expect(dates, [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 2),
      DateTime(2026, 1, 3),
      DateTime(2026, 1, 4),
    ]);
  });

  test('reports progress after each save', () async {
    final base = dateOnly(DateTime(2026, 1, 1));
    const rule = RepeatRule(
      frequency: RepeatFrequency.daily,
      endMode: RepeatEndMode.afterOccurrences,
      occurrences: 3,
    );
    final progress = <int>[];

    await service.saveWithRepeat(base, rule,
        onProgress: (done, total) => progress.add(done));

    expect(progress, [1, 2, 3]);
  });
}
