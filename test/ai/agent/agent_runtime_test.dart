import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/agent/agent_config.dart';
import 'package:my_time_manager/ai/agent/agent_result.dart';
import 'package:my_time_manager/ai/agent/agent_runtime.dart';
import 'package:my_time_manager/ai/agent/agent_trace.dart';
import 'package:my_time_manager/ai/core/ai_cancellation_token.dart';
import 'package:my_time_manager/ai/core/ai_capabilities.dart';
import 'package:my_time_manager/ai/core/ai_engine.dart';
import 'package:my_time_manager/ai/core/ai_exception.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_stream_event.dart';
import 'package:my_time_manager/ai/core/ai_tool_call.dart';
import 'package:my_time_manager/ai/policy/action_policy.dart';
import 'package:my_time_manager/ai/tools/tool.dart';
import 'package:my_time_manager/ai/tools/tool_executor.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';
import 'package:my_time_manager/ai/tools/tool_result.dart';

/// A scripted engine: each call to [generate] returns the next queued response.
/// If the queue empties it keeps returning the last one (useful to force loops).
class _ScriptedEngine implements AiEngine {
  _ScriptedEngine(this._responses);
  final List<AiResponse> _responses;
  int calls = 0;
  final List<AiRequest> received = [];

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
    received.add(request);
    final i = calls < _responses.length ? calls : _responses.length - 1;
    calls++;
    return _responses[i];
  }

  @override
  Stream<AiStreamEvent> stream(AiRequest request,
      {AiCancellationToken? cancelToken}) async* {
    yield AiStreamDone(await generate(request, cancelToken: cancelToken));
  }
}

/// An engine that always throws (to test error handling).
class _FailingEngine implements AiEngine {
  @override
  String get id => 'failing';
  @override
  AiCapabilities get capabilities => const AiCapabilities();
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<AiResponse> generate(AiRequest request,
          {AiCancellationToken? cancelToken}) async =>
      throw const AiException.unavailable('down');
  @override
  Stream<AiStreamEvent> stream(AiRequest request,
          {AiCancellationToken? cancelToken}) async* {
    yield const AiStreamError('down');
  }
}

/// A simple tool that records its calls and returns a fixed result.
class _RecordingTool extends Tool {
  _RecordingTool(this._name, this._result);
  final String _name;
  final ToolResult _result;
  final List<Map<String, dynamic>> calls = [];

  @override
  String get name => _name;
  @override
  String get description => 'test tool';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    calls.add(arguments);
    return _result;
  }
}

AiToolCall _call(String name, [Map<String, dynamic> args = const {}]) =>
    AiToolCall(id: 'c_${name}_${args.hashCode}', name: name, arguments: args);

void main() {
  test('single-turn: no tool calls returns the final text', () async {
    final engine = _ScriptedEngine([const AiResponse(text: 'Hello!')]);
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());

    final result = await agent.run('hi');
    expect(result.stopReason, AgentStopReason.completed);
    expect(result.text, 'Hello!');
    expect(result.iterations, 1);
    expect(engine.calls, 1);
  });

  test('the first request carries system + user + tool definitions', () async {
    final tool = _RecordingTool('list_tasks', const ToolResult.ok([]));
    final engine = _ScriptedEngine([const AiResponse(text: 'done')]);
    final agent =
        AgentRuntime(engine: engine, registry: ToolRegistry([tool]));

    await agent.run('what are my tasks?');
    final first = engine.received.first;
    expect(first.messages.first.content, contains('time-management'));
    expect(first.messages.last.content, 'what are my tasks?');
    expect(first.tools.single.name, 'list_tasks');
  });

  test('default system prompt carries the untrusted-data rule (C8b)',
      () async {
    final engine = _ScriptedEngine([const AiResponse(text: 'ok')]);
    await AgentRuntime(engine: engine, registry: ToolRegistry()).run('hi');
    expect(engine.received.first.messages.first.content,
        contains(AgentConfig.untrustedDataRule));
  });

  test('one tool call: executes tool then returns the follow-up answer',
      () async {
    final tool = _RecordingTool('list_tasks', const ToolResult.ok({'count': 2}));
    final engine = _ScriptedEngine([
      AiResponse(finishReason: AiFinishReason.toolCalls, toolCalls: [
        _call('list_tasks', {'onlyIncomplete': true})
      ]),
      const AiResponse(text: 'You have 2 tasks.'),
    ]);
    final agent =
        AgentRuntime(engine: engine, registry: ToolRegistry([tool]));

    final result = await agent.run('how many tasks?');
    expect(result.stopReason, AgentStopReason.completed);
    expect(result.text, 'You have 2 tasks.');
    expect(tool.calls.single['onlyIncomplete'], true);
    expect(result.iterations, 2);
  });

  test('multiple tool calls in one turn are all executed', () async {
    final a = _RecordingTool('a', const ToolResult.ok(1));
    final b = _RecordingTool('b', const ToolResult.ok(2));
    final engine = _ScriptedEngine([
      AiResponse(
          finishReason: AiFinishReason.toolCalls,
          toolCalls: [_call('a'), _call('b')]),
      const AiResponse(text: 'ok'),
    ]);
    final agent =
        AgentRuntime(engine: engine, registry: ToolRegistry([a, b]));

    final result = await agent.run('do both');
    expect(a.calls, hasLength(1));
    expect(b.calls, hasLength(1));
    expect(result.text, 'ok');
  });

  test('tool failure is fed back and the agent can still finish', () async {
    final tool = _RecordingTool(
        'boom', const ToolResult.failure('domain_error', 'nope'));
    final engine = _ScriptedEngine([
      AiResponse(
          finishReason: AiFinishReason.toolCalls, toolCalls: [_call('boom')]),
      const AiResponse(text: 'Handled the failure.'),
    ]);
    final agent =
        AgentRuntime(engine: engine, registry: ToolRegistry([tool]));

    final result = await agent.run('try it');
    expect(result.stopReason, AgentStopReason.completed);
    expect(result.text, 'Handled the failure.');
    // The tool-result message fed back must contain the failure.
    final toolMsg =
        result.messages.firstWhere((m) => m.name == 'boom');
    expect(toolMsg.content, contains('domain_error'));
  });

  test('unknown tool name yields an unknown_tool result, loop continues',
      () async {
    final engine = _ScriptedEngine([
      AiResponse(
          finishReason: AiFinishReason.toolCalls,
          toolCalls: [_call('does_not_exist')]),
      const AiResponse(text: 'recovered'),
    ]);
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());

    final result = await agent.run('go');
    expect(result.text, 'recovered');
    final toolMsg =
        result.messages.firstWhere((m) => m.name == 'does_not_exist');
    expect(toolMsg.content, contains('unknown_tool'));
  });

  test('malformed tool-call arguments become an invalid_arguments result',
      () async {
    final engine = _ScriptedEngine([
      AiResponse(finishReason: AiFinishReason.toolCalls, toolCalls: [
        AiToolCall.fromRawArguments(
            id: 'c1', name: 'list_tasks', rawArguments: '{bad json'),
      ]),
      const AiResponse(text: 'ok'),
    ]);
    final tool = _RecordingTool('list_tasks', const ToolResult.ok([]));
    final agent =
        AgentRuntime(engine: engine, registry: ToolRegistry([tool]));

    final result = await agent.run('go');
    expect(result.text, 'ok');
    // The malformed call must not have reached the tool.
    expect(tool.calls, isEmpty);
    final toolMsg =
        result.messages.firstWhere((m) => m.name == 'list_tasks');
    expect(toolMsg.content, contains('invalid_arguments'));
  });

  test('max iterations stops a model that never stops calling tools', () async {
    final tool = _RecordingTool('loop', const ToolResult.ok('again'));
    // Always returns a tool call -> would loop forever without the cap.
    final engine = _ScriptedEngine([
      AiResponse(
          finishReason: AiFinishReason.toolCalls, toolCalls: [_call('loop')]),
    ]);
    final agent = AgentRuntime(
      engine: engine,
      registry: ToolRegistry([tool]),
      config: const AgentConfig(maxIterations: 3),
    );

    final result = await agent.run('loop forever');
    expect(result.stopReason, AgentStopReason.maxIterations);
    expect(result.iterations, 3);
    expect(engine.calls, 3);
  });

  test('engine error yields an error result, not a throw', () async {
    final agent = AgentRuntime(engine: _FailingEngine(), registry: ToolRegistry());
    final result = await agent.run('hi');
    expect(result.stopReason, AgentStopReason.error);
    expect(result.errorMessage, 'down');
  });

  test('cancellation before the run stops immediately', () async {
    final engine = _ScriptedEngine([const AiResponse(text: 'unused')]);
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());
    final token = AiCancellationToken()..cancel();

    final result = await agent.run('hi', cancelToken: token);
    expect(result.stopReason, AgentStopReason.cancelled);
    expect(engine.calls, 0);
  });

  test('tracer receives a coherent event sequence', () async {
    final tool = _RecordingTool('t', const ToolResult.ok(1));
    final engine = _ScriptedEngine([
      AiResponse(finishReason: AiFinishReason.toolCalls, toolCalls: [_call('t')]),
      const AiResponse(text: 'final'),
    ]);
    final tracer = CollectingTracer();
    final agent = AgentRuntime(
      engine: engine,
      registry: ToolRegistry([tool]),
      tracer: tracer.call,
    );

    await agent.run('go');
    final types = tracer.events.map((e) => e.runtimeType).toList();
    expect(types.first, AgentStarted);
    expect(types.contains(AgentToolCallStarted), isTrue);
    expect(types.contains(AgentToolCallFinished), isTrue);
    expect(types.last, AgentFinished);
  });

  test('history seeds prior turns before the new user message', () async {
    final engine = _ScriptedEngine([const AiResponse(text: 'ok')]);
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());
    await agent.run('second',
        history: const [AiMessage.assistant('first')]);
    // messages: system, assistant(first), user(second)
    final req = engine.received.first;
    expect(req.messages[1].content, 'first');
    expect(req.messages.last.content, 'second');
  });

  group('text tool-call fallback (model emits JSON as content)', () {
    test('a text JSON tool call is executed, not treated as a final answer',
        () async {
      final tool = _RecordingTool('list_tasks', const ToolResult.ok({'n': 0}));
      final engine = _ScriptedEngine([
        // Model prints the call as content instead of using tool_calls.
        const AiResponse(
            text: '{"name": "list_tasks", "arguments": {"onlyIncomplete": true}}'),
        const AiResponse(text: 'You have no open tasks.'),
      ]);
      final agent = AgentRuntime(engine: engine, registry: ToolRegistry([tool]));

      final result = await agent.run('what are my tasks?');
      expect(tool.calls.single['onlyIncomplete'], true,
          reason: 'the text-emitted call must actually run the tool');
      expect(result.text, 'You have no open tasks.');
      expect(result.iterations, 2);
    });

    test('text tool call still passes through the ActionPolicy (needs approval)',
        () async {
      // A "write" tool proposed as text must NOT run without confirmation.
      final registry = ToolRegistry([_WriteTool()]);
      final tool = registry.lookup('create_calendar_event') as _WriteTool;
      final executor = ToolExecutor(
        registry,
        policy: const ActionPolicy(), // confirmWrites
        confirm: (_) async => false, // user rejects
      );
      final engine = _ScriptedEngine([
        const AiResponse(
            text:
                '{"name": "create_calendar_event", "arguments": {"title": "ML"}}'),
        const AiResponse(text: 'Okay, I will not add it.'),
      ]);
      final agent = AgentRuntime(
          engine: engine, registry: registry, executor: executor);

      await agent.run('add my class');
      expect(tool.executed, 0,
          reason: 'a write proposed as text must still require approval');
    });

    test('text tool call runs when the user approves', () async {
      final registry = ToolRegistry([_WriteTool()]);
      final tool = registry.lookup('create_calendar_event') as _WriteTool;
      final executor = ToolExecutor(
        registry,
        policy: const ActionPolicy(),
        confirm: (_) async => true, // user approves
      );
      final engine = _ScriptedEngine([
        const AiResponse(
            text:
                '{"name": "create_calendar_event", "arguments": {"title": "ML"}}'),
        const AiResponse(text: 'Added.'),
      ]);
      final agent = AgentRuntime(
          engine: engine, registry: registry, executor: executor);

      await agent.run('add my class');
      expect(tool.executed, 1);
    });
  });
}

/// A write-risk tool that records executions.
class _WriteTool extends Tool {
  int executed = 0;
  @override
  String get name => 'create_calendar_event';
  @override
  String get description => 'create event';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    executed++;
    return const ToolResult.ok('created');
  }
}
