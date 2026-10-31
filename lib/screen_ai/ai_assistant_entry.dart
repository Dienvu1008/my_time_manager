import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ai/agent/agent_config.dart';
import '../ai/config/ai_config.dart';
import '../ai/config/ai_config_service.dart';
import '../ai/config/device_timezone.dart';
import '../ai/context/context_builder.dart';
import '../ai/core/ai_engine.dart';
import '../ai/gateway/ai_engine_factory.dart';
import '../ai/gateway/provider_selection.dart';
import '../ai/policy/action_policy.dart';
import '../ai/policy/ai_action_log.dart';
import '../ai/tools/domain/domain_tools.dart';
import '../application/reminders/reminder_coordinator.dart';
import '../domain/repositories/ai_action_log_repository.dart';
import '../domain/repositories/calendar_repository.dart';
import '../domain/repositories/conversation_repository.dart';
import '../domain/repositories/focus_repository.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/repositories/learning_repository.dart';
import '../domain/repositories/note_repository.dart';
import '../domain/repositories/project_repository.dart';
import '../domain/repositories/reminder_rule_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/time_interval_repository.dart';
import '../domain/services/focus_statistics_service.dart';
import '../domain/services/goal_progress_service.dart';
import '../domain/services/learning_progress_service.dart';
import '../domain/services/project_workspace_service.dart';
import '../domain/services/task_completion_service.dart';
import 'ai_assistant_controller.dart';
import 'ai_assistant_page.dart';
import 'ai_settings_page.dart';

/// Composition root for the AI Assistant feature.
///
/// Loads the saved [AiConfig], then uses the [AiEngineFactory] (an [AiGateway]
/// under the hood) to pick an [AiEngine] for the CURRENT PLATFORM and mode —
/// Ollama on desktop, llama.cpp on mobile when opted in. It then assembles the
/// AI stack from the domain repositories/services provided app-wide (via
/// [context.read]).
///
/// This is the ONLY place that assembles the AI feature, keeping app.dart free
/// of AI wiring and letting the assistant reach data solely through the domain
/// layer.
class AiAssistantEntry extends StatefulWidget {
  const AiAssistantEntry({
    super.key,
    this.policy = const ActionPolicy(),
    this.agentConfig = const AgentConfig(),
    this.configService,
    this.engineFactory,
  });

  final ActionPolicy policy;
  final AgentConfig agentConfig;

  /// Optional injected config service (tests); a default is created otherwise.
  final AiConfigService? configService;

  /// Optional injected engine factory (tests / to opt into llama.cpp). Defaults
  /// to a desktop-Ollama-only factory.
  final AiEngineFactory? engineFactory;

  @override
  State<AiAssistantEntry> createState() => _AiAssistantEntryState();
}

class _AiAssistantEntryState extends State<AiAssistantEntry> {
  AiAssistantController? _controller;
  AiEngine? _engine;

  /// Set when selection failed, so the UI can guide the user.
  ProviderSelection? _failure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = widget.configService ?? AiConfigService();
    final factory = widget.engineFactory ?? AiEngineFactory();
    final config = await service.load();

    final selection = await factory.select(config);
    if (!mounted) return;

    if (!selection.isSelected) {
      setState(() {
        _loading = false;
        _failure = selection;
        _controller = null;
      });
      return;
    }

    final engine = selection.engine!;
    // Resolve the timezone to surface to the model: the user's configured one,
    // else the device's.
    final timezone = await effectiveTimezone(config.timezone);
    if (!mounted) return;

    final tasks = context.read<TaskRepository>();
    final calendar = context.read<CalendarRepository>();
    final intervals = context.read<TimeIntervalRepository>();
    final focus = context.read<FocusRepository>();
    final taskCompletion = context.read<TaskCompletionService>();
    final focusStats = context.read<FocusStatisticsService>();
    final conversations = context.read<ConversationRepository>();
    final goals = context.read<GoalRepository>();
    final goalProgress = context.read<GoalProgressService>();
    final projects = context.read<ProjectRepository>();
    final projectWorkspace = context.read<ProjectWorkspaceService>();
    final learning = context.read<LearningRepository>();
    final learningProgress = context.read<LearningProgressService>();
    final notes = context.read<NoteRepository>();
    final reminderRules = context.read<ReminderRuleRepository>();
    final reminderCoordinator = context.read<ReminderCoordinator>();
    final actionLogRepo = context.read<AiActionLogRepository?>();

    // Best-effort retention: drop chat history older than the configured
    // number of days (null = keep forever). Never blocks opening the screen.
    final retentionDays = config.chatHistoryRetentionDays;
    if (retentionDays != null && retentionDays > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
      try {
        await conversations.deleteConversationsUpdatedBefore(cutoff);
      } catch (_) {/* purge is best-effort; ignore failures */}
      if (!mounted) return;
    }

    final registry = buildDomainToolRegistry(
      tasks: tasks,
      taskCompletion: taskCompletion,
      calendar: calendar,
      timeIntervals: intervals,
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
      upcomingReminders: reminderCoordinator.upcoming,
    );

    setState(() {
      _loading = false;
      _failure = null;
      _engine = engine;
      _controller = AiAssistantController(
        engine: engine,
        registry: registry,
        contextBuilder: ContextBuilder(
          tasks: tasks,
          calendar: calendar,
          timeIntervals: intervals,
          focusStats: focusStats,
          goals: goals,
          goalProgress: goalProgress,
          projects: projects,
          learning: learning,
        ),
        policy: widget.policy,
        agentConfig: widget.agentConfig,
        timezone: timezone,
        conversations: conversations,
        actionLog: actionLogRepo == null
            ? const NoOpAiActionLog()
            : RepositoryAiActionLog(actionLogRepo),
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    final engine = _engine;
    // Ollama/llama engines expose dispose(); call it dynamically to avoid
    // widening the AiEngine interface. Best-effort.
    try {
      (engine as dynamic)?.dispose();
    } catch (_) {/* engine may not need disposal */}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final controller = _controller;
    if (controller == null) {
      return _UnavailableView(
        selection: _failure,
        onOpenSettings: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AiSettingsPage()),
          );
          if (mounted) _load();
        },
      );
    }
    return AiAssistantPage(controller: controller);
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.selection, required this.onOpenSettings});
  final ProviderSelection? selection;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    // Choose a helpful message based on why selection failed.
    final reason = selection?.reason;
    final String message;
    switch (reason) {
      case NoProviderReason.noneAvailable:
        message = 'No AI model is selected, or the AI server is not reachable.\n'
            'Open AI Settings to pick a model and check the connection.';
        break;
      case NoProviderReason.unsupportedPlatform:
        message = 'No AI provider is available for this platform yet.\n'
            'On desktop, run a local Ollama server; on mobile, enable llama.cpp.';
        break;
      case NoProviderReason.cloudDisallowed:
        message = 'Only a cloud provider fits, but the mode is local-only.\n'
            'Change the privacy mode in AI Settings to allow it.';
        break;
      default:
        message = 'The AI assistant is not available yet.\n'
            'Open AI Settings to configure a model.';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (selection?.explanation != null) ...[
                const SizedBox(height: 8),
                Text(selection!.explanation,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open AI Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
