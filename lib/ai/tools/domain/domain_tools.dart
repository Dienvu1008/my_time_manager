import '../../../domain/repositories/calendar_repository.dart';
import '../../../domain/repositories/focus_repository.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/repositories/time_interval_repository.dart';
import '../../../domain/services/focus_statistics_service.dart';
import '../../../domain/services/task_completion_service.dart';
import '../tool.dart';
import '../tool_registry.dart';
import 'analytics_tools.dart';
import 'calendar_tools.dart';
import 'focus_tools.dart';
import 'task_tools.dart';
import 'time_planning_tools.dart';

/// Assembles the full set of domain tools from the app's domain
/// repositories/services. This is the single place that wires the AI tool layer
/// to the domain layer — tools reach data ONLY through these interfaces, never
/// through DatabaseManager/SQLite.
List<Tool> buildDomainTools({
  required TaskRepository tasks,
  required TaskCompletionService taskCompletion,
  required CalendarRepository calendar,
  required TimeIntervalRepository timeIntervals,
  required FocusRepository focus,
  required FocusStatisticsService focusStats,
}) =>
    [
      ...taskTools(tasks, taskCompletion),
      ...calendarTools(calendar),
      ...timePlanningTools(timeIntervals),
      ...focusTools(focus, focusStats),
      ...analyticsTools(tasks, timeIntervals, focus, focusStats),
    ];

/// Build a ready-to-use [ToolRegistry] with all domain tools registered.
ToolRegistry buildDomainToolRegistry({
  required TaskRepository tasks,
  required TaskCompletionService taskCompletion,
  required CalendarRepository calendar,
  required TimeIntervalRepository timeIntervals,
  required FocusRepository focus,
  required FocusStatisticsService focusStats,
}) =>
    ToolRegistry(buildDomainTools(
      tasks: tasks,
      taskCompletion: taskCompletion,
      calendar: calendar,
      timeIntervals: timeIntervals,
      focus: focus,
      focusStats: focusStats,
    ));
