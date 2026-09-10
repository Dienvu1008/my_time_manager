import '../core/ai_response.dart';
import '../core/ai_tool_call.dart';
import '../tools/tool_result.dart';

/// A structured trace event emitted during an agent run, for observability and
/// debugging. Events are provider-independent and contain no secrets beyond the
/// content the caller already supplied.
sealed class AgentTraceEvent {
  const AgentTraceEvent(this.iteration);

  /// The 1-based loop iteration this event belongs to (0 = before the loop).
  final int iteration;
}

/// The run has started with the given user prompt length (not the content).
class AgentStarted extends AgentTraceEvent {
  const AgentStarted({required this.promptChars}) : super(0);
  final int promptChars;
  @override
  String toString() => 'AgentStarted(promptChars: $promptChars)';
}

/// About to call the model.
class AgentModelRequest extends AgentTraceEvent {
  const AgentModelRequest(super.iteration, {required this.messageCount, required this.toolCount});
  final int messageCount;
  final int toolCount;
  @override
  String toString() =>
      'AgentModelRequest(iter: $iteration, messages: $messageCount, tools: $toolCount)';
}

/// The model responded.
class AgentModelResponse extends AgentTraceEvent {
  const AgentModelResponse(super.iteration, this.response);
  final AiResponse response;
  @override
  String toString() => 'AgentModelResponse(iter: $iteration, $response)';
}

/// A tool is about to be executed.
class AgentToolCallStarted extends AgentTraceEvent {
  const AgentToolCallStarted(super.iteration, this.call);
  final AiToolCall call;
  @override
  String toString() => 'AgentToolCallStarted(iter: $iteration, $call)';
}

/// A tool finished executing.
class AgentToolCallFinished extends AgentTraceEvent {
  const AgentToolCallFinished(super.iteration, this.name, this.result, this.durationMs);
  final String name;
  final ToolResult result;
  final int durationMs;
  @override
  String toString() =>
      'AgentToolCallFinished(iter: $iteration, $name -> $result, ${durationMs}ms)';
}

/// The run completed (final response or a stop reason).
class AgentFinished extends AgentTraceEvent {
  const AgentFinished(super.iteration, {required this.reason, required this.durationMs});
  final String reason;
  final int durationMs;
  @override
  String toString() =>
      'AgentFinished(iter: $iteration, reason: $reason, ${durationMs}ms)';
}

/// An error occurred during the run.
class AgentError extends AgentTraceEvent {
  const AgentError(super.iteration, this.message);
  final String message;
  @override
  String toString() => 'AgentError(iter: $iteration, $message)';
}

/// Receives trace events. Defaults to a no-op; callers can supply a logger or a
/// UI stream. Kept as a simple callback to avoid a dependency.
typedef AgentTracer = void Function(AgentTraceEvent event);

/// A tracer that discards everything.
void noopTracer(AgentTraceEvent event) {}

/// A tracer that collects events into a list (handy for tests and debug views).
class CollectingTracer {
  final List<AgentTraceEvent> events = [];
  void call(AgentTraceEvent event) => events.add(event);
}
