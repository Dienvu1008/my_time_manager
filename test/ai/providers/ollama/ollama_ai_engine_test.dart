import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_time_manager/ai/config/ai_config.dart';
import 'package:my_time_manager/ai/core/ai_cancellation_token.dart';
import 'package:my_time_manager/ai/core/ai_exception.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_stream_event.dart';
import 'package:my_time_manager/ai/providers/ollama/ollama_ai_engine.dart';

/// Engine tests using http's MockClient — no running Ollama server required.
void main() {
  const cfg = AiConfig(defaultModel: 'llama3');
  const req = AiRequest(messages: [AiMessage.user('hi')]);

  OllamaAiEngine engineReturning(
    MockClient client, {
    AiConfig config = cfg,
  }) =>
      OllamaAiEngine(config: config, client: client);

  group('isAvailable', () {
    test('true on 200 from /api/tags', () async {
      final client = MockClient((r) async {
        expect(r.url.path, '/api/tags');
        return http.Response(jsonEncode({'models': []}), 200);
      });
      expect(await engineReturning(client).isAvailable(), isTrue);
    });

    test('false on non-200', () async {
      final client = MockClient((r) async => http.Response('nope', 500));
      expect(await engineReturning(client).isAvailable(), isFalse);
    });

    test('false (never throws) on connection error', () async {
      final client = MockClient((r) async => throw Exception('refused'));
      expect(await engineReturning(client).isAvailable(), isFalse);
    });
  });

  group('generate', () {
    test('returns parsed text for a normal completion', () async {
      final client = MockClient((r) async {
        expect(r.url.path, '/api/chat');
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        expect(body['stream'], false);
        expect(body['model'], 'llama3');
        return http.Response(
          jsonEncode({
            'model': 'llama3',
            'message': {'role': 'assistant', 'content': 'Hello!'},
            'done_reason': 'stop',
          }),
          200,
        );
      });
      final resp = await engineReturning(client).generate(req);
      expect(resp.text, 'Hello!');
      expect(resp.finishReason, AiFinishReason.stop);
    });

    test('surfaces tool calls', () async {
      final client = MockClient((r) async => http.Response(
            jsonEncode({
              'message': {
                'tool_calls': [
                  {
                    'function': {
                      'name': 'list_tasks',
                      'arguments': {'limit': 5}
                    }
                  }
                ]
              }
            }),
            200,
          ));
      final resp = await engineReturning(client).generate(req);
      expect(resp.hasToolCalls, isTrue);
      expect(resp.toolCalls.single.name, 'list_tasks');
    });

    test('throws invalidRequest when no model is set anywhere', () async {
      final client = MockClient((r) async => http.Response('{}', 200));
      final engine = OllamaAiEngine(config: const AiConfig(), client: client);
      await expectLater(
        engine.generate(const AiRequest(messages: [AiMessage.user('hi')])),
        throwsA(isA<AiException>()
            .having((e) => e.kind, 'kind', AiErrorKind.invalidRequest)),
      );
    });

    test('maps 404 model-not-found', () async {
      final client = MockClient((r) async =>
          http.Response(jsonEncode({'error': 'model "llama3" not found'}), 404));
      await expectLater(
        engineReturning(client).generate(req),
        throwsA(isA<AiException>()
            .having((e) => e.kind, 'kind', AiErrorKind.modelNotFound)),
      );
    });

    test('maps other backend errors', () async {
      final client = MockClient((r) async =>
          http.Response(jsonEncode({'error': 'boom'}), 500));
      await expectLater(
        engineReturning(client).generate(req),
        throwsA(isA<AiException>()
            .having((e) => e.kind, 'kind', AiErrorKind.backend)),
      );
    });

    test('maps connection failure to unavailable', () async {
      final client = MockClient((r) async => throw Exception('refused'));
      await expectLater(
        engineReturning(client).generate(req),
        throwsA(isA<AiException>()
            .having((e) => e.kind, 'kind', AiErrorKind.unavailable)),
      );
    });

    test('throws cancelled when token already cancelled', () async {
      final client = MockClient((r) async => http.Response('{}', 200));
      final token = AiCancellationToken()..cancel();
      await expectLater(
        engineReturning(client).generate(req, cancelToken: token),
        throwsA(isA<AiException>()
            .having((e) => e.kind, 'kind', AiErrorKind.cancelled)),
      );
    });
  });

  group('stream', () {
    test('emits text deltas then a done event with assembled text', () async {
      final ndjson = [
        jsonEncode({
          'message': {'content': 'Hel'},
          'done': false
        }),
        jsonEncode({
          'message': {'content': 'lo'},
          'done': false
        }),
        jsonEncode({
          'message': {'content': ''},
          'done': true,
          'done_reason': 'stop'
        }),
      ].join('\n');

      final client = MockClient((r) async {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        expect(body['stream'], true);
        return http.Response(ndjson, 200);
      });

      final events = await engineReturning(client).stream(req).toList();
      final deltas = events.whereType<AiTextDelta>().map((e) => e.text).toList();
      expect(deltas, ['Hel', 'lo']);

      final done = events.last as AiStreamDone;
      expect(done.response.text, 'Hello');
      expect(done.response.finishReason, AiFinishReason.stop);
    });

    test('emits a tool-call event during streaming', () async {
      final ndjson = [
        jsonEncode({
          'message': {
            'tool_calls': [
              {
                'function': {
                  'name': 'create_task',
                  'arguments': {'title': 'X'}
                }
              }
            ]
          },
          'done': false
        }),
        jsonEncode({
          'message': {'content': ''},
          'done': true
        }),
      ].join('\n');
      final client = MockClient((r) async => http.Response(ndjson, 200));

      final events = await engineReturning(client).stream(req).toList();
      expect(events.whereType<AiToolCallEvent>(), hasLength(1));
      final done = events.last as AiStreamDone;
      expect(done.response.finishReason, AiFinishReason.toolCalls);
    });

    test('emits error on non-200', () async {
      final client = MockClient((r) async => http.Response('bad', 500));
      final events = await engineReturning(client).stream(req).toList();
      expect(events.single, isA<AiStreamError>());
    });

    test('emits error on connection failure', () async {
      final client = MockClient((r) async => throw Exception('refused'));
      final events = await engineReturning(client).stream(req).toList();
      expect(events.single, isA<AiStreamError>());
    });

    test('emits error on malformed chunk', () async {
      final client = MockClient((r) async => http.Response('not json\n', 200));
      final events = await engineReturning(client).stream(req).toList();
      expect(events.last, isA<AiStreamError>());
    });

    test('cancelled token yields a single error event', () async {
      final client = MockClient((r) async => http.Response('{}', 200));
      final token = AiCancellationToken()..cancel();
      final events =
          await engineReturning(client).stream(req, cancelToken: token).toList();
      expect(events.single, isA<AiStreamError>());
    });
  });
}
