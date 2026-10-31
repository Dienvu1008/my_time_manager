import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_milestone.dart';
import 'package:my_time_manager/domain/models/model_note.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/goal_repository.dart';
import 'package:my_time_manager/domain/repositories/note_repository.dart';
import 'package:my_time_manager/domain/repositories/project_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';

/// In-memory [GoalRepository] for widget tests. Mirrors the SQLite contract
/// (no cascade on trash/archive, SET NULL on milestone delete, link upsert per
/// (goal, type, entity) with milestone validation).
class FakeGoalRepository implements GoalRepository {
  final Map<String, Goal> goals = {};
  final Map<String, Milestone> milestones = {};
  final Map<String, GoalLink> links = {};

  // --- Goals ---
  @override
  Future<List<Goal>> getGoals() async {
    final list =
        goals.values.where((g) => !g.isDeleted && !g.isArchived).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<Goal?> getGoal(String id) async => goals[id];
  @override
  Future<void> createGoal(Goal goal) async => goals[goal.id] = goal;
  @override
  Future<void> updateGoal(Goal goal) async => goals[goal.id] = goal;

  @override
  Future<void> deleteGoal(String id) async {
    goals.remove(id);
    milestones.removeWhere((_, m) => m.goalId == id);
    links.removeWhere((_, l) => l.goalId == id);
  }

  Goal _flag(Goal g, {bool? deleted, bool? archived}) => Goal(
        id: g.id,
        title: g.title,
        description: g.description,
        color: g.color,
        status: g.status,
        targetDate: g.targetDate,
        createdAt: g.createdAt,
        updateTimeStamp: g.updateTimeStamp,
        isDeleted: deleted ?? g.isDeleted,
        deletedAt: (deleted ?? g.isDeleted) ? DateTime.now() : null,
        isArchived: archived ?? g.isArchived,
        archivedAt: (archived ?? g.isArchived) ? DateTime.now() : null,
      );

  @override
  Future<void> softDeleteGoal(String id) async =>
      goals[id] = _flag(goals[id]!, deleted: true);
  @override
  Future<void> restoreGoal(String id) async =>
      goals[id] = _flag(goals[id]!, deleted: false);
  @override
  Future<void> permanentlyDeleteGoal(String id) => deleteGoal(id);
  @override
  Future<void> archiveGoal(String id) async =>
      goals[id] = _flag(goals[id]!, archived: true);
  @override
  Future<void> unarchiveGoal(String id) async =>
      goals[id] = _flag(goals[id]!, archived: false);

  // --- Milestones ---
  @override
  Future<List<Milestone>> getMilestones(String goalId) async {
    final list = milestones.values.where((m) => m.goalId == goalId).toList();
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.title.compareTo(b.title);
    });
    return list;
  }

  @override
  Future<Milestone?> getMilestone(String id) async => milestones[id];
  @override
  Future<void> createMilestone(Milestone milestone) async =>
      milestones[milestone.id] = milestone;
  @override
  Future<void> updateMilestone(Milestone milestone) async =>
      milestones[milestone.id] = milestone;

  @override
  Future<void> deleteMilestone(String id) async {
    milestones.remove(id);
    for (final l in links.values.where((l) => l.milestoneId == id).toList()) {
      links[l.id] = _withMilestone(l, null);
    }
  }

  @override
  Future<void> setMilestoneCompleted(String id, bool completed) async {
    final m = milestones[id];
    if (m == null) return;
    milestones[id] = m.copyWith(
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
      clearCompletedAt: !completed,
      updateTimeStamp: DateTime.now(),
    );
  }

  @override
  Future<void> reorderMilestones(String goalId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final m = milestones[orderedIds[i]];
      if (m != null && m.goalId == goalId) {
        milestones[m.id] = m.copyWith(sortOrder: i);
      }
    }
  }

  // --- Links ---
  GoalLink _withMilestone(GoalLink l, String? milestoneId) => GoalLink(
        id: l.id,
        goalId: l.goalId,
        milestoneId: milestoneId,
        entityType: l.entityType,
        entityId: l.entityId,
        createdAt: l.createdAt,
      );

  List<GoalLink> _sorted(Iterable<GoalLink> it) =>
      it.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<GoalLink>> getLinks(String goalId) async =>
      _sorted(links.values.where((l) => l.goalId == goalId));

  @override
  Future<List<GoalLink>> getLinksForEntity(
          String entityType, String entityId) async =>
      _sorted(links.values.where(
          (l) => l.entityType == entityType && l.entityId == entityId));

  Future<GoalLink> _link(String goalId, String entityType, String entityId,
      String? milestoneId) async {
    if (milestoneId != null) {
      final m = milestones[milestoneId];
      if (m == null || m.goalId != goalId) {
        throw ArgumentError.value(milestoneId, 'milestoneId',
            'Milestone does not belong to goal $goalId');
      }
    }
    for (final l in links.values) {
      if (l.goalId == goalId &&
          l.entityType == entityType &&
          l.entityId == entityId) {
        return links[l.id] = _withMilestone(l, milestoneId);
      }
    }
    final link = GoalLink(
      goalId: goalId,
      milestoneId: milestoneId,
      entityType: entityType,
      entityId: entityId,
    );
    return links[link.id] = link;
  }

  void _unlinkEntity(String goalId, String entityType, String entityId) =>
      links.removeWhere((_, l) =>
          l.goalId == goalId &&
          l.entityType == entityType &&
          l.entityId == entityId);

  @override
  Future<GoalLink> linkTask(String goalId, String taskId,
          {String? milestoneId}) =>
      _link(goalId, GoalEntityType.task, taskId, milestoneId);

  @override
  Future<GoalLink> linkCourse(String goalId, String courseId,
          {String? milestoneId}) =>
      _link(goalId, GoalEntityType.course, courseId, milestoneId);

  @override
  Future<void> unlink(String linkId) async => links.remove(linkId);

  @override
  Future<void> unlinkTask(String goalId, String taskId) async =>
      _unlinkEntity(goalId, GoalEntityType.task, taskId);

  @override
  Future<void> unlinkCourse(String goalId, String courseId) async =>
      _unlinkEntity(goalId, GoalEntityType.course, courseId);
}

/// In-memory [ProjectRepository] for widget tests (upsert per
/// (project, type, entity); no cascade on trash/archive).
class FakeProjectRepository implements ProjectRepository {
  final Map<String, Project> projects = {};
  final Map<String, ProjectItem> items = {};

  @override
  Future<List<Project>> getProjects() async {
    final list =
        projects.values.where((p) => !p.isDeleted && !p.isArchived).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<Project?> getProject(String id) async => projects[id];
  @override
  Future<void> createProject(Project project) async =>
      projects[project.id] = project;
  @override
  Future<void> updateProject(Project project) async =>
      projects[project.id] = project;

  @override
  Future<void> deleteProject(String id) async {
    projects.remove(id);
    items.removeWhere((_, i) => i.projectId == id);
  }

  Project _flag(Project p, {bool? deleted, bool? archived}) => Project(
        id: p.id,
        title: p.title,
        description: p.description,
        color: p.color,
        status: p.status,
        startDate: p.startDate,
        targetDate: p.targetDate,
        createdAt: p.createdAt,
        updateTimeStamp: p.updateTimeStamp,
        isDeleted: deleted ?? p.isDeleted,
        deletedAt: (deleted ?? p.isDeleted) ? DateTime.now() : null,
        isArchived: archived ?? p.isArchived,
        archivedAt: (archived ?? p.isArchived) ? DateTime.now() : null,
      );

  @override
  Future<void> softDeleteProject(String id) async =>
      projects[id] = _flag(projects[id]!, deleted: true);
  @override
  Future<void> restoreProject(String id) async =>
      projects[id] = _flag(projects[id]!, deleted: false);
  @override
  Future<void> permanentlyDeleteProject(String id) => deleteProject(id);
  @override
  Future<void> archiveProject(String id) async =>
      projects[id] = _flag(projects[id]!, archived: true);
  @override
  Future<void> unarchiveProject(String id) async =>
      projects[id] = _flag(projects[id]!, archived: false);

  List<ProjectItem> _sorted(Iterable<ProjectItem> it) => it.toList()
    ..sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });

  @override
  Future<List<ProjectItem>> getItems(String projectId) async =>
      _sorted(items.values.where((i) => i.projectId == projectId));

  @override
  Future<List<ProjectItem>> getItemsForEntity(
          String entityType, String entityId) async =>
      _sorted(items.values.where(
          (i) => i.entityType == entityType && i.entityId == entityId));

  @override
  Future<ProjectItem> addItem(
      String projectId, String entityType, String entityId,
      {int? sortOrder}) async {
    if (!projects.containsKey(projectId)) {
      throw ArgumentError.value(projectId, 'projectId');
    }
    if (entityType.isEmpty) {
      throw ArgumentError.value(entityType, 'entityType');
    }
    for (final i in items.values) {
      if (i.projectId == projectId &&
          i.entityType == entityType &&
          i.entityId == entityId) {
        return sortOrder == null
            ? i
            : items[i.id] = i.copyWith(sortOrder: sortOrder);
      }
    }
    final item = ProjectItem(
      projectId: projectId,
      entityType: entityType,
      entityId: entityId,
      sortOrder: sortOrder ?? 0,
    );
    return items[item.id] = item;
  }

  @override
  Future<void> removeItem(String itemId) async => items.remove(itemId);

  @override
  Future<void> removeEntity(
          String projectId, String entityType, String entityId) async =>
      items.removeWhere((_, i) =>
          i.projectId == projectId &&
          i.entityType == entityType &&
          i.entityId == entityId);
}

/// [getTaskLists] returns [visible]; other members are unsupported.
class FakeTaskListRepository implements TaskListRepository {
  final List<TaskList> visible = [];

  @override
  Future<List<TaskList>> getTaskLists() async => List.of(visible);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [getTasks] returns [visible]; other members are unsupported.
class FakeTaskRepository implements TaskRepository {
  final List<Task> visible = [];

  @override
  Future<List<Task>> getTasks() async => List.of(visible);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [getNotes] returns [visible]; other members are unsupported.
class FakeNoteRepository implements NoteRepository {
  final List<Note> visible = [];

  @override
  Future<List<Note>> getNotes() async => List.of(visible);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [getCalendarEvents] returns [visible]; other members are unsupported.
class FakeCalendarRepository implements CalendarRepository {
  final List<CalendarEvent> visible = [];

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async => List.of(visible);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
