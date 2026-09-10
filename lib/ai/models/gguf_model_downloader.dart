import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'model_manager.dart';

/// Downloads a GGUF model file to disk and verifies its integrity by SHA-256.
///
/// This is the piece llama.cpp needs that Ollama does not: with an embedded
/// runtime there is no server managing model files, so the app must fetch and
/// verify them itself. Pure Dart (http + crypto + dart:io) — no native code —
/// so it is unit-testable with a mock client and a temp directory.
///
/// Large models are downloaded here at runtime, never bundled in the binary.
class GgufModelDownloader {
  GgufModelDownloader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Download [url] to [destinationPath], streaming progress. If [expectedSha256]
  /// is given, the file is verified after download and deleted on mismatch.
  ///
  /// Emits 'downloading' progress, then a 'verifying' event (if a checksum is
  /// provided), then 'done' — or 'error'. The stream always terminates.
  Stream<ModelOperationProgress> download({
    required String modelId,
    required String url,
    required String destinationPath,
    String? expectedSha256,
  }) async* {
    final file = File(destinationPath);
    IOSink? sink;
    try {
      await file.parent.create(recursive: true);

      final request = http.Request('GET', Uri.parse(url));
      final http.StreamedResponse resp;
      try {
        resp = await _client.send(request);
      } catch (e) {
        yield ModelOperationProgress(
            modelId: modelId, phase: 'error', message: 'Download failed: $e');
        return;
      }
      if (resp.statusCode != 200) {
        yield ModelOperationProgress(
            modelId: modelId,
            phase: 'error',
            message: 'Download failed (HTTP ${resp.statusCode}).');
        return;
      }

      final total = resp.contentLength;
      var received = 0;
      sink = file.openWrite();
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        received += chunk.length;
        yield ModelOperationProgress(
          modelId: modelId,
          phase: 'downloading',
          receivedBytes: received,
          totalBytes: total,
        );
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (expectedSha256 != null && expectedSha256.isNotEmpty) {
        yield ModelOperationProgress(modelId: modelId, phase: 'verifying');
        final actual = await _sha256OfFile(file);
        final expected = _normalizeHash(expectedSha256);
        if (actual != expected) {
          await _safeDelete(file);
          yield ModelOperationProgress(
            modelId: modelId,
            phase: 'error',
            message: 'Checksum mismatch: expected $expected, got $actual. '
                'File deleted.',
          );
          return;
        }
      }

      yield ModelOperationProgress(
          modelId: modelId, phase: 'done', message: destinationPath);
    } catch (e) {
      await sink?.close();
      yield ModelOperationProgress(
          modelId: modelId, phase: 'error', message: 'Unexpected error: $e');
    }
  }

  Future<String> _sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static String _normalizeHash(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('sha256:') ? t.substring(7) : t;
  }

  static Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {/* ignore */}
  }

  void dispose() => _client.close();
}
