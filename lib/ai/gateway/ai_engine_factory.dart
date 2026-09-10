import '../config/ai_config.dart';
import '../core/ai_capabilities.dart';
import '../core/ai_engine.dart';
import '../providers/llama_cpp/llama_backend.dart';
import '../providers/llama_cpp/llama_cpp_ai_engine.dart';
import '../providers/ollama/ollama_ai_engine.dart';
import 'ai_gateway.dart';
import 'platform_kind.dart';
import 'provider_candidate.dart';
import 'provider_selection.dart';

/// Optional factory that builds a concrete [LlamaBackend] once you opt into the
/// native binding (see llama_cpp_dart_backend.dart). Null when llama.cpp is not
/// wired, which keeps the app building on desktop/web.
typedef LlamaBackendFactory = LlamaBackend Function();

/// Builds an [AiGateway] with the app's providers and selects an [AiEngine] for
/// the current platform + mode. This is the single place that turns an
/// [AiConfig] into a running engine via platform routing.
///
/// - Ollama is offered on desktop (Windows/macOS/Linux) — where a local server
///   typically runs — and advertises tool-calling.
/// - llama.cpp is offered on mobile (Android/iOS) + macOS, and ONLY when a
///   [llamaBackendFactory] + model path are provided (i.e. you opted in). It
///   advertises streaming but not tool-calling (matching the engine's honest
///   capabilities).
///
/// Callers still receive only an [AiEngine]; nothing above learns which backend
/// was chosen.
class AiEngineFactory {
  AiEngineFactory({
    this.llamaBackendFactory,
    this.llamaModelPath,
    PlatformResolver? platformResolver,
  }) : _platformResolver = platformResolver;

  final LlamaBackendFactory? llamaBackendFactory;
  final String? llamaModelPath;
  final PlatformResolver? _platformResolver;

  /// Build the gateway for a given [config].
  AiGateway gateway(AiConfig config) {
    final candidates = <ProviderCandidate>[
      // Ollama: desktop-first, tool-calling capable.
      ProviderCandidate(
        kind: AiProviderKind.ollama,
        supportedPlatforms: const {
          PlatformKind.windows,
          PlatformKind.macos,
          PlatformKind.linux,
        },
        capabilities: const AiCapabilities(
          streaming: true,
          toolCalling: true,
          structuredOutput: true,
        ),
        priority: 10,
        // Available only when a model is chosen AND the server is reachable.
        isAvailable: () async {
          if (config.defaultModel == null || config.defaultModel!.isEmpty) {
            return false;
          }
          return OllamaAiEngine(config: config).isAvailable();
        },
        create: () => OllamaAiEngine(config: config),
      ),

      // llama.cpp: mobile-first, only when opted in (backend factory + model).
      if (llamaBackendFactory != null &&
          llamaModelPath != null &&
          llamaModelPath!.isNotEmpty)
        ProviderCandidate(
          kind: AiProviderKind.llamaCpp,
          supportedPlatforms: const {
            PlatformKind.android,
            PlatformKind.ios,
            PlatformKind.macos,
          },
          capabilities: const AiCapabilities(
            streaming: true,
            toolCalling: false,
          ),
          priority: 5,
          create: () => LlamaCppAiEngine(
            backend: llamaBackendFactory!(),
            modelPath: llamaModelPath!,
          ),
        ),
    ];

    return AiGateway(
      candidates: candidates,
      platformResolver: _platformResolver,
    );
  }

  /// Convenience: build the gateway and select an engine in one call.
  Future<ProviderSelection> select(AiConfig config) =>
      gateway(config).select(mode: config.mode);
}
