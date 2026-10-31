import '../models/model_habit.dart';
import '../models/model_habit_occurrence.dart';
import '../repositories/habit_repository.dart';

/// One local day of a habit with its effective outcome.
class ResolvedHabitDay {
  const ResolvedHabitDay({
    required this.day,
    required this.outcome,
    required this.isRecorded,
    required this.isScheduled,
    this.occurrence,
  });

  /// Local day (date-only).
  final DateTime day;

  /// Effective outcome: the recorded one, or the derived one (missed /
  /// pending) for an unrecorded scheduled day.
  final HabitOutcome outcome;

  /// True if [outcome] comes from a user-recorded row (not derived).
  final bool isRecorded;

  /// True if the day is scheduled under the CURRENT recurrence rule.
  final bool isScheduled;

  /// The stored row for this day, if any.
  final HabitOccurrence? occurrence;

  @override
  String toString() =>
      'ResolvedHabitDay(${HabitDay.format(day)}: ${outcome.name}'
      '${isRecorded ? '' : ' (derived)'})';
}

/// How one resolved day affects a streak.
enum StreakEffect { add, pause, breakStreak }

/// Aggregated statistics of one habit. Computed deterministically from
/// recorded rows + the current rule + the streak policy + `now`.
class HabitStatistics {
  const HabitStatistics({
    required this.habitId,
    required this.today,
    required this.from,
    required this.to,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.counts,
    required this.scheduledDayCount,
    required this.days,
  });

  final String habitId;

  /// Local day of `now`.
  final DateTime today;

  /// Window (inclusive local days) of [completionRate], [counts], [days].
  final DateTime from;
  final DateTime to;

  /// Streak ending today (all history, independent of the window).
  final int currentStreak;

  /// Longest streak in all history up to today.
  final int bestStreak;

  /// Successful / resolved (excluding skipped) days in the window up to today,
  /// in [0, 1]; 0 when there is nothing resolved.
  final double completionRate;

  /// Count of each effective outcome over [days] (all 5 keys present).
  final Map<HabitOutcome, int> counts;

  /// Days scheduled under the current rule in the window.
  final int scheduledDayCount;

  /// Resolved days of the window, oldest first.
  final List<ResolvedHabitDay> days;
}

/// Pure, deterministic habit statistics (Phase H1, mirrors the
/// `FocusStatisticsService` approach: maths in Dart, no SQL, no writes).
///
/// **Derivation** (nothing is ever written in the background):
/// - A recorded row with a resolving outcome (completed / partial / skipped /
///   missed) is used as-is, on ANY day — also on days the current rule no
///   longer schedules (history survives rule changes).
/// - An unrecorded scheduled day (or one recorded as `pending`, or with an
///   unknown stored outcome) is derived: before today → `missed`; today or
///   later → `pending`. "Long offline" therefore turns past days into missed
///   deterministically at read time.
/// - Scheduled days come from the CURRENT rule (anchored at `startDate`,
///   bounded by `endDate` and, when archived, by the archive day). A rule
///   change never rewrites rows; it only changes which UNRECORDED days are
///   derived (also retroactively for past unrecorded days — documented choice).
///
/// **Streak policy (H-a):** completed → add; partial → add iff
/// `partialCountsTowardStreak`, otherwise pause; skipped → pause (no add, no
/// break); missed → break; pending (only today/future) → pause, so today's
/// pending never breaks the current streak; non-scheduled unrecorded days are
/// ignored. Only days ≤ today are walked.
///
/// **Completion rate:** over window days ≤ today: (completed + partial if
/// the flag is set) / (completed + partial + missed). Skipped and pending days
/// are excluded from the denominator; a partial that does not count is in the
/// denominator only.
class HabitStatisticsService {
  const HabitStatisticsService({HabitRepository? repository})
      : _repository = repository;

  final HabitRepository? _repository;

  /// Streak effect of one effective outcome under [habit]'s policy.
  static StreakEffect effectOf(Habit habit, HabitOutcome outcome) {
    switch (outcome) {
      case HabitOutcome.completed:
        return StreakEffect.add;
      case HabitOutcome.partial:
        return habit.partialCountsTowardStreak
            ? StreakEffect.add
            : StreakEffect.pause;
      case HabitOutcome.skipped:
      case HabitOutcome.pending:
        return StreakEffect.pause;
      case HabitOutcome.missed:
        return StreakEffect.breakStreak;
    }
  }

  /// True if [outcome] counts as a success for completion rate / streaks.
  static bool isSuccess(Habit habit, HabitOutcome outcome) =>
      outcome == HabitOutcome.completed ||
      (outcome == HabitOutcome.partial && habit.partialCountsTowardStreak);

  /// Resolve the days of [habit] in `[from, to]` (inclusive local days):
  /// scheduled days under the current rule ∪ days with a resolving recorded
  /// outcome, oldest first.
  List<ResolvedHabitDay> resolveDays(
    Habit habit,
    List<HabitOccurrence> occurrences, {
    required DateTime from,
    required DateTime to,
    required DateTime now,
  }) {
    final today = HabitDay.of(now);
    final first = HabitDay.of(from);
    final last = HabitDay.of(to);
    if (last.isBefore(first)) return const [];

    final byDay = <DateTime, HabitOccurrence>{};
    for (final o in occurrences) {
      if (o.habitId != habit.id) continue;
      if (o.localDate.isBefore(first) || o.localDate.isAfter(last)) continue;
      byDay[o.localDate] = o;
    }
    final scheduled = habit.scheduledDaysBetween(first, last).toSet();

    final allDays = <DateTime>{
      ...scheduled,
      for (final e in byDay.entries)
        if (e.value.outcome != HabitOutcome.pending) e.key,
    }.toList()
      ..sort();

    return [
      for (final day in allDays)
        _resolve(day, byDay[day], scheduled.contains(day), today),
    ];
  }

  ResolvedHabitDay _resolve(
      DateTime day, HabitOccurrence? row, bool isScheduled, DateTime today) {
    if (row != null && row.outcome != HabitOutcome.pending) {
      return ResolvedHabitDay(
        day: day,
        outcome: row.outcome,
        isRecorded: true,
        isScheduled: isScheduled,
        occurrence: row,
      );
    }
    return ResolvedHabitDay(
      day: day,
      outcome: day.isBefore(today) ? HabitOutcome.missed : HabitOutcome.pending,
      isRecorded: false,
      isScheduled: isScheduled,
      occurrence: row,
    );
  }

  /// First day with any history: min(startDate, earliest recorded day).
  DateTime _historyStart(Habit habit, List<HabitOccurrence> occurrences) {
    var first = habit.startDate;
    for (final o in occurrences) {
      if (o.habitId == habit.id && o.localDate.isBefore(first)) {
        first = o.localDate;
      }
    }
    return first;
  }

  /// (current, best) streaks over all history up to today.
  (int, int) streaks(
      Habit habit, List<HabitOccurrence> occurrences, DateTime now) {
    final days = resolveDays(habit, occurrences,
        from: _historyStart(habit, occurrences), to: now, now: now);
    var run = 0;
    var best = 0;
    for (final d in days) {
      switch (effectOf(habit, d.outcome)) {
        case StreakEffect.add:
          run++;
          if (run > best) best = run;
          break;
        case StreakEffect.pause:
          break;
        case StreakEffect.breakStreak:
          run = 0;
          break;
      }
    }
    return (run, best);
  }

  int currentStreak(
          Habit habit, List<HabitOccurrence> occurrences, DateTime now) =>
      streaks(habit, occurrences, now).$1;

  int bestStreak(
          Habit habit, List<HabitOccurrence> occurrences, DateTime now) =>
      streaks(habit, occurrences, now).$2;

  /// Completion rate over `[from, to]` capped at today (defaults: habit
  /// history start .. today).
  double completionRate(
    Habit habit,
    List<HabitOccurrence> occurrences, {
    required DateTime now,
    DateTime? from,
    DateTime? to,
  }) {
    final today = HabitDay.of(now);
    var last = to == null ? today : HabitDay.of(to);
    if (last.isAfter(today)) last = today;
    final days = resolveDays(habit, occurrences,
        from: from ?? _historyStart(habit, occurrences), to: last, now: now);
    return _rate(habit, days);
  }

  double _rate(Habit habit, Iterable<ResolvedHabitDay> days) {
    var success = 0;
    var resolved = 0;
    for (final d in days) {
      switch (d.outcome) {
        case HabitOutcome.completed:
        case HabitOutcome.partial:
        case HabitOutcome.missed:
          resolved++;
          if (isSuccess(habit, d.outcome)) success++;
          break;
        case HabitOutcome.skipped:
        case HabitOutcome.pending:
          break;
      }
    }
    return resolved == 0 ? 0 : success / resolved;
  }

  /// Full statistics. Window defaults to history start .. today. Days after
  /// today in the window appear as pending in [HabitStatistics.days] /
  /// [HabitStatistics.counts] but never affect rate or streaks.
  HabitStatistics compute(
    Habit habit,
    List<HabitOccurrence> occurrences, {
    required DateTime now,
    DateTime? from,
    DateTime? to,
  }) {
    final today = HabitDay.of(now);
    final windowFrom =
        from == null ? _historyStart(habit, occurrences) : HabitDay.of(from);
    final windowTo = to == null ? today : HabitDay.of(to);
    final days = resolveDays(habit, occurrences,
        from: windowFrom, to: windowTo, now: now);
    final counts = {for (final o in HabitOutcome.values) o: 0};
    for (final d in days) {
      counts[d.outcome] = counts[d.outcome]! + 1;
    }
    final (current, best) = streaks(habit, occurrences, now);
    return HabitStatistics(
      habitId: habit.id,
      today: today,
      from: windowFrom,
      to: windowTo,
      currentStreak: current,
      bestStreak: best,
      completionRate: _rate(habit, days.where((d) => !d.day.isAfter(today))),
      counts: Map.unmodifiable(counts),
      scheduledDayCount: days.where((d) => d.isScheduled).length,
      days: List.unmodifiable(days),
    );
  }

  /// Convenience: load the habit + its occurrences from the repository and
  /// [compute]. Null if the habit does not exist. Requires a repository.
  Future<HabitStatistics?> statisticsFor(
    String habitId, {
    DateTime? now,
    DateTime? from,
    DateTime? to,
  }) async {
    final repo = _repository;
    if (repo == null) {
      throw StateError('HabitStatisticsService has no repository');
    }
    final habit = await repo.getHabit(habitId);
    if (habit == null) return null;
    final occurrences = await repo.occurrencesOf(habitId);
    return compute(habit, occurrences,
        now: now ?? DateTime.now(), from: from, to: to);
  }
}
