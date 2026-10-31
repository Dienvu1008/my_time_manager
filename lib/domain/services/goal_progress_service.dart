import '../models/model_goal.dart';
import '../models/model_goal_link.dart';
import '../models/model_milestone.dart';
import '../repositories/goal_repository.dart';
import '../repositories/task_repository.dart';

/// Derived progress of one milestone.
class MilestoneProgress {
  const MilestoneProgress({
    required this.milestoneId,
    required this.ratio,
    required this.completedTasks,
    required this.totalTasks,
    required this.isDone,
  });

  final String milestoneId;

  /// 0.0 … 1.0.
  final double ratio;

  /// Live linked tasks that are completed.
  final int completedTasks;

  /// Live linked tasks (missing / trashed / archived tasks excluded).
  final int totalTasks;

  /// True iff [ratio] == 1.0.
  final bool isDone;
}

/// Derived progress of one goal.
class GoalProgress {
  const GoalProgress({
    required this.goalId,
    required this.ratio,
    required this.doneMilestones,
    required this.totalMilestones,
    required this.directCompletedTasks,
    required this.directTotalTasks,
    required this.milestones,
  });

  final String goalId;

  /// 0.0 … 1.0.
  final double ratio;
  final int doneMilestones;
  final int totalMilestones;

  /// Live tasks linked directly to the goal (milestoneId == null).
  final int directCompletedTasks;
  final int directTotalTasks;

  /// Per-milestone breakdown, in the order the milestones were given.
  final List<MilestoneProgress> milestones;
}

/// Pure, deterministic progress rules for goals and milestones (Core Track C5).
/// Progress is always DERIVED — never stored, no manual override:
///
///     UI / AI Tool → GoalProgressService → GoalRepository / TaskRepository
///
/// "Live" task = a task linked with `entityType == 'task'` that is present in
/// [TaskRepository.getTasks] (exists, not trashed, not archived). Links to
/// missing / trashed / archived tasks are ignored entirely (neither numerator
/// nor denominator); duplicate entity ids count once; other entity types are
/// ignored.
///
/// Milestone:
/// - `isCompleted` flag set → 1.0 (flag wins regardless of tasks);
/// - else 0 live linked tasks → 0.0;
/// - else completed live / total live.
/// A milestone is *done* iff its ratio == 1.0. The service never writes
/// `isCompleted`.
///
/// Goal:
/// - `status == completed` → 1.0 (explicit terminal state);
/// - else ≥1 milestone → done milestones / total milestones (direct links are
///   reported but do not affect the ratio);
/// - else (no milestones) → completed live direct-linked tasks / live
///   direct-linked tasks, 0 live → 0.0.
class GoalProgressService {
  GoalProgressService(this._goals, this._tasks);

  final GoalRepository _goals;
  final TaskRepository _tasks;

  /// Progress of a goal, or null if the goal does not exist.
  Future<GoalProgress?> progressOf(String goalId) async {
    final goal = await _goals.getGoal(goalId);
    if (goal == null) return null;
    final milestones = await _goals.getMilestones(goalId);
    final links = await _goals.getLinks(goalId);
    return computeGoal(goal, milestones, links, await _liveTaskCompletion());
  }

  /// Progress of a milestone, or null if the milestone does not exist.
  Future<MilestoneProgress?> milestoneProgressOf(String milestoneId) async {
    final milestone = await _goals.getMilestone(milestoneId);
    if (milestone == null) return null;
    final links = await _goals.getLinks(milestone.goalId);
    return computeMilestone(milestone, links, await _liveTaskCompletion());
  }

  Future<Map<String, bool>> _liveTaskCompletion() async {
    final tasks = await _tasks.getTasks();
    return {for (final t in tasks) t.id: t.isCompleted};
  }

  /// Milestone rule. Only [links] whose milestoneId == [m.id] are considered.
  /// [liveTaskCompletion] maps live task id → isCompleted; ids absent from the
  /// map are treated as missing/trashed/archived and ignored.
  static MilestoneProgress computeMilestone(Milestone m,
      Iterable<GoalLink> links, Map<String, bool> liveTaskCompletion) {
    final (completed, total) = _countLive(
        links.where((l) => l.milestoneId == m.id), liveTaskCompletion);
    final double ratio;
    if (m.isCompleted) {
      ratio = 1.0;
    } else if (total == 0) {
      ratio = 0.0;
    } else {
      ratio = completed / total;
    }
    return MilestoneProgress(
      milestoneId: m.id,
      ratio: ratio,
      completedTasks: completed,
      totalTasks: total,
      isDone: ratio == 1.0,
    );
  }

  /// Goal rule (see class doc).
  static GoalProgress computeGoal(Goal goal, List<Milestone> milestones,
      List<GoalLink> links, Map<String, bool> liveTaskCompletion) {
    final perMilestone = [
      for (final m in milestones)
        computeMilestone(m, links, liveTaskCompletion),
    ];
    final done = perMilestone.where((p) => p.isDone).length;
    final (directCompleted, directTotal) = _countLive(
        links.where((l) => l.milestoneId == null), liveTaskCompletion);

    final double ratio;
    if (goal.status == GoalStatus.completed) {
      ratio = 1.0;
    } else if (milestones.isNotEmpty) {
      ratio = done / milestones.length;
    } else if (directTotal == 0) {
      ratio = 0.0;
    } else {
      ratio = directCompleted / directTotal;
    }
    return GoalProgress(
      goalId: goal.id,
      ratio: ratio,
      doneMilestones: done,
      totalMilestones: milestones.length,
      directCompletedTasks: directCompleted,
      directTotalTasks: directTotal,
      milestones: perMilestone,
    );
  }

  /// (completed, total) over live, de-duplicated task links.
  static (int, int) _countLive(
      Iterable<GoalLink> links, Map<String, bool> liveTaskCompletion) {
    final ids = <String>{
      for (final l in links)
        if (l.entityType == GoalEntityType.task &&
            liveTaskCompletion.containsKey(l.entityId))
          l.entityId,
    };
    final completed = ids.where((id) => liveTaskCompletion[id] == true).length;
    return (completed, ids.length);
  }
}
