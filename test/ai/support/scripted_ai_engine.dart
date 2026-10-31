import 'dart:convert';

import 'package:my_time_manager/ai/agent/agent_result.dart';
import 'package:my_time_manager/ai/core/ai_cancellation_token.dart';
import 'package:my_time_manager/ai/core/ai_capabilities.dart';
import 'package:my_time_manager/ai/core/ai_engine.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_stream_event.dart';
import 'package:my_time_manager/ai/core/ai_tool_call.dart';

/// Reusable evaluation-harness engine (Phase C8b): replays a scripted
/// sequence of [AiResponse]s — final texts, structured tool calls, or tool
/// calls written as JSON text (recovered by `TextToolCallParser`) — and
/// records every [AiRequest]. Once the script is exhausted it answers with
/// [fallbackText] (no tool calls) so the agent loop ends. Needs no Ollama /
/// llama.cpp.
class ScriptedAiEngine implements AiEngine {
  ScriptedAiEngine(List<AiResponse> script, {this.fallbackText = 'Done.'})
      : _script = List.of(script);

  final List<AiResponse> _script;
  final String fallbackText;
  final List<AiRequest> requests = [];
  int _next = 0;

  static int _ids = 0;

  /// A response with one structured tool call.
  static AiResponse toolCall(String name, Map<String, dynamic> args,
          {String? id}) =>
      AiResponse(
        finishReason: AiFinishReason.toolCalls,
        toolCalls: [
          AiToolCall(id: id ?? 'call_${_ids++}', name: name, arguments: args)
        ],
      );

  /// A response whose TEXT is a JSON tool call and has no structured calls.
  static AiResponse textToolCall(String name, Map<String, dynamic> args) =>
      AiResponse(text: jsonEncode({'name': name, 'arguments': args}));

  /// A plain final answer.
  static AiResponse say(String text) => AiResponse(text: text);

  @override
  String get id => 'scripted';

  @override
  AiCapabilities get capabilities =>
      const AiCapabilities(toolCalling: true, streaming: true);

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<AiResponse> generate(AiRequest request,
      {AiCancellationToken? cancelToken}) async {
    requests.add(request);
    if (_next < _script.length) return _script[_next++];
    return AiResponse(text: fallbackText);
  }

  @override
  Stream<AiStreamEvent> stream(AiRequest request,
      {AiCancellationToken? cancelToken}) async* {
    yield AiStreamDone(await generate(request, cancelToken: cancelToken));
  }
}

/// Decoded tool-result messages of a run, in order, as
/// `{'name': toolName, 'result': ToolResult.toJson()}`.
List<Map<String, dynamic>> toolResultsOf(AgentResult r) => [
      for (final m in r.messages)
        if (m.role == AiRole.tool)
          {
            'name': m.name,
            'result': jsonDecode(m.content) as Map<String, dynamic>,
          },
    ];
