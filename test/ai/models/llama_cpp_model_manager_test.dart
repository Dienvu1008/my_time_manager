import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_time_manager/ai/config/ai_config_service.dart';
import 'package:my_time_manager/ai/models/gguf_model_downloader.dart';
import 'package:my_time_manager/ai/models/llama_cpp_model_manager.dart';
import 'package:my_time_manager/ai/models/model_info.dart';
import 'package:my_time_manager/ai/models/model_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('llama_mgr_');
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<Directory> dirResolver() async => tmp;

  ModelRegistry registryFor(List<int> bytes) => ModelRegistry([
        ModelInfo(
          id: 'phi3.gguf',
          name: 'Phi-3',
          format: ModelFormat.gguf,
          downloadUrl: 'http://x/phi3.gguf',
          checksum: 'sha256:${sha256.convert(bytes).toString()}',
        ),
      ]);

  MockClient streaming(List<int> bytes) =>
      MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(Stream.value(bytes), 200,
            contentLength: bytes.length);
      });

  LlamaCppModelManager manager({
    required ModelRegistry registry,
    required GgufModelDownloader downloader,
    AiConfigService? svc,
  }) =>
      LlamaCppModelManager(
        registry: registry,
        modelsDir: dirResolver,
        downloader: downloader,
        configService: svc,
      );

  test('list is empty when no gguf files present', () async {
    final m = manager(
        registry: ModelRegistry(),
        downloader: GgufModelDownloader(client: streaming(const [])));
    expect(await m.list(), isEmpty);
  });

  test('download fetches, verifies, and the file then appears in list',
      () async {
    final bytes = utf8.encode('model-weights');
    final m = manager(
      registry: registryFor(bytes),
      downloader: GgufModelDownloader(client: streaming(bytes)),
    );

    final events = await m.download('phi3.gguf').toList();
    expect(events.last.isDone, isTrue);

    final listed = await m.list();
    expect(listed.map((e) => e.id), contains('phi3.gguf'));
    expect(listed.single.installed, isTrue);
    expect(listed.single.format, ModelFormat.gguf);
  });

  test('download errors for an unknown model id', () async {
    final m = manager(
        registry: ModelRegistry(),
        downloader: GgufModelDownloader(client: streaming(const [])));
    final events = await m.download('unknown.gguf').toList();
    expect(events.single.isError, isTrue);
  });

  test('verify reflects presence; delete removes the file', () async {
    final bytes = utf8.encode('w');
    final m = manager(
      registry: registryFor(bytes),
      downloader: GgufModelDownloader(client: streaming(bytes)),
    );
    await m.download('phi3.gguf').toList();

    expect(await m.verify('phi3.gguf'), isTrue);
    await m.delete('phi3.gguf');
    expect(await m.verify('phi3.gguf'), isFalse);
    expect(await m.list(), isEmpty);
  });

  test('select persists and selected reads it back', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final m = manager(
      registry: ModelRegistry(),
      downloader: GgufModelDownloader(client: streaming(const [])),
      svc: AiConfigService(prefs: prefs),
    );
    expect(await m.selected(), isNull);
    await m.select('phi3.gguf');
    expect(await m.selected(), 'phi3.gguf');
  });
}
