import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/config/ai_config.dart';
import 'package:my_time_manager/ai/gateway/ai_engine_factory.dart';
import 'package:my_time_manager/ai/gateway/platform_kind.dart';
import 'package:my_time_manager/ai/gateway/provider_selection.dart';
import 'package:my_time_manager/ai/providers/llama_cpp/llama_backend.dart';

/// A no-op backend so we can register the llama.cpp candidate without native
/// code (we only assert routing/selection, not generation).
class _NoopBackend implements LlamaBackend {
  @override
  bool get isLoaded => true;
  @override
  Future<void> load(String modelPath) async {}
  @override
  Stream<LlamaGenerationEvent> generate(LlamaPrompt prompt) =>
      const Stream.empty();
  @override
  void cancel() {}
  @override
  Future<void> dispose() async {}
}

void main() {
  test('desktop with no model selected -> not available (no network hit)',
      () async {
    final factory = AiEngineFactory(platformResolver: () => PlatformKind.windows);
    // No defaultModel => Ollama candidate reports unavailable without a server.
    final s = await factory.select(const AiConfig());
    expect(s.isSelected, isFalse);
    expect(s.reason, NoProviderReason.noneAvailable);
  });

  test('Android without opt-in llama.cpp -> unsupported platform', () async {
    // Only the Ollama candidate exists (no llama factory), and Ollama does not
    // support Android, so there is no candidate for the platform.
    final factory = AiEngineFactory(platformResolver: () => PlatformKind.android);
    final s = await factory.select(const AiConfig(defaultModel: 'llama3'));
    expect(s.isSelected, isFalse);
    expect(s.reason, NoProviderReason.unsupportedPlatform);
  });

  test('Android WITH opt-in llama.cpp -> selects llama.cpp', () async {
    final factory = AiEngineFactory(
      platformResolver: () => PlatformKind.android,
      llamaBackendFactory: () => _NoopBackend(),
      llamaModelPath: '/models/m.gguf',
    );
    final s = await factory.select(const AiConfig(defaultModel: 'llama3'));
    expect(s.isSelected, isTrue);
    expect(s.kind, AiProviderKind.llamaCpp);
    expect(s.engine!.id, 'llama_cpp');
  });

  test('macOS: Ollama unavailable (no model) falls through to opted-in llama',
      () async {
    // On macOS both candidates fit the platform. Ollama has higher priority but
    // is unavailable here because no model is configured (it reports false
    // before any network call), so the gateway falls through to the available
    // llama.cpp candidate. Deterministic regardless of whether a real Ollama
    // server happens to be running on the test machine.
    final factory = AiEngineFactory(
      platformResolver: () => PlatformKind.macos,
      llamaBackendFactory: () => _NoopBackend(),
      llamaModelPath: '/models/m.gguf',
    );
    final s = await factory.select(const AiConfig()); // no defaultModel
    expect(s.isSelected, isTrue);
    expect(s.kind, AiProviderKind.llamaCpp);
  });

}
