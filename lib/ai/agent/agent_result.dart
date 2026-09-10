import '../core/ai_message.dart';

/// Why an agent run ended.
enum AgentStopReason {
  /// The model produced a final answer with no further tool calls.
  completed,

  /// The loop hit [AgentConfig.maxIterations] without a final answer.
  maxIterations,

  /// The caller cancelled the run.
  cancelled,

  /// An unrecoverable error occurred (engine failure, timeout, …).
  error,
}

/// The outcome of an agent run.
class AgentResult {
  const AgentResult({
    required this.text,
    required this.stopReason,
    required this.iterations,
    required this.messages,
    this.errorMessage,
  });

  /// The agent's final text response (may be empty on error/cancellation).
  final String text;

  final AgentStopReason stopReason;

  /// Number of model+tool iterations performed.
  final int iterations;

  /// The full conversation transcript (system → user → assistant/tool …),
  /// useful for debugging and for continuing a session.
  final List<AiMessage> messages;

  /// Present when [stopReason] is [AgentStopReason.error].
  final String? errorMessage;

  bool get isSuccess => stopReason == AgentStopReason.completed;

  @override
  String toString() =>
      'AgentResult(stop: $stopReason, iterations: $iterations, '
      'text: "${text.length > 40 ? '${text.substring(0, 40)}…' : text}")';
}
