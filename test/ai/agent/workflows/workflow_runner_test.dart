import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/agent/agent_result.dart';
import 'package:my_time_manager/ai/agent/agent_runtime.dart';
import 'package:my_time_manager/ai/agent/workflows/agent_workflow.dart';
import 'package:my_time_manager/ai/agent/workflows/workflow_runner.dart';
import 'package:my_time_manager/ai/core/ai_cancellation_token.dart';
import 'package:my_time_manager/ai/core/ai_capabilities.dart';
import 'package:my_time_manager/ai/core/ai_engine.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_stream_event.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';

/// Records the requests it receives and returns a fixed final answer.
class _RecordingEngine implements AiEngine {
  final List<AiRequest> received = [];
  final String answer;
  _RecordingEngine(this.answer);

  @override
  String get id => 'rec';
  @override
  AiCapabilities get capabilities => const AiCapabilities();
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<AiResponse> generate(AiRequest r, {AiCancellationToken? cancelToken}) async {
    received.add(r);
    return AiResponse(text: answer);
  }

  @override
  Stream<AiStreamEvent> stream(AiRequest r, {AiCancellationToken? cancelToken}) async* {
    yield AiStreamDone(await generate(r, cancelToken: cancelToken));
  }
}

void main() {
  test('AgentWorkflow exposes title/description/opening/guidance for each', () {
    for (final w in AgentWorkflow.values) {
      expect(w.title, isNotEmpty);
      expect(w.description, isNotEmpty);
      expect(w.openingMessage, isNotEmpty);
      expect(w.guidance, isNotEmpty);
    }
  });

  test('runner sends the opening message and injects workflow guidance', () async {
    final engine = _RecordingEngine('Here is your plan.');
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());
    final runner = WorkflowRunner(agentRuntime: agent);

    final result = await runner.run(AgentWorkflow.dailyPlanning);

    expect(result.stopReason, AgentStopReason.completed);
    expect(result.text, 'Here is your plan.');

    final req = engine.received.single;
    // messages: system(base), system(guidance), user(opening)
    final systems =
        req.messages.where((m) => m.role == AiRole.system).toList();
    expect(systems.length, greaterThanOrEqualTo(2));
    expect(systems.any((m) => m.content.contains('Daily Planning')), isTrue);
    expect(req.messages.last.role, AiRole.user);
    expect(req.messages.last.content, AgentWorkflow.dailyPlanning.openingMessage);
  });

  test('weekly review guidance marks the workflow read-only', () async {
    final engine = _RecordingEngine('Summary.');
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());
    final runner = WorkflowRunner(agentRuntime: agent);

    await runner.run(AgentWorkflow.weeklyReview);
    final guidanceMsg = engine.received.single.messages
        .firstWhere((m) => m.content.contains('Weekly Review'));
    expect(guidanceMsg.content.toLowerCase(), contains('read-only'));
  });

  test('rescheduling uses the "reorganize" opening message', () async {
    final engine = _RecordingEngine('New plan.');
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());
    final runner = WorkflowRunner(agentRuntime: agent);

    await runner.run(AgentWorkflow.rescheduling);
    expect(engine.received.single.messages.last.content,
        AgentWorkflow.rescheduling.openingMessage);
  });

  test('cancellation before run yields a cancelled result', () async {
    final engine = _RecordingEngine('unused');
    final agent = AgentRuntime(engine: engine, registry: ToolRegistry());
    final runner = WorkflowRunner(agentRuntime: agent);
    final token = AiCancellationToken()..cancel();

    final result =
        await runner.run(AgentWorkflow.dailyPlanning, cancelToken: token);
    expect(result.stopReason, AgentStopReason.cancelled);
    expect(engine.received, isEmpty);
  });
}
