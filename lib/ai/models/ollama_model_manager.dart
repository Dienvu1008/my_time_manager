import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import '../config/ai_config_service.dart';
import '../providers/ollama/ollama_ai_engine.dart';
import 'model_info.dart';
import 'model_manager.dart';

/// [ModelManager] backed by a local Ollama server.
///
/// Ollama already stores and manages model files, so this manager does NOT
/// download raw files itself — it drives Ollama's own endpoints:
///   - list   → GET  /api/tags
///   - download→ POST /api/pull   (NDJSON progress)
///   - delete → DELETE /api/delete
///   - verify → present in /api/tags
///   - select → persisted via AiConfigService (defaultModel)
///
/// This is the only place that knows Ollama's model endpoints. Real file
/// download + checksum verification is a GGUF/llama.cpp concern (Phase 9).
class OllamaModelManager implements ModelManager {
  OllamaModelManager({
    AiConfig config = const AiConfig(),
    AiConfigService? configService,
    http.Client? client,
  })  : _config = config,
        _configService = configService ?? AiConfigService(),
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final AiConfig _config;
  final AiConfigService _configService;
  final http.Client _client;
  final bool _ownsClient;

  String get _baseUrl =>
      _config.effectiveEndpoint ?? AiConfig.defaultOllamaEndpoint;
  Duration get _timeout => _config.requestTimeout;

  @override
  String get id => 'ollama';

  @override
  Future<List<ModelInfo>> list() async {
    // Reuse the engine's model listing to avoid duplicating /api/tags parsing.
    final engine = OllamaAiEngine(config: _config, client: _client);
    final tags = await engine.listModels();
    return [
      for (final tag in tags)
        ModelInfo(
          id: tag,
          name: tag,
          format: ModelFormat.ollama,
          installed: true,
        ),
    ];
  }

  @override
  Stream<ModelOperationProgress> download(String modelId) async* {
    final request = http.Request('POST', Uri.parse('$_baseUrl/api/pull'))
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({'name': modelId, 'stream': true});

    http.StreamedResponse resp;
    try {
      resp = await _client.send(request).timeout(_timeout);
    } catch (e) {
      yield ModelOperationProgress(
        modelId: modelId,
        phase: 'error',
        message: 'Could not reach Ollama at $_baseUrl: $e',
      );
      return;
    }

    if (resp.statusCode != 200) {
      final body = await resp.stream.bytesToString();
      yield ModelOperationProgress(
        modelId: modelId,
        phase: 'error',
        message: 'Ollama pull failed (HTTP ${resp.statusCode}): $body',
      );
      return;
    }

    final lines =
        resp.stream.transform(utf8.decoder).transform(const LineSplitter());
    try {
      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        Map<String, dynamic> json;
        try {
          json = jsonDecode(trimmed) as Map<String, dynamic>;
        } catch (_) {
          continue; // skip unparseable keep-alive lines
        }
        if (json['error'] != null) {
          yield ModelOperationProgress(
            modelId: modelId,
            phase: 'error',
            message: json['error'].toString(),
          );
          return;
        }
        final status = json['status'] as String?;
        if (status == 'success') {
          yield ModelOperationProgress(modelId: modelId, phase: 'done');
          return;
        }
        yield ModelOperationProgress(
          modelId: modelId,
          phase: 'downloading',
          receivedBytes: (json['completed'] as num?)?.toInt(),
          totalBytes: (json['total'] as num?)?.toInt(),
          message: status,
        );
      }
      // Stream ended without an explicit success line — treat as done.
      yield ModelOperationProgress(modelId: modelId, phase: 'done');
    } catch (e) {
      yield ModelOperationProgress(
          modelId: modelId, phase: 'error', message: 'Pull stream error: $e');
    }
  }

  @override
  Future<bool> verify(String modelId) async {
    try {
      final installed = await list();
      return installed.any((m) => m.id == modelId);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> delete(String modelId) async {
    final request = http.Request('DELETE', Uri.parse('$_baseUrl/api/delete'))
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({'name': modelId});
    final resp = await _client.send(request).timeout(_timeout);
    if (resp.statusCode != 200) {
      final body = await resp.stream.bytesToString();
      throw StateError('Ollama delete failed (HTTP ${resp.statusCode}): $body');
    }
  }

  @override
  Future<String> select(String modelId) async {
    final current = await _configService.load();
    await _configService.save(current.copyWith(defaultModel: modelId));
    return modelId;
  }

  @override
  Future<String?> selected() async {
    final current = await _configService.load();
    return current.defaultModel;
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
