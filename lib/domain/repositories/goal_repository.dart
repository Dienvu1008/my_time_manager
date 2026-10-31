import '../models/model_goal.dart';
import '../models/model_goal_link.dart';
import '../models/model_milestone.dart';

/// Domain boundary for **goals** and their milestones and links (Core Track C5).
///
/// A goal, its milestones and its links form one aggregate. There is no
/// separate "Plan" entity: a goal's plan = its milestones + linked items.
///
/// Callers (UI, blocs, controllers, and — in the future — AI tools) depend on
/// this interface, never on [DatabaseManager] / SQLite directly. Implementations
/// live in `lib/data/repositories/`.
///
/// Trash and archive of a goal do NOT cascade to milestones/links (those are
/// only reachable through their goal). Hard delete cascades via FK.
abstract class GoalRepository {
  /// All visible goals (excludes trashed and archived), oldest first.
  Future<List<Goal>> getGoals();

  /// A single goal by id (any state), or null if it does not exist.
  Future<Goal?> getGoal(String id);

  /// Create a new goal.
  Future<void> createGoal(Goal goal);

  /// Update an existing goal.
  Future<void> updateGoal(Goal goal);

  /// Hard-delete a goal (cascades to milestones and links). Prefer
  /// [softDeleteGoal] for user-facing deletes.
  Future<void> deleteGoal(String id);

  // --- Trash (soft-delete) ---

  /// Move a goal to trash (milestones/links are kept untouched).
  Future<void> softDeleteGoal(String id);

  /// Restore a goal from trash.
  Future<void> restoreGoal(String id);

  /// Permanently delete a goal (cascades to milestones and links).
  Future<void> permanentlyDeleteGoal(String id);

  // --- Archive ---

  /// Archive a goal (milestones/links are kept untouched).
  Future<void> archiveGoal(String id);

  /// Unarchive a goal.
  Future<void> unarchiveGoal(String id);

  // --- Milestones ---

  /// Milestones of a goal, ordered by sortOrder then title.
  Future<List<Milestone>> getMilestones(String goalId);

  /// A single milestone by id, or null if it does not exist.
  Future<Milestone?> getMilestone(String id);

  /// Create a milestone.
  Future<void> createMilestone(Milestone milestone);

  /// Update a milestone.
  Future<void> updateMilestone(Milestone milestone);

  /// Delete a milestone. Links pointing to it become direct goal links
  /// (milestoneId set to null).
  Future<void> deleteMilestone(String id);

  /// Set/clear the milestone's manual completed flag (stamps completedAt).
  Future<void> setMilestoneCompleted(String id, bool completed);

  /// Reorder the milestones of a goal: sets sortOrder = index in
  /// [orderedIds], in a single transaction. Ids that do not belong to
  /// [goalId] are ignored.
  Future<void> reorderMilestones(String goalId, List<String> orderedIds);

  // --- Links ---

  /// All links of a goal.
  Future<List<GoalLink>> getLinks(String goalId);

  /// All links of a given entity (e.g. which goals a task serves).
  Future<List<GoalLink>> getLinksForEntity(String entityType, String entityId);

  /// Link a task to a goal, optionally under one of its milestones. Upsert: a
  /// task has at most one link per goal; calling again moves it to
  /// [milestoneId]. Throws [ArgumentError] if [milestoneId] does not belong to
  /// [goalId].
  Future<GoalLink> linkTask(String goalId, String taskId, {String? milestoneId});

  /// Remove a link by id.
  Future<void> unlink(String linkId);

  /// Remove the link between a goal and a task.
  Future<void> unlinkTask(String goalId, String taskId);

  /// Link a course (Core Track C7) to a goal, optionally under one of its
  /// milestones. Same upsert / validation rules as [linkTask]. Course progress
  /// does NOT count toward goal progress (GoalProgressService only counts task
  /// links); the link is informational.
  Future<GoalLink> linkCourse(String goalId, String courseId,
      {String? milestoneId});

  /// Remove the link between a goal and a course.
  Future<void> unlinkCourse(String goalId, String courseId);

  /// Link a habit (Phase H3) directly to a goal (`goal_links` entityType
  /// `'habit'`, no milestone). Upsert per (goal, habit). Habit links are
  /// informational: they do NOT count toward goal progress
  /// (GoalProgressService only counts task links).
  Future<GoalLink> linkHabit(String goalId, String habitId);

  /// Remove the link between a goal and a habit.
  Future<void> unlinkHabit(String goalId, String habitId);
}
