import '../../../domain/repositories/calendar_repository.dart';
import '../../../domain/repositories/focus_repository.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../domain/repositories/learning_repository.dart';
import '../../../domain/repositories/note_repository.dart';
import '../../../domain/repositories/project_repository.dart';
import '../../../domain/repositories/reminder_rule_repository.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/repositories/time_interval_repository.dart';
import '../../../domain/services/focus_statistics_service.dart';
import '../../../domain/services/goal_progress_service.dart';
import '../../../domain/services/learning_progress_service.dart';
import '../../../domain/services/project_workspace_service.dart';
import '../../../domain/services/task_completion_service.dart';
import '../tool.dart';
import '../tool_registry.dart';
import 'analytics_tools.dart';
import 'calendar_tools.dart';
import 'focus_tools.dart';
import 'goal_tools.dart';
import 'learning_tools.dart';
import 'note_tools.dart';
import 'project_tools.dart';
import 'reminder_tools.dart';
import 'task_tools.dart';
import 'time_planning_tools.dart';

/// Assembles the full set of domain tools from the app's domain
/// repositories/services. This is the single place that wires the AI tool layer
/// to the domain layer — tools reach data ONLY through these interfaces, never
/// through DatabaseManager/SQLite.
///
/// The C8a entity tools (goals, projects, courses, notes, reminders) are
/// registered only when their optional dependencies are given.
List<Tool> buildDomainTools({
  required TaskRepository tasks,
  required TaskCompletionService taskCompletion,
  required CalendarRepository calendar,
  required TimeIntervalRepository timeIntervals,
  required FocusRepository focus,
  required FocusStatisticsService focusStats,
  GoalRepository? goals,
  GoalProgressService? goalProgress,
  ProjectRepository? projects,
  ProjectWorkspaceService? projectWorkspace,
  LearningRepository? learning,
  LearningProgressService? learningProgress,
  NoteRepository? notes,
  ReminderRuleRepository? reminderRules,
  UpcomingRemindersLoader? upcomingReminders,
}) =>
    [
      ...taskTools(tasks, taskCompletion),
      ...calendarTools(calendar),
      ...timePlanningTools(timeIntervals),
      ...focusTools(focus, focusStats),
      ...analyticsTools(tasks, timeIntervals, focus, focusStats),
      if (goals != null && goalProgress != null)
        ...goalTools(goals, goalProgress, tasks),
      if (projects != null && projectWorkspace != null)
        ...projectTools(projects, projectWorkspace),
      if (learning != null && learningProgress != null)
        ...learningTools(learning, learningProgress),
      if (notes != null) ...noteTools(notes),
      ...reminderTools(
        upcoming: upcomingReminders,
        rules: reminderRules,
        timeIntervals: timeIntervals,
      ),
    ];

/// Build a ready-to-use [ToolRegistry] with all domain tools registered.
ToolRegistry buildDomainToolRegistry({
  required TaskRepository tasks,
  required TaskCompletionService taskCompletion,
  required CalendarRepository calendar,
  required TimeIntervalRepository timeIntervals,
  required FocusRepository focus,
  required FocusStatisticsService focusStats,
  GoalRepository? goals,
  GoalProgressService? goalProgress,
  ProjectRepository? projects,
  ProjectWorkspaceService? projectWorkspace,
  LearningRepository? learning,
  LearningProgressService? learningProgress,
  NoteRepository? notes,
  ReminderRuleRepository? reminderRules,
  UpcomingRemindersLoader? upcomingReminders,
}) =>
    ToolRegistry(buildDomainTools(
      tasks: tasks,
      taskCompletion: taskCompletion,
      calendar: calendar,
      timeIntervals: timeIntervals,
      focus: focus,
      focusStats: focusStats,
      goals: goals,
      goalProgress: goalProgress,
      projects: projects,
      projectWorkspace: projectWorkspace,
      learning: learning,
      learningProgress: learningProgress,
      notes: notes,
      reminderRules: reminderRules,
      upcomingReminders: upcomingReminders,
    ));
