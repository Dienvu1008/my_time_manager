import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_tool_call.dart';
import 'package:my_time_manager/ai/core/ai_tool_definition.dart';
import 'package:my_time_manager/ai/providers/ollama/ollama_wire.dart';

/// Pure wire-mapping tests for the Ollama provider. No HTTP, no server.
void main() {
  group('chatRequestBody', () {
    test('maps messages, model, stream flag', () {
      const req = AiRequest(messages: [
        AiMessage.system('You are a planner.'),
        AiMessage.user('Plan my day.'),
      ]);
      final body =
          OllamaWire.chatRequestBody(req, model: 'llama3', stream: true);

      expect(body['model'], 'llama3');
      expect(body['stream'], true);
      final messages = body['messages'] as List;
      expect(messages, hasLength(2));
      expect((messages.first as Map)['role'], 'system');
      expect((messages.last as Map)['content'], 'Plan my day.');
    });

    test('maps temperature/maxTokens/stop into options', () {
      const req = AiRequest(
        messages: [AiMessage.user('hi')],
        temperature: 0.3,
        maxTokens: 256,
        stopSequences: ['STOP'],
      );
      final body =
          OllamaWire.chatRequestBody(req, model: 'm', stream: false);
      final options = body['options'] as Map<String, dynamic>;
      expect(options['temperature'], 0.3);
      expect(options['num_predict'], 256);
      expect(options['stop'], ['STOP']);
    });

    test('omits options when none are set', () {
      const req = AiRequest(messages: [AiMessage.user('hi')]);
      final body = OllamaWire.chatRequestBody(req, model: 'm', stream: false);
      expect(body.containsKey('options'), isFalse);
    });

    test('maps tools into function-calling shape', () {
      const req = AiRequest(
        messages: [AiMessage.user('list my tasks')],
        tools: [
          AiToolDefinition(
            name: 'list_tasks',
            description: 'List tasks',
            parametersSchema: {
              'type': 'object',
              'properties': {
                'limit': {'type': 'integer'}
              },
            },
          ),
        ],
      );
      final body = OllamaWire.chatRequestBody(req, model: 'm', stream: false);
      final tools = body['tools'] as List;
      expect(tools, hasLength(1));
      final fn = (tools.first as Map)['function'] as Map;
      expect((tools.first as Map)['type'], 'function');
      expect(fn['name'], 'list_tasks');
      expect((fn['parameters'] as Map)['type'], 'object');
    });

    test('maps responseSchema into format', () {
      const req = AiRequest(
        messages: [AiMessage.user('hi')],
        responseSchema: {'type': 'object'},
      );
      final body = OllamaWire.chatRequestBody(req, model: 'm', stream: false);
      expect(body['format'], {'type': 'object'});
    });

    test('maps an assistant tool-call and a tool result message', () {
      const req = AiRequest(messages: [
        AiMessage.assistantToolCalls([
          AiToolCall(id: 'c1', name: 'list_tasks', arguments: {'limit': 3}),
        ]),
        AiMessage.toolResult(
            toolCallId: 'c1', content: '[]', name: 'list_tasks'),
      ]);
      final body = OllamaWire.chatRequestBody(req, model: 'm', stream: false);
      final messages = body['messages'] as List;

      final assistant = messages.first as Map;
      final call = (assistant['tool_calls'] as List).first as Map;
      expect((call['function'] as Map)['name'], 'list_tasks');
      expect((call['function'] as Map)['arguments'], {'limit': 3});

      final toolMsg = messages.last as Map;
      expect(toolMsg['role'], 'tool');
      expect(toolMsg['name'], 'list_tasks');
      expect(toolMsg['content'], '[]');
    });
  });

  group('parseChatResponse', () {
    test('parses plain text with usage and stop reason', () {
      final resp = OllamaWire.parseChatResponse({
        'model': 'llama3',
        'message': {'role': 'assistant', 'content': 'Hello there.'},
        'done_reason': 'stop',
        'prompt_eval_count': 12,
        'eval_count': 7,
      });
      expect(resp.text, 'Hello there.');
      expect(resp.finishReason, AiFinishReason.stop);
      expect(resp.model, 'llama3');
      expect(resp.usage!.promptTokens, 12);
      expect(resp.usage!.completionTokens, 7);
      expect(resp.hasToolCalls, isFalse);
    });

    test('parses tool calls with object arguments', () {
      final resp = OllamaWire.parseChatResponse({
        'message': {
          'role': 'assistant',
          'content': '',
          'tool_calls': [
            {
              'function': {
                'name': 'create_task',
                'arguments': {'title': 'Write report'}
              }
            }
          ]
        },
      });
      expect(resp.finishReason, AiFinishReason.toolCalls);
      expect(resp.toolCalls.single.name, 'create_task');
      expect(resp.toolCalls.single.arguments['title'], 'Write report');
    });

    test('parses tool call whose arguments are a JSON string', () {
      final resp = OllamaWire.parseChatResponse({
        'message': {
          'tool_calls': [
            {
              'function': {
                'name': 'complete_task',
                'arguments': '{"id":"t1"}'
              }
            }
          ]
        },
      });
      expect(resp.toolCalls.single.arguments['id'], 't1');
    });

    test('length done_reason maps to length', () {
      final resp = OllamaWire.parseChatResponse({
        'message': {'content': 'partial'},
        'done_reason': 'length',
      });
      expect(resp.finishReason, AiFinishReason.length);
    });
  });

  group('parseStreamChunk', () {
    test('parses an incremental text chunk that is not done', () {
      final chunk = OllamaWire.parseStreamChunk({
        'model': 'llama3',
        'message': {'role': 'assistant', 'content': 'Hel'},
        'done': false,
      });
      expect(chunk.textDelta, 'Hel');
      expect(chunk.done, isFalse);
      expect(chunk.model, 'llama3');
    });

    test('parses the final chunk with done + reason', () {
      final chunk = OllamaWire.parseStreamChunk({
        'message': {'content': ''},
        'done': true,
        'done_reason': 'stop',
        'eval_count': 5,
      });
      expect(chunk.done, isTrue);
      expect(chunk.doneReason, 'stop');
      expect(chunk.usage!.completionTokens, 5);
    });
  });

  group('parseModelTags', () {
    test('extracts model names', () {
      final names = OllamaWire.parseModelTags({
        'models': [
          {'name': 'llama3:latest'},
          {'name': 'qwen2.5:7b'},
        ]
      });
      expect(names, ['llama3:latest', 'qwen2.5:7b']);
    });

    test('empty when no models key', () {
      expect(OllamaWire.parseModelTags({}), isEmpty);
    });
  });
}
