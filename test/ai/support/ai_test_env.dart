import 'package:my_time_manager/ai/policy/action_policy.dart';
import 'package:my_time_manager/ai/policy/ai_action_log.dart';
import 'package:my_time_manager/ai/policy/confirmation.dart';
import 'package:my_time_manager/ai/tools/domain/domain_tools.dart';
import 'package:my_time_manager/ai/tools/tool_executor.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_ai_action_log_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_focus_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_learning_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_note_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_project_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_reminder_rule_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_time_interval_repository.dart';
import 'package:my_time_manager/domain/services/focus_statistics_service.dart';
import 'package:my_time_manager/domain/services/goal_progress_service.dart';
import 'package:my_time_manager/domain/services/learning_progress_service.dart';
import 'package:my_time_manager/domain/services/project_workspace_service.dart';
import 'package:my_time_manager/domain/services/task_completion_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Point sqflite at the FFI factory (call from `setUpAll`).
void initAiTestFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// The full domain tool registry (Phase C8b eval harness) over a fresh
/// in-memory SQLite database and the real `Sqlite*Repository` classes, so
/// agent-loop tests exercise production tools end to end without any model
/// runtime.
class AiTestEnv {
  AiTestEnv._();

  final tasks = SqliteTaskRepository();
  final taskLists = SqliteTaskListRepository();
  final calendar = SqliteCalendarRepository();
  final timeIntervals = SqliteTimeIntervalRepository();
  final focus = SqliteFocusRepository();
  final notes = SqliteNoteRepository();
  final goals = SqliteGoalRepository();
  final projects = SqliteProjectRepository();
  final learning = SqliteLearningRepository();
  final reminderRules = SqliteReminderRuleRepository();
  final actionLogs = SqliteAiActionLogRepository();

  late final TaskCompletionService taskCompletion;
  late final FocusStatisticsService focusStats;
  late final GoalProgressService goalProgress;
  late final LearningProgressService learningProgress;
  late final ProjectWorkspaceService projectWorkspace;
  late final ToolRegistry registry;

  /// Resets the shared in-memory DB and builds the registry.
  static Future<AiTestEnv> create() async {
    await DatabaseManager().resetForTesting(inMemory: true);
    final env = AiTestEnv._();
    env.taskCompletion = TaskCompletionService(env.tasks);
    env.focusStats = FocusStatisticsService(env.focus);
    env.goalProgress = GoalProgressService(env.goals, env.tasks);
    env.learningProgress = LearningProgressService(env.learning);
    env.projectWorkspace = ProjectWorkspaceService(
      projects: env.projects,
      taskLists: env.taskLists,
      tasks: env.tasks,
      notes: env.notes,
      calendar: env.calendar,
      goals: env.goals,
      goalProgress: env.goalProgress,
      learning: env.learning,
      learningProgress: env.learningProgress,
    );
    env.registry = buildDomainToolRegistry(
      tasks: env.tasks,
      taskCompletion: env.taskCompletion,
      calendar: env.calendar,
      timeIntervals: env.timeIntervals,
      focus: env.focus,
      focusStats: env.focusStats,
      goals: env.goals,
      goalProgress: env.goalProgress,
      projects: env.projects,
      projectWorkspace: env.projectWorkspace,
      learning: env.learning,
      learningProgress: env.learningProgress,
      notes: env.notes,
      reminderRules: env.reminderRules,
      upcomingReminders: () async => const [],
    );
    return env;
  }

  /// An executor over [registry] with the given policy / confirmation / log.
  ToolExecutor executor({
    PolicyMode mode = PolicyMode.confirmWrites,
    ConfirmationHandler confirm = approveAllConfirmation,
    AiActionLog? log,
  }) =>
      ToolExecutor(
        registry,
        policy: ActionPolicy(mode: mode),
        confirm: confirm,
        actionLog: log ?? RepositoryAiActionLog(actionLogs),
      );
}
