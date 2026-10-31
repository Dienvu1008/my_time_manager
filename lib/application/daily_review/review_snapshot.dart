// Authoritative input snapshot + fingerprints for Daily Review (Phase DR1).
import '../../domain/models/model_calendar_event.dart';
import '../../domain/models/model_habit.dart';
import '../../domain/models/model_habit_occurrence.dart';
import '../../domain/models/model_task.dart';
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/time_interval_repository.dart';

/// Everything the review / planner / applier read, loaded once from the
/// repositories (Q-DR1: computed on demand, nothing persisted).
class ReviewSnapshot {
  ReviewSnapshot({
    required List<TimeInterval> intervals,
    required List<Task> tasks,
    required List<CalendarEvent> events,
    List<Habit> habits = const [],
    Map<String, List<HabitOccurrence>> habitOccurrences = const {},
  })  : intervals = List.unmodifiable(intervals),
        tasks = List.unmodifiable(tasks),
        events = List.unmodifiable(events),
        habits = List.unmodifiable(habits),
        habitOccurrences = Map.unmodifiable(habitOccurrences),
        _tasksById = {for (final t in tasks) t.id: t};

  /// All persisted time intervals.
  final List<TimeInterval> intervals;

  /// VISIBLE tasks (repository already excludes trashed / archived).
  final List<Task> tasks;

  /// Visible calendar events (read-only for DR — never moved, DR-b).
  final List<CalendarEvent> events;

  /// Active habits (read-only for DR — never moved).
  final List<Habit> habits;

  /// Recorded occurrences per habit id (only the review window is loaded).
  final Map<String, List<HabitOccurrence>> habitOccurrences;

  final Map<String, Task> _tasksById;

  Task? taskOf(TimeInterval i) => i.taskId == null ? null : _tasksById[i.taskId];

  /// True when [i] belongs to live, unfinished work: an interval of a hidden
  /// (trashed / archived / missing) task, a completed task, or a completed
  /// subtask is NOT live.
  bool isLive(TimeInterval i) {
    if (i.taskId == null) return true;
    final t = _tasksById[i.taskId];
    if (t == null || t.isCompleted) return false;
    final sid = i.subtaskId;
    if (sid != null) {
      for (final s in t.subtasks) {
        if (s.id == sid) return !s.isCompleted;
      }
    }
    return true;
  }

  /// Load from the repositories. [habitsFrom]/[habitsTo] bound the occurrence
  /// rows loaded per habit; without a [habits] repository habits are empty.
  static Future<ReviewSnapshot> load({
    required TimeIntervalRepository timeIntervals,
    required TaskRepository tasks,
    required CalendarRepository calendar,
    HabitRepository? habits,
    DateTime? habitsFrom,
    DateTime? habitsTo,
  }) async {
    final results = await Future.wait<Object>([
      timeIntervals.getTimeIntervals(),
      tasks.getTasks(),
      calendar.getCalendarEvents(),
    ]);
    var habitList = <Habit>[];
    final occ = <String, List<HabitOccurrence>>{};
    if (habits != null) {
      habitList = await habits.getHabits();
      for (final h in habitList) {
        occ[h.id] =
            await habits.occurrencesOf(h.id, from: habitsFrom, to: habitsTo);
      }
    }
    return ReviewSnapshot(
      intervals: (results[0] as List).cast<TimeInterval>(),
      tasks: (results[1] as List).cast<Task>(),
      events: (results[2] as List).cast<CalendarEvent>(),
      habits: habitList,
      habitOccurrences: occ,
    );
  }
}

/// Fingerprint (version) of the AUTHORITATIVE fields of a time interval that a
/// proposal depends on (Q-DR2). Any edit to schedule, completion, progress,
/// ownership or the update stamp changes it, so the applier can reject stale
/// items. Deterministic across runs (FNV-1a 32-bit over a canonical string).
String intervalFingerprint(TimeInterval i) {
  final canonical = [
    i.id,
    i.taskId ?? '',
    i.subtaskId ?? '',
    i.isCompleted ? 1 : 0,
    i.isStartDateUndefined ? 1 : 0,
    i.isStartTimeUndefined ? 1 : 0,
    i.isEndDateUndefined ? 1 : 0,
    i.isEndTimeUndefined ? 1 : 0,
    i.calendarStartDateTime?.toIso8601String() ?? '',
    i.calendarEndDateTime?.toIso8601String() ?? '',
    i.howMuchHasBeenDone,
    i.updateTimeStamp.toIso8601String(),
  ].join('|');
  return fnv1a32(canonical);
}

/// FNV-1a 32-bit hash as 8 hex chars (web-safe: masked to 32 bits).
String fnv1a32(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    // hash * 0x01000193 == (hash << 24) + hash * 0x193, kept < 2^53.
    hash = (((hash << 24) & 0xffffffff) + hash * 0x193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
