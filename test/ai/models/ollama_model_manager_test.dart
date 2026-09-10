import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_time_manager/ai/config/ai_config.dart';
import 'package:my_time_manager/ai/config/ai_config_service.dart';
import 'package:my_time_manager/ai/models/model_info.dart';
import 'package:my_time_manager/ai/models/ollama_model_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cfg = AiConfig();

  OllamaModelManager manager(MockClient client, {AiConfigService? svc}) =>
      OllamaModelManager(config: cfg, client: client, configService: svc);

  group('list', () {
    test('maps /api/tags to installed ModelInfo', () async {
      final client = MockClient((r) async {
        expect(r.url.path, '/api/tags');
        return http.Response(
          jsonEncode({
            'models': [
              {'name': 'llama3:latest'},
              {'name': 'qwen2.5:7b'},
            ]
          }),
          200,
        );
      });
      final models = await manager(client).list();
      expect(models.map((m) => m.id), ['llama3:latest', 'qwen2.5:7b']);
      expect(models.every((m) => m.installed), isTrue);
      expect(models.every((m) => m.format == ModelFormat.ollama), isTrue);
    });
  });

  group('download', () {
    test('streams progress then a done event on success', () async {
      final ndjson = [
        jsonEncode({'status': 'pulling manifest'}),
        jsonEncode({'status': 'downloading', 'total': 100, 'completed': 40}),
        jsonEncode({'status': 'downloading', 'total': 100, 'completed': 100}),
        jsonEncode({'status': 'success'}),
      ].join('\n');
      final client = MockClient((r) async {
        expect(r.url.path, '/api/pull');
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        expect(body['name'], 'llama3');
        return http.Response(ndjson, 200);
      });

      final events = await manager(client).download('llama3').toList();
      expect(events.last.isDone, isTrue);
      final progress = events.firstWhere((e) => e.fraction == 0.4);
      expect(progress.phase, 'downloading');
    });

    test('emits an error event on an error line', () async {
      final client = MockClient((r) async =>
          http.Response(jsonEncode({'error': 'pull access denied'}), 200));
      final events = await manager(client).download('nope').toList();
      expect(events.single.isError, isTrue);
      expect(events.single.message, contains('denied'));
    });

    test('emits an error event on non-200', () async {
      final client = MockClient((r) async => http.Response('bad', 500));
      final events = await manager(client).download('x').toList();
      expect(events.single.isError, isTrue);
    });

    test('emits an error event on connection failure', () async {
      final client = MockClient((r) async => throw Exception('refused'));
      final events = await manager(client).download('x').toList();
      expect(events.single.isError, isTrue);
    });
  });

  group('verify', () {
    test('true when the model is in the installed list', () async {
      final client = MockClient((r) async => http.Response(
          jsonEncode({
            'models': [
              {'name': 'llama3:latest'}
            ]
          }),
          200));
      expect(await manager(client).verify('llama3:latest'), isTrue);
      expect(await manager(client).verify('absent'), isFalse);
    });

    test('false (never throws) when server unreachable', () async {
      final client = MockClient((r) async => throw Exception('down'));
      expect(await manager(client).verify('x'), isFalse);
    });
  });

  group('delete', () {
    test('succeeds on 200', () async {
      final client = MockClient((r) async {
        expect(r.method, 'DELETE');
        expect(r.url.path, '/api/delete');
        return http.Response('', 200);
      });
      await manager(client).delete('llama3'); // should not throw
    });

    test('throws on non-200', () async {
      final client = MockClient((r) async => http.Response('nope', 404));
      expect(() => manager(client).delete('llama3'), throwsStateError);
    });
  });

  group('select / selected', () {
    test('select persists and selected reads it back', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = AiConfigService(prefs: prefs);
      final client = MockClient((r) async => http.Response('{}', 200));
      final m = manager(client, svc: svc);

      expect(await m.selected(), isNull);
      final chosen = await m.select('llama3:latest');
      expect(chosen, 'llama3:latest');
      expect(await m.selected(), 'llama3:latest');
    });
  });
}
