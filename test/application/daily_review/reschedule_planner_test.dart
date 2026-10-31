import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/daily_review/daily_review.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';

import 'daily_review_fixtures.dart';

void main() {
  late Env env;
  setUp(() {
    env = Env();
    env.intervals.put(timed('o1', at(10, 9), at(10, 10))); // overdue deadline
  });

  ProposalItem only(RescheduleProposal p) {
    expect(p.items, hasLength(1));
    return p.items.single;
  }

  test('doNow: next free slot from now, skipping opaque events', () async {
    env.calendar.visible.add(event('meeting', at(11, 10), at(11, 11)));
    final p = await env.plan([const ReviewSelection('o1', RescheduleAction.doNow)]);
    final item = only(p);
    expect(item.status, ProposalItemStatus.ready);
    expect(item.isApplicable, isTrue);
    expect(item.changes.single.kind, IntervalChangeKind.update);
    expect(item.changes.single.current, TimeRange(at(10, 9), at(10, 10)));
    expect(item.changes.single.proposed, TimeRange(at(11, 11), at(11, 12)));
    expect(item.movesDeadline, isTrue, reason: 'deadline move is flagged');
    expect(p.source, ProposalSource.deterministic);
  });

  test('reschedule: default tomorrow, explicit target day', () async {
    var item = only(
        await env.plan([const ReviewSelection('o1', RescheduleAction.reschedule)]));
    expect(item.changes.single.proposed!.start, at(12, 9));
    item = only(await env.plan([
      ReviewSelection('o1', RescheduleAction.reschedule, targetDay: at(13, 0))
    ]));
    expect(item.changes.single.proposed!.start, at(13, 9));
  });

  test('reschedule at an explicit conflicting slot → conflict, not applicable',
      () async {
    env.calendar.visible.add(event('meeting', at(12, 9), at(12, 10)));
    var item = only(await env.plan([
      ReviewSelection('o1', RescheduleAction.reschedule, at: at(12, 9, 30))
    ]));
    expect(item.status, ProposalItemStatus.conflict);
    expect(item.isApplicable, isFalse);
    expect(item.conflicts.single.kind, ConflictKind.calendarEvent);
    expect(item.conflicts.single.refId, 'meeting');

    item = only(await env.plan([
      ReviewSelection('o1', RescheduleAction.reschedule, at: at(12, 20))
    ]));
    expect(item.conflicts.map((c) => c.kind), [ConflictKind.outsideWorkingHours]);

    item = only(await env.plan([
      ReviewSelection('o1', RescheduleAction.reschedule, at: at(12, 11))
    ]));
    expect(item.status, ProposalItemStatus.ready);
    expect(item.changes.single.proposed, TimeRange(at(12, 11), at(12, 12)));
  });

  test('split: part 1 now (update), part 2 tomorrow (new occurrence)', () async {
    final item = only(await env.plan([
      const ReviewSelection('o1', RescheduleAction.split,
          firstPart: Duration(minutes: 30), secondPart: Duration(minutes: 45)),
    ]));
    expect(item.status, ProposalItemStatus.ready);
    expect(item.changes, hasLength(2));
    expect(item.changes[0].kind, IntervalChangeKind.update);
    expect(item.changes[0].proposed, TimeRange(at(11, 10), at(11, 10, 30)));
    expect(item.changes[1].kind, IntervalChangeKind.create);
    expect(item.changes[1].intervalId, 'new-1');
    expect(item.changes[1].proposed, TimeRange(at(12, 9), at(12, 9, 45)));

    final halves = only(await env.plan(
        [const ReviewSelection('o1', RescheduleAction.split)]));
    expect(halves.changes[0].proposed!.duration, const Duration(minutes: 30));
    expect(halves.changes[1].proposed!.duration, const Duration(minutes: 30));
  });

  test('placed items block later ones (no double booking)', () async {
    env.intervals.put(timed('o2', at(10, 11), at(10, 12)));
    final p = await env.plan([
      const ReviewSelection('o2', RescheduleAction.doNow),
      const ReviewSelection('o1', RescheduleAction.doNow),
    ]);
    // Review order (o1 ends first) — not selection order.
    expect(p.items.map((i) => i.intervalId), ['o1', 'o2']);
    expect(p.items[0].changes.single.proposed!.start, at(11, 10));
    expect(p.items[1].changes.single.proposed!.start, at(11, 11));
  });

  test('overcapacity: only what fits is placed, rest keep pending', () async {
    final env = Env();
    for (final id in ['s2', 's3', 's4']) {
      env.intervals.put(timed(id, at(11, 9), at(12, 10))); // non-deadline
    }
    env.intervals.put(timed('o1', at(10, 9), at(10, 10))); // deadline
    const d = Duration(minutes: 30);
    final p = await env.plan([
      const ReviewSelection('s2', RescheduleAction.doNow, duration: d),
      const ReviewSelection('s3', RescheduleAction.doNow, duration: d),
      const ReviewSelection('s4', RescheduleAction.doNow, duration: d),
      const ReviewSelection('o1', RescheduleAction.doNow, duration: d),
    ], now: at(11, 17));
    final byId = {for (final i in p.items) i.intervalId: i};
    // Review order: overdue o1 first, then started s2, s3, s4.
    expect(byId['o1']!.changes.single.proposed!.start, at(11, 17));
    expect(byId['s2']!.changes.single.proposed!.start, at(11, 17, 30));
    expect(byId['s3']!.status, ProposalItemStatus.noCapacity);
    expect(byId['s3']!.reason, ProposalReason.noCapacityToday);
    expect(byId['s3']!.changes, isEmpty);
    expect(byId['s4']!.status, ProposalItemStatus.noCapacity);
    expect(p.applicable.map((i) => i.intervalId), ['o1', 's2']);
  });

  test('unknown duration → needsDuration; supplied duration resolves it',
      () async {
    env.intervals.put(untimed('u', at(11, 0)));
    var item = only(
        await env.plan([const ReviewSelection('u', RescheduleAction.doNow)]));
    expect(item.status, ProposalItemStatus.needsDuration);
    expect(item.reason, ProposalReason.unknownDuration);
    expect(item.isApplicable, isFalse);

    item = only(await env.plan([
      const ReviewSelection('u', RescheduleAction.doNow,
          duration: Duration(minutes: 45))
    ]));
    expect(item.status, ProposalItemStatus.ready);
    expect(item.changes.single.current, isNull);
    expect(item.changes.single.proposed, TimeRange(at(11, 10), at(11, 10, 45)));
    expect(item.assumptions, contains(ProposalAssumption.suppliedDuration));
  });

  test('deadline with no slot → unresolvable, no change', () async {
    final item = only(await env.plan(
        [const ReviewSelection('o1', RescheduleAction.doNow)],
        now: at(11, 17, 30)));
    expect(item.status, ProposalItemStatus.unresolvable);
    expect(item.reason, ProposalReason.deadlineNoSlot);
    expect(item.changes, isEmpty);
    expect(item.isApplicable, isFalse);
  });

  test('calendar events and habits are never in the change set', () async {
    env.calendar.visible.add(event('meeting', at(11, 10), at(11, 11)));
    env.habits.habits['h1'] = Habit(id: 'h1', title: 'h', startDate: at(1, 0));
    final p = await env.plan([
      const ReviewSelection('meeting', RescheduleAction.doNow),
      const ReviewSelection('h1', RescheduleAction.reschedule),
      const ReviewSelection('o1', RescheduleAction.doNow),
    ]);
    expect(p.ignoredIds, ['meeting', 'h1']);
    expect(p.items.map((i) => i.intervalId), ['o1']);
    expect(p.affectedIds, {'o1'});
  });

  test('keepPending → noChange; cancelOccurrence → destructive delete',
      () async {
    env.intervals.put(timed('o2', at(10, 11), at(10, 12)));
    final p = await env.plan([
      const ReviewSelection('o1', RescheduleAction.keepPending),
      const ReviewSelection('o2', RescheduleAction.cancelOccurrence),
    ]);
    expect(p.itemFor('o1')!.status, ProposalItemStatus.noChange);
    expect(p.itemFor('o1')!.isApplicable, isFalse);
    final cancel = p.itemFor('o2')!;
    expect(cancel.status, ProposalItemStatus.ready);
    expect(cancel.isDestructive, isTrue);
    expect(cancel.changes.single.kind, IntervalChangeKind.delete);
    expect(cancel.assumptions,
        contains(ProposalAssumption.deletesOnlyThisOccurrence));
  });

  test('same inputs → same proposal fingerprint', () async {
    const sel = [ReviewSelection('o1', RescheduleAction.doNow)];
    final a = await env.plan(sel);
    final b = await env.plan(sel);
    expect(a.fingerprint, b.fingerprint);
    expect(a.items.single.fingerprint, b.items.single.fingerprint);
  });
}
