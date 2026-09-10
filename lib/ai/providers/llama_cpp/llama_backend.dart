/// A generation event from a llama.cpp backend: an incremental text token, or
/// the end of generation.
sealed class LlamaGenerationEvent {
  const LlamaGenerationEvent();
}

/// A chunk of generated text.
class LlamaToken extends LlamaGenerationEvent {
  const LlamaToken(this.text);
  final String text;
}

/// Generation finished. [reason] is 'stop' | 'length' | 'cancelled'.
class LlamaDone extends LlamaGenerationEvent {
  const LlamaDone(this.reason);
  final String reason;
}

/// An error occurred during generation.
class LlamaFailure extends LlamaGenerationEvent {
  const LlamaFailure(this.message);
  final String message;
}

/// A prompt to run: the model expects a single rendered string (llama.cpp
/// applies the model's chat template). The agent/engine renders messages into
/// this string; the backend just runs inference.
class LlamaPrompt {
  const LlamaPrompt({
    required this.text,
    this.maxTokens,
    this.temperature,
    this.stopSequences = const [],
  });
  final String text;
  final int? maxTokens;
  final double? temperature;
  final List<String> stopSequences;
}

/// The minimal port between our [AiEngine] adapter and an ACTUAL llama.cpp
/// binding (e.g. `llama_cpp_dart`'s `LlamaEngine`).
///
/// Defining our own narrow port — instead of coupling the engine directly to a
/// specific, pre-1.0, mobile-only binding — keeps the native dependency
/// isolated to ONE adapter, lets us unit-test the engine with a fake backend,
/// and lets the concrete binding be swapped without touching the engine or the
/// agent. The agent still has no idea llama.cpp (or any backend) exists.
///
/// A concrete implementation wraps the binding: `load` spawns/loads the model
/// off the UI isolate, `generate` streams tokens, `cancel`/`dispose` free
/// resources.
abstract class LlamaBackend {
  /// Whether a model is currently loaded and ready.
  bool get isLoaded;

  /// Load the model at [modelPath] (a local GGUF file). Throws on failure.
  Future<void> load(String modelPath);

  /// Stream generation events for [prompt]. Must end with [LlamaDone] or
  /// [LlamaFailure].
  Stream<LlamaGenerationEvent> generate(LlamaPrompt prompt);

  /// Request cancellation of the in-flight generation.
  void cancel();

  /// Release native resources.
  Future<void> dispose();
}
