import '../config/ai_config.dart';
import '../core/ai_engine.dart';

/// Why the gateway could not pick a provider.
enum NoProviderReason {
  /// No candidate supports the current platform.
  unsupportedPlatform,

  /// Candidates exist but none satisfy the required capabilities.
  capabilityUnmet,

  /// The only fitting candidates are cloud, but the mode forbids cloud.
  cloudDisallowed,

  /// Fitting candidates exist but none are currently available (e.g. server
  /// not running, model not installed).
  noneAvailable,

  /// No candidates were provided at all.
  noCandidates,
}

/// The outcome of a routing decision.
class ProviderSelection {
  const ProviderSelection._({
    this.engine,
    this.kind,
    this.reason,
    required this.explanation,
  });

  /// A successful selection.
  ProviderSelection.selected({
    required AiEngine engine,
    required AiProviderKind kind,
    required String explanation,
  }) : this._(engine: engine, kind: kind, explanation: explanation);

  /// No provider could be chosen.
  ProviderSelection.none({
    required NoProviderReason reason,
    required String explanation,
  }) : this._(reason: reason, explanation: explanation);

  /// The chosen engine, or null when none.
  final AiEngine? engine;

  /// The chosen provider kind, or null when none.
  final AiProviderKind? kind;

  /// Why no provider was chosen, or null on success.
  final NoProviderReason? reason;

  /// A human-readable explanation of the decision (for logs/UI).
  final String explanation;

  bool get isSelected => engine != null;

  @override
  String toString() => isSelected
      ? 'ProviderSelection.selected($kind: $explanation)'
      : 'ProviderSelection.none($reason: $explanation)';
}
