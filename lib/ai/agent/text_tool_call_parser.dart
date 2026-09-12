import 'dart:convert';

import '../core/ai_tool_call.dart';

/// Parses tool calls that a model emitted as TEXT instead of via the backend's
/// structured tool-call field.
///
/// Many local models (especially smaller ones through Ollama) don't populate
/// `message.tool_calls`; they just print JSON like
/// `{"name": "create_calendar_event", "arguments": {...}}` in the content. This
/// parser recognizes that shape so the agent can still route it through the
/// normal execute → policy → confirm flow.
///
/// It is deliberately conservative: it only returns a call when the extracted
/// JSON has a string `name` that is one of [knownToolNames]. Otherwise it
/// returns null and the text is treated as a normal answer.
class TextToolCallParser {
  const TextToolCallParser(this.knownToolNames);

  final Set<String> knownToolNames;

  /// Try to extract tool calls from [text]. Returns an empty list when none are
  /// found (i.e. the text is a normal answer).
  List<AiToolCall> parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];

    final candidates = <Map<String, dynamic>>[];

    // 1) The whole message is a JSON object or array of calls.
    _collectFromJsonString(trimmed, candidates);

    // 2) JSON inside fenced code blocks ```...``` or ```json ... ```.
    for (final block in _extractCodeFences(trimmed)) {
      _collectFromJsonString(block, candidates);
    }

    // 3) A JSON object embedded somewhere in surrounding prose.
    if (candidates.isEmpty) {
      for (final obj in _extractBalancedObjects(trimmed)) {
        _collectFromJsonString(obj, candidates);
      }
    }

    final calls = <AiToolCall>[];
    var i = 0;
    for (final map in candidates) {
      final call = _toCall(map, i);
      if (call != null) {
        calls.add(call);
        i++;
      }
    }
    return calls;
  }

  /// Decode [s] as JSON; add any object that looks like a call (single object,
  /// or a list of objects, or an object wrapping a list under common keys).
  void _collectFromJsonString(String s, List<Map<String, dynamic>> out) {
    dynamic decoded;
    try {
      decoded = jsonDecode(s);
    } catch (_) {
      return;
    }
    _collectFromDecoded(decoded, out);
  }

  void _collectFromDecoded(dynamic decoded, List<Map<String, dynamic>> out) {
    if (decoded is Map<String, dynamic>) {
      // Some models wrap calls: {"tool_calls": [...]} or {"tool": {...}}.
      final wrapped = decoded['tool_calls'] ?? decoded['toolCalls'];
      if (wrapped is List) {
        for (final e in wrapped) {
          _collectFromDecoded(e, out);
        }
        return;
      }
      out.add(decoded);
    } else if (decoded is List) {
      for (final e in decoded) {
        if (e is Map<String, dynamic>) out.add(e);
      }
    }
  }

  /// Turn a decoded map into an [AiToolCall] if it names a known tool.
  AiToolCall? _toCall(Map<String, dynamic> map, int index) {
    // Accept both {name, arguments} and the function-style
    // {function: {name, arguments}} shape.
    final fn = map['function'];
    final source = fn is Map<String, dynamic> ? fn : map;

    final name = source['name'];
    if (name is! String || !knownToolNames.contains(name)) return null;

    final args = source['arguments'] ?? source['parameters'] ?? source['args'];
    if (args is Map<String, dynamic>) {
      return AiToolCall(id: 'text_call_$index', name: name, arguments: args);
    }
    if (args is String) {
      return AiToolCall.fromRawArguments(
        id: 'text_call_$index',
        name: name,
        rawArguments: args,
      );
    }
    // No arguments provided.
    return AiToolCall(id: 'text_call_$index', name: name);
  }

  /// Extract contents of ```...``` fenced blocks (optionally ```json).
  List<String> _extractCodeFences(String text) {
    final result = <String>[];
    final pattern = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    for (final m in pattern.allMatches(text)) {
      final inner = m.group(1);
      if (inner != null && inner.trim().isNotEmpty) result.add(inner.trim());
    }
    return result;
  }

  /// Find top-level balanced `{...}` substrings in [text] (brace-matched, so it
  /// tolerates nested objects). Returns them longest-first is not needed; order
  /// as found is fine.
  List<String> _extractBalancedObjects(String text) {
    final objects = <String>[];
    var depth = 0;
    var start = -1;
    var inString = false;
    var escape = false;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (c == r'\') {
          escape = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (c == '}') {
        if (depth > 0) {
          depth--;
          if (depth == 0 && start >= 0) {
            objects.add(text.substring(start, i + 1));
            start = -1;
          }
        }
      }
    }
    return objects;
  }
}
