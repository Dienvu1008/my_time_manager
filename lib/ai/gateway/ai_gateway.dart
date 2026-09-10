import '../config/ai_config.dart';
import 'platform_kind.dart';
import 'provider_candidate.dart';
import 'provider_selection.dart';

/// A required capability the caller wants the chosen provider to have.
class CapabilityRequirement {
  const CapabilityRequirement({
    this.toolCalling = false,
    this.streaming = false,
    this.structuredOutput = false,
  });

  final bool toolCalling;
  final bool streaming;
  final bool structuredOutput;

  bool get any => toolCalling || streaming || structuredOutput;
}

/// Chooses an [AiEngine] provider for the current platform, mode, and required
/// capabilities — the "AI Gateway".
///
/// It makes NO hard-coded platform assumptions: each [ProviderCandidate]
/// declares its own supported platforms and capabilities, and the gateway
/// filters + ranks them. Policy comes from [AiMode] (local-only / hybrid /
/// cloud-optional). Local providers are preferred; cloud is only considered
/// when the mode allows it, and only after local options are exhausted.
///
/// The agent still depends only on the resulting [AiEngine] — it never learns
/// which backend was picked.
class AiGateway {
  AiGateway({
    required List<ProviderCandidate> candidates,
    PlatformResolver? platformResolver,
  })  : _candidates = candidates,
        _platform = platformResolver ?? defaultPlatformResolver;

  final List<ProviderCandidate> _candidates;
  final PlatformResolver _platform;

  PlatformKind get platform => _platform();

  /// Select a provider given the [mode] and optional capability [require]ments.
  ///
  /// Ranking within an allowed group: higher [ProviderCandidate.priority] first;
  /// ties broken by declaration order (stable).
  Future<ProviderSelection> select({
    AiMode mode = AiMode.localOnly,
    CapabilityRequirement require = const CapabilityRequirement(),
  }) async {
    if (_candidates.isEmpty) {
      return ProviderSelection.none(
        reason: NoProviderReason.noCandidates,
        explanation: 'No AI providers are configured.',
      );
    }

    final p = platform;

    // 1) Platform filter.
    final onPlatform =
        _candidates.where((c) => c.supportsPlatform(p)).toList();
    if (onPlatform.isEmpty) {
      return ProviderSelection.none(
        reason: NoProviderReason.unsupportedPlatform,
        explanation: 'No provider supports platform ${p.wireName}.',
      );
    }

    // 2) Capability filter.
    final capable =
        onPlatform.where((c) => _satisfies(c, require)).toList();
    if (capable.isEmpty) {
      return ProviderSelection.none(
        reason: NoProviderReason.capabilityUnmet,
        explanation: 'No provider on ${p.wireName} meets the required '
            'capabilities.',
      );
    }

    // 3) Mode filter: split local vs cloud, honoring the policy.
    final local = capable.where((c) => !c.isCloud).toList();
    final cloud = capable.where((c) => c.isCloud).toList();

    List<ProviderCandidate> allowed;
    switch (mode) {
      case AiMode.localOnly:
        if (local.isEmpty) {
          return ProviderSelection.none(
            reason: NoProviderReason.cloudDisallowed,
            explanation:
                'Only cloud providers fit, but mode is local-only.',
          );
        }
        allowed = local;
        break;
      case AiMode.hybrid:
      case AiMode.cloudOptional:
        // Prefer local; fall back to cloud.
        allowed = [...local, ...cloud];
        break;
    }

    // 4) Rank: priority desc, stable by original order.
    allowed = _rank(allowed);

    // 5) Pick the first available one.
    for (final c in allowed) {
      if (await c.isAvailable()) {
        return ProviderSelection.selected(
          engine: c.create(),
          kind: c.kind,
          explanation: 'Chose ${c.kind.wireName} on ${p.wireName}'
              '${c.isCloud ? ' (cloud)' : ''}.',
        );
      }
    }

    return ProviderSelection.none(
      reason: NoProviderReason.noneAvailable,
      explanation: 'Fitting providers exist on ${p.wireName} but none are '
          'currently available.',
    );
  }

  bool _satisfies(ProviderCandidate c, CapabilityRequirement r) {
    if (r.toolCalling && !c.capabilities.toolCalling) return false;
    if (r.streaming && !c.capabilities.streaming) return false;
    if (r.structuredOutput && !c.capabilities.structuredOutput) return false;
    return true;
  }

  List<ProviderCandidate> _rank(List<ProviderCandidate> list) {
    final indexed = [
      for (var i = 0; i < list.length; i++) (i, list[i]),
    ];
    indexed.sort((a, b) {
      final byPriority = b.$2.priority.compareTo(a.$2.priority);
      if (byPriority != 0) return byPriority;
      return a.$1.compareTo(b.$1); // stable
    });
    return [for (final e in indexed) e.$2];
  }
}
