// Validated, user-confirmed commit of a RescheduleProposal (Phase DR1, DR-a).
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/time_interval_repository.dart';
import 'availability.dart';
import 'reschedule_proposal.dart';
import 'review_snapshot.dart';

/// What the user is asked to approve before anything is written.
///
/// Domain-level equivalent of the AI `ConfirmationRequest`
/// (`lib/ai/policy/confirmation.dart`): that type is bound to AI tools
/// (`toolName`, `ToolRisk`) and lives in `lib/ai`, which the application layer
/// must not depend on. DR2 (UI) / the C9 AI overlay adapt to this type.
class ReviewConfirmationRequest {
  ReviewConfirmationRequest({required this.proposal, required List<ProposalItem> items})
      : items = List.unmodifiable(items);

  final RescheduleProposal proposal;

  /// Accepted AND applicable items that will be written if approved.
  final List<ProposalItem> items;

  int get moveCount => _count(IntervalChangeKind.update);
  int get createCount => _count(IntervalChangeKind.create);
  int get deleteCount => _count(IntervalChangeKind.delete);

  /// Deadlines that would be moved (never silent — shown to the user).
  int get deadlineMoveCount => items.where((i) => i.movesDeadline).length;
  bool get isDestructive => deleteCount > 0;

  int _count(IntervalChangeKind k) =>
      items.fold(0, (n, i) => n + i.changes.where((c) => c.kind == k).length);

  /// Short, non-localized summary (the UI renders its own text).
  String get summary => 'Apply ${items.length} change(s): $moveCount move, '
      '$createCount new, $deleteCount delete'
      '${deadlineMoveCount > 0 ? ', $deadlineMoveCount deadline(s) moved' : ''}';
}

/// Returns true to approve the whole accepted batch, false to decline.
typedef ReviewConfirmationHandler = Future<bool> Function(
    ReviewConfirmationRequest request);

/// Safe default: declines everything (nothing applies without explicit UI).
Future<bool> denyReviewByDefault(ReviewConfirmationRequest request) async =>
    false;

enum ApplyOutcome {
  /// Written.
  applied,

  /// Accepted item with nothing to write (keep pending / already in place).
  noChange,

  /// Accepted item not applicable (needs duration / no capacity /
  /// unresolvable). Nothing written.
  notApplicable,

  /// The user declined the confirmation. Nothing written.
  notConfirmed,

  /// Authoritative state changed since the proposal (fingerprint mismatch,
  /// interval gone, task completed/hidden). Nothing written.
  rejectedStale,

  /// The proposed slot conflicts now (or was flagged in the proposal), or is
  /// in the past. Nothing written.
  rejectedConflict,

  /// The write threw. That item's own partial writes are compensated; items
  /// applied before it are kept (reported as partial).
  failed,
}

class ItemApplyResult {
  const ItemApplyResult(this.intervalId, this.outcome,
      {this.detail, this.conflicts = const []});

  final String intervalId;
  final ApplyOutcome outcome;
  final String? detail;
  final List<ProposalConflict> conflicts;

  @override
  String toString() => 'ItemApplyResult($intervalId ${outcome.name}'
      '${detail == null ? '' : ' $detail'})';
}

class ApplyResult {
  ApplyResult({required this.confirmed, required List<ItemApplyResult> results})
      : results = List.unmodifiable(results);

  /// True iff the confirmation handler approved.
  final bool confirmed;
  final List<ItemApplyResult> results;

  ApplyOutcome? outcomeOf(String intervalId) {
    for (final r in results) {
      if (r.intervalId == intervalId) return r.outcome;
    }
    return null;
  }

  int count(ApplyOutcome o) => results.where((r) => r.outcome == o).length;
  int get appliedCount => count(ApplyOutcome.applied);

  /// Something was applied and something that should have been was not.
  bool get isPartial =>
      appliedCount > 0 &&
      results.any((r) =>
          r.outcome == ApplyOutcome.failed ||
          r.outcome == ApplyOutcome.rejectedStale ||
          r.outcome == ApplyOutcome.rejectedConflict);

  bool get isNoOp => appliedCount == 0;
}

/// Commits the accepted subset of a proposal (DR-a: per-item transactional).
///
/// 1. Nothing is written without an approving [ReviewConfirmationHandler];
///    declined / throwing handler → no-op.
/// 2. Authoritative state is re-read: each item's interval is re-fetched and
///    its fingerprint recomputed (mismatch → rejectedStale); the proposed
///    slots are re-checked against current opaque events and incomplete
///    intervals (overlap / past → rejectedConflict).
/// 3. Writes go ONLY through [TimeIntervalRepository] so reminders reconcile.
///    Split = create part 2, then update the original; if the update throws the
///    created row is deleted again (no half-applied item).
/// 4. Items already applied are not rolled back when a later one fails.
/// Re-applying the same proposal is idempotent: applied items changed their
/// fingerprint → rejectedStale.
class ProposalApplier {
  ProposalApplier({
    required TimeIntervalRepository timeIntervals,
    required TaskRepository tasks,
    required CalendarRepository calendar,
    EventOccurrenceExpander? expander,
  })  : _timeIntervals = timeIntervals,
        _tasks = tasks,
        _calendar = calendar,
        _expander = expander;

  final TimeIntervalRepository _timeIntervals;
  final TaskRepository _tasks;
  final CalendarRepository _calendar;
  final EventOccurrenceExpander? _expander;

  Future<ApplyResult> apply(
    RescheduleProposal proposal,
    Set<String> acceptedIds, {
    required ReviewConfirmationHandler confirm,
    required DateTime now,
  }) async {
    final accepted = [
      for (final i in proposal.items)
        if (acceptedIds.contains(i.intervalId)) i
    ];
    final results = <ItemApplyResult>[];
    final applicable = <ProposalItem>[];
    for (final i in accepted) {
      if (i.isApplicable) {
        applicable.add(i);
      } else if (i.status == ProposalItemStatus.conflict || i.conflicts.isNotEmpty) {
        results.add(ItemApplyResult(i.intervalId, ApplyOutcome.rejectedConflict,
            detail: 'flaggedInProposal', conflicts: i.conflicts));
      } else if (i.status == ProposalItemStatus.noChange) {
        results.add(ItemApplyResult(i.intervalId, ApplyOutcome.noChange));
      } else {
        results.add(ItemApplyResult(i.intervalId, ApplyOutcome.notApplicable,
            detail: i.reason));
      }
    }
    if (applicable.isEmpty) return ApplyResult(confirmed: false, results: results);

    var approved = false;
    try {
      approved = await confirm(
          ReviewConfirmationRequest(proposal: proposal, items: applicable));
    } catch (_) {
      approved = false;
    }
    if (!approved) {
      return ApplyResult(confirmed: false, results: [
        ...results,
        for (final i in applicable)
          ItemApplyResult(i.intervalId, ApplyOutcome.notConfirmed),
      ]);
    }

    final snapshot = await ReviewSnapshot.load(
        timeIntervals: _timeIntervals, tasks: _tasks, calendar: _calendar);
    final current = {for (final i in snapshot.intervals) i.id: i};
    final calc = AvailabilityCalculator(const Availability(), expander: _expander);

    for (final item in applicable) {
      results.add(await _applyOne(item, snapshot, current, calc, now));
    }
    return ApplyResult(confirmed: true, results: results);
  }

  Future<ItemApplyResult> _applyOne(
    ProposalItem item,
    ReviewSnapshot snapshot,
    Map<String, TimeInterval> current,
    AvailabilityCalculator calc,
    DateTime now,
  ) async {
    final id = item.intervalId;
    TimeInterval fresh;
    try {
      fresh = await _timeIntervals.getTimeInterval(id);
    } catch (_) {
      return ItemApplyResult(id, ApplyOutcome.rejectedStale, detail: 'missing');
    }
    if (intervalFingerprint(fresh) != item.fingerprint) {
      return ItemApplyResult(id, ApplyOutcome.rejectedStale, detail: 'changed');
    }
    if (fresh.isCompleted || !snapshot.isLive(fresh)) {
      return ItemApplyResult(id, ApplyOutcome.rejectedStale, detail: 'notLive');
    }

    // Re-check proposed slots against CURRENT authoritative state.
    final conflicts = <ProposalConflict>[];
    for (final c in item.changes) {
      final r = c.proposed;
      if (r == null) continue;
      if (r.start.isBefore(now)) {
        conflicts.add(ProposalConflict(ConflictKind.past, range: r));
      }
      final busy = calc.busyBlocks(
        window: r,
        events: snapshot.events,
        intervals: current.values.where(snapshot.isLive),
        excludeIntervalIds: {id},
      );
      for (final b in calc.conflictsWith(r, busy)) {
        conflicts.add(ProposalConflict(ProposalConflict.kindOf(b.source),
            refId: b.refId, range: b.range));
      }
    }
    if (conflicts.isNotEmpty) {
      return ItemApplyResult(id, ApplyOutcome.rejectedConflict,
          detail: 'conflictAtCommit', conflicts: conflicts);
    }

    TimeInterval? created;
    try {
      final update = _changeOf(item, IntervalChangeKind.update);
      final create = _changeOf(item, IntervalChangeKind.create);
      final delete = _changeOf(item, IntervalChangeKind.delete);
      if (delete != null) {
        await _timeIntervals.deleteTimeInterval(id);
        current.remove(id);
        return ItemApplyResult(id, ApplyOutcome.applied);
      }
      if (create != null) {
        final part2 = withRange(fresh, create.proposed!, stamp: now, newId: create.intervalId);
        await _timeIntervals.createTimeInterval(part2);
        created = part2;
      }
      if (update != null) {
        final moved = withRange(fresh, update.proposed!, stamp: now);
        await _timeIntervals.updateTimeInterval(moved);
        current[id] = moved;
      }
      if (created != null) current[created.id] = created;
      return ItemApplyResult(id, ApplyOutcome.applied);
    } catch (e) {
      if (created != null) {
        try {
          await _timeIntervals.deleteTimeInterval(created.id);
        } catch (_) {
          // Best effort; reported below.
          return ItemApplyResult(id, ApplyOutcome.failed,
              detail: '$e (compensation failed for ${created.id})');
        }
      }
      return ItemApplyResult(id, ApplyOutcome.failed, detail: '$e');
    }
  }

  static IntervalChange? _changeOf(ProposalItem item, IntervalChangeKind k) {
    for (final c in item.changes) {
      if (c.kind == k) return c;
    }
    return null;
  }

  /// Copy of [src] with a fully timed `[range]` (all "undefined" flags off).
  /// Built through `toMap`/`fromMap` so this layer needs no Flutter import
  /// (`TimeOfDay` lives in material). With [newId] the copy is a NEW
  /// occurrence: fresh id, not completed, progress reset.
  static TimeInterval withRange(TimeInterval src, TimeRange range,
      {required DateTime stamp, String? newId}) {
    DateTime dateOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final m = Map<String, dynamic>.from(src.toMap());
    m['startDate'] = dateOf(range.start).toIso8601String();
    m['endDate'] = dateOf(range.end).toIso8601String();
    m['startTime'] = range.start.hour * 60 + range.start.minute;
    m['endTime'] = range.end.hour * 60 + range.end.minute;
    m['isStartDateUndefined'] = 0;
    m['isEndDateUndefined'] = 0;
    m['isStartTimeUndefined'] = 0;
    m['isEndTimeUndefined'] = 0;
    m['updateTimeStamp'] = stamp.toIso8601String();
    if (newId != null) {
      m['id'] = newId;
      m['isCompleted'] = 0;
      m['howMuchHasBeenDone'] = 0.0;
    }
    return TimeInterval.fromMap(m);
  }
}
