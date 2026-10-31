import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';
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
import 'package:my_time_manager/domain/repositories/learning_repository.dart';
import 'package:my_time_manager/domain/repositories/note_repository.dart';
import 'package:my_time_manager/domain/repositories/project_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/services/goal_progress_service.dart';
import 'package:my_time_manager/domain/services/learning_progress_service.dart';
import 'package:my_time_manager/domain/services/project_workspace_service.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';

import '../shared/fake_repositories.dart' show FakeHabitRepository;

// In-memory fakes: only the read members used by ProjectWorkspaceService /
// GoalProgressService are meaningful; everything else falls to noSuchMethod.

class _FakeProjects implements ProjectRepository {
  final Map<String, Project> projects = {};
  final List<ProjectItem> items = [];

  @override
  Future<Project?> getProject(String id) async => projects[id];
  @override
  Future<List<ProjectItem>> getItems(String projectId) async {
    final list = items.where((i) => i.projectId == projectId).toList();
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTaskLists implements TaskListRepository {
  final List<TaskList> visible = [];
  @override
  Future<List<TaskList>> getTaskLists() async => visible;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTasks implements TaskRepository {
  final List<Task> visible = [];
  @override
  Future<List<Task>> getTasks() async => visible;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotes implements NoteRepository {
  final List<Note> visible = [];
  @override
  Future<List<Note>> getNotes() async => visible;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCalendar implements CalendarRepository {
  final List<CalendarEvent> visible = [];
  @override
  Future<List<CalendarEvent>> getCalendarEvents() async => visible;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [all] = every goal (any state); [visible] ids = live goals.
class _FakeGoals implements GoalRepository {
  final Map<String, Goal> all = {};
  final Set<String> hidden = {};
  final List<GoalLink> links = [];

  @override
  Future<List<Goal>> getGoals() async =>
      all.values.where((g) => !hidden.contains(g.id)).toList();
  @override
  Future<Goal?> getGoal(String id) async => all[id];
  @override
  Future<List<Milestone>> getMilestones(String goalId) async => const [];
  @override
  Future<List<GoalLink>> getLinks(String goalId) async =>
      links.where((l) => l.goalId == goalId).toList();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [all] = every course (any state); [hidden] ids = trashed / archived.
class _FakeLearning implements LearningRepository {
  final Map<String, Course> all = {};
  final Set<String> hidden = {};

  @override
  Future<List<Course>> getCourses() async =>
      all.values.where((c) => !hidden.contains(c.id)).toList();
  @override
  Future<Course?> getCourse(String id) async => all[id];
  @override
  Future<List<CourseModule>> getModules(String courseId) async => const [];
  @override
  Future<List<Lesson>> getLessonsOfCourse(String courseId) async => const [];
  @override
  Future<List<LessonProgress>> getProgressForCourse(String courseId) async =>
      const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeProjects projects;
  late _FakeTaskLists lists;
  late _FakeTasks tasks;
  late _FakeNotes notes;
  late _FakeCalendar calendar;
  late _FakeGoals goals;
  late _FakeLearning learning;
  late ProjectWorkspaceService service;
  late Project project;
  var order = 0;

  setUp(() {
    projects = _FakeProjects();
    lists = _FakeTaskLists();
    tasks = _FakeTasks();
    notes = _FakeNotes();
    calendar = _FakeCalendar();
    goals = _FakeGoals();
    learning = _FakeLearning();
    service = ProjectWorkspaceService(
      projects: projects,
      taskLists: lists,
      tasks: tasks,
      notes: notes,
      calendar: calendar,
      goals: goals,
      goalProgress: GoalProgressService(goals, tasks),
      learning: learning,
      learningProgress: LearningProgressService(learning),
    );
    project = Project(id: 'p', title: 'P');
    projects.projects[project.id] = project;
    order = 0;
  });

  /// Adds an item with increasing sortOrder (link order).
  void link(String type, String id) => projects.items.add(ProjectItem(
        projectId: project.id,
        entityType: type,
        entityId: id,
        sortOrder: order++,
      ));

  CalendarEvent event(String id, String title) => CalendarEvent(
        id: id,
        title: title,
        start: EventDateTime(dateTime: DateTime(2026, 5, 1, 9)),
        end: EventDateTime(dateTime: DateTime(2026, 5, 1, 10)),
      );

  test('missing project → null', () async {
    expect(await service.workspaceOf('nope'), isNull);
  });

  test('empty project → isEmpty, counts 0, ratio 0.0', () async {
    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.project, project);
    expect(ws.isEmpty, isTrue);
    expect(ws.totalTasks, 0);
    expect(ws.completedTasks, 0);
    expect(ws.taskCompletionRatio, 0.0);
    expect(ws.ignoredItemCount, 0);
  });

  test('linked list makes its live tasks implicit (via list, not direct)',
      () async {
    lists.visible.add(TaskList(id: 'L', title: 'List'));
    tasks.visible.addAll([
      Task(id: 't1', taskListId: 'L', title: 'A'),
      Task(id: 't2', taskListId: 'L', title: 'B'),
      Task(id: 'other', taskListId: 'X', title: 'Other'),
    ]);
    link(ProjectEntityType.taskList, 'L');

    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.taskLists.map((l) => l.id), ['L']);
    expect(ws.tasks.map((t) => t.task.id), ['t1', 't2']);
    for (final t in ws.tasks) {
      expect(t.isViaTaskList, isTrue);
      expect(t.viaTaskListId, 'L');
      expect(t.isDirect, isFalse);
    }
  });

  test('task linked directly AND via its list appears once with both flags',
      () async {
    lists.visible.add(TaskList(id: 'L', title: 'List'));
    tasks.visible.add(Task(id: 't1', taskListId: 'L', title: 'A'));
    link(ProjectEntityType.task, 't1');
    link(ProjectEntityType.taskList, 'L');

    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.tasks, hasLength(1));
    expect(ws.tasks.single.isDirect, isTrue);
    expect(ws.tasks.single.viaTaskListId, 'L');
    expect(ws.totalTasks, 1);
  });

  test('order follows sortOrder / first appearance', () async {
    tasks.visible.addAll([
      Task(id: 'a', title: 'A'),
      Task(id: 'b', title: 'B'),
      Task(id: 'c', title: 'C'),
    ]);
    projects.items.addAll([
      ProjectItem(
          projectId: 'p', entityType: 'task', entityId: 'c', sortOrder: 0),
      ProjectItem(
          projectId: 'p', entityType: 'task', entityId: 'a', sortOrder: 1),
      ProjectItem(
          projectId: 'p', entityType: 'task', entityId: 'b', sortOrder: 2),
    ]);
    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.tasks.map((t) => t.task.id), ['c', 'a', 'b']);
  });

  test('links to missing / trashed / archived entities are ignored and counted',
      () async {
    // Trashed list 'TL' is not in getTaskLists; its task is live but must
    // not become implicit.
    tasks.visible.add(Task(id: 'inTrashedList', taskListId: 'TL', title: 'X'));
    link(ProjectEntityType.task, 'missingTask');
    link(ProjectEntityType.task, 'trashedTask'); // absent from getTasks
    link(ProjectEntityType.taskList, 'TL');
    link(ProjectEntityType.note, 'missingNote');
    link(ProjectEntityType.calendarEvent, 'archivedEvent');
    goals.all['tg'] = Goal(id: 'tg', title: 'Trashed goal');
    goals.hidden.add('tg');
    link(ProjectEntityType.goal, 'tg');

    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.isEmpty, isTrue);
    expect(ws.ignoredItemCount, 6);
  });

  test('unknown entityType is ignored and counted', () async {
    link('document', 'd1');
    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.isEmpty, isTrue);
    expect(ws.ignoredItemCount, 1);
  });

  group('habits (H3)', () {
    late FakeHabitRepository habits;
    final now = DateTime(2026, 3, 10, 12);

    ProjectWorkspaceService withHabits() => ProjectWorkspaceService(
          projects: projects,
          taskLists: lists,
          tasks: tasks,
          notes: notes,
          calendar: calendar,
          goals: goals,
          goalProgress: GoalProgressService(goals, tasks),
          learning: learning,
          learningProgress: LearningProgressService(learning),
          habits: habits,
          now: () => now,
        );

    setUp(() => habits = FakeHabitRepository());

    test("'habit' is a supported item type", () {
      expect(ProjectEntityType.supported, contains(ProjectEntityType.habit));
    });

    test('active linked habit is listed with its current streak', () async {
      final h = Habit(
          id: 'h1', title: 'Read', startDate: DateTime(2026, 3, 1));
      await habits.createHabit(h);
      for (final d in [8, 9, 10]) {
        await habits.recordOutcome(
            'h1', DateTime(2026, 3, d), HabitOutcome.completed);
      }
      link(ProjectEntityType.habit, 'h1');

      final ws = (await withHabits().workspaceOf(project.id))!;
      expect(ws.habits.map((w) => w.habit.id), ['h1']);
      expect(ws.habits.single.currentStreak, 3);
      expect(ws.isEmpty, isFalse);
      expect(ws.ignoredItemCount, 0);
      // Habits do not affect task counts.
      expect(ws.totalTasks, 0);
    });

    test('archived / missing habits are ignored and counted', () async {
      await habits.createHabit(Habit(id: 'arch', title: 'Old'));
      await habits.archiveHabit('arch');
      link(ProjectEntityType.habit, 'arch');
      link(ProjectEntityType.habit, 'missing');

      final ws = (await withHabits().workspaceOf(project.id))!;
      expect(ws.habits, isEmpty);
      expect(ws.isEmpty, isTrue);
      expect(ws.ignoredItemCount, 2);
    });

    test('without a HabitRepository habit items are ignored', () async {
      link(ProjectEntityType.habit, 'h1');
      final ws = (await service.workspaceOf(project.id))!;
      expect(ws.habits, isEmpty);
      expect(ws.ignoredItemCount, 1);
    });
  });

  test('goal progress passthrough', () async {
    final g = Goal(id: 'g', title: 'G');
    final done = Goal(id: 'done', title: 'Done', status: GoalStatus.completed);
    goals.all[g.id] = g;
    goals.all[done.id] = done;
    tasks.visible.addAll([
      Task(id: 't1', title: 'T1', isCompleted: true),
      Task(id: 't2', title: 'T2'),
    ]);
    goals.links.addAll([
      GoalLink(goalId: 'g', entityType: GoalEntityType.task, entityId: 't1'),
      GoalLink(goalId: 'g', entityType: GoalEntityType.task, entityId: 't2'),
    ]);
    link(ProjectEntityType.goal, 'g');
    link(ProjectEntityType.goal, 'done');

    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.goals.map((wg) => wg.goal.id), ['g', 'done']);
    expect(ws.goals[0].progress!.ratio, 0.5);
    expect(ws.goals[1].progress!.ratio, 1.0);
    // Goal-linked tasks are NOT project tasks unless linked to the project.
    expect(ws.tasks, isEmpty);
  });

  test('totalTasks / completedTasks / ratio', () async {
    tasks.visible.addAll([
      Task(id: 'a', title: 'A', isCompleted: true),
      Task(id: 'b', title: 'B'),
      Task(id: 'c', title: 'C', isCompleted: true),
      Task(id: 'd', title: 'D'),
    ]);
    for (final id in ['a', 'b', 'c', 'd']) {
      link(ProjectEntityType.task, id);
    }
    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.totalTasks, 4);
    expect(ws.completedTasks, 2);
    expect(ws.taskCompletionRatio, 0.5);
  });

  test('notes and events appear in link order', () async {
    notes.visible.addAll([Note(id: 'n1', title: 'N1'), Note(id: 'n2')]);
    calendar.visible.addAll([event('e1', 'E1'), event('e2', 'E2')]);
    link(ProjectEntityType.calendarEvent, 'e2');
    link(ProjectEntityType.note, 'n2');
    link(ProjectEntityType.calendarEvent, 'e1');
    link(ProjectEntityType.note, 'n1');

    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.notes.map((n) => n.id), ['n2', 'n1']);
    expect(ws.calendarEvents.map((e) => e.id), ['e2', 'e1']);
    expect(ws.ignoredItemCount, 0);
  });

  test('live linked course (C7) is listed with derived progress', () async {
    learning.all['c'] = Course(id: 'c', title: 'Course');
    link(ProjectEntityType.course, 'c');

    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.isEmpty, isFalse);
    expect(ws.courses.map((wc) => wc.course.id), ['c']);
    expect(ws.courses.single.progress, isNotNull);
    expect(ws.courses.single.progress!.ratio, 0.0);
    expect(ws.ignoredItemCount, 0);
    // Courses do not affect task counts.
    expect(ws.totalTasks, 0);
  });

  test('trashed / archived / missing course is ignored and counted',
      () async {
    learning.all['hidden'] = Course(id: 'hidden', title: 'Hidden');
    learning.hidden.add('hidden');
    link(ProjectEntityType.course, 'hidden');
    link(ProjectEntityType.course, 'missing');

    final ws = (await service.workspaceOf(project.id))!;
    expect(ws.courses, isEmpty);
    expect(ws.isEmpty, isTrue);
    expect(ws.ignoredItemCount, 2);
  });

  test('compute is pure: duplicate items count once', () {
    final t = Task(id: 't', title: 'T');
    final ws = ProjectWorkspaceService.compute(
      project: project,
      items: [
        ProjectItem(projectId: 'p', entityType: 'task', entityId: 't'),
        ProjectItem(projectId: 'p', entityType: 'task', entityId: 't'),
      ],
      liveTaskLists: const [],
      liveTasks: [t],
      liveNotes: const [],
      liveEvents: const [],
      liveGoals: const [],
    );
    expect(ws.tasks, hasLength(1));
    expect(ws.ignoredItemCount, 0);
  });
}
