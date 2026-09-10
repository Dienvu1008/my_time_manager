import 'ai_tool_call.dart';

/// Why generation stopped.
enum AiFinishReason {
  /// The model produced a complete response.
  stop,

  /// Generation hit the max-token limit.
  length,

  /// The model requested one or more tool calls.
  toolCalls,

  /// Generation was cancelled by the caller.
  cancelled,

  /// The provider gave a reason we do not model explicitly.
  other;

  String get wireName => name;

  static AiFinishReason fromWireName(String? value) {
    if (value == null) return AiFinishReason.other;
    return AiFinishReason.values.firstWhere(
      (r) => r.wireName == value,
      orElse: () => AiFinishReason.other,
    );
  }
}

/// Token accounting for a generation, when the provider reports it.
class AiUsage {
  const AiUsage({this.promptTokens, this.completionTokens});

  final int? promptTokens;
  final int? completionTokens;

  int? get totalTokens => (promptTokens == null && completionTokens == null)
      ? null
      : (promptTokens ?? 0) + (completionTokens ?? 0);

  Map<String, dynamic> toJson() => {
        if (promptTokens != null) 'promptTokens': promptTokens,
        if (completionTokens != null) 'completionTokens': completionTokens,
      };

  factory AiUsage.fromJson(Map<String, dynamic> json) => AiUsage(
        promptTokens: json['promptTokens'] as int?,
        completionTokens: json['completionTokens'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is AiUsage &&
      other.promptTokens == promptTokens &&
      other.completionTokens == completionTokens;

  @override
  int get hashCode => Object.hash(promptTokens, completionTokens);
}

/// A completed, provider-independent AI response.
class AiResponse {
  const AiResponse({
    this.text = '',
    this.toolCalls = const [],
    this.finishReason = AiFinishReason.stop,
    this.model,
    this.usage,
  });

  /// The generated text (may be empty when the model only requested tools).
  final String text;

  /// Tool calls the model requested (empty otherwise).
  final List<AiToolCall> toolCalls;

  final AiFinishReason finishReason;

  /// The model that produced this response, if reported.
  final String? model;

  final AiUsage? usage;

  bool get hasToolCalls => toolCalls.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (toolCalls.isNotEmpty)
          'toolCalls': toolCalls.map((c) => c.toJson()).toList(),
        'finishReason': finishReason.wireName,
        if (model != null) 'model': model,
        if (usage != null) 'usage': usage!.toJson(),
      };

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    final rawCalls = json['toolCalls'] as List<dynamic>?;
    return AiResponse(
      text: (json['text'] as String?) ?? '',
      toolCalls: rawCalls == null
          ? const []
          : rawCalls
              .map((e) => AiToolCall.fromJson(e as Map<String, dynamic>))
              .toList(),
      finishReason: AiFinishReason.fromWireName(json['finishReason'] as String?),
      model: json['model'] as String?,
      usage: json['usage'] == null
          ? null
          : AiUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() => 'AiResponse(finishReason: $finishReason, '
      'text: "${text.length > 40 ? '${text.substring(0, 40)}…' : text}", '
      'toolCalls: ${toolCalls.length})';
}
