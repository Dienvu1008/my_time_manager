import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/daily_review/daily_review.dart';

import 'daily_review_fixtures.dart';

void main() {
  late Env env;
  setUp(() {
    env = Env();
    env.intervals.put(timed('o1', at(10, 9), at(10, 10)));
    env.intervals.put(timed('o2', at(10, 11), at(10, 12)));
  });

  TimeRange rangeOf(String id) => timedRangeOf(env.intervals.store[id]!)!;

  Future<RescheduleProposal> planBoth() => env.plan(const [
        ReviewSelection('o1', RescheduleAction.doNow),
        ReviewSelection('o2', RescheduleAction.doNow),
      ]);

  test('without approval nothing applies (deny default / declined / throwing)',
      () async {
    final p = await planBoth();
    for (final handler in <ReviewConfirmationHandler>[
      denyReviewByDefault,
      RecordingConfirm(false).call,
      (_) async => throw StateError('ui crashed'),
    ]) {
      final r = await env.applier
          .apply(p, {'o1', 'o2'}, confirm: handler, now: kNow);
      expect(r.confirmed, isFalse);
      expect(r.isNoOp, isTrue);
      expect(r.outcomeOf('o1'), ApplyOutcome.notConfirmed);
    }
    expect(env.intervals.writes, isEmpty);
  });

  test('empty acceptance → no-op without asking', () async {
    final p = await planBoth();
    final confirm = RecordingConfirm(true);
    final r = await env.applier.apply(p, {}, confirm: confirm.call, now: kNow);
    expect(r.results, isEmpty);
    expect(confirm.requests, isEmpty);
    expect(env.intervals.writes, isEmpty);
  });

  test('approved: applies accepted subset via the repository', () async {
    final p = await planBoth();
    final confirm = RecordingConfirm(true);
    final r =
        await env.applier.apply(p, {'o1'}, confirm: confirm.call, now: kNow);
    expect(r.confirmed, isTrue);
    expect(r.outcomeOf('o1'), ApplyOutcome.applied);
    expect(r.outcomeOf('o2'), isNull, reason: 'not accepted');
    expect(env.intervals.writes, ['update:o1']);
    expect(rangeOf('o1'), TimeRange(at(11, 10), at(11, 11)));
    expect(rangeOf('o2'), TimeRange(at(10, 11), at(10, 12)));
    final req = confirm.requests.single;
    expect(req.items.map((i) => i.intervalId), ['o1']);
    expect(req.moveCount, 1);
    expect(req.deadlineMoveCount, 1);
    expect(req.isDestructive, isFalse);
  });

  test('split creates part 2 and updates the original; cancel deletes only '
      'that occurrence', () async {
    final p = await env.plan(const [
      ReviewSelection('o1', RescheduleAction.split,
          firstPart: Duration(minutes: 20), secondPart: Duration(minutes: 40)),
      ReviewSelection('o2', RescheduleAction.cancelOccurrence),
    ]);
    final confirm = RecordingConfirm(true);
    final r = await env.applier
        .apply(p, {'o1', 'o2'}, confirm: confirm.call, now: kNow);
    expect(r.appliedCount, 2);
    expect(env.intervals.writes, ['create:new-1', 'update:o1', 'delete:o2']);
    expect(rangeOf('o1'), TimeRange(at(11, 10), at(11, 10, 20)));
    expect(rangeOf('new-1'), TimeRange(at(12, 9), at(12, 9, 40)));
    final part2 = env.intervals.store['new-1']!;
    expect(part2.taskId, 't1');
    expect(part2.isCompleted, isFalse);
    expect(env.intervals.store.containsKey('o2'), isFalse);
    expect(confirm.requests.single.deleteCount, 1);
    expect(confirm.requests.single.createCount, 1);
  });

  test('interval edited after proposal → rejectedStale', () async {
    final p = await planBoth();
    final o1 = env.intervals.store['o1']!;
    env.intervals.put(o1.copyWith(updateTimeStamp: DateTime(2026, 3, 11, 9)));
    env.intervals.put(env.intervals.store['o2']!.copyWith(isCompleted: true));
    env.intervals.writes.clear();
    final r = await env.applier
        .apply(p, {'o1', 'o2'}, confirm: approveAll, now: kNow);
    expect(r.outcomeOf('o1'), ApplyOutcome.rejectedStale);
    expect(r.outcomeOf('o2'), ApplyOutcome.rejectedStale);
    expect(env.intervals.writes, isEmpty);
  });

  test('deleted interval / completed task after proposal → rejectedStale',
      () async {
    final p = await planBoth();
    env.intervals.store.remove('o1');
    env.tasks.visible.clear(); // task trashed
    final r = await env.applier
        .apply(p, {'o1', 'o2'}, confirm: approveAll, now: kNow);
    expect(r.outcomeOf('o1'), ApplyOutcome.rejectedStale);
    expect(r.outcomeOf('o2'), ApplyOutcome.rejectedStale);
    expect(env.intervals.writes, isEmpty);
  });

  test('conflict appearing after proposal → rejectedConflict', () async {
    final p = await planBoth();
    env.calendar.visible.add(event('new meeting', at(11, 10, 30), at(11, 11)));
    final r = await env.applier
        .apply(p, {'o1', 'o2'}, confirm: approveAll, now: kNow);
    expect(r.outcomeOf('o1'), ApplyOutcome.rejectedConflict);
    expect(r.outcomeOf('o2'), ApplyOutcome.applied, reason: '11:00–12:00 free');
    expect(r.isPartial, isTrue);
    expect(env.intervals.writes, ['update:o2']);
    expect(rangeOf('o1'), TimeRange(at(10, 9), at(10, 10)));
  });

  test('a slot that became past at commit → rejectedConflict', () async {
    final p = await planBoth();
    final r = await env.applier
        .apply(p, {'o1'}, confirm: approveAll, now: at(11, 10, 30));
    expect(r.outcomeOf('o1'), ApplyOutcome.rejectedConflict);
    expect(env.intervals.writes, isEmpty);
  });

  test('flagged conflict / needsDuration / unresolvable are never applied',
      () async {
    env.intervals.put(untimed('u', at(11, 0)));
    env.calendar.visible.add(event('meeting', at(12, 9), at(12, 10)));
    final p = await env.plan([
      ReviewSelection('o1', RescheduleAction.reschedule, at: at(12, 9)),
      const ReviewSelection('u', RescheduleAction.doNow),
      const ReviewSelection('o2', RescheduleAction.keepPending),
    ]);
    final confirm = RecordingConfirm(true);
    final r = await env.applier
        .apply(p, {'o1', 'u', 'o2'}, confirm: confirm.call, now: kNow);
    expect(r.outcomeOf('o1'), ApplyOutcome.rejectedConflict);
    expect(r.outcomeOf('u'), ApplyOutcome.notApplicable);
    expect(r.outcomeOf('o2'), ApplyOutcome.noChange);
    expect(confirm.requests, isEmpty, reason: 'nothing applicable to confirm');
    expect(env.intervals.writes, isEmpty);
  });

  test('deadline with no slot: unresolvable, deadline unchanged', () async {
    final before = rangeOf('o1');
    final p = await env.plan(
        const [ReviewSelection('o1', RescheduleAction.doNow)],
        now: at(11, 17, 30));
    final r = await env.applier
        .apply(p, {'o1'}, confirm: approveAll, now: at(11, 17, 30));
    expect(r.outcomeOf('o1'), ApplyOutcome.notApplicable);
    expect(rangeOf('o1'), before);
    expect(env.intervals.writes, isEmpty);
  });

  test('partial batch failure: first applied, second failed, reported',
      () async {
    final p = await planBoth();
    env.intervals.beforeWrite = (op, id) {
      if (id == 'o2') throw StateError('disk full');
    };
    final r = await env.applier
        .apply(p, {'o1', 'o2'}, confirm: approveAll, now: kNow);
    expect(r.outcomeOf('o1'), ApplyOutcome.applied);
    expect(r.outcomeOf('o2'), ApplyOutcome.failed);
    expect(r.results.last.detail, contains('disk full'));
    expect(r.isPartial, isTrue);
    expect(rangeOf('o1'), TimeRange(at(11, 10), at(11, 11)), reason: 'kept');
    expect(rangeOf('o2'), TimeRange(at(10, 11), at(10, 12)));
  });

  test('split failure is compensated (no half-applied item)', () async {
    final p = await env.plan(
        const [ReviewSelection('o1', RescheduleAction.split)]);
    env.intervals.beforeWrite = (op, id) {
      if (op == 'update') throw StateError('boom');
    };
    final r =
        await env.applier.apply(p, {'o1'}, confirm: approveAll, now: kNow);
    expect(r.outcomeOf('o1'), ApplyOutcome.failed);
    expect(env.intervals.writes, ['create:new-1', 'delete:new-1']);
    expect(env.intervals.store.keys.toSet(), {'o1', 'o2'});
    expect(rangeOf('o1'), TimeRange(at(10, 9), at(10, 10)));
  });

  test('re-applying the same proposal is idempotent', () async {
    final p = await planBoth();
    final first = await env.applier
        .apply(p, {'o1', 'o2'}, confirm: approveAll, now: kNow);
    expect(first.appliedCount, 2);
    final writes = List.of(env.intervals.writes);
    final snapshot = Map.of(env.intervals.store);
    final second = await env.applier
        .apply(p, {'o1', 'o2'}, confirm: approveAll, now: kNow);
    expect(second.appliedCount, 0);
    expect(second.outcomeOf('o1'), ApplyOutcome.rejectedStale);
    expect(second.outcomeOf('o2'), ApplyOutcome.rejectedStale);
    expect(env.intervals.writes, writes);
    expect(env.intervals.store, snapshot);
  });

  test('a fresh review after apply proposes no duplicate change', () async {
    final p = await env.plan(
        const [ReviewSelection('o1', RescheduleAction.reschedule)]);
    await env.applier.apply(p, {'o1'}, confirm: approveAll, now: kNow);
    final r = await env.review();
    expect(r.itemById('o1'), isNull, reason: 'moved to tomorrow, not due');
    expect(env.intervals.store.length, 2, reason: 'no duplicated rows');
  });
}

Future<bool> approveAll(ReviewConfirmationRequest _) async => true;
