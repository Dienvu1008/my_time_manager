/// What an AI engine/model can do. Providers expose this so higher layers (and
/// the future platform routing in Phase 10) can pick an appropriate backend
/// without knowing which one it is.
class AiCapabilities {
  const AiCapabilities({
    this.streaming = false,
    this.toolCalling = false,
    this.structuredOutput = false,
    this.systemMessages = true,
    this.contextLength,
  });

  /// The engine can stream tokens as they are generated.
  final bool streaming;

  /// The engine supports structured tool/function calling.
  final bool toolCalling;

  /// The engine can be constrained to emit structured (JSON) output.
  final bool structuredOutput;

  /// The engine honors a dedicated system message role.
  final bool systemMessages;

  /// Maximum context window in tokens, if known (null = unknown).
  final int? contextLength;

  AiCapabilities copyWith({
    bool? streaming,
    bool? toolCalling,
    bool? structuredOutput,
    bool? systemMessages,
    int? contextLength,
  }) {
    return AiCapabilities(
      streaming: streaming ?? this.streaming,
      toolCalling: toolCalling ?? this.toolCalling,
      structuredOutput: structuredOutput ?? this.structuredOutput,
      systemMessages: systemMessages ?? this.systemMessages,
      contextLength: contextLength ?? this.contextLength,
    );
  }

  Map<String, dynamic> toJson() => {
        'streaming': streaming,
        'toolCalling': toolCalling,
        'structuredOutput': structuredOutput,
        'systemMessages': systemMessages,
        if (contextLength != null) 'contextLength': contextLength,
      };

  factory AiCapabilities.fromJson(Map<String, dynamic> json) {
    return AiCapabilities(
      streaming: (json['streaming'] as bool?) ?? false,
      toolCalling: (json['toolCalling'] as bool?) ?? false,
      structuredOutput: (json['structuredOutput'] as bool?) ?? false,
      systemMessages: (json['systemMessages'] as bool?) ?? true,
      contextLength: json['contextLength'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiCapabilities &&
        other.streaming == streaming &&
        other.toolCalling == toolCalling &&
        other.structuredOutput == structuredOutput &&
        other.systemMessages == systemMessages &&
        other.contextLength == contextLength;
  }

  @override
  int get hashCode => Object.hash(
      streaming, toolCalling, structuredOutput, systemMessages, contextLength);

  @override
  String toString() => 'AiCapabilities(streaming: $streaming, '
      'toolCalling: $toolCalling, structuredOutput: $structuredOutput, '
      'systemMessages: $systemMessages, contextLength: $contextLength)';
}
