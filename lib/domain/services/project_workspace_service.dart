import '../models/model_calendar_event.dart';
import '../models/model_course.dart';
import '../models/model_goal.dart';
import '../models/model_habit.dart';
import '../models/model_list.dart';
import '../models/model_note.dart';
import '../models/model_project.dart';
import '../models/model_project_item.dart';
import '../models/model_task.dart';
import '../repositories/calendar_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/learning_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_list_repository.dart';
import '../repositories/task_repository.dart';
import 'goal_progress_service.dart';
import 'habit_statistics_service.dart';
import 'learning_progress_service.dart';

/// A task in a project workspace, with where its membership comes from.
class WorkspaceTask {
  const WorkspaceTask({
    required this.task,
    required this.isDirect,
    this.viaTaskListId,
  });

  final Task task;

  /// The task has a direct `'task'` item in the project.
  final bool isDirect;

  /// Id of the linked (and live) task list the task belongs to, or null.
  final String? viaTaskListId;

  bool get isViaTaskList => viaTaskListId != null;
}

/// A goal in a project workspace with its DERIVED progress (C5 rules).
class WorkspaceGoal {
  const WorkspaceGoal({required this.goal, this.progress});

  final Goal goal;
  final GoalProgress? progress;
}

/// A course in a project workspace with its DERIVED progress (C7 rules).
class WorkspaceCourse {
  const WorkspaceCourse({required this.course, this.progress});

  final Course course;
  final CourseProgress? progress;
}

/// A habit in a project workspace with its DERIVED current streak (Phase H3,
/// [HabitStatisticsService] rules). Habits do not affect the task counts.
class WorkspaceHabit {
  const WorkspaceHabit({required this.habit, this.currentStreak = 0});

  final Habit habit;
  final int currentStreak;
}

/// Read model of one project (never stored).
class ProjectWorkspace {
  const ProjectWorkspace({
    required this.project,
    this.taskLists = const [],
    this.tasks = const [],
    this.notes = const [],
    this.goals = const [],
    this.calendarEvents = const [],
    this.courses = const [],
    this.habits = const [],
    this.ignoredItemCount = 0,
  });

  final Project project;
  final List<TaskList> taskLists;
  final List<WorkspaceTask> tasks;
  final List<Note> notes;
  final List<WorkspaceGoal> goals;
  final List<CalendarEvent> calendarEvents;
  final List<WorkspaceCourse> courses;

  /// Linked active habits (Phase H3).
  final List<WorkspaceHabit> habits;

  /// Items skipped because their entity is missing / trashed / archived or
  /// their entityType is unknown.
  final int ignoredItemCount;

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.task.isCompleted).length;
  double get taskCompletionRatio =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  bool get isEmpty =>
      taskLists.isEmpty &&
      tasks.isEmpty &&
      notes.isEmpty &&
      goals.isEmpty &&
      calendarEvents.isEmpty &&
      courses.isEmpty &&
      habits.isEmpty;
}

/// Pure, deterministic read model of a project (Core Track C6):
///
///     UI / AI Tool → ProjectWorkspaceService → repositories (+ GoalProgressService)
///
/// Rules:
/// - "Live" entity = present in the repository's visible list
///   (`getTaskLists`, `getTasks`, `getNotes`, `getCalendarEvents`,
///   `getGoals`): exists, not trashed, not archived. Items pointing to anything
///   else, and items with an unknown entityType, are skipped and counted in
///   [ProjectWorkspace.ignoredItemCount].
/// - Items are walked in the given order (sortOrder, createdAt); each
///   (entityType, entityId) is taken on first occurrence.
/// - `'taskList'` (live) → listed, and its live tasks (in `getTasks` order) are
///   IMPLICITLY part of the project with `viaTaskListId` = list id. A task of a
///   linked but non-live list is not implicit.
/// - `'task'` (live) → `isDirect: true`. A task reached both directly and via
///   its list appears ONCE with both flags.
/// - `'goal'` (live) → listed with its [GoalProgress] from
///   [GoalProgressService] (passthrough, not recomputed).
/// - 'course' (live, C7: present in [LearningRepository.getCourses]) →
///   listed with its [CourseProgress] from [LearningProgressService]
///   (passthrough). Course progress does not affect the task counts.
/// - `'habit'` (Phase H3; live = active, i.e. in [HabitRepository.getHabits])
///   → listed with its current streak from [HabitStatisticsService].
///   Archived / missing habits are ignored (counted in ignoredItemCount);
///   without a [HabitRepository] every habit item is ignored. Habits do not
///   affect the task counts.
/// - Counts (total/completed tasks, ratio) are derived; nothing is written.
class ProjectWorkspaceService {
  ProjectWorkspaceService({
    required ProjectRepository projects,
    required TaskListRepository taskLists,
    required TaskRepository tasks,
    required NoteRepository notes,
    required CalendarRepository calendar,
    required GoalRepository goals,
    required GoalProgressService goalProgress,
    required LearningRepository learning,
    required LearningProgressService learningProgress,
    HabitRepository? habits,
    HabitStatisticsService habitStatistics = const HabitStatisticsService(),
    DateTime Function()? now,
  })  : _projects = projects,
        _taskLists = taskLists,
        _tasks = tasks,
        _notes = notes,
        _calendar = calendar,
        _goals = goals,
        _goalProgress = goalProgress,
        _learning = learning,
        _learningProgress = learningProgress,
        _habits = habits,
        _habitStatistics = habitStatistics,
        _now = now ?? DateTime.now;

  final HabitRepository? _habits;
  final HabitStatisticsService _habitStatistics;
  final DateTime Function() _now;

  final ProjectRepository _projects;
  final TaskListRepository _taskLists;
  final TaskRepository _tasks;
  final NoteRepository _notes;
  final CalendarRepository _calendar;
  final GoalRepository _goals;
  final GoalProgressService _goalProgress;
  final LearningRepository _learning;
  final LearningProgressService _learningProgress;

  /// Workspace of a project (any state), or null if it does not exist.
  Future<ProjectWorkspace?> workspaceOf(String projectId) async {
    final project = await _projects.getProject(projectId);
    if (project == null) return null;
    final items = await _projects.getItems(projectId);
    final liveLists = await _taskLists.getTaskLists();
    final liveTasks = await _tasks.getTasks();
    final liveNotes = await _notes.getNotes();
    final liveEvents = await _calendar.getCalendarEvents();
    final liveGoals = await _goals.getGoals();
    final liveCourses = await _learning.getCourses();

    final liveGoalIds = {for (final g in liveGoals) g.id};
    final linkedGoalIds = <String>{
      for (final i in items)
        if (i.entityType == ProjectEntityType.goal &&
            liveGoalIds.contains(i.entityId))
          i.entityId,
    };
    final progress = <String, GoalProgress?>{
      for (final id in linkedGoalIds) id: await _goalProgress.progressOf(id),
    };
    final liveCourseIds = {for (final c in liveCourses) c.id};
    final linkedCourseIds = <String>{
      for (final i in items)
        if (i.entityType == ProjectEntityType.course &&
            liveCourseIds.contains(i.entityId))
          i.entityId,
    };
    final courseProgress = <String, CourseProgress?>{
      for (final id in linkedCourseIds)
        id: await _learningProgress.courseProgressOf(id),
    };

    final habitRepo = _habits;
    final liveHabits =
        habitRepo == null ? const <Habit>[] : await habitRepo.getHabits();
    final habitStreaks = <String, int>{};
    if (habitRepo != null) {
      final now = _now();
      final linkedHabitIds = {
        for (final i in items)
          if (i.entityType == ProjectEntityType.habit) i.entityId,
      };
      for (final h in liveHabits) {
        if (!linkedHabitIds.contains(h.id)) continue;
        habitStreaks[h.id] = _habitStatistics.currentStreak(
            h, await habitRepo.occurrencesOf(h.id), now);
      }
    }

    return compute(
      project: project,
      items: items,
      liveTaskLists: liveLists,
      liveTasks: liveTasks,
      liveNotes: liveNotes,
      liveEvents: liveEvents,
      liveGoals: liveGoals,
      goalProgress: progress,
      liveCourses: liveCourses,
      courseProgress: courseProgress,
      liveHabits: liveHabits,
      habitStreaks: habitStreaks,
    );
  }

  /// Pure rule (see class doc).
  static ProjectWorkspace compute({
    required Project project,
    required List<ProjectItem> items,
    required List<TaskList> liveTaskLists,
    required List<Task> liveTasks,
    required List<Note> liveNotes,
    required List<CalendarEvent> liveEvents,
    required List<Goal> liveGoals,
    Map<String, GoalProgress?> goalProgress = const {},
    List<Course> liveCourses = const [],
    Map<String, CourseProgress?> courseProgress = const {},
    List<Habit> liveHabits = const [],
    Map<String, int> habitStreaks = const {},
  }) {
    final habitsById = {
      for (final h in liveHabits)
        if (!h.isArchived) h.id: h,
    };
    final habits = <WorkspaceHabit>[];
    final listsById = {for (final l in liveTaskLists) l.id: l};
    final tasksById = {for (final t in liveTasks) t.id: t};
    final notesById = {for (final n in liveNotes) n.id: n};
    final eventsById = {for (final e in liveEvents) e.id: e};
    final goalsById = {for (final g in liveGoals) g.id: g};
    final coursesById = {for (final c in liveCourses) c.id: c};

    final seen = <String>{};
    final taskLists = <TaskList>[];
    // Map literal = LinkedHashMap: giữ thứ tự xuất hiện đầu tiên.
    final taskEntries = <String, _TaskEntry>{};
    final notes = <Note>[];
    final goals = <WorkspaceGoal>[];
    final events = <CalendarEvent>[];
    final courses = <WorkspaceCourse>[];
    var ignored = 0;

    for (final item in items) {
      if (!seen.add('${item.entityType}\u0000${item.entityId}')) continue;
      switch (item.entityType) {
        case ProjectEntityType.taskList:
          final list = listsById[item.entityId];
          if (list == null) {
            ignored++;
            break;
          }
          taskLists.add(list);
          for (final t in liveTasks) {
            if (t.taskListId != list.id) continue;
            final entry = taskEntries.putIfAbsent(t.id, () => _TaskEntry(t));
            entry.viaTaskListId ??= list.id;
          }
          break;
        case ProjectEntityType.task:
          final task = tasksById[item.entityId];
          if (task == null) {
            ignored++;
            break;
          }
          taskEntries.putIfAbsent(task.id, () => _TaskEntry(task)).isDirect =
              true;
          break;
        case ProjectEntityType.note:
          final note = notesById[item.entityId];
          if (note == null) {
            ignored++;
            break;
          }
          notes.add(note);
          break;
        case ProjectEntityType.calendarEvent:
          final event = eventsById[item.entityId];
          if (event == null) {
            ignored++;
            break;
          }
          events.add(event);
          break;
        case ProjectEntityType.goal:
          final goal = goalsById[item.entityId];
          if (goal == null) {
            ignored++;
            break;
          }
          goals.add(WorkspaceGoal(goal: goal, progress: goalProgress[goal.id]));
          break;
        case ProjectEntityType.course:
          final course = coursesById[item.entityId];
          if (course == null) {
            ignored++;
            break;
          }
          courses.add(WorkspaceCourse(
              course: course, progress: courseProgress[course.id]));
          break;
        case ProjectEntityType.habit:
          final habit = habitsById[item.entityId];
          if (habit == null) {
            ignored++;
            break;
          }
          habits.add(WorkspaceHabit(
              habit: habit, currentStreak: habitStreaks[habit.id] ?? 0));
          break;
        default:
          ignored++;
      }
    }

    return ProjectWorkspace(
      project: project,
      taskLists: List.unmodifiable(taskLists),
      tasks: List.unmodifiable([
        for (final e in taskEntries.values)
          WorkspaceTask(
            task: e.task,
            isDirect: e.isDirect,
            viaTaskListId: e.viaTaskListId,
          ),
      ]),
      notes: List.unmodifiable(notes),
      goals: List.unmodifiable(goals),
      calendarEvents: List.unmodifiable(events),
      courses: List.unmodifiable(courses),
      habits: List.unmodifiable(habits),
      ignoredItemCount: ignored,
    );
  }
}

/// Mutable builder entry used only inside [ProjectWorkspaceService.compute].
class _TaskEntry {
  _TaskEntry(this.task);

  final Task task;
  bool isDirect = false;
  String? viaTaskListId;
}
