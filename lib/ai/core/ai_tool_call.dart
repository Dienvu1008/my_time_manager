import 'dart:convert';

/// A request, produced by the model, to invoke a tool with structured
/// arguments. Provider-independent: providers parse their own tool-call shape
/// into this type before it reaches the agent.
///
/// [arguments] are already-decoded structured arguments (a JSON object). The
/// raw string form is kept in [rawArguments] because some models emit slightly
/// malformed JSON that the agent may want to inspect or repair.
class AiToolCall {
  const AiToolCall({
    required this.id,
    required this.name,
    this.arguments = const {},
    this.rawArguments,
  });

  /// A stable id for this call, used to correlate the tool result.
  final String id;

  /// The tool name the model wants to invoke.
  final String name;

  /// Parsed structured arguments. Empty when none / unparseable.
  final Map<String, dynamic> arguments;

  /// The original argument string as emitted by the model, if available. Useful
  /// for diagnosing malformed output.
  final String? rawArguments;

  /// Parse arguments from a raw JSON string, tolerating malformed input by
  /// falling back to empty arguments while preserving [rawArguments].
  factory AiToolCall.fromRawArguments({
    required String id,
    required String name,
    required String rawArguments,
  }) {
    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(rawArguments);
      parsed = decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      parsed = const {};
    }
    return AiToolCall(
      id: id,
      name: name,
      arguments: parsed,
      rawArguments: rawArguments,
    );
  }

  /// True when the raw arguments were present but could not be parsed into a
  /// JSON object. The agent uses this to reject malformed tool calls cleanly.
  bool get hasMalformedArguments =>
      rawArguments != null && rawArguments!.trim().isNotEmpty && arguments.isEmpty
          ? !_looksLikeEmptyObject(rawArguments!)
          : false;

  static bool _looksLikeEmptyObject(String s) {
    final t = s.trim();
    return t == '{}' || t.isEmpty;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arguments': arguments,
        if (rawArguments != null) 'rawArguments': rawArguments,
      };

  factory AiToolCall.fromJson(Map<String, dynamic> json) {
    return AiToolCall(
      id: json['id'] as String,
      name: json['name'] as String,
      arguments: (json['arguments'] as Map<String, dynamic>?) ?? const {},
      rawArguments: json['rawArguments'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiToolCall &&
        other.id == id &&
        other.name == name &&
        other.rawArguments == rawArguments &&
        _mapEquals(other.arguments, arguments);
  }

  @override
  int get hashCode =>
      Object.hash(id, name, rawArguments, _mapHash(arguments));

  @override
  String toString() => 'AiToolCall(id: $id, name: $name, arguments: $arguments)';
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapHash(Map<String, dynamic> m) {
  var h = 0;
  for (final entry in m.entries) {
    h ^= Object.hash(entry.key, entry.value);
  }
  return h;
}
