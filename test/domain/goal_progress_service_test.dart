import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_milestone.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/goal_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/services/goal_progress_service.dart';

/// In-memory fake of [GoalRepository] (only the read members used by
/// [GoalProgressService] are meaningful).
class _FakeGoalRepository implements GoalRepository {
  final Map<String, Goal> goals = {};
  final List<Milestone> milestones = [];
  final List<GoalLink> links = [];

  @override
  Future<Goal?> getGoal(String id) async => goals[id];
  @override
  Future<List<Milestone>> getMilestones(String goalId) async =>
      milestones.where((m) => m.goalId == goalId).toList();
  @override
  Future<Milestone?> getMilestone(String id) async {
    for (final m in milestones) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Future<List<GoalLink>> getLinks(String goalId) async =>
      links.where((l) => l.goalId == goalId).toList();

  // --- Unused by these tests ---
  @override
  Future<List<Goal>> getGoals() async => goals.values.toList();
  @override
  Future<void> createGoal(Goal goal) async {}
  @override
  Future<void> updateGoal(Goal goal) async {}
  @override
  Future<void> deleteGoal(String id) async {}
  @override
  Future<void> softDeleteGoal(String id) async {}
  @override
  Future<void> restoreGoal(String id) async {}
  @override
  Future<void> permanentlyDeleteGoal(String id) async {}
  @override
  Future<void> archiveGoal(String id) async {}
  @override
  Future<void> unarchiveGoal(String id) async {}
  @override
  Future<void> createMilestone(Milestone milestone) async {}
  @override
  Future<void> updateMilestone(Milestone milestone) async {}
  @override
  Future<void> deleteMilestone(String id) async {}
  @override
  Future<void> setMilestoneCompleted(String id, bool completed) async {}
  @override
  Future<void> reorderMilestones(String goalId, List<String> orderedIds) async {}
  @override
  Future<List<GoalLink>> getLinksForEntity(
          String entityType, String entityId) async =>
      const [];
  @override
  Future<GoalLink> linkTask(String goalId, String taskId,
          {String? milestoneId}) =>
      throw UnimplementedError();
  @override
  Future<void> unlink(String linkId) async {}
  @override
  Future<void> unlinkTask(String goalId, String taskId) async {}
  @override
  Future<GoalLink> linkCourse(String goalId, String courseId,
          {String? milestoneId}) =>
      throw UnimplementedError();
  @override
  Future<void> unlinkCourse(String goalId, String courseId) async {}
  @override
  Future<GoalLink> linkHabit(String goalId, String habitId) =>
      throw UnimplementedError();
  @override
  Future<void> unlinkHabit(String goalId, String habitId) async {}
}

/// Fake [TaskRepository]: [getTasks] returns the "visible" (live) tasks.
class _FakeTaskRepository implements TaskRepository {
  final List<Task> visible = [];

  @override
  Future<List<Task>> getTasks() async => visible;

  // --- Unused by these tests ---
  @override
  Future<void> updateTask(Task task) async {}
  @override
  Future<void> createTask(Task task) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<Task> getTask(String id) => throw UnimplementedError();
  @override
  Future<List<Task>> getTasksOfTaskList(String taskListId) async => const [];
  @override
  Future<List<Task>> getTasksWithoutTaskList() async => const [];
  @override
  Future<void> moveTask(String taskId, String? newTaskListId) async {}
  @override
  Future<void> softDeleteTask(String id) async {}
  @override
  Future<void> restoreTask(String id) async {}
  @override
  Future<void> permanentlyDeleteTask(String id) async {}
  @override
  Future<void> archiveTask(String id) async {}
  @override
  Future<void> unarchiveTask(String id) async {}
}

GoalLink _taskLink(String goalId, String taskId, {String? milestoneId}) =>
    GoalLink(
      goalId: goalId,
      milestoneId: milestoneId,
      entityType: GoalEntityType.task,
      entityId: taskId,
    );

void main() {
  group('computeMilestone', () {
    final m = Milestone(id: 'm', goalId: 'g', title: 'M');

    test('completed flag → 1.0 even with 0 or incomplete tasks', () {
      final done = m.copyWith(isCompleted: true);
      expect(GoalProgressService.computeMilestone(done, const [], const {})
          .ratio, 1.0);
      final p = GoalProgressService.computeMilestone(
          done, [_taskLink('g', 't1', milestoneId: 'm')], {'t1': false});
      expect(p.ratio, 1.0);
      expect(p.isDone, isTrue);
      expect(p.completedTasks, 0);
      expect(p.totalTasks, 1);
    });

    test('0 live tasks → 0.0, not done', () {
      final p = GoalProgressService.computeMilestone(m, const [], const {});
      expect(p.ratio, 0.0);
      expect(p.isDone, isFalse);
    });

    test('1 of 3 completed → 1/3', () {
      final links = [
        for (final id in ['a', 'b', 'c']) _taskLink('g', id, milestoneId: 'm'),
      ];
      final p = GoalProgressService.computeMilestone(
          m, links, {'a': true, 'b': false, 'c': false});
      expect(p.ratio, closeTo(1 / 3, 1e-9));
      expect(p.completedTasks, 1);
      expect(p.totalTasks, 3);
    });

    test('links to missing/trashed/archived tasks are ignored', () {
      final links = [
        _taskLink('g', 'live', milestoneId: 'm'),
        _taskLink('g', 'gone', milestoneId: 'm'),
      ];
      final p = GoalProgressService.computeMilestone(m, links, {'live': true});
      expect(p.totalTasks, 1);
      expect(p.ratio, 1.0);
      expect(p.isDone, isTrue);
    });

    test('duplicate links counted once', () {
      final links = [
        _taskLink('g', 'a', milestoneId: 'm'),
        _taskLink('g', 'a', milestoneId: 'm'),
        _taskLink('g', 'b', milestoneId: 'm'),
      ];
      final p =
          GoalProgressService.computeMilestone(m, links, {'a': true, 'b': false});
      expect(p.totalTasks, 2);
      expect(p.ratio, 0.5);
    });

    test('non-task entityType is ignored', () {
      final links = [
        GoalLink(goalId: 'g', milestoneId: 'm', entityType: 'habit',
            entityId: 'a'),
        _taskLink('g', 'b', milestoneId: 'm'),
      ];
      final p =
          GoalProgressService.computeMilestone(m, links, {'a': false, 'b': true});
      expect(p.totalTasks, 1);
      expect(p.ratio, 1.0);
    });

    test('links of other milestones / direct links are not counted', () {
      final links = [
        _taskLink('g', 'a', milestoneId: 'other'),
        _taskLink('g', 'b'),
      ];
      final p =
          GoalProgressService.computeMilestone(m, links, {'a': true, 'b': true});
      expect(p.totalTasks, 0);
      expect(p.ratio, 0.0);
    });

    test('all live tasks completed → done without the flag', () {
      final links = [
        _taskLink('g', 'a', milestoneId: 'm'),
        _taskLink('g', 'b', milestoneId: 'm'),
      ];
      final p =
          GoalProgressService.computeMilestone(m, links, {'a': true, 'b': true});
      expect(p.isDone, isTrue);
      expect(m.isCompleted, isFalse);
    });
  });

  group('computeGoal', () {
    final m1 = Milestone(id: 'm1', goalId: 'g', title: 'M1', isCompleted: true);
    final m2 = Milestone(id: 'm2', goalId: 'g', title: 'M2');

    test('1 of 2 milestones done → 0.5; direct links do not change it', () {
      final links = [
        _taskLink('g', 'x', milestoneId: 'm2'),
        _taskLink('g', 'd1'),
        _taskLink('g', 'd2'),
      ];
      final p = GoalProgressService.computeGoal(Goal(id: 'g', title: 'G'),
          [m1, m2], links, {'x': false, 'd1': true, 'd2': true});
      expect(p.ratio, 0.5);
      expect(p.doneMilestones, 1);
      expect(p.totalMilestones, 2);
      expect(p.directCompletedTasks, 2);
      expect(p.directTotalTasks, 2);
      expect(p.milestones.map((e) => e.milestoneId), ['m1', 'm2']);
    });

    test('no milestones → direct-link fallback 2/4 = 0.5', () {
      final links = [
        for (final id in ['a', 'b', 'c', 'd']) _taskLink('g', id),
      ];
      final p = GoalProgressService.computeGoal(Goal(id: 'g', title: 'G'),
          const [], links, {'a': true, 'b': true, 'c': false, 'd': false});
      expect(p.ratio, 0.5);
      expect(p.totalMilestones, 0);
    });

    test('no milestones and no live links → 0.0', () {
      final p = GoalProgressService.computeGoal(Goal(id: 'g', title: 'G'),
          const [], [_taskLink('g', 'gone')], const {});
      expect(p.ratio, 0.0);
      expect(p.directTotalTasks, 0);
    });

    test('status completed → 1.0', () {
      final p = GoalProgressService.computeGoal(
          Goal(id: 'g', title: 'G', status: GoalStatus.completed),
          [m2],
          const [],
          const {});
      expect(p.ratio, 1.0);
      expect(p.doneMilestones, 0);
    });

    test('paused / abandoned are computed normally', () {
      for (final s in [GoalStatus.paused, GoalStatus.abandoned]) {
        final p = GoalProgressService.computeGoal(
            Goal(id: 'g', title: 'G', status: s), [m1, m2], const [], const {});
        expect(p.ratio, 0.5, reason: s.name);
      }
    });
  });

  group('service (through repositories)', () {
    late _FakeGoalRepository goals;
    late _FakeTaskRepository tasks;
    late GoalProgressService service;

    setUp(() {
      goals = _FakeGoalRepository();
      tasks = _FakeTaskRepository();
      service = GoalProgressService(goals, tasks);
    });

    test('progressOf unknown goal → null', () async {
      expect(await service.progressOf('nope'), isNull);
      expect(await service.milestoneProgressOf('nope'), isNull);
    });

    test('progressOf end-to-end uses visible tasks as the live set',
        () async {
      final g = Goal(id: 'g', title: 'G');
      goals.goals[g.id] = g;
      final m1 = Milestone(id: 'm1', goalId: 'g', title: 'M1');
      final m2 = Milestone(id: 'm2', goalId: 'g', title: 'M2');
      goals.milestones.addAll([m1, m2]);
      final done = Task(id: 't1', title: 'done', isCompleted: true);
      final open = Task(id: 't2', title: 'open', isCompleted: false);
      tasks.visible.addAll([done, open]);
      goals.links.addAll([
        _taskLink('g', 't1', milestoneId: 'm1'),
        _taskLink('g', 'trashed', milestoneId: 'm1'), // not visible → ignored
        _taskLink('g', 't2', milestoneId: 'm2'),
      ]);

      final p = (await service.progressOf('g'))!;
      expect(p.goalId, 'g');
      expect(p.ratio, 0.5);
      expect(p.milestones[0].isDone, isTrue);
      expect(p.milestones[0].totalTasks, 1);
      expect(p.milestones[1].ratio, 0.0);

      final mp = (await service.milestoneProgressOf('m2'))!;
      expect(mp.milestoneId, 'm2');
      expect(mp.totalTasks, 1);
      expect(mp.completedTasks, 0);
    });

    test('course links (C7) do not count toward goal progress', () async {
      final g = Goal(id: 'g', title: 'G');
      final only = Goal(id: 'only', title: 'Only course');
      goals.goals.addAll({g.id: g, only.id: only});
      tasks.visible.add(Task(id: 't1', title: 'done', isCompleted: true));
      GoalLink courseLink(String goalId) => GoalLink(
          goalId: goalId,
          entityType: GoalEntityType.course,
          entityId: 'course1');
      goals.links.addAll([
        _taskLink('g', 't1'),
        courseLink('g'),
        courseLink('only'),
      ]);

      final p = (await service.progressOf('g'))!;
      expect(p.ratio, 1.0);
      expect(p.directTotalTasks, 1);
      expect(p.directCompletedTasks, 1);

      final o = (await service.progressOf('only'))!;
      expect(o.ratio, 0.0);
      expect(o.directTotalTasks, 0);
    });
  });
}
