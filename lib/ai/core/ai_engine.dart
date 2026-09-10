import 'ai_cancellation_token.dart';
import 'ai_capabilities.dart';
import 'ai_request.dart';
import 'ai_response.dart';
import 'ai_stream_event.dart';

/// The provider-independent AI inference interface.
///
/// This is the ONLY AI type the agent runtime depends on. Concrete engines
/// (OllamaAiEngine in Phase 2, LlamaCppAiEngine in Phase 9, or a cloud engine)
/// implement it. Nothing above this interface may import a provider-specific
/// class — that separation is what lets the inference backend change without
/// touching the agent.
///
/// Contract:
/// - [generate] returns a single [AiResponse] or throws [AiException].
/// - [stream] emits [AiStreamEvent]s and MUST end with either an [AiStreamDone]
///   or an [AiStreamError]; it should not also throw for normal backend errors
///   (surface them as [AiStreamError]).
/// - Both accept an optional [AiCancellationToken]; on cancellation, [generate]
///   throws `AiException(AiErrorKind.cancelled, …)` and [stream] emits a final
///   [AiStreamError] or an [AiStreamDone] with `finishReason == cancelled`.
/// - [isAvailable] performs a cheap health check and never throws.
abstract class AiEngine {
  /// A short identifier for the engine implementation (e.g. `ollama`).
  String get id;

  /// What this engine/model can do (used by higher-level routing).
  AiCapabilities get capabilities;

  /// Cheap health/availability check. Returns false instead of throwing.
  Future<bool> isAvailable();

  /// Generate a single, complete response.
  Future<AiResponse> generate(
    AiRequest request, {
    AiCancellationToken? cancelToken,
  });

  /// Stream a response as a sequence of events. Ends with [AiStreamDone] or
  /// [AiStreamError].
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    AiCancellationToken? cancelToken,
  });
}
