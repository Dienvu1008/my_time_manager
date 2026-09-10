import 'dart:async';

import '../../core/ai_cancellation_token.dart';
import '../../core/ai_capabilities.dart';
import '../../core/ai_engine.dart';
import '../../core/ai_exception.dart';
import '../../core/ai_message.dart';
import '../../core/ai_request.dart';
import '../../core/ai_response.dart';
import '../../core/ai_stream_event.dart';
import 'llama_backend.dart';

/// [AiEngine] backed by an embedded llama.cpp runtime (mobile-first: Android /
/// iOS, plus macOS). It adapts our provider-independent request/response types
/// to a [LlamaBackend] port — the only seam that touches an actual llama.cpp
/// binding.
///
/// The agent depends solely on [AiEngine]; it never learns that llama.cpp (or
/// any backend) is in use. Swapping the concrete binding means swapping the
/// [LlamaBackend] implementation, not this engine.
///
/// Capability note: this path does not expose structured tool-calling (most
/// local GGUF chat models don't reliably support Ollama-style function calling
/// through a raw prompt), so [capabilities.toolCalling] is false. The engine
/// still streams text, which is enough for conversational and planning-as-text
/// use; a tool-capable model can be surfaced later by extending the backend.
class LlamaCppAiEngine implements AiEngine {
  LlamaCppAiEngine({
    required LlamaBackend backend,
    required String modelPath,
    int? contextLength,
  })  : _backend = backend,
        _modelPath = modelPath,
        _contextLength = contextLength;

  final LlamaBackend _backend;
  final String _modelPath;
  final int? _contextLength;

  @override
  String get id => 'llama_cpp';

  @override
  AiCapabilities get capabilities => AiCapabilities(
        streaming: true,
        toolCalling: false,
        structuredOutput: false,
        systemMessages: true,
        contextLength: _contextLength,
      );

  @override
  Future<bool> isAvailable() async {
    // Available once a model is (or can be) loaded. We treat a non-empty model
    // path as the precondition; actual load happens lazily on first use.
    return _modelPath.isNotEmpty;
  }

  Future<void> _ensureLoaded() async {
    if (_backend.isLoaded) return;
    try {
      await _backend.load(_modelPath);
    } catch (e) {
      throw AiException.unavailable(
        'Failed to load the local model at "$_modelPath": $e',
        cause: e,
      );
    }
  }

  @override
  Future<AiResponse> generate(
    AiRequest request, {
    AiCancellationToken? cancelToken,
  }) async {
    final buffer = StringBuffer();
    AiFinishReason reason = AiFinishReason.stop;
    await for (final event in stream(request, cancelToken: cancelToken)) {
      switch (event) {
        case AiTextDelta(:final text):
          buffer.write(text);
        case AiStreamDone(:final response):
          return AiResponse(
            text: buffer.isNotEmpty ? buffer.toString() : response.text,
            finishReason: response.finishReason,
            model: id,
          );
        case AiStreamError(:final message):
          throw AiException(AiErrorKind.backend, message);
        case AiToolCallEvent():
          break; // not supported on this path
      }
    }
    return AiResponse(text: buffer.toString(), finishReason: reason, model: id);
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
    try {
      await _ensureLoaded();
    } on AiException catch (e) {
      yield AiStreamError(e.message, cause: e);
      return;
    }

    // Wire cancellation to the backend.
    final sub = cancelToken?.whenCancelled.then((_) => _backend.cancel());

    final prompt = LlamaPrompt(
      text: renderPrompt(request.messages),
      maxTokens: request.maxTokens,
      temperature: request.temperature,
      stopSequences: request.stopSequences,
    );

    final buffer = StringBuffer();
    try {
      await for (final event in _backend.generate(prompt)) {
        if (cancelToken?.isCancelled ?? false) {
          yield AiStreamDone(AiResponse(
            text: buffer.toString(),
            finishReason: AiFinishReason.cancelled,
            model: id,
          ));
          return;
        }
        switch (event) {
          case LlamaToken(:final text):
            buffer.write(text);
            yield AiTextDelta(text);
          case LlamaDone(:final reason):
            yield AiStreamDone(AiResponse(
              text: buffer.toString(),
              finishReason: reason == 'length'
                  ? AiFinishReason.length
                  : (reason == 'cancelled'
                      ? AiFinishReason.cancelled
                      : AiFinishReason.stop),
              model: id,
            ));
            return;
          case LlamaFailure(:final message):
            yield AiStreamError(message);
            return;
        }
      }
      // Backend stream ended without an explicit done.
      yield AiStreamDone(AiResponse(
        text: buffer.toString(),
        finishReason: AiFinishReason.stop,
        model: id,
      ));
    } catch (e) {
      yield AiStreamError('llama.cpp generation error: $e', cause: e);
    } finally {
      // Detach the cancellation listener (best effort).
      unawaited(Future.value(sub));
    }
  }

  /// Render the conversation into a single prompt string. This is a portable
  /// fallback rendering; a concrete backend may instead apply the model's
  /// embedded chat template. Kept static + pure for testability.
  static String renderPrompt(List<AiMessage> messages) {
    final b = StringBuffer();
    for (final m in messages) {
      switch (m.role) {
        case AiRole.system:
          b.writeln('[System]\n${m.content}\n');
        case AiRole.user:
          b.writeln('[User]\n${m.content}\n');
        case AiRole.assistant:
          if (m.content.isNotEmpty) b.writeln('[Assistant]\n${m.content}\n');
        case AiRole.tool:
          b.writeln('[Tool ${m.name ?? ''} result]\n${m.content}\n');
      }
    }
    b.write('[Assistant]\n');
    return b.toString();
  }
}
