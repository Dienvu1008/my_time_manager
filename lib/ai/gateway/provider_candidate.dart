import '../config/ai_config.dart';
import '../core/ai_capabilities.dart';
import '../core/ai_engine.dart';
import 'platform_kind.dart';

/// A provider the gateway may choose from. Each candidate self-declares which
/// platforms it supports and what it can do, so the gateway makes NO hard-coded
/// assumptions — it just filters and ranks candidates.
///
/// [create] builds the engine lazily (only for the chosen candidate).
/// [isAvailable] is a cheap runtime check (e.g. "Ollama server reachable");
/// defaults to always-available for backends with no server dependency.
class ProviderCandidate {
  const ProviderCandidate({
    required this.kind,
    required this.supportedPlatforms,
    required this.capabilities,
    required this.create,
    this.isCloud = false,
    this.isAvailable = _alwaysAvailable,
    this.priority = 0,
  });

  final AiProviderKind kind;

  /// Platforms this provider can run on.
  final Set<PlatformKind> supportedPlatforms;

  /// What this provider/model can do (used to satisfy capability requirements).
  final AiCapabilities capabilities;

  /// Lazily construct the engine for this candidate.
  final AiEngine Function() create;

  /// Whether this is a cloud provider (gated by [AiMode]).
  final bool isCloud;

  /// Cheap runtime availability check.
  final Future<bool> Function() isAvailable;

  /// Higher wins when multiple candidates are otherwise equal. Lets a caller
  /// express "prefer Ollama on desktop" without the gateway hard-coding it.
  final int priority;

  bool supportsPlatform(PlatformKind p) => supportedPlatforms.contains(p);

  static Future<bool> _alwaysAvailable() async => true;
}
