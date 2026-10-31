// Deterministic scheduler + conflict checker for Daily Review (Phase DR1).
import 'package:uuid/uuid.dart';

import 'availability.dart';
import 'daily_review_service.dart';
import 'reschedule_proposal.dart';

/// Turns the user's selections into a [RescheduleProposal]. Pure and
/// deterministic for a given review, selections, availability and id
/// generator. Writes nothing.
///
/// Policies:
/// - Items are processed in REVIEW order (overdue → started → due today; each
///   important first, then time, then id) regardless of selection order, so
///   capacity is handed out deterministically.
/// - Items selected for a move/cancel give up their current slot; items kept
///   pending (and every unselected interval) keep blocking theirs. Each
///   placed item blocks its new slot for the following ones (never overfill).
/// - Overcapacity: an item that does not fit is NOT placed — non-deadlines get
///   [ProposalItemStatus.noCapacity] (keep pending), deadlines get
///   [ProposalItemStatus.unresolvable] (deadline unchanged).
/// - An explicit `at` is never auto-shifted: a conflicting / out-of-hours /
///   past slot → [ProposalItemStatus.conflict] (excluded from apply).
/// - Only task time intervals are ever changed; selections of other ids
///   (habits, calendar events, unknown) go to `ignoredIds`.
class ReschedulePlanner {
  ReschedulePlanner({this.expander, String Function()? newId})
      : _newId = newId ?? (() => const Uuid().v4());

  final EventOccurrenceExpander? expander;
  final String Function() _newId;

  RescheduleProposal plan({
    required DailyReview review,
    required List<ReviewSelection> selections,
    required Availability availability,
    DateTime? now,
    ProposalSource source = ProposalSource.deterministic,
  }) {
    final at = now ?? review.now;
    final day = DateTime(at.year, at.month, at.day);
    final endOfToday = DateTime(day.year, day.month, day.day + 1);
    final calc = AvailabilityCalculator(availability, expander: expander);

    final bySelection = <String, ReviewSelection>{};
    final ignored = <String>[];
    for (final s in selections) {
      if (review.itemById(s.intervalId) == null) {
        if (!ignored.contains(s.intervalId)) ignored.add(s.intervalId);
      } else {
        bySelection[s.intervalId] = s; // last selection for an id wins
      }
    }
    final ordered = [
      for (final i in review.items)
        if (bySelection.containsKey(i.id)) i
    ];

    final snapshot = review.snapshot;
    // Items the user chose to move/cancel give up their current slot; kept
    // items keep blocking theirs.
    final movingIds = {
      for (final i in ordered)
        if (bySelection[i.id]!.action != RescheduleAction.keepPending) i.id
    };
    final searchEnd = DateTime(day.year, day.month,
        day.day + availability.horizonDays + 31); // generous window for blocks
    final window = TimeRange(day, searchEnd);
    final base = calc.busyBlocks(
      window: window,
      events: snapshot.events,
      intervals: snapshot.intervals.where(snapshot.isLive),
      excludeIntervalIds: movingIds,
    );
    final placed = <BusyBlock>[];

    List<BusyBlock> busyNow() => [...base, ...placed];

    final items = <ProposalItem>[];
    for (final item in ordered) {
      final sel = bySelection[item.id]!;
      final assumptions = <String>[];
      final current = timedRangeOf(item.interval);
      ProposalItem result(ProposalItemStatus status, String reason,
              {List<IntervalChange> changes = const [],
              List<ProposalConflict> conflicts = const []}) =>
          ProposalItem(
            intervalId: item.id,
            action: sel.action,
            status: status,
            reason: reason,
            fingerprint: item.fingerprint,
            isDeadline: item.isDeadline,
            changes: changes,
            conflicts: conflicts,
            assumptions: assumptions,
          );
      ProposalItem notPlaced(String reasonIfNotDeadline) => item.isDeadline
          ? result(ProposalItemStatus.unresolvable, ProposalReason.deadlineNoSlot)
          : result(ProposalItemStatus.noCapacity, reasonIfNotDeadline);
      void commit(String id, TimeRange r) =>
          placed.add(BusyBlock(r, BusySource.proposal, id));

      if (sel.action == RescheduleAction.keepPending) {
        items.add(result(ProposalItemStatus.noChange, ProposalReason.keptByUser));
        continue;
      }
      if (sel.action == RescheduleAction.cancelOccurrence) {
        assumptions.add(ProposalAssumption.deletesOnlyThisOccurrence);
        items.add(result(ProposalItemStatus.ready, ProposalReason.cancelOccurrence,
            changes: [
              IntervalChange(
                  kind: IntervalChangeKind.delete,
                  intervalId: item.id,
                  current: current),
            ]));
        continue;
      }

      final duration = sel.duration ?? item.duration;
      if (duration == null || duration <= Duration.zero) {
        items.add(result(
            ProposalItemStatus.needsDuration, ProposalReason.unknownDuration));
        continue;
      }
      if (sel.duration != null) {
        assumptions.add(ProposalAssumption.suppliedDuration);
      }
      if (item.isDeadline) assumptions.add(ProposalAssumption.movesDeadline);
      final target = sel.targetDay == null
          ? endOfToday
          : DateTime(sel.targetDay!.year, sel.targetDay!.month, sel.targetDay!.day);
      DateTime horizonFrom(DateTime d) =>
          DateTime(d.year, d.month, d.day + availability.horizonDays);
      DateTime maxOf(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

      ProposalItem update(TimeRange r) {
        if (current != null && current == r) {
          assumptions.remove(ProposalAssumption.movesDeadline);
          return result(ProposalItemStatus.noChange, ProposalReason.alreadyInPlace);
        }
        commit(item.id, r);
        return result(ProposalItemStatus.ready, ProposalReason.placed, changes: [
          IntervalChange(
              kind: IntervalChangeKind.update,
              intervalId: item.id,
              current: current,
              proposed: r),
        ]);
      }

      switch (sel.action) {
        case RescheduleAction.doNow:
          final slot = calc.findSlot(
              from: at, until: endOfToday, duration: duration, busy: busyNow());
          items.add(slot == null
              ? notPlaced(ProposalReason.noCapacityToday)
              : update(slot));
        case RescheduleAction.reschedule:
          if (sel.at != null) {
            final r = TimeRange(sel.at!, sel.at!.add(duration));
            final conflicts = <ProposalConflict>[
              if (r.start.isBefore(at)) ProposalConflict(ConflictKind.past, range: r),
              if (!availability.isWithinWorkingHours(r))
                ProposalConflict(ConflictKind.outsideWorkingHours, range: r),
              for (final b in calc.conflictsWith(r, busyNow()))
                ProposalConflict(ProposalConflict.kindOf(b.source),
                    refId: b.refId, range: b.range),
            ];
            if (conflicts.isEmpty) {
              items.add(update(r));
            } else {
              items.add(result(ProposalItemStatus.conflict,
                  ProposalReason.requestedSlotConflict,
                  changes: [
                    IntervalChange(
                        kind: IntervalChangeKind.update,
                        intervalId: item.id,
                        current: current,
                        proposed: r),
                  ],
                  conflicts: conflicts));
            }
            break;
          }
          final from = maxOf(at, target);
          final slot = calc.findSlot(
              from: from,
              until: horizonFrom(from),
              duration: duration,
              busy: busyNow());
          items.add(slot == null
              ? notPlaced(ProposalReason.noCapacityInHorizon)
              : update(slot));
        case RescheduleAction.split:
          var first = sel.firstPart;
          var second = sel.secondPart;
          if (first == null && second == null) {
            final half = Duration(minutes: duration.inMinutes ~/ 2);
            first = half;
            second = duration - half;
          }
          if (first == null ||
              second == null ||
              first <= Duration.zero ||
              second <= Duration.zero) {
            assumptions.remove(ProposalAssumption.movesDeadline);
            items.add(result(ProposalItemStatus.noChange, ProposalReason.invalidSplit));
            break;
          }
          final busy1 = busyNow();
          final slot1 = calc.findSlot(
              from: at, until: endOfToday, duration: first, busy: busy1);
          TimeRange? slot2;
          if (slot1 != null) {
            final from2 = maxOf(slot1.end, target);
            slot2 = calc.findSlot(
                from: from2,
                until: horizonFrom(from2),
                duration: second,
                busy: [...busy1, BusyBlock(slot1, BusySource.proposal, item.id)]);
          }
          if (slot1 == null || slot2 == null) {
            items.add(notPlaced(ProposalReason.noCapacityInHorizon));
            break;
          }
          final newId = _newId();
          commit(item.id, slot1);
          placed.add(BusyBlock(slot2, BusySource.proposal, newId));
          items.add(result(ProposalItemStatus.ready, ProposalReason.placed, changes: [
            IntervalChange(
                kind: IntervalChangeKind.update,
                intervalId: item.id,
                current: current,
                proposed: slot1),
            IntervalChange(
                kind: IntervalChangeKind.create,
                intervalId: newId,
                proposed: slot2),
          ]));
        case RescheduleAction.keepPending:
        case RescheduleAction.cancelOccurrence:
          break; // handled above
      }
    }

    return RescheduleProposal(
      createdAt: at,
      source: source,
      items: items,
      ignoredIds: ignored,
      assumptions: [
        if (expander == null && snapshot.events.any((e) => e.isRecurring))
          ProposalAssumption.recurringEventsNotExpanded,
      ],
    );
  }
}
