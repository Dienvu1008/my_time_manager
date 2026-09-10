/// Configuration for a single agent run. Provider-independent.
class AgentConfig {
  const AgentConfig({
    this.systemPrompt = _defaultSystemPrompt,
    this.model,
    this.temperature,
    this.maxIterations = 6,
    this.turnTimeout = const Duration(seconds: 60),
  }) : assert(maxIterations > 0, 'maxIterations must be positive');

  /// The system prompt that frames the agent as a time-management assistant.
  final String systemPrompt;

  /// Optional model override (else the engine/config default is used).
  final String? model;

  /// Optional sampling temperature.
  final double? temperature;

  /// Hard cap on model+tool loop iterations. Prevents infinite loops.
  final int maxIterations;

  /// Timeout applied to each model call within the loop.
  final Duration turnTimeout;

  static const String _defaultSystemPrompt =
      'You are a personal time-management assistant embedded in the My Time '
      'Manager app. You help the user manage tasks, calendar events, planned '
      'time intervals, focus sessions, and notes. Use the provided tools to '
      'read and modify real data instead of guessing. Prefer reading current '
      'state before making changes. Be concise.';

  AgentConfig copyWith({
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxIterations,
    Duration? turnTimeout,
  }) {
    return AgentConfig(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxIterations: maxIterations ?? this.maxIterations,
      turnTimeout: turnTimeout ?? this.turnTimeout,
    );
  }
}
