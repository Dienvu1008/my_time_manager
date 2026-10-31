import '../../domain/models/model_goal.dart';
import '../../domain/models/model_goal_link.dart';
import '../../domain/models/model_milestone.dart';
import '../../domain/repositories/goal_repository.dart';
import '../database/daos/goal_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [GoalRepository] (Core Track C5) over [GoalDao].
class SqliteGoalRepository implements GoalRepository {
  SqliteGoalRepository({DatabaseManager? databaseManager})
      : _dao = GoalDao(() => (databaseManager ?? DatabaseManager()).database);

  final GoalDao _dao;

  @override
  Future<List<Goal>> getGoals() => _dao.getAll();

  @override
  Future<Goal?> getGoal(String id) => _dao.getById(id);

  @override
  Future<void> createGoal(Goal goal) => _dao.insert(goal);

  @override
  Future<void> updateGoal(Goal goal) => _dao.update(goal);

  @override
  Future<void> deleteGoal(String id) => _dao.delete(id);

  @override
  Future<void> softDeleteGoal(String id) => _dao.softDelete(id);

  @override
  Future<void> restoreGoal(String id) => _dao.restore(id);

  @override
  Future<void> permanentlyDeleteGoal(String id) => _dao.permanentlyDelete(id);

  @override
  Future<void> archiveGoal(String id) => _dao.archive(id);

  @override
  Future<void> unarchiveGoal(String id) => _dao.unarchive(id);

  @override
  Future<List<Milestone>> getMilestones(String goalId) =>
      _dao.milestonesOf(goalId);

  @override
  Future<Milestone?> getMilestone(String id) => _dao.getMilestone(id);

  @override
  Future<void> createMilestone(Milestone milestone) =>
      _dao.insertMilestone(milestone);

  @override
  Future<void> updateMilestone(Milestone milestone) =>
      _dao.updateMilestone(milestone);

  @override
  Future<void> deleteMilestone(String id) => _dao.deleteMilestone(id);

  @override
  Future<void> setMilestoneCompleted(String id, bool completed) =>
      _dao.setMilestoneCompleted(id, completed);

  @override
  Future<void> reorderMilestones(String goalId, List<String> orderedIds) =>
      _dao.reorderMilestones(goalId, orderedIds);

  @override
  Future<List<GoalLink>> getLinks(String goalId) => _dao.linksOf(goalId);

  @override
  Future<List<GoalLink>> getLinksForEntity(
          String entityType, String entityId) =>
      _dao.linksOfEntity(entityType, entityId);

  @override
  Future<GoalLink> linkTask(String goalId, String taskId,
          {String? milestoneId}) =>
      _linkEntity(goalId, GoalEntityType.task, taskId, milestoneId);

  @override
  Future<GoalLink> linkCourse(String goalId, String courseId,
          {String? milestoneId}) =>
      _linkEntity(goalId, GoalEntityType.course, courseId, milestoneId);

  Future<GoalLink> _linkEntity(String goalId, String entityType,
      String entityId, String? milestoneId) async {
    if (milestoneId != null) {
      final milestone = await _dao.getMilestone(milestoneId);
      if (milestone == null || milestone.goalId != goalId) {
        throw ArgumentError.value(milestoneId, 'milestoneId',
            'Milestone does not belong to goal $goalId');
      }
    }
    return _dao.link(
      goalId: goalId,
      entityType: entityType,
      entityId: entityId,
      milestoneId: milestoneId,
    );
  }

  @override
  Future<void> unlink(String linkId) => _dao.unlink(linkId);

  @override
  Future<void> unlinkTask(String goalId, String taskId) =>
      _dao.unlinkEntity(goalId, GoalEntityType.task, taskId);

  @override
  Future<void> unlinkCourse(String goalId, String courseId) =>
      _dao.unlinkEntity(goalId, GoalEntityType.course, courseId);
}
