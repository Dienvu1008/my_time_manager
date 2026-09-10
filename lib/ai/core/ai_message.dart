import 'ai_tool_call.dart';

/// Who authored a message in a conversation.
enum AiRole {
  system,
  user,
  assistant,
  tool;

  String get wireName => name;

  static AiRole fromWireName(String value) {
    return AiRole.values.firstWhere(
      (r) => r.wireName == value,
      orElse: () => throw ArgumentError('Unknown AiRole: $value'),
    );
  }
}

/// A single message in an AI conversation, provider-independent.
///
/// This type deliberately knows nothing about any backend (Ollama, llama.cpp,
/// cloud). Providers translate it to their own wire format. It supports the
/// four roles plus the two tool-related shapes used by the agent loop:
///
/// - an **assistant** message may carry [toolCalls] (the model asking to run
///   tools);
/// - a **tool** message carries [toolCallId] + [content] (the result handed
///   back to the model).
class AiMessage {
  const AiMessage({
    required this.role,
    this.content = '',
    this.toolCalls = const [],
    this.toolCallId,
    this.name,
  });

  /// Convenience constructors for the common cases.
  const AiMessage.system(String content)
      : this(role: AiRole.system, content: content);
  const AiMessage.user(String content)
      : this(role: AiRole.user, content: content);
  const AiMessage.assistant(String content)
      : this(role: AiRole.assistant, content: content);

  /// An assistant turn that requests one or more tool calls.
  const AiMessage.assistantToolCalls(List<AiToolCall> toolCalls)
      : this(role: AiRole.assistant, toolCalls: toolCalls);

  /// A tool result fed back into the conversation.
  const AiMessage.toolResult({
    required String toolCallId,
    required String content,
    String? name,
  }) : this(
          role: AiRole.tool,
          content: content,
          toolCallId: toolCallId,
          name: name,
        );

  final AiRole role;

  /// Plain-text content. Empty for an assistant message that only carries
  /// [toolCalls].
  final String content;

  /// Tool calls requested by an assistant message (empty otherwise).
  final List<AiToolCall> toolCalls;

  /// For a [AiRole.tool] message, the id of the tool call this result answers.
  final String? toolCallId;

  /// Optional name (e.g. the tool name for a tool message). May be null.
  final String? name;

  bool get hasToolCalls => toolCalls.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'role': role.wireName,
        'content': content,
        if (toolCalls.isNotEmpty)
          'toolCalls': toolCalls.map((c) => c.toJson()).toList(),
        if (toolCallId != null) 'toolCallId': toolCallId,
        if (name != null) 'name': name,
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    final rawCalls = json['toolCalls'] as List<dynamic>?;
    return AiMessage(
      role: AiRole.fromWireName(json['role'] as String),
      content: (json['content'] as String?) ?? '',
      toolCalls: rawCalls == null
          ? const []
          : rawCalls
              .map((e) => AiToolCall.fromJson(e as Map<String, dynamic>))
              .toList(),
      toolCallId: json['toolCallId'] as String?,
      name: json['name'] as String?,
    );
  }

  AiMessage copyWith({
    AiRole? role,
    String? content,
    List<AiToolCall>? toolCalls,
    String? toolCallId,
    String? name,
  }) {
    return AiMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiMessage &&
        other.role == role &&
        other.content == content &&
        _listEquals(other.toolCalls, toolCalls) &&
        other.toolCallId == toolCallId &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(
        role,
        content,
        Object.hashAll(toolCalls),
        toolCallId,
        name,
      );

  @override
  String toString() =>
      'AiMessage(role: $role, content: "$content", toolCalls: $toolCalls)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
