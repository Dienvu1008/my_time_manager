import '../../core/ai_message.dart';
import '../../core/ai_request.dart';
import '../../core/ai_response.dart';
import '../../core/ai_tool_call.dart';

/// Pure translation between the provider-independent AI types and Ollama's
/// `/api/chat` wire format. Kept free of any HTTP/IO so it can be unit-tested
/// exhaustively without a running Ollama server.
///
/// This is the ONLY place (besides the engine that uses it) that knows Ollama's
/// JSON shape. Nothing above the provider imports it.
class OllamaWire {
  const OllamaWire._();

  /// Build the JSON body for `POST /api/chat`.
  static Map<String, dynamic> chatRequestBody(
    AiRequest request, {
    required String model,
    required bool stream,
  }) {
    final options = <String, dynamic>{};
    if (request.temperature != null) {
      options['temperature'] = request.temperature;
    }
    if (request.maxTokens != null) {
      // Ollama uses `num_predict` for the max tokens to generate.
      options['num_predict'] = request.maxTokens;
    }
    if (request.stopSequences.isNotEmpty) {
      options['stop'] = request.stopSequences;
    }

    final body = <String, dynamic>{
      'model': model,
      'stream': stream,
      'messages': request.messages.map(_messageToWire).toList(),
    };
    if (options.isNotEmpty) body['options'] = options;
    if (request.tools.isNotEmpty) {
      body['tools'] = request.tools
          .map((t) => {
                'type': 'function',
                'function': {
                  'name': t.name,
                  'description': t.description,
                  'parameters': t.parametersSchema,
                },
              })
          .toList();
    }
    // Structured output: Ollama accepts a JSON schema in `format`.
    if (request.responseSchema != null) {
      body['format'] = request.responseSchema;
    }
    return body;
  }

  static Map<String, dynamic> _messageToWire(AiMessage m) {
    final wire = <String, dynamic>{
      'role': m.role.wireName,
      'content': m.content,
    };
    if (m.toolCalls.isNotEmpty) {
      wire['tool_calls'] = m.toolCalls
          .map((c) => {
                'function': {
                  'name': c.name,
                  'arguments': c.arguments,
                },
              })
          .toList();
    }
    // Ollama expects a tool message to carry the tool name.
    if (m.role == AiRole.tool && m.name != null) {
      wire['name'] = m.name;
    }
    return wire;
  }

  /// Parse a full (non-streaming) `/api/chat` response object into an
  /// [AiResponse].
  static AiResponse parseChatResponse(Map<String, dynamic> json) {
    final message = (json['message'] as Map<String, dynamic>?) ?? const {};
    final text = (message['content'] as String?) ?? '';
    final toolCalls = _parseToolCalls(message['tool_calls'] as List<dynamic>?);

    return AiResponse(
      text: text,
      toolCalls: toolCalls,
      finishReason: _finishReason(
        doneReason: json['done_reason'] as String?,
        hasToolCalls: toolCalls.isNotEmpty,
      ),
      model: json['model'] as String?,
      usage: _parseUsage(json),
    );
  }

  /// Parse a single streamed NDJSON chunk. Returns the chunk's incremental
  /// text (may be empty), any completed tool calls, and whether this is the
  /// final chunk (`done == true`).
  static OllamaStreamChunk parseStreamChunk(Map<String, dynamic> json) {
    final message = (json['message'] as Map<String, dynamic>?) ?? const {};
    return OllamaStreamChunk(
      textDelta: (message['content'] as String?) ?? '',
      toolCalls: _parseToolCalls(message['tool_calls'] as List<dynamic>?),
      done: (json['done'] as bool?) ?? false,
      doneReason: json['done_reason'] as String?,
      model: json['model'] as String?,
      usage: _parseUsage(json),
    );
  }

  static List<AiToolCall> _parseToolCalls(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final result = <AiToolCall>[];
    for (var i = 0; i < raw.length; i++) {
      final call = raw[i] as Map<String, dynamic>;
      final fn = (call['function'] as Map<String, dynamic>?) ?? const {};
      final name = (fn['name'] as String?) ?? '';
      final args = fn['arguments'];
      // Ollama usually returns arguments as an object, but some models emit a
      // JSON string. Normalise both, tolerating malformed input.
      if (args is Map<String, dynamic>) {
        result.add(AiToolCall(
          id: (call['id'] as String?) ?? 'call_$i',
          name: name,
          arguments: args,
        ));
      } else if (args is String) {
        result.add(AiToolCall.fromRawArguments(
          id: (call['id'] as String?) ?? 'call_$i',
          name: name,
          rawArguments: args,
        ));
      } else {
        result.add(AiToolCall(id: (call['id'] as String?) ?? 'call_$i', name: name));
      }
    }
    return result;
  }

  static AiUsage? _parseUsage(Map<String, dynamic> json) {
    final prompt = json['prompt_eval_count'] as int?;
    final completion = json['eval_count'] as int?;
    if (prompt == null && completion == null) return null;
    return AiUsage(promptTokens: prompt, completionTokens: completion);
  }

  static AiFinishReason _finishReason({
    required String? doneReason,
    required bool hasToolCalls,
  }) {
    if (hasToolCalls) return AiFinishReason.toolCalls;
    switch (doneReason) {
      case 'stop':
        return AiFinishReason.stop;
      case 'length':
        return AiFinishReason.length;
      case null:
        return AiFinishReason.stop;
      default:
        return AiFinishReason.other;
    }
  }

  /// Parse `GET /api/tags` into the list of installed model names.
  static List<String> parseModelTags(Map<String, dynamic> json) {
    final models = json['models'] as List<dynamic>?;
    if (models == null) return const [];
    return [
      for (final m in models)
        if ((m as Map<String, dynamic>)['name'] is String) m['name'] as String,
    ];
  }
}

/// The decoded contents of one streamed chunk.
class OllamaStreamChunk {
  const OllamaStreamChunk({
    required this.textDelta,
    required this.toolCalls,
    required this.done,
    this.doneReason,
    this.model,
    this.usage,
  });

  final String textDelta;
  final List<AiToolCall> toolCalls;
  final bool done;
  final String? doneReason;
  final String? model;
  final AiUsage? usage;
}
