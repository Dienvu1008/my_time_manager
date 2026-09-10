// LlamaBackend implementation backed by the `llama_cpp_dart` package
// (netdur/llama_cpp_dart, 0.9.x).
//
// ┌─ IMPORTANT — OPT-IN, NOT WIRED BY DEFAULT ───────────────────────────────┐
// │ This file imports `package:llama_cpp_dart/...`, which is a mobile-first   │
// │ native binding (iOS / Android / macOS only) and ships native artifacts.  │
// │ It is deliberately NOT imported anywhere in the app's default build graph │
// │ so the app keeps building on Windows / Linux / Web (where that package    │
// │ is unavailable). Nothing references this file unless you opt in.          │
// │                                                                           │
// │ To enable llama.cpp on mobile:                                            │
// │   1. Add the dependency:  `llama_cpp_dart: ^0.9.0` in pubspec.yaml.       │
// │   2. Add the native artifact per the package README (Android AAR is       │
// │      bundled automatically; iOS/macOS embed the xcframework).             │
// │   3. Register a candidate in the AiGateway wiring that constructs a        │
// │      `LlamaCppAiEngine(backend: LlamaCppDartBackend(...), modelPath: ...)`.│
// │   4. Uncomment the import + body below.                                   │
// │                                                                           │
// │ Until then the surrounding architecture already targets llama.cpp via the │
// │ `LlamaBackend` port + `LlamaCppAiEngine` (both fully implemented + tested  │
// │ against a fake backend), so no other code changes are needed to switch    │
// │ the engine on.                                                            │
// └───────────────────────────────────────────────────────────────────────────┘
//
// The implementation below is written against the documented `llama_cpp_dart`
// 0.9.x API (LlamaEngine.spawn / createSession / session.generate streaming
// GenerationEvent → TokenEvent | ShiftEvent | DoneEvent). It is kept commented
// so the default build does not require the package. Uncomment after step 1.

/*
import 'dart:async';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import 'llama_backend.dart';

/// Wraps `llama_cpp_dart`'s [LlamaEngine] as our provider-independent
/// [LlamaBackend]. This is the ONLY file that knows the concrete binding; the
/// engine ([LlamaCppAiEngine]) and the agent above it never import it.
class LlamaCppDartBackend implements LlamaBackend {
  LlamaCppDartBackend({
    this.libraryPath,
    this.gpuLayers = 99,
    this.contextTokens = 4096,
    SamplerParams? sampler,
  }) : _sampler = sampler ?? const SamplerParams(temperature: 0.7, topP: 0.9);

  /// Path to the native library. Needed on macOS/CLI; on Android the bundled
  /// libllama.so is the default (leave null). On iOS use spawnFromProcess
  /// (adjust the spawn call accordingly).
  final String? libraryPath;
  final int gpuLayers;
  final int contextTokens;
  final SamplerParams _sampler;

  LlamaEngine? _engine;
  EngineSession? _session;
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load(String modelPath) async {
    if (_loaded) return;
    _engine = await LlamaEngine.spawn(
      libraryPath: libraryPath,
      modelParams: ModelParams(path: modelPath, gpuLayers: gpuLayers),
      contextParams: ContextParams(nCtx: contextTokens),
    );
    _session = await _engine!.createSession();
    _loaded = true;
  }

  @override
  Stream<LlamaGenerationEvent> generate(LlamaPrompt prompt) async* {
    final session = _session;
    if (session == null) {
      yield const LlamaFailure('Model not loaded.');
      return;
    }
    try {
      final sampler = prompt.temperature != null
          ? SamplerParams(temperature: prompt.temperature!, topP: 0.9)
          : _sampler;
      await for (final event in session.generate(
        prompt: prompt.text,
        addSpecial: true,
        sampler: sampler,
        maxTokens: prompt.maxTokens ?? 512,
      )) {
        switch (event) {
          case TokenEvent():
            yield LlamaToken(event.text);
          case ShiftEvent():
            // KV-cache bookkeeping; nothing to surface.
            break;
          case DoneEvent():
            yield LlamaDone(_mapReason(event.reason));
            return;
        }
      }
      yield const LlamaDone('stop');
    } catch (e) {
      yield LlamaFailure('llama.cpp error: $e');
    }
  }

  String _mapReason(StopReason reason) {
    switch (reason) {
      case StopMaxTokens():
        return 'length';
      case StopUserAbort():
        return 'cancelled';
      case StopEog():
      default:
        return 'stop';
    }
  }

  @override
  void cancel() {
    // llama_cpp_dart aborts by disposing/ending the session; the DoneEvent
    // will report StopUserAbort. A finer-grained abort hook can be wired here
    // if the binding exposes one.
    _session?.dispose();
  }

  @override
  Future<void> dispose() async {
    await _session?.dispose();
    await _engine?.dispose();
    _session = null;
    _engine = null;
    _loaded = false;
  }
}
*/
