import '../models/model_habit.dart';
import '../models/model_habit_occurrence.dart';

/// Domain boundary for **habits** and their recorded occurrences (Phase H1).
///
/// A habit and its occurrences form one aggregate. Only USER-RECORDED
/// outcomes are stored; unrecorded scheduled days are derived at read time by
/// `HabitStatisticsService` (nothing is written in the background).
///
/// There is no trash for habits: [archiveHabit] is the default removal (keeps
/// history, stops future scheduling); [deleteHabitPermanently] is a separate,
/// explicit hard delete that cascades occurrences (FK) and removes goal links /
/// project items pointing at the habit (triggers).
abstract class HabitRepository {
  /// Active (non-archived) habits, oldest first.
  Future<List<Habit>> getHabits();

  /// Archived habits, most recently archived first.
  Future<List<Habit>> getArchivedHabits();

  /// A single habit by id (any state), or null.
  Future<Habit?> getHabit(String id);

  Future<void> createHabit(Habit habit);

  /// Update a habit's definition. Changing the recurrence NEVER rewrites
  /// recorded occurrences.
  Future<void> updateHabit(Habit habit);

  Future<void> archiveHabit(String id);

  Future<void> unarchiveHabit(String id);

  /// Explicit hard delete: removes the habit, all its occurrences, and goal
  /// links / project items referencing it. Irreversible.
  Future<void> deleteHabitPermanently(String id);

  // --- Occurrences ---

  /// Record (upsert) the outcome of [habitId] on the local day [localDate].
  /// Update-first-then-insert (never REPLACE); stamps `recordedAt = now`.
  /// Throws [ArgumentError] if the habit does not exist.
  Future<HabitOccurrence> recordOutcome(
    String habitId,
    DateTime localDate,
    HabitOutcome outcome, {
    double? amount,
    String? note,
  });

  /// Remove the recorded outcome of [habitId] on [localDate] (the day becomes
  /// derived again). No-op when nothing is recorded.
  Future<void> clearOutcome(String habitId, DateTime localDate);

  /// The recorded occurrence of [habitId] on [localDate], or null.
  Future<HabitOccurrence?> getOccurrence(String habitId, DateTime localDate);

  /// Recorded occurrences of [habitId], oldest day first, optionally limited
  /// to local days in `[from, to]` (inclusive).
  Future<List<HabitOccurrence>> occurrencesOf(String habitId,
      {DateTime? from, DateTime? to});
}
