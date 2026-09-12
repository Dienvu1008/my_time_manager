import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/config/ai_config.dart';
import 'package:my_time_manager/ai/core/ai_cancellation_token.dart';
import 'package:my_time_manager/ai/core/ai_capabilities.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_stream_event.dart';
import 'package:my_time_manager/ai/core/ai_tool_call.dart';
import 'package:my_time_manager/ai/core/ai_tool_definition.dart';

/// Phase 1 unit tests for the provider-independent AI abstraction. No provider
/// (Ollama/llama.cpp) is involved — these exercise data shapes, serialization,
/// and the cancellation token only.
void main() {
  group('AiMessage', () {
    test('role helpers set role + content', () {
      expect(const AiMessage.system('s').role, AiRole.system);
      expect(const AiMessage.user('u').content, 'u');
      expect(const AiMessage.assistant('a').role, AiRole.assistant);
    });

    test('json round-trip preserves a plain message', () {
      const msg = AiMessage.user('hello');
      final restored = AiMessage.fromJson(msg.toJson());
      expect(restored, msg);
    });

    test('json round-trip preserves an assistant tool-call message', () {
      const msg = AiMessage.assistantToolCalls([
        AiToolCall(id: 'c1', name: 'list_tasks', arguments: {'limit': 5}),
      ]);
      final restored = AiMessage.fromJson(msg.toJson());
      expect(restored, msg);
      expect(restored.hasToolCalls, isTrue);
      expect(restored.toolCalls.single.arguments['limit'], 5);
    });

    test('json round-trip preserves a tool result message', () {
      const msg = AiMessage.toolResult(
        toolCallId: 'c1',
        content: '{"count":3}',
        name: 'list_tasks',
      );
      final restored = AiMessage.fromJson(msg.toJson());
      expect(restored, msg);
      expect(restored.role, AiRole.tool);
      expect(restored.toolCallId, 'c1');
    });

    test('fromWireName rejects an unknown role', () {
      expect(() => AiRole.fromWireName('robot'), throwsArgumentError);
    });
  });

  group('AiToolCall', () {
    test('parses valid raw JSON arguments', () {
      final call = AiToolCall.fromRawArguments(
        id: 'c1',
        name: 'create_task',
        rawArguments: '{"title":"Write report","important":true}',
      );
      expect(call.arguments['title'], 'Write report');
      expect(call.arguments['important'], true);
      expect(call.hasMalformedArguments, isFalse);
    });

    test('tolerates malformed JSON and flags it', () {
      final call = AiToolCall.fromRawArguments(
        id: 'c1',
        name: 'create_task',
        rawArguments: '{title: not json',
      );
      expect(call.arguments, isEmpty);
      expect(call.hasMalformedArguments, isTrue);
    });

    test('empty-object raw args are not flagged as malformed', () {
      final call = AiToolCall.fromRawArguments(
        id: 'c1',
        name: 'ping',
        rawArguments: '{}',
      );
      expect(call.arguments, isEmpty);
      expect(call.hasMalformedArguments, isFalse);
    });

    test('json round-trip', () {
      const call = AiToolCall(id: 'c1', name: 'x', arguments: {'a': 1});
      expect(AiToolCall.fromJson(call.toJson()), call);
    });
  });

  group('AiCapabilities', () {
    test('json round-trip', () {
      const caps = AiCapabilities(
        streaming: true,
        toolCalling: true,
        structuredOutput: true,
        contextLength: 8192,
      );
      expect(AiCapabilities.fromJson(caps.toJson()), caps);
    });
  });

  group('AiToolDefinition', () {
    test('json round-trip preserves schema', () {
      const def = AiToolDefinition(
        name: 'create_task',
        description: 'Create a task',
        parametersSchema: {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'}
          },
          'required': ['title'],
        },
      );
      final restored = AiToolDefinition.fromJson(def.toJson());
      expect(restored.name, 'create_task');
      expect(restored.parametersSchema['required'], ['title']);
    });
  });

  group('AiRequest', () {
    test('json round-trip preserves messages, tools, and params', () {
      const req = AiRequest(
        messages: [
          AiMessage.system('You are a planner.'),
          AiMessage.user('Plan my day.'),
        ],
        model: 'llama3',
        temperature: 0.2,
        maxTokens: 512,
        stopSequences: ['</end>'],
        tools: [
          AiToolDefinition(name: 'list_tasks', description: 'List tasks'),
        ],
        responseSchema: {'type': 'object'},
      );
      final restored = AiRequest.fromJson(req.toJson());
      expect(restored.messages.length, 2);
      expect(restored.model, 'llama3');
      expect(restored.temperature, 0.2);
      expect(restored.maxTokens, 512);
      expect(restored.stopSequences, ['</end>']);
      expect(restored.tools.single.name, 'list_tasks');
      expect(restored.wantsToolCalling, isTrue);
      expect(restored.wantsStructuredOutput, isTrue);
    });

    test('addMessage appends without mutating the original', () {
      const req = AiRequest(messages: [AiMessage.user('hi')]);
      final next = req.addMessage(const AiMessage.assistant('hello'));
      expect(req.messages.length, 1);
      expect(next.messages.length, 2);
      expect(next.messages.last.role, AiRole.assistant);
    });

    test('defaults: no tools, no structured output', () {
      const req = AiRequest(messages: [AiMessage.user('hi')]);
      expect(req.wantsToolCalling, isFalse);
      expect(req.wantsStructuredOutput, isFalse);
    });
  });

  group('AiResponse', () {
    test('json round-trip with tool calls and usage', () {
      const resp = AiResponse(
        text: '',
        toolCalls: [AiToolCall(id: 'c1', name: 'list_tasks')],
        finishReason: AiFinishReason.toolCalls,
        model: 'llama3',
        usage: AiUsage(promptTokens: 10, completionTokens: 5),
      );
      final restored = AiResponse.fromJson(resp.toJson());
      expect(restored.hasToolCalls, isTrue);
      expect(restored.finishReason, AiFinishReason.toolCalls);
      expect(restored.usage!.totalTokens, 15);
      expect(restored.model, 'llama3');
    });

    test('unknown finish reason maps to other', () {
      final resp = AiResponse.fromJson({'text': 'hi', 'finishReason': 'weird'});
      expect(resp.finishReason, AiFinishReason.other);
    });
  });

  group('AiStreamEvent', () {
    test('text deltas compare by content', () {
      expect(const AiTextDelta('a'), const AiTextDelta('a'));
      expect(const AiTextDelta('a'), isNot(const AiTextDelta('b')));
    });

    test('done carries the assembled response', () {
      const done = AiStreamDone(AiResponse(text: 'final'));
      expect(done.response.text, 'final');
    });

    test('error carries a message', () {
      const err = AiStreamError('boom');
      expect(err.message, 'boom');
    });
  });

  group('AiCancellationToken', () {
    test('starts not cancelled, becomes cancelled once', () {
      final token = AiCancellationToken();
      expect(token.isCancelled, isFalse);
      token.cancel();
      expect(token.isCancelled, isTrue);
      token.cancel(); // idempotent, must not throw
      expect(token.isCancelled, isTrue);
    });

    test('whenCancelled completes on cancel', () async {
      final token = AiCancellationToken();
      var completed = false;
      final f = token.whenCancelled.then((_) => completed = true);
      token.cancel();
      await f;
      expect(completed, isTrue);
    });

    test('guard runs only when not cancelled', () {
      final token = AiCancellationToken();
      expect(token.guard(() => 42), 42);
      token.cancel();
      expect(token.guard(() => 42), isNull);
    });
  });

  group('AiConfig', () {
    test('defaults are local-first Ollama with the conventional endpoint', () {
      const cfg = AiConfig();
      expect(cfg.provider, AiProviderKind.ollama);
      expect(cfg.mode, AiMode.localOnly);
      expect(cfg.allowsCloud, isFalse);
      expect(cfg.effectiveEndpoint, AiConfig.defaultOllamaEndpoint);
    });

    test('endpoint override wins over provider default', () {
      const cfg = AiConfig(endpoint: 'http://192.168.1.10:11434');
      expect(cfg.effectiveEndpoint, 'http://192.168.1.10:11434');
    });

    test('llamaCpp / cloud have no default endpoint', () {
      expect(const AiConfig(provider: AiProviderKind.llamaCpp).effectiveEndpoint,
          isNull);
      expect(const AiConfig(provider: AiProviderKind.cloud).effectiveEndpoint,
          isNull);
    });

    test('hybrid and cloudOptional allow cloud', () {
      expect(const AiConfig(mode: AiMode.hybrid).allowsCloud, isTrue);
      expect(const AiConfig(mode: AiMode.cloudOptional).allowsCloud, isTrue);
    });

    test('json round-trip (incl. timezone)', () {
      const cfg = AiConfig(
        provider: AiProviderKind.ollama,
        mode: AiMode.hybrid,
        defaultModel: 'llama3',
        endpoint: 'http://localhost:11434',
        requestTimeout: Duration(seconds: 30),
        timezone: 'Asia/Ho_Chi_Minh',
      );
      final restored = AiConfig.fromJson(cfg.toJson());
      expect(restored, cfg);
      expect(restored.timezone, 'Asia/Ho_Chi_Minh');
    });

    test('timezone defaults to null (device) and round-trips as absent', () {
      const cfg = AiConfig();
      expect(cfg.timezone, isNull);
      expect(cfg.toJson().containsKey('timezone'), isFalse);
      expect(AiConfig.fromJson(cfg.toJson()).timezone, isNull);
    });

    test('copyWith sets and clears the timezone', () {
      const cfg = AiConfig(timezone: 'Europe/Paris');
      expect(cfg.copyWith(timezone: 'Asia/Tokyo').timezone, 'Asia/Tokyo');
      expect(cfg.copyWith(clearTimezone: true).timezone, isNull);
      // Not passing it leaves it unchanged.
      expect(cfg.copyWith(defaultModel: 'm').timezone, 'Europe/Paris');
    });

    test('chatHistoryRetentionDays defaults to null and round-trips', () {
      const cfg = AiConfig();
      expect(cfg.chatHistoryRetentionDays, isNull);
      expect(cfg.toJson().containsKey('chatHistoryRetentionDays'), isFalse);

      const withRetention = AiConfig(chatHistoryRetentionDays: 30);
      final restored = AiConfig.fromJson(withRetention.toJson());
      expect(restored.chatHistoryRetentionDays, 30);
      expect(restored, withRetention);
    });

    test('copyWith sets and clears chatHistoryRetentionDays', () {
      const cfg = AiConfig(chatHistoryRetentionDays: 30);
      expect(cfg.copyWith(chatHistoryRetentionDays: 90).chatHistoryRetentionDays,
          90);
      expect(cfg.copyWith(clearChatHistoryRetentionDays: true)
          .chatHistoryRetentionDays, isNull);
    });
  });
}
