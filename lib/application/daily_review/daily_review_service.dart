// Deterministic Daily Review query (Phase DR1).
import '../../domain/models/model_habit.dart';
import '../../domain/models/model_habit_occurrence.dart';
import '../../domain/models/model_task.dart';
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/time_interval_repository.dart';
import '../../domain/services/habit_statistics_service.dart';
import '../../domain/services/time_interval_progress_service.dart';
import 'availability.dart';
import 'review_snapshot.dart';

/// Category of one unresolved time interval. Each interval lands in exactly
/// one category, checked in this order.
enum ReviewCategory {
  /// Known end before `now`, incomplete.
  overdue,

  /// `TimeIntervalProgressService.isStartedButIncomplete`.
  startedIncomplete,

  /// Incomplete, not started yet, starting or ending on the review day.
  dueToday,
}

/// One unresolved time interval in the review.
class ReviewItem {
  ReviewItem({
    required this.interval,
    required this.task,
    required this.category,
    required this.isImportant,
    required this.isDeadline,
    required this.fingerprint,
  });

  final TimeInterval interval;

  /// Owning visible task (null for an interval without task).
  final Task? task;
  final ReviewCategory category;

  /// Interval OR owning task marked important.
  final bool isImportant;

  /// DR-b deadline: incomplete with a known end date on/before the review day.
  /// (Intervals carry no series link — every row is an occurrence, so the
  /// "non-recurring" part of the definition holds for all of them.)
  /// Deadlines are never moved silently: no slot → unresolvable.
  final bool isDeadline;

  /// [intervalFingerprint] at review time.
  final String fingerprint;

  String get id => interval.id;
  DateTime? get start => interval.isStartDateUndefined ? null : interval.calendarStartDateTime;
  DateTime? get end => interval.isEndDateUndefined ? null : interval.calendarEndDateTime;

  /// Known duration (start AND end date+time known), else null (Q-DR3).
  Duration? get duration => timedRangeOf(interval)?.duration;

  @override
  String toString() => 'ReviewItem(${category.name} $id)';
}

/// A habit scheduled on the review day that is still pending (or recorded as
/// missed). Report-only: DR never moves habits.
class HabitReviewEntry {
  const HabitReviewEntry({required this.habit, required this.outcome});

  final Habit habit;

  /// `pending` or `missed`.
  final HabitOutcome outcome;
}

/// Result of [DailyReviewService.review]. Transient (Q-DR1).
class DailyReview {
  DailyReview({
    required this.now,
    required this.day,
    required this.snapshot,
    required this.overdue,
    required this.startedIncomplete,
    required this.dueToday,
    required this.unscheduledTasks,
    required this.habitsPending,
    required this.habitsMissed,
    required this.freeTimeToday,
  });

  final DateTime now;

  /// Local date of [now].
  final DateTime day;

  /// The authoritative inputs this review was computed from (fed to the
  /// planner so the proposal fingerprints match what the user saw).
  final ReviewSnapshot snapshot;

  final List<ReviewItem> overdue;
  final List<ReviewItem> startedIncomplete;
  final List<ReviewItem> dueToday;

  /// Incomplete visible tasks without ANY time interval. Informational backlog:
  /// not counted in [isAllClear] and not schedulable in DR1 (DR only edits
  /// existing interval occurrences).
  final List<Task> unscheduledTasks;

  final List<HabitReviewEntry> habitsPending;
  final List<HabitReviewEntry> habitsMissed;

  /// Free working time left today (from now) under the availability.
  final Duration freeTimeToday;

  /// All interval items in display order: overdue, started, due today.
  List<ReviewItem> get items => [...overdue, ...startedIncomplete, ...dueToday];

  ReviewItem? itemById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  int get overdueCount => overdue.length;
  int get startedCount => startedIncomplete.length;
  int get dueTodayCount => dueToday.length;
  int get habitsOpenCount => habitsPending.length + habitsMissed.length;

  /// Known duration of all interval items.
  Duration get knownWorkload => items.fold(
      Duration.zero, (sum, i) => sum + (i.duration ?? Duration.zero));

  /// Positive empty state: nothing unresolved (intervals or habits).
  bool get isAllClear => items.isEmpty && habitsOpenCount == 0;
}

/// Deterministic categorization of unresolved work for the review day.
///
/// Stable ordering inside every list: important first, then time (overdue:
/// end; started: start; due today: start ?? end), then id.
class DailyReviewService {
  DailyReviewService({
    required TimeIntervalRepository timeIntervals,
    required TaskRepository tasks,
    required CalendarRepository calendar,
    HabitRepository? habits,
    HabitStatisticsService habitStatistics = const HabitStatisticsService(),
    EventOccurrenceExpander? expander,
  })  : _timeIntervals = timeIntervals,
        _tasks = tasks,
        _calendar = calendar,
        _habits = habits,
        _habitStatistics = habitStatistics,
        _expander = expander;

  final TimeIntervalRepository _timeIntervals;
  final TaskRepository _tasks;
  final CalendarRepository _calendar;
  final HabitRepository? _habits;
  final HabitStatisticsService _habitStatistics;
  final EventOccurrenceExpander? _expander;

  /// Load the snapshot and [categorize].
  Future<DailyReview> review(DateTime now, Availability availability) async {
    final day = DateTime(now.year, now.month, now.day);
    final snapshot = await ReviewSnapshot.load(
      timeIntervals: _timeIntervals,
      tasks: _tasks,
      calendar: _calendar,
      habits: _habits,
      habitsFrom: day,
      habitsTo: day,
    );
    return categorize(snapshot, now, availability);
  }

  /// Pure categorization of [snapshot] at [now].
  DailyReview categorize(
      ReviewSnapshot snapshot, DateTime now, Availability availability) {
    final day = DateTime(now.year, now.month, now.day);
    final nextDay = DateTime(day.year, day.month, day.day + 1);
    final overdue = <ReviewItem>[];
    final started = <ReviewItem>[];
    final dueToday = <ReviewItem>[];
    final withInterval = <String>{};

    for (final i in snapshot.intervals) {
      if (i.taskId != null) withInterval.add(i.taskId!);
      if (i.isCompleted || !snapshot.isLive(i)) continue;
      final start = i.isStartDateUndefined ? null : i.calendarStartDateTime;
      final end = i.isEndDateUndefined ? null : i.calendarEndDateTime;
      ReviewCategory? cat;
      if (end != null && end.isBefore(now)) {
        cat = ReviewCategory.overdue;
      } else if (TimeIntervalProgressService.isStartedButIncomplete(i, now)) {
        cat = ReviewCategory.startedIncomplete;
      } else if ((start != null && _sameDay(start, day)) ||
          (end != null && _sameDay(end, day))) {
        cat = ReviewCategory.dueToday;
      }
      if (cat == null) continue;
      final task = snapshot.taskOf(i);
      final item = ReviewItem(
        interval: i,
        task: task,
        category: cat,
        isImportant: i.isImportant || (task?.isImportant ?? false),
        isDeadline: end != null && end.isBefore(nextDay),
        fingerprint: intervalFingerprint(i),
      );
      switch (cat) {
        case ReviewCategory.overdue:
          overdue.add(item);
        case ReviewCategory.startedIncomplete:
          started.add(item);
        case ReviewCategory.dueToday:
          dueToday.add(item);
      }
    }
    overdue.sort(_comparator((i) => i.end));
    started.sort(_comparator((i) => i.start));
    dueToday.sort(_comparator((i) => i.start ?? i.end));

    final unscheduled = [
      for (final t in snapshot.tasks)
        if (!t.isCompleted && !withInterval.contains(t.id)) t
    ]..sort((a, b) {
        if (a.isImportant != b.isImportant) return a.isImportant ? -1 : 1;
        return a.id.compareTo(b.id);
      });

    final pending = <HabitReviewEntry>[];
    final missed = <HabitReviewEntry>[];
    for (final h in snapshot.habits) {
      if (h.isArchived || !h.isScheduledOn(day)) continue;
      final days = _habitStatistics.resolveDays(
          h, snapshot.habitOccurrences[h.id] ?? const [],
          from: day, to: day, now: now);
      for (final d in days) {
        if (d.day != day) continue;
        if (d.outcome == HabitOutcome.pending) {
          pending.add(HabitReviewEntry(habit: h, outcome: d.outcome));
        } else if (d.outcome == HabitOutcome.missed) {
          missed.add(HabitReviewEntry(habit: h, outcome: d.outcome));
        }
      }
    }
    int byHabit(HabitReviewEntry a, HabitReviewEntry b) {
      final c = a.habit.title.compareTo(b.habit.title);
      return c != 0 ? c : a.habit.id.compareTo(b.habit.id);
    }

    pending.sort(byHabit);
    missed.sort(byHabit);

    final calc = AvailabilityCalculator(availability, expander: _expander);
    final todayWindow = TimeRange(now, nextDay);
    final busy = calc.busyBlocks(
        window: todayWindow,
        events: snapshot.events,
        intervals: snapshot.intervals.where(snapshot.isLive));

    return DailyReview(
      now: now,
      day: day,
      snapshot: snapshot,
      overdue: List.unmodifiable(overdue),
      startedIncomplete: List.unmodifiable(started),
      dueToday: List.unmodifiable(dueToday),
      unscheduledTasks: List.unmodifiable(unscheduled),
      habitsPending: List.unmodifiable(pending),
      habitsMissed: List.unmodifiable(missed),
      freeTimeToday: calc.freeTimeBetween(now, nextDay, busy),
    );
  }

  static bool _sameDay(DateTime a, DateTime day) =>
      a.year == day.year && a.month == day.month && a.day == day.day;

  static int Function(ReviewItem, ReviewItem) _comparator(
          DateTime? Function(ReviewItem) key) =>
      (a, b) {
        if (a.isImportant != b.isImportant) return a.isImportant ? -1 : 1;
        final ka = key(a);
        final kb = key(b);
        if (ka != null && kb != null) {
          final c = ka.compareTo(kb);
          if (c != 0) return c;
        } else if (ka != null || kb != null) {
          return ka != null ? -1 : 1;
        }
        return a.id.compareTo(b.id);
      };
}
