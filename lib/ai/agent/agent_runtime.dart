import 'dart:convert';

import '../core/ai_cancellation_token.dart';
import '../core/ai_engine.dart';
import '../core/ai_exception.dart';
import '../core/ai_message.dart';
import '../core/ai_request.dart';
import '../core/ai_response.dart';
import '../core/ai_tool_call.dart';
import '../tools/tool_executor.dart';
import '../tools/tool_registry.dart';
import '../tools/tool_result.dart';
import 'agent_config.dart';
import 'agent_result.dart';
import 'agent_trace.dart';

/// A domain-specific agent for personal time management. NOT a general-purpose
/// coding agent.
///
/// It runs a controlled loop: build a request from the conversation + tool
/// definitions, ask the [AiEngine] for a response, and if the model requests
/// tools, execute them via [ToolExecutor] and feed the results back — repeating
/// until the model produces a final answer or a hard limit is hit.
///
/// Depends only on [AiEngine] + tool abstractions — it has no idea which
/// inference backend is used, and it never touches the database.
class AgentRuntime {
  AgentRuntime({
    required AiEngine engine,
    required ToolRegistry registry,
    ToolExecutor? executor,
    AgentConfig config = const AgentConfig(),
    AgentTracer tracer = noopTracer,
  })  : _engine = engine,
        _registry = registry,
        _executor = executor ?? ToolExecutor(registry),
        _config = config,
        _trace = tracer;

  final AiEngine _engine;
  final ToolRegistry _registry;
  final ToolExecutor _executor;
  final AgentConfig _config;
  final AgentTracer _trace;

  /// Run the agent on a single [userMessage]. [history] may seed prior turns.
  ///
  /// [contextText] is an optional pre-built, targeted snapshot of the user's
  /// state (from a ContextBuilder) injected as a second system message so the
  /// model starts with relevant context without dumping the database. The agent
  /// can still request more via tools.
  ///
  /// [extraSystemPrompt] is optional workflow-specific guidance appended as an
  /// additional system message (used by the Phase 12 execution workflows to
  /// frame behaviour without building a new runtime).
  Future<AgentResult> run(
    String userMessage, {
    List<AiMessage> history = const [],
    String? contextText,
    String? extraSystemPrompt,
    AiCancellationToken? cancelToken,
  }) async {
    final started = DateTime.now();
    _trace(AgentStarted(promptChars: userMessage.length));

    final messages = <AiMessage>[
      AiMessage.system(_config.systemPrompt),
      if (extraSystemPrompt != null && extraSystemPrompt.trim().isNotEmpty)
        AiMessage.system(extraSystemPrompt),
      if (contextText != null && contextText.trim().isNotEmpty)
        AiMessage.system(contextText),
      ...history,
      AiMessage.user(userMessage),
    ];
    final toolDefs = _registry.definitions;

    var iteration = 0;
    while (true) {
      if (cancelToken?.isCancelled ?? false) {
        return _finish(messages, AgentStopReason.cancelled, iteration, started);
      }
      if (iteration >= _config.maxIterations) {
        _trace(AgentFinished(iteration,
            reason: 'maxIterations',
            durationMs: _elapsedMs(started)));
        return AgentResult(
          text: _lastAssistantText(messages),
          stopReason: AgentStopReason.maxIterations,
          iterations: iteration,
          messages: messages,
        );
      }
      iteration++;

      final request = AiRequest(
        // Snapshot the conversation so the request is not mutated as the loop
        // continues to append messages.
        messages: List.unmodifiable(messages),
        model: _config.model,
        temperature: _config.temperature,
        tools: toolDefs,
      );
      _trace(AgentModelRequest(iteration,
          messageCount: messages.length, toolCount: toolDefs.length));

      final AiResponse response;
      try {
        response = await _generateWithTimeout(request, cancelToken);
      } on AiException catch (e) {
        if (e.kind == AiErrorKind.cancelled) {
          return _finish(
              messages, AgentStopReason.cancelled, iteration, started);
        }
        _trace(AgentError(iteration, e.message));
        return AgentResult(
          text: '',
          stopReason: AgentStopReason.error,
          iterations: iteration,
          messages: messages,
          errorMessage: e.message,
        );
      }
      _trace(AgentModelResponse(iteration, response));

      if (!response.hasToolCalls) {
        // Final answer.
        messages.add(AiMessage.assistant(response.text));
        _trace(AgentFinished(iteration,
            reason: 'completed', durationMs: _elapsedMs(started)));
        return AgentResult(
          text: response.text,
          stopReason: AgentStopReason.completed,
          iterations: iteration,
          messages: messages,
        );
      }

      // Record the assistant's tool-call turn, then run each tool.
      messages.add(AiMessage.assistantToolCalls(response.toolCalls));
      for (final call in response.toolCalls) {
        if (cancelToken?.isCancelled ?? false) {
          return _finish(
              messages, AgentStopReason.cancelled, iteration, started);
        }
        messages.add(await _runTool(call, iteration));
      }
      // Loop again so the model can react to the tool results.
    }
  }

  /// Execute one tool call, tracing timing, and produce a tool-result message.
  Future<AiMessage> _runTool(AiToolCall call, int iteration) async {
    _trace(AgentToolCallStarted(iteration, call));
    final sw = Stopwatch()..start();
    // The executor classifies unknown/blank tool names and malformed arguments
    // into structured failures, so this never throws.
    final result = await _executor.executeCall(call);
    sw.stop();
    _trace(AgentToolCallFinished(
        iteration, call.name, result, sw.elapsedMilliseconds));

    return AiMessage.toolResult(
      toolCallId: call.id,
      name: call.name,
      content: _encodeResult(result),
    );
  }

  Future<AiResponse> _generateWithTimeout(
    AiRequest request,
    AiCancellationToken? cancelToken,
  ) {
    final future = _engine.generate(request, cancelToken: cancelToken);
    return future.timeout(
      _config.turnTimeout,
      onTimeout: () => throw AiException.timeout(
        'The model did not respond within '
        '${_config.turnTimeout.inSeconds}s.',
      ),
    );
  }

  AgentResult _finish(
    List<AiMessage> messages,
    AgentStopReason reason,
    int iteration,
    DateTime started,
  ) {
    _trace(AgentFinished(iteration,
        reason: reason.name, durationMs: _elapsedMs(started)));
    return AgentResult(
      text: _lastAssistantText(messages),
      stopReason: reason,
      iterations: iteration,
      messages: messages,
    );
  }

  static String _encodeResult(ToolResult result) {
    // The tool result is fed back to the model as JSON text.
    return jsonEncode(result.toJson());
  }

  static String _lastAssistantText(List<AiMessage> messages) {
    for (final m in messages.reversed) {
      if (m.role == AiRole.assistant && m.content.isNotEmpty) return m.content;
    }
    return '';
  }

  int _elapsedMs(DateTime start) =>
      DateTime.now().difference(start).inMilliseconds;
}
