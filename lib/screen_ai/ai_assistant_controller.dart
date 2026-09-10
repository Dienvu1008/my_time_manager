import 'package:flutter/foundation.dart';

import '../ai/agent/agent_config.dart';
import '../ai/agent/agent_result.dart';
import '../ai/agent/agent_runtime.dart';
import '../ai/agent/agent_trace.dart';
import '../ai/agent/workflows/agent_workflow.dart';
import '../ai/context/context_builder.dart';
import '../ai/core/ai_cancellation_token.dart';
import '../ai/core/ai_engine.dart';
import '../ai/core/ai_message.dart';
import '../ai/policy/action_policy.dart';
import '../ai/policy/confirmation.dart';
import '../ai/tools/tool_executor.dart';
import '../ai/tools/tool_registry.dart';

/// A message shown in the assistant transcript.
class AiChatMessage {
  AiChatMessage.user(this.text)
      : isUser = true,
        isError = false;
  AiChatMessage.assistant(this.text)
      : isUser = false,
        isError = false;
  AiChatMessage.error(this.text)
      : isUser = false,
        isError = true;

  final String text;
  final bool isUser;
  final bool isError;
}

/// High-level status of the assistant, so the UI can show progress.
enum AiAssistantStatus { idle, thinking, toolRunning, error }

/// Drives the AI Assistant screen: holds the transcript, builds targeted
/// context, runs the agent loop, surfaces confirmation requests to the UI, and
/// exposes status for progress indicators. Uses ChangeNotifier to match the
/// app's existing lightweight controller pattern (DataController).
///
/// It assembles its own [AgentRuntime] and [ToolExecutor] from the primitives
/// (engine, registry, policy, context builder). Building them here — rather than
/// taking a pre-built runtime — avoids a construction cycle: the executor's
/// confirmation handler and the runtime's tracer both point back to `this`.
///
/// It talks only to the AI layer and the domain-backed ContextBuilder — never
/// the database directly.
class AiAssistantController extends ChangeNotifier {
  AiAssistantController({
    required AiEngine engine,
    required ToolRegistry registry,
    required ContextBuilder contextBuilder,
    ActionPolicy policy = const ActionPolicy(),
    AgentConfig agentConfig = const AgentConfig(),
  })  : _engine = engine,
        _context = contextBuilder {
    final executor = ToolExecutor(
      registry,
      policy: policy,
      confirm: _handleConfirmation,
    );
    _agent = AgentRuntime(
      engine: engine,
      registry: registry,
      executor: executor,
      config: agentConfig,
      tracer: onTrace,
    );
  }

  final AiEngine _engine;
  final ContextBuilder _context;
  late final AgentRuntime _agent;

  final List<AiChatMessage> _messages = [];
  List<AiChatMessage> get messages => List.unmodifiable(_messages);

  AiAssistantStatus _status = AiAssistantStatus.idle;
  AiAssistantStatus get status => _status;

  String _statusDetail = '';
  String get statusDetail => _statusDetail;

  bool get isBusy =>
      _status == AiAssistantStatus.thinking ||
      _status == AiAssistantStatus.toolRunning;

  AiCancellationToken? _cancelToken;

  /// Conversation history carried across turns (excludes the system prompt,
  /// which the runtime adds).
  final List<AiMessage> _history = [];

  /// The UI registers this to prompt the user to approve/reject an action.
  /// When null, actions requiring confirmation are rejected (safe default).
  ConfirmationHandler? confirmationHandler;

  Future<bool> _handleConfirmation(ConfirmationRequest request) async {
    final handler = confirmationHandler;
    if (handler == null) return false; // safe default: reject
    return handler(request);
  }

  /// Check whether the backend is reachable (for a status hint in the UI).
  Future<bool> checkAvailability() => _engine.isAvailable();

  /// Send a user message and run the agent. No-op when empty or busy.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isBusy) return;

    _messages.add(AiChatMessage.user(trimmed));
    _setStatus(AiAssistantStatus.thinking, 'Thinking…');

    final token = AiCancellationToken();
    _cancelToken = token;

    try {
      final ctx = await _context.build();
      final result = await _agent.run(
        trimmed,
        history: List.unmodifiable(_history),
        contextText: ctx.render(),
        cancelToken: token,
      );
      _applyResult(trimmed, result);
    } catch (e) {
      _messages.add(AiChatMessage.error('Something went wrong: $e'));
      _setStatus(AiAssistantStatus.error, '');
    } finally {
      _cancelToken = null;
      if (_status != AiAssistantStatus.error) {
        _setStatus(AiAssistantStatus.idle, '');
      }
    }
  }

  /// Run a high-level execution workflow (Daily Planning, Weekly Review,
  /// Rescheduling). Rides the same agent loop — tools, policy, and confirmation
  /// all apply. No-op when busy.
  Future<void> runWorkflow(AgentWorkflow workflow) async {
    if (isBusy) return;

    final opening = workflow.openingMessage;
    _messages.add(AiChatMessage.user(opening));
    _setStatus(AiAssistantStatus.thinking, 'Thinking…');

    final token = AiCancellationToken();
    _cancelToken = token;

    try {
      final ctx = await _context.build();
      final result = await _agent.run(
        opening,
        history: List.unmodifiable(_history),
        contextText: ctx.render(),
        extraSystemPrompt: workflow.guidance,
        cancelToken: token,
      );
      _applyResult(opening, result);
    } catch (e) {
      _messages.add(AiChatMessage.error('Something went wrong: $e'));
      _setStatus(AiAssistantStatus.error, '');
    } finally {
      _cancelToken = null;
      if (_status != AiAssistantStatus.error) {
        _setStatus(AiAssistantStatus.idle, '');
      }
    }
  }

  /// Cancel an in-flight run.
  void cancel() => _cancelToken?.cancel();

  /// Clear the transcript and history.
  void reset() {
    _messages.clear();
    _history.clear();
    _setStatus(AiAssistantStatus.idle, '');
  }

  void _applyResult(String userText, AgentResult result) {
    switch (result.stopReason) {
      case AgentStopReason.completed:
        _messages.add(AiChatMessage.assistant(
            result.text.isEmpty ? '(no response)' : result.text));
        _history
          ..add(AiMessage.user(userText))
          ..add(AiMessage.assistant(result.text));
        _setStatus(AiAssistantStatus.idle, '');
        break;
      case AgentStopReason.maxIterations:
        _messages.add(AiChatMessage.assistant(result.text.isEmpty
            ? 'I stopped after several steps without a final answer.'
            : result.text));
        _setStatus(AiAssistantStatus.idle, '');
        break;
      case AgentStopReason.cancelled:
        _messages.add(AiChatMessage.error('Cancelled.'));
        _setStatus(AiAssistantStatus.idle, '');
        break;
      case AgentStopReason.error:
        _messages.add(AiChatMessage.error(
            result.errorMessage ?? 'The assistant could not complete this.'));
        _setStatus(AiAssistantStatus.error, '');
        break;
    }
  }

  /// A tracer the runtime calls to update the live status line.
  void onTrace(AgentTraceEvent event) {
    if (event is AgentModelRequest) {
      _setStatus(AiAssistantStatus.thinking, 'Thinking…');
    } else if (event is AgentToolCallStarted) {
      _setStatus(AiAssistantStatus.toolRunning, 'Running ${event.call.name}…');
    }
  }

  void _setStatus(AiAssistantStatus status, String detail) {
    _status = status;
    _statusDetail = detail;
    notifyListeners();
  }
}
