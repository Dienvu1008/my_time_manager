import 'package:flutter/material.dart' show Color;

import '../models/model_habit.dart';
import '../models/model_habit_occurrence.dart';
import '../repositories/habit_repository.dart';
import 'habit_statistics_service.dart';

/// One habit day shown on the calendar (Phase H3). Read model only: never
/// stored, never edited through the calendar.
class HabitCalendarEntry {
  const HabitCalendarEntry({
    required this.habitId,
    required this.title,
    required this.color,
    required this.localDate,
    required this.outcome,
    required this.isRecorded,
    required this.isScheduled,
    this.reminderTime,
  });

  final String habitId;
  final String title;
  final Color color;

  /// Local day (date-only).
  final DateTime localDate;

  /// `HH:mm` or null (shown in the all-day area).
  final String? reminderTime;

  /// Effective outcome resolved by [HabitStatisticsService.resolveDays].
  final HabitOutcome outcome;

  /// True if [outcome] comes from a user-recorded row.
  final bool isRecorded;

  /// True if the day is scheduled under the habit's current rule.
  final bool isScheduled;

  @override
  bool operator ==(Object other) =>
      other is HabitCalendarEntry &&
      other.habitId == habitId &&
      other.title == title &&
      other.color == color &&
      other.localDate == localDate &&
      other.reminderTime == reminderTime &&
      other.outcome == outcome &&
      other.isRecorded == isRecorded &&
      other.isScheduled == isScheduled;

  @override
  int get hashCode => Object.hash(habitId, title, color, localDate,
      reminderTime, outcome, isRecorded, isScheduled);

  @override
  String toString() => 'HabitCalendarEntry($habitId '
      '${HabitDay.format(localDate)} ${reminderTime ?? 'all-day'}: '
      '${outcome.name}${isRecorded ? '' : ' (derived)'})';
}

/// Read-only calendar projection of habits (Phase H3, Q-H3).
///
/// For a local-day range, every ACTIVE (non-archived) habit contributes its
/// scheduled days under the current rule plus its recorded days, each with
/// the effective outcome from [HabitStatisticsService.resolveDays] (past
/// unrecorded → missed, today/future unrecorded → pending). Nothing is
/// written; completing a habit goes through the habit workflow
/// (`HabitRepository.recordOutcome`), never through calendar data.
///
/// Output order (deterministic): day, then all-day entries (no reminder time)
/// before timed ones by `HH:mm`, then title, then habit id.
class HabitCalendarProjection {
  const HabitCalendarProjection({
    HabitStatisticsService statistics = const HabitStatisticsService(),
  }) : _statistics = statistics;

  final HabitStatisticsService _statistics;

  /// Pure projection over in-memory data. [occurrences] may contain rows of
  /// any habit / day; rows of other habits are ignored per habit.
  List<HabitCalendarEntry> project(
    List<Habit> habits,
    List<HabitOccurrence> occurrences, {
    required DateTime from,
    required DateTime to,
    required DateTime now,
  }) {
    final byHabit = <String, List<HabitOccurrence>>{};
    for (final o in occurrences) {
      byHabit.putIfAbsent(o.habitId, () => []).add(o);
    }
    final out = <HabitCalendarEntry>[];
    for (final h in habits) {
      if (h.isArchived) continue;
      final days = _statistics.resolveDays(h, byHabit[h.id] ?? const [],
          from: from, to: to, now: now);
      for (final d in days) {
        out.add(HabitCalendarEntry(
          habitId: h.id,
          title: h.title,
          color: h.color,
          localDate: d.day,
          reminderTime: h.reminderTime,
          outcome: d.outcome,
          isRecorded: d.isRecorded,
          isScheduled: d.isScheduled,
        ));
      }
    }
    out.sort(_compare);
    return out;
  }

  /// Load active habits + their occurrences in `[from, to]` from [repository]
  /// and [project].
  Future<List<HabitCalendarEntry>> load(
    HabitRepository repository, {
    required DateTime from,
    required DateTime to,
    required DateTime now,
  }) async {
    final habits = await repository.getHabits();
    final occurrences = <HabitOccurrence>[];
    for (final h in habits) {
      occurrences
          .addAll(await repository.occurrencesOf(h.id, from: from, to: to));
    }
    return project(habits, occurrences, from: from, to: to, now: now);
  }

  static int _compare(HabitCalendarEntry a, HabitCalendarEntry b) {
    var c = a.localDate.compareTo(b.localDate);
    if (c != 0) return c;
    final ta = a.reminderTime, tb = b.reminderTime;
    if (ta == null && tb != null) return -1;
    if (ta != null && tb == null) return 1;
    if (ta != null && tb != null) {
      c = ta.compareTo(tb);
      if (c != 0) return c;
    }
    c = a.title.compareTo(b.title);
    if (c != 0) return c;
    return a.habitId.compareTo(b.habitId);
  }
}
