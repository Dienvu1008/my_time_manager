import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_time_manager/ai/models/gguf_model_downloader.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gguf_test_');
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  String destPath(String name) => '${tmp.path}${Platform.pathSeparator}$name';

  MockClient streaming(List<int> bytes, {int status = 200}) {
    return MockClient.streaming((request, bodyStream) async {
      return http.StreamedResponse(
        Stream.value(bytes),
        status,
        contentLength: bytes.length,
      );
    });
  }

  test('downloads bytes to disk and reports progress + done', () async {
    final bytes = utf8.encode('hello gguf content');
    final downloader = GgufModelDownloader(client: streaming(bytes));
    final dest = destPath('m.gguf');

    final events = await downloader
        .download(modelId: 'm.gguf', url: 'http://x/m.gguf', destinationPath: dest)
        .toList();

    expect(events.last.isDone, isTrue);
    expect(events.any((e) => e.phase == 'downloading'), isTrue);
    expect(await File(dest).readAsBytes(), bytes);
  });

  test('verifies a correct sha256 and keeps the file', () async {
    final bytes = utf8.encode('verify me');
    final expected = sha256.convert(bytes).toString();
    final downloader = GgufModelDownloader(client: streaming(bytes));
    final dest = destPath('ok.gguf');

    final events = await downloader
        .download(
          modelId: 'ok.gguf',
          url: 'http://x/ok.gguf',
          destinationPath: dest,
          expectedSha256: 'sha256:$expected',
        )
        .toList();

    expect(events.any((e) => e.phase == 'verifying'), isTrue);
    expect(events.last.isDone, isTrue);
    expect(await File(dest).exists(), isTrue);
  });

  test('deletes the file and errors on checksum mismatch', () async {
    final bytes = utf8.encode('tampered');
    final downloader = GgufModelDownloader(client: streaming(bytes));
    final dest = destPath('bad.gguf');

    final events = await downloader
        .download(
          modelId: 'bad.gguf',
          url: 'http://x/bad.gguf',
          destinationPath: dest,
          expectedSha256: 'sha256:${'0' * 64}',
        )
        .toList();

    expect(events.last.isError, isTrue);
    expect(events.last.message, contains('Checksum mismatch'));
    expect(await File(dest).exists(), isFalse); // deleted
  });

  test('errors on non-200', () async {
    final downloader =
        GgufModelDownloader(client: streaming(const [1, 2, 3], status: 404));
    final events = await downloader
        .download(
            modelId: 'x', url: 'http://x/x', destinationPath: destPath('x.gguf'))
        .toList();
    expect(events.last.isError, isTrue);
  });

  test('errors on connection failure', () async {
    final client = MockClient((r) async => throw Exception('refused'));
    final downloader = GgufModelDownloader(client: client);
    final events = await downloader
        .download(
            modelId: 'x', url: 'http://x/x', destinationPath: destPath('x.gguf'))
        .toList();
    expect(events.last.isError, isTrue);
  });
}
