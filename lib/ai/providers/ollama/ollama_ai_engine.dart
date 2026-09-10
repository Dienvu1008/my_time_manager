import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/ai_config.dart';
import '../../core/ai_cancellation_token.dart';
import '../../core/ai_capabilities.dart';
import '../../core/ai_engine.dart';
import '../../core/ai_exception.dart';
import '../../core/ai_request.dart';
import '../../core/ai_response.dart';
import '../../core/ai_stream_event.dart';
import '../../core/ai_tool_call.dart';
import 'ollama_wire.dart';

/// [AiEngine] backed by a local Ollama server (desktop-first: Windows, macOS,
/// Linux). This is the only class that talks to Ollama's HTTP API; everything
/// above it depends solely on [AiEngine].
///
/// The endpoint, default model, and timeout come from [AiConfig] (nothing is
/// hard-coded into logic — the conventional endpoint is a configurable
/// default). An [http.Client] is injected so the engine is unit-testable with a
/// mock client, without a running server.
class OllamaAiEngine implements AiEngine {
  OllamaAiEngine({
    AiConfig config = const AiConfig(),
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final AiConfig _config;
  final http.Client _client;
  final bool _ownsClient;

  @override
  String get id => 'ollama';

  @override
  AiCapabilities get capabilities => const AiCapabilities(
        streaming: true,
        toolCalling: true,
        structuredOutput: true,
        systemMessages: true,
      );

  String get _baseUrl =>
      _config.effectiveEndpoint ?? AiConfig.defaultOllamaEndpoint;

  Duration get _timeout => _config.requestTimeout;

  /// Resolve the model to use for a request: request override, else config
  /// default. Throws an invalid-request error if neither is set.
  String _resolveModel(AiRequest request) {
    final model = request.model ?? _config.defaultModel;
    if (model == null || model.isEmpty) {
      throw const AiException(
        AiErrorKind.invalidRequest,
        'No model specified: set AiRequest.model or AiConfig.defaultModel.',
      );
    }
    return model;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      // Availability checks never throw.
      return false;
    }
  }

  /// List the model names installed on the Ollama server (via `/api/tags`).
  /// Throws [AiException] on failure so the UI can show a precise message.
  /// This is Ollama-specific and intentionally lives only in this provider.
  Future<List<String>> listModels() async {
    final http.Response resp;
    try {
      resp = await _client
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(_timeout);
    } catch (e) {
      throw AiException.unavailable(
        'Could not reach Ollama at $_baseUrl. Is it running? ($e)',
        cause: e,
      );
    }
    if (resp.statusCode != 200) {
      throw AiException(
        AiErrorKind.backend,
        'Ollama returned HTTP ${resp.statusCode} listing models.',
      );
    }
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return OllamaWire.parseModelTags(json);
    } catch (e) {
      throw AiException(
          AiErrorKind.parsing, 'Failed to parse model list: $e', cause: e);
    }
  }

  @override
  Future<AiResponse> generate(
    AiRequest request, {
    AiCancellationToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      throw const AiException.cancelled();
    }
    final model = _resolveModel(request);
    final body = OllamaWire.chatRequestBody(request, model: model, stream: false);

    final httpRequest = http.Request('POST', Uri.parse('$_baseUrl/api/chat'))
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode(body);

    http.StreamedResponse streamed;
    try {
      final sendFuture = _client.send(httpRequest);
      streamed = await _awaitWithCancel(sendFuture, cancelToken).timeout(
        _timeout,
        onTimeout: () => throw AiException.timeout(
          'Ollama did not respond within ${_timeout.inSeconds}s.',
        ),
      );
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException.unavailable(
        'Could not reach Ollama at $_baseUrl. Is it running? ($e)',
        cause: e,
      );
    }

    final raw = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw _mapHttpError(streamed.statusCode, raw, model);
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw AiException(AiErrorKind.parsing,
          'Failed to parse Ollama response: $e', cause: e);
    }
    return OllamaWire.parseChatResponse(json);
  }

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    AiCancellationToken? cancelToken,
  }) async* {
    if (cancelToken?.isCancelled ?? false) {
      yield const AiStreamError('Request cancelled');
      return;
    }

    final String model;
    try {
      model = _resolveModel(request);
    } on AiException catch (e) {
      yield AiStreamError(e.message, cause: e);
      return;
    }

    final body = OllamaWire.chatRequestBody(request, model: model, stream: true);
    final httpRequest = http.Request('POST', Uri.parse('$_baseUrl/api/chat'))
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode(body);

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(httpRequest).timeout(_timeout);
    } catch (e) {
      yield AiStreamError(
        'Could not reach Ollama at $_baseUrl. Is it running? ($e)',
        cause: e,
      );
      return;
    }

    if (streamed.statusCode != 200) {
      final raw = await streamed.stream.bytesToString();
      final err = _mapHttpError(streamed.statusCode, raw, model);
      yield AiStreamError(err.message, cause: err);
      return;
    }

    final buffer = StringBuffer();
    final toolCalls = <AiToolCall>[];
    String? doneReason;
    String? respModel;
    AiUsage? usage;

    // Ollama streams NDJSON: one JSON object per line.
    final lines = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    try {
      await for (final line in lines) {
        if (cancelToken?.isCancelled ?? false) {
          yield AiStreamDone(AiResponse(
            text: buffer.toString(),
            toolCalls: toolCalls,
            finishReason: AiFinishReason.cancelled,
            model: respModel,
            usage: usage,
          ));
          return;
        }
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        Map<String, dynamic> json;
        try {
          json = jsonDecode(trimmed) as Map<String, dynamic>;
        } catch (e) {
          yield AiStreamError('Malformed stream chunk: $e', cause: e);
          return;
        }

        final chunk = OllamaWire.parseStreamChunk(json);
        if (chunk.textDelta.isNotEmpty) {
          buffer.write(chunk.textDelta);
          yield AiTextDelta(chunk.textDelta);
        }
        for (final call in chunk.toolCalls) {
          toolCalls.add(call);
          yield AiToolCallEvent(call);
        }
        respModel ??= chunk.model;
        if (chunk.usage != null) usage = chunk.usage;
        if (chunk.done) {
          doneReason = chunk.doneReason;
          break;
        }
      }
    } catch (e) {
      yield AiStreamError('Ollama stream error: $e', cause: e);
      return;
    }

    yield AiStreamDone(AiResponse(
      text: buffer.toString(),
      toolCalls: toolCalls,
      finishReason: toolCalls.isNotEmpty
          ? AiFinishReason.toolCalls
          : (doneReason == 'length'
              ? AiFinishReason.length
              : AiFinishReason.stop),
      model: respModel,
      usage: usage,
    ));
  }

  /// Race a future against cancellation. Throws [AiException.cancelled] if the
  /// token fires first.
  Future<T> _awaitWithCancel<T>(
    Future<T> future,
    AiCancellationToken? token,
  ) {
    if (token == null) return future;
    return Future.any<T>([
      future,
      token.whenCancelled.then<T>(
        (_) => throw const AiException.cancelled(),
      ),
    ]);
  }

  AiException _mapHttpError(int status, String rawBody, String model) {
    // Ollama returns 404 with an "not found, try pulling it" style message when
    // the model is not installed.
    if (status == 404 && rawBody.toLowerCase().contains('model')) {
      return AiException.modelNotFound(
        'Model "$model" is not available on the Ollama server. '
        'Install it with `ollama pull $model`.',
      );
    }
    String detail = rawBody;
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map && decoded['error'] is String) {
        detail = decoded['error'] as String;
      }
    } catch (_) {
      // keep raw body
    }
    return AiException(
      AiErrorKind.backend,
      'Ollama returned HTTP $status: $detail',
    );
  }

  /// Close the underlying client if this engine created it.
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
