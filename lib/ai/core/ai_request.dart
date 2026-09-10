import 'ai_message.dart';
import 'ai_tool_definition.dart';

/// A provider-independent request to an [AiEngine].
///
/// It carries the conversation, the target model, decoding parameters, the
/// tools the model may call, and an optional response JSON-schema for structured
/// output. Providers translate this into their own API shape; nothing here is
/// specific to Ollama, llama.cpp, or any cloud vendor.
class AiRequest {
  const AiRequest({
    required this.messages,
    this.model,
    this.temperature,
    this.maxTokens,
    this.stopSequences = const [],
    this.tools = const [],
    this.responseSchema,
  });

  /// The conversation so far (system/user/assistant/tool messages).
  final List<AiMessage> messages;

  /// The model identifier to use. Null lets the engine/provider use its
  /// configured default.
  final String? model;

  /// Sampling temperature (provider clamps to its own valid range). Null = use
  /// the provider default.
  final double? temperature;

  /// Maximum number of tokens to generate. Null = provider default.
  final int? maxTokens;

  /// Sequences that, if generated, stop the output.
  final List<String> stopSequences;

  /// Tools the model is allowed to call this turn (empty = no tool calling).
  final List<AiToolDefinition> tools;

  /// A JSON-Schema object requesting structured output. Null = free-form text.
  final Map<String, dynamic>? responseSchema;

  bool get wantsToolCalling => tools.isNotEmpty;
  bool get wantsStructuredOutput => responseSchema != null;

  AiRequest copyWith({
    List<AiMessage>? messages,
    String? model,
    double? temperature,
    int? maxTokens,
    List<String>? stopSequences,
    List<AiToolDefinition>? tools,
    Map<String, dynamic>? responseSchema,
  }) {
    return AiRequest(
      messages: messages ?? this.messages,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      stopSequences: stopSequences ?? this.stopSequences,
      tools: tools ?? this.tools,
      responseSchema: responseSchema ?? this.responseSchema,
    );
  }

  /// Returns a copy with [message] appended — handy for the agent loop.
  AiRequest addMessage(AiMessage message) =>
      copyWith(messages: [...messages, message]);

  Map<String, dynamic> toJson() => {
        'messages': messages.map((m) => m.toJson()).toList(),
        if (model != null) 'model': model,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'maxTokens': maxTokens,
        if (stopSequences.isNotEmpty) 'stopSequences': stopSequences,
        if (tools.isNotEmpty) 'tools': tools.map((t) => t.toJson()).toList(),
        if (responseSchema != null) 'responseSchema': responseSchema,
      };

  factory AiRequest.fromJson(Map<String, dynamic> json) {
    final rawTools = json['tools'] as List<dynamic>?;
    final rawStops = json['stopSequences'] as List<dynamic>?;
    return AiRequest(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => AiMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      model: json['model'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      maxTokens: json['maxTokens'] as int?,
      stopSequences:
          rawStops == null ? const [] : rawStops.cast<String>(),
      tools: rawTools == null
          ? const []
          : rawTools
              .map((e) => AiToolDefinition.fromJson(e as Map<String, dynamic>))
              .toList(),
      responseSchema: json['responseSchema'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() =>
      'AiRequest(model: $model, messages: ${messages.length}, '
      'tools: ${tools.length}, structured: $wantsStructuredOutput)';
}
