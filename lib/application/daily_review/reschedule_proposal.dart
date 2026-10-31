// Transient reschedule proposal (Phase DR1, Q-DR2). Never persisted.
import 'availability.dart';
import 'review_snapshot.dart';

/// What the user wants to do with one reviewed time interval.
enum RescheduleAction {
  /// Place at the next free slot from now, on the review day only.
  doNow,

  /// Next free slot on/after a target day (default: tomorrow) within the
  /// availability horizon — or at an explicit start (conflict-checked).
  reschedule,

  /// Split into TWO occurrences: part 1 at the next free slot today (updates
  /// the original row), part 2 at the next free slot on/after the target day
  /// (default: tomorrow) as a NEW row. Both must fit or nothing is placed.
  split,

  /// No change.
  keepPending,

  /// Delete ONLY this occurrence (never the series / task). Destructive:
  /// flagged in the proposal and covered by the batch confirmation.
  cancelOccurrence,
}

/// Who produced the proposal (the deterministic planner, or the future AI
/// overlay feeding the same validator, Q-WORKFLOW).
enum ProposalSource { deterministic, ai }

enum ProposalItemStatus {
  /// Applicable (subject to re-validation at commit).
  ready,

  /// Nothing to change (keepPending, already in place, invalid request).
  noChange,

  /// Duration unknown and not supplied — ask the user (Q-DR3).
  needsDuration,

  /// Overcapacity: no free slot; left pending (never overfilled).
  noCapacity,

  /// A deadline with no slot: surfaced, deadline left unchanged.
  unresolvable,

  /// The requested slot conflicts; excluded from apply.
  conflict,
}

/// Stable reason codes (UI maps them to text in DR2).
abstract final class ProposalReason {
  static const keptByUser = 'keptByUser';
  static const alreadyInPlace = 'alreadyInPlace';
  static const unknownDuration = 'unknownDuration';
  static const noCapacityToday = 'noCapacityToday';
  static const noCapacityInHorizon = 'noCapacityInHorizon';
  static const deadlineNoSlot = 'deadlineNoSlot';
  static const requestedSlotConflict = 'requestedSlotConflict';
  static const invalidSplit = 'invalidSplit';
  static const cancelOccurrence = 'cancelOccurrence';
  static const placed = 'placed';
}

/// Stable assumption codes recorded on items.
abstract final class ProposalAssumption {
  /// The item is a deadline and the proposal moves it (never silent).
  static const movesDeadline = 'movesDeadline';

  /// The duration came from the caller, not from the interval.
  static const suppliedDuration = 'suppliedDuration';

  /// Deletes only this occurrence row.
  static const deletesOnlyThisOccurrence = 'deletesOnlyThisOccurrence';

  /// Recurring calendar events were not expanded (no expander injected).
  static const recurringEventsNotExpanded = 'recurringEventsNotExpanded';
}

/// One selection made by the user in the review.
class ReviewSelection {
  const ReviewSelection(
    this.intervalId,
    this.action, {
    this.duration,
    this.targetDay,
    this.at,
    this.firstPart,
    this.secondPart,
  });

  final String intervalId;
  final RescheduleAction action;

  /// Resolves an unknown duration (Q-DR3) or overrides the known one.
  final Duration? duration;

  /// reschedule / split part 2: earliest day (default: the day after review).
  final DateTime? targetDay;

  /// reschedule only: explicit start; conflict-checked, never auto-shifted.
  final DateTime? at;

  /// split only: the two part lengths (default: halves of the duration).
  final Duration? firstPart;
  final Duration? secondPart;
}

enum IntervalChangeKind { update, create, delete }

/// A concrete change of ONE time interval row: current vs proposed values.
class IntervalChange {
  const IntervalChange({
    required this.kind,
    required this.intervalId,
    this.current,
    this.proposed,
  });

  final IntervalChangeKind kind;

  /// Existing id for update/delete; the NEW id for create.
  final String intervalId;

  /// Current timed range (null when unknown or for create).
  final TimeRange? current;

  /// Proposed range (null for delete).
  final TimeRange? proposed;

  @override
  String toString() =>
      'IntervalChange(${kind.name} $intervalId: $current → $proposed)';
}

enum ConflictKind { calendarEvent, timeInterval, proposal, outsideWorkingHours, past }

class ProposalConflict {
  const ProposalConflict(this.kind, {this.refId, this.range});

  final ConflictKind kind;
  final String? refId;
  final TimeRange? range;

  static ConflictKind kindOf(BusySource s) => switch (s) {
        BusySource.calendarEvent => ConflictKind.calendarEvent,
        BusySource.timeInterval => ConflictKind.timeInterval,
        BusySource.proposal => ConflictKind.proposal,
      };

  @override
  String toString() => 'ProposalConflict(${kind.name} $refId)';
}

/// The proposal for one selected interval.
class ProposalItem {
  ProposalItem({
    required this.intervalId,
    required this.action,
    required this.status,
    required this.reason,
    required this.fingerprint,
    this.isDeadline = false,
    List<IntervalChange> changes = const [],
    List<ProposalConflict> conflicts = const [],
    List<String> assumptions = const [],
  })  : changes = List.unmodifiable(changes),
        conflicts = List.unmodifiable(conflicts),
        assumptions = List.unmodifiable(assumptions);

  final String intervalId;
  final RescheduleAction action;
  final ProposalItemStatus status;

  /// A [ProposalReason] code.
  final String reason;

  /// [intervalFingerprint] the proposal was computed against.
  final String fingerprint;
  final bool isDeadline;
  final List<IntervalChange> changes;
  final List<ProposalConflict> conflicts;
  final List<String> assumptions;

  bool get isDestructive =>
      changes.any((c) => c.kind == IntervalChangeKind.delete);
  bool get movesDeadline =>
      assumptions.contains(ProposalAssumption.movesDeadline);

  /// Only conflict-free ready items can be applied.
  bool get isApplicable =>
      status == ProposalItemStatus.ready && conflicts.isEmpty && changes.isNotEmpty;

  @override
  String toString() =>
      'ProposalItem($intervalId ${action.name} ${status.name} $reason $changes)';
}

/// Transient reschedule proposal (Q-DR2). Only ever touches task time
/// intervals — never calendar events, habits, tasks or repeat rules.
class RescheduleProposal {
  RescheduleProposal({
    required this.createdAt,
    required this.source,
    required List<ProposalItem> items,
    List<String> ignoredIds = const [],
    List<String> assumptions = const [],
  })  : items = List.unmodifiable(items),
        ignoredIds = List.unmodifiable(ignoredIds),
        assumptions = List.unmodifiable(assumptions),
        fingerprint = _fingerprintOf(items);

  final DateTime createdAt;
  final ProposalSource source;
  final List<ProposalItem> items;

  /// Selected ids that are not reviewable time intervals (e.g. habit or
  /// calendar-event ids) — ignored, never changed.
  final List<String> ignoredIds;

  /// Proposal-wide assumptions ([ProposalAssumption] codes).
  final List<String> assumptions;

  /// Version of the whole proposal (item fingerprints + changes).
  final String fingerprint;

  ProposalItem? itemFor(String intervalId) {
    for (final i in items) {
      if (i.intervalId == intervalId) return i;
    }
    return null;
  }

  /// Every interval id an applied proposal would touch (incl. created ids).
  Set<String> get affectedIds => {
        for (final i in items)
          for (final c in i.changes) c.intervalId,
      };

  List<ProposalItem> get applicable => [for (final i in items) if (i.isApplicable) i];

  static String _fingerprintOf(List<ProposalItem> items) => fnv1a32([
        for (final i in items)
          '${i.intervalId}:${i.fingerprint}:${i.status.name}:'
              '${i.changes.map((c) => '${c.kind.name}/${c.intervalId}/'
                  '${c.proposed?.start.toIso8601String()}/'
                  '${c.proposed?.end.toIso8601String()}').join(',')}',
      ].join(';'));
}
