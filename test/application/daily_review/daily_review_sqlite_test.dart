@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/daily_review/daily_review.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_time_interval_repository.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/fake_repositories.dart';
import 'daily_review_fixtures.dart';

/// End-to-end DR1 flow against the real SQLite repositories (in-memory FFI):
/// review → plan → apply → re-read; re-apply is rejected as stale.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  test('review, split + move, idempotent re-apply (SQLite)', () async {
    final tasks = SqliteTaskRepository();
    final intervals = SqliteTimeIntervalRepository();
    final calendar = FakeCalendarRepository();
    await tasks.createTask(Task(id: 't1', title: 'Owner'));
    await intervals.createTimeInterval(timed('o1', at(10, 9), at(10, 10)));
    await intervals.createTimeInterval(timed('o2', at(10, 11), at(10, 12)));

    final review = await DailyReviewService(
            timeIntervals: intervals, tasks: tasks, calendar: calendar)
        .review(kNow, const Availability());
    expect(review.overdue.map((i) => i.id), ['o1', 'o2']);

    var n = 0;
    final proposal = ReschedulePlanner(newId: () => 'part2-${++n}').plan(
      review: review,
      availability: const Availability(),
      selections: const [
        ReviewSelection('o1', RescheduleAction.split),
        ReviewSelection('o2', RescheduleAction.reschedule),
      ],
    );
    final applier = ProposalApplier(
        timeIntervals: intervals, tasks: tasks, calendar: calendar);
    Future<bool> approve(ReviewConfirmationRequest _) async => true;

    final result = await applier
        .apply(proposal, {'o1', 'o2'}, confirm: approve, now: kNow);
    expect(result.appliedCount, 2, reason: '${result.results}');

    final o1 = await intervals.getTimeInterval('o1');
    final part2 = await intervals.getTimeInterval('part2-1');
    final o2 = await intervals.getTimeInterval('o2');
    expect(timedRangeOf(o1), TimeRange(at(11, 10), at(11, 10, 30)));
    expect(timedRangeOf(part2), TimeRange(at(12, 9), at(12, 9, 30)));
    expect(part2.taskId, 't1');
    // o2 rescheduled to tomorrow after part 2 (part 2 blocks 09:00–09:30).
    expect(timedRangeOf(o2), TimeRange(at(12, 9, 30), at(12, 10, 30)));

    final again = await applier
        .apply(proposal, {'o1', 'o2'}, confirm: approve, now: kNow);
    expect(again.appliedCount, 0);
    expect(again.outcomeOf('o1'), ApplyOutcome.rejectedStale);
    expect(again.outcomeOf('o2'), ApplyOutcome.rejectedStale);
    expect((await intervals.getTimeIntervals()).length, 3);
  });
}
