// Model HabitOccurrence (Phase H1 — Habit data layer)
import 'package:equatable/equatable.dart';

import 'model_habit.dart';

/// The outcome of a habit on one local day. Exactly these five states; stored
/// as `.name` (TEXT, enforced by a CHECK constraint).
enum HabitOutcome {
  completed,
  partial,
  skipped,
  missed,
  pending;

  /// Read a stored value. Null / unknown (e.g. written by a newer build) →
  /// [HabitOutcome.pending], i.e. "unresolved": the statistics resolver then
  /// derives it like an unrecorded day (past → missed, today/future →
  /// pending), so an unknown value never fabricates a success.
  static HabitOutcome parse(Object? raw) {
    for (final o in HabitOutcome.values) {
      if (o.name == raw) return o;
    }
    return HabitOutcome.pending;
  }

  /// Strict variant: null for unknown values.
  static HabitOutcome? tryParse(Object? raw) {
    for (final o in HabitOutcome.values) {
      if (o.name == raw) return o;
    }
    return null;
  }
}

/// A USER-RECORDED outcome of a habit on one local day. Only recorded days are
/// stored; unrecorded scheduled days are derived at read time by
/// `HabitStatisticsService` (nothing is written in the background).
///
/// One row per (habitId, localDate). The id is deterministic —
/// [HabitOccurrence.idFor] = `'<habitId>:<yyyy-MM-dd>'` — so the same day
/// recorded on two devices merges by id on backup import (like
/// `lesson_progress.id == lessonId` in C7) instead of colliding on the UNIQUE
/// index. `deviceId` is attached by the DAO on insert.
class HabitOccurrence extends Equatable {
  final String id;
  final String habitId;

  /// Local day (date-only).
  final DateTime localDate;
  final HabitOutcome outcome;
  final double? amount;
  final String? note;
  final DateTime recordedAt;
  final String? deviceId;

  HabitOccurrence({
    String? id,
    required this.habitId,
    required DateTime localDate,
    required this.outcome,
    this.amount,
    this.note,
    DateTime? recordedAt,
    this.deviceId,
  })  : localDate = HabitDay.of(localDate),
        id = id ?? idFor(habitId, localDate),
        recordedAt = recordedAt ?? DateTime.now();

  static String idFor(String habitId, DateTime localDate) =>
      '$habitId:${HabitDay.format(localDate)}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'localDate': HabitDay.format(localDate),
      'outcome': outcome.name,
      'amount': amount,
      'note': note,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory HabitOccurrence.fromMap(Map<String, dynamic> map) {
    final recordedRaw = map['recordedAt'];
    return HabitOccurrence(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      localDate:
          HabitDay.tryParse(map['localDate']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      outcome: HabitOutcome.parse(map['outcome']),
      amount: (map['amount'] as num?)?.toDouble(),
      note: map['note'] as String?,
      recordedAt: recordedRaw == null
          ? null
          : DateTime.tryParse(recordedRaw.toString()),
      deviceId: map['deviceId'] as String?,
    );
  }

  @override
  String toString() => 'HabitOccurrence($habitId '
      '${HabitDay.format(localDate)}: ${outcome.name})';

  @override
  List<Object?> get props =>
      [id, habitId, localDate, outcome, amount, note, recordedAt];
}
