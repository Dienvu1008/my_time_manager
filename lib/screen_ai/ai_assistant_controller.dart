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
import '../ai/policy/ai_action_log.dart';
import '../ai/policy/confirmation.dart';
import '../ai/tools/tool_executor.dart';
import '../ai/tools/tool_registry.dart';
import '../domain/models/model_conversation.dart';
import '../domain/repositories/conversation_repository.dart';

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
/// app's lightweight controller pattern used across the UI.
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
    String? timezone,
    ConversationRepository? conversations,
    AiActionLog actionLog = const NoOpAiActionLog(),
  })  : _engine = engine,
        _context = contextBuilder,
        _timezone = timezone,
        _conversations = conversations {
    final executor = ToolExecutor(
      registry,
      policy: policy,
      confirm: _handleConfirmation,
      actionLog: actionLog,
      conversationId: () => _current?.id,
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

  /// The user's effective IANA timezone, surfaced in the built context.
  final String? _timezone;
  late final AgentRuntime _agent;

  /// Optional persistence for chat history. When null, the assistant works
  /// exactly as before (in-memory only) — keeps tests and headless use simple.
  final ConversationRepository? _conversations;

  /// The conversation currently being viewed/edited. Null until the first user
  /// message creates one (lazy), or until [load] opens an existing one.
  Conversation? _current;
  Conversation? get currentConversation => _current;
  String? get currentConversationId => _current?.id;

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

    await _ensureConversation(trimmed);
    _messages.add(AiChatMessage.user(trimmed));
    await _persistMessage(AiMessage.user(trimmed));
    _setStatus(AiAssistantStatus.thinking, 'Thinking…');

    final token = AiCancellationToken();
    _cancelToken = token;

    try {
      final ctx = await _context.build(timezone: _timezone);
      final result = await _agent.run(
        trimmed,
        history: List.unmodifiable(_history),
        contextText: ctx.render(),
        cancelToken: token,
      );
      await _applyResult(trimmed, result);
    } catch (e) {
      _messages.add(AiChatMessage.error('Something went wrong: $e'));
      await _persistMessage(AiMessage.assistant('Something went wrong: $e'),
          isError: true);
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
    await _ensureConversation(opening);
    _messages.add(AiChatMessage.user(opening));
    await _persistMessage(AiMessage.user(opening));
    _setStatus(AiAssistantStatus.thinking, 'Thinking…');

    final token = AiCancellationToken();
    _cancelToken = token;

    try {
      final ctx = await _context.build(timezone: _timezone);
      final result = await _agent.run(
        opening,
        history: List.unmodifiable(_history),
        contextText: ctx.render(),
        extraSystemPrompt: workflow.guidance,
        cancelToken: token,
      );
      await _applyResult(opening, result);
    } catch (e) {
      _messages.add(AiChatMessage.error('Something went wrong: $e'));
      await _persistMessage(AiMessage.assistant('Something went wrong: $e'),
          isError: true);
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

  /// Clear the transcript and history and detach from the current conversation
  /// (a new one is created lazily on the next message). Alias of [newChat].
  void reset() => newChat();

  Future<void> _applyResult(String userText, AgentResult result) async {
    // Note: the user message is already appended to _messages and persisted by
    // the caller; here we only add the assistant/error side and grow _history.
    switch (result.stopReason) {
      case AgentStopReason.completed:
        final text = result.text.isEmpty ? '(no response)' : result.text;
        _messages.add(AiChatMessage.assistant(text));
        _history
          ..add(AiMessage.user(userText))
          ..add(AiMessage.assistant(result.text));
        await _persistMessage(AiMessage.assistant(result.text));
        _setStatus(AiAssistantStatus.idle, '');
        break;
      case AgentStopReason.maxIterations:
        final text = result.text.isEmpty
            ? 'I stopped after several steps without a final answer.'
            : result.text;
        _messages.add(AiChatMessage.assistant(text));
        await _persistMessage(AiMessage.assistant(text));
        _setStatus(AiAssistantStatus.idle, '');
        break;
      case AgentStopReason.cancelled:
        _messages.add(AiChatMessage.error('Cancelled.'));
        await _persistMessage(AiMessage.assistant('Cancelled.'), isError: true);
        _setStatus(AiAssistantStatus.idle, '');
        break;
      case AgentStopReason.error:
        final text =
            result.errorMessage ?? 'The assistant could not complete this.';
        _messages.add(AiChatMessage.error(text));
        await _persistMessage(AiMessage.assistant(text), isError: true);
        _setStatus(AiAssistantStatus.error, '');
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Chat-history persistence
  // ---------------------------------------------------------------------------

  /// Ensure there is a current [Conversation] before persisting a turn. Creates
  /// one lazily (title from the first user message) the first time the user
  /// sends something. No-op when persistence is disabled ([_conversations] null)
  /// or a conversation already exists.
  Future<void> _ensureConversation(String firstUserText) async {
    final repo = _conversations;
    if (repo == null || _current != null) return;
    final convo = Conversation(title: _titleFrom(firstUserText));
    await repo.createConversation(convo);
    _current = convo;
    notifyListeners();
  }

  /// Persist a single message into the current conversation and bump its
  /// updatedAt (so it sorts to the top and retention tracks last activity).
  Future<void> _persistMessage(AiMessage message, {bool isError = false}) async {
    final repo = _conversations;
    final convo = _current;
    if (repo == null || convo == null) return;
    await repo.appendMessage(
      ChatMessageRecord.fromAiMessage(convo.id, message, isError: isError),
    );
    final touched = convo.copyWith(updatedAt: DateTime.now());
    _current = touched;
    await repo.updateConversation(touched);
  }

  /// Derive a short conversation title from the first user message.
  String _titleFrom(String text) {
    final oneLine = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (oneLine.isEmpty) return 'New chat';
    return oneLine.length <= 60 ? oneLine : '${oneLine.substring(0, 57)}…';
  }

  /// Open an existing conversation: rebuild the transcript and the model-facing
  /// history from stored messages. Safe no-op while busy.
  Future<void> load(Conversation conversation) async {
    final repo = _conversations;
    if (repo == null || isBusy) return;
    final records = await repo.getMessages(conversation.id);
    _messages.clear();
    _history.clear();
    for (final r in records) {
      // Rebuild the UI transcript (user / assistant / error bubbles).
      if (r.isError) {
        _messages.add(AiChatMessage.error(r.content));
        continue; // errors are not fed back to the model
      }
      switch (r.role) {
        case AiRole.user:
          _messages.add(AiChatMessage.user(r.content));
          _history.add(r.toAiMessage());
          break;
        case AiRole.assistant:
          _messages.add(AiChatMessage.assistant(r.content));
          _history.add(r.toAiMessage());
          break;
        case AiRole.tool:
        case AiRole.system:
          // Tool/system rows are not shown as bubbles but stay in history so
          // the model sees a coherent thread.
          _history.add(r.toAiMessage());
          break;
      }
    }
    _current = conversation;
    _setStatus(AiAssistantStatus.idle, '');
  }

  /// Start a fresh conversation. Clears the transcript/history; a new
  /// [Conversation] row is created lazily on the next user message.
  void newChat() {
    _messages.clear();
    _history.clear();
    _current = null;
    _setStatus(AiAssistantStatus.idle, '');
  }

  /// Whether chat history persistence is available (a repo was injected).
  bool get historyEnabled => _conversations != null;

  /// List saved conversations (most recently updated first). Empty when
  /// persistence is disabled.
  Future<List<Conversation>> listConversations() async {
    final repo = _conversations;
    if (repo == null) return const [];
    return repo.getConversations();
  }

  /// Rename a conversation. Updates the in-memory pointer if it is the current
  /// one so the UI reflects the new title immediately.
  Future<void> renameConversation(String id, String title) async {
    final repo = _conversations;
    if (repo == null) return;
    final existing = await repo.getConversation(id);
    if (existing == null) return;
    final updated = existing.copyWith(title: title.trim());
    await repo.updateConversation(updated);
    if (_current?.id == id) _current = updated;
    notifyListeners();
  }

  /// Delete a conversation. If it is the one currently open, start a new chat.
  Future<void> deleteConversation(String id) async {
    final repo = _conversations;
    if (repo == null) return;
    await repo.deleteConversation(id);
    if (_current?.id == id) newChat();
    notifyListeners();
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
