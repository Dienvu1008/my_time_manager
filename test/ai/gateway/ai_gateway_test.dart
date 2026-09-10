import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/config/ai_config.dart';
import 'package:my_time_manager/ai/core/ai_cancellation_token.dart';
import 'package:my_time_manager/ai/core/ai_capabilities.dart';
import 'package:my_time_manager/ai/core/ai_engine.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_stream_event.dart';
import 'package:my_time_manager/ai/gateway/ai_gateway.dart';
import 'package:my_time_manager/ai/gateway/platform_kind.dart';
import 'package:my_time_manager/ai/gateway/provider_candidate.dart';
import 'package:my_time_manager/ai/gateway/provider_selection.dart';

/// A trivial engine tagged with its provider id, so tests can assert which one
/// was chosen.
class _TagEngine implements AiEngine {
  _TagEngine(this._id);
  final String _id;
  @override
  String get id => _id;
  @override
  AiCapabilities get capabilities => const AiCapabilities();
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<AiResponse> generate(AiRequest r, {AiCancellationToken? cancelToken}) async =>
      const AiResponse(text: 'x');
  @override
  Stream<AiStreamEvent> stream(AiRequest r, {AiCancellationToken? cancelToken}) =>
      const Stream.empty();
}

ProviderCandidate _candidate({
  required AiProviderKind kind,
  required Set<PlatformKind> platforms,
  AiCapabilities caps = const AiCapabilities(streaming: true),
  bool isCloud = false,
  bool available = true,
  int priority = 0,
  String? engineId,
}) {
  return ProviderCandidate(
    kind: kind,
    supportedPlatforms: platforms,
    capabilities: caps,
    isCloud: isCloud,
    isAvailable: () async => available,
    priority: priority,
    create: () => _TagEngine(engineId ?? kind.wireName),
  );
}

AiGateway gateway(List<ProviderCandidate> c, PlatformKind on) =>
    AiGateway(candidates: c, platformResolver: () => on);

void main() {
  final ollamaDesktop = _candidate(
    kind: AiProviderKind.ollama,
    platforms: {PlatformKind.windows, PlatformKind.macos, PlatformKind.linux},
    caps: const AiCapabilities(streaming: true, toolCalling: true),
    priority: 10,
  );
  final llamaMobile = _candidate(
    kind: AiProviderKind.llamaCpp,
    platforms: {PlatformKind.android, PlatformKind.ios, PlatformKind.macos},
    caps: const AiCapabilities(streaming: true, toolCalling: false),
    priority: 5,
  );
  final cloud = _candidate(
    kind: AiProviderKind.cloud,
    platforms: PlatformKind.values.toSet(),
    caps: const AiCapabilities(streaming: true, toolCalling: true),
    isCloud: true,
  );

  test('no candidates -> none(noCandidates)', () async {
    final s = await gateway([], PlatformKind.windows).select();
    expect(s.isSelected, isFalse);
    expect(s.reason, NoProviderReason.noCandidates);
  });

  test('Windows local-only picks Ollama', () async {
    final s = await gateway([ollamaDesktop, llamaMobile], PlatformKind.windows)
        .select();
    expect(s.isSelected, isTrue);
    expect(s.kind, AiProviderKind.ollama);
    expect(s.engine!.id, 'ollama');
  });

  test('Android local-only picks llama.cpp (Ollama not on Android)', () async {
    final s = await gateway([ollamaDesktop, llamaMobile], PlatformKind.android)
        .select();
    expect(s.kind, AiProviderKind.llamaCpp);
  });

  test('unsupported platform -> none(unsupportedPlatform)', () async {
    final s = await gateway([ollamaDesktop], PlatformKind.android).select();
    expect(s.reason, NoProviderReason.unsupportedPlatform);
  });

  test('capability requirement filters out non-tool-calling providers',
      () async {
    // On macOS both fit the platform; require tool-calling -> only Ollama.
    final s = await gateway([llamaMobile, ollamaDesktop], PlatformKind.macos)
        .select(require: const CapabilityRequirement(toolCalling: true));
    expect(s.kind, AiProviderKind.ollama);
  });

  test('capability unmet -> none(capabilityUnmet)', () async {
    // Only llama.cpp on Android, but tool-calling required.
    final s = await gateway([llamaMobile], PlatformKind.android)
        .select(require: const CapabilityRequirement(toolCalling: true));
    expect(s.reason, NoProviderReason.capabilityUnmet);
  });

  test('local-only forbids cloud even if it is the only fit', () async {
    final s = await gateway([cloud], PlatformKind.windows)
        .select(mode: AiMode.localOnly);
    expect(s.reason, NoProviderReason.cloudDisallowed);
  });

  test('hybrid falls back to cloud when no local fits', () async {
    final s = await gateway([cloud], PlatformKind.windows)
        .select(mode: AiMode.hybrid);
    expect(s.kind, AiProviderKind.cloud);
  });

  test('hybrid still prefers local over cloud', () async {
    final s = await gateway([cloud, ollamaDesktop], PlatformKind.windows)
        .select(mode: AiMode.hybrid);
    expect(s.kind, AiProviderKind.ollama);
  });

  test('priority ranks equal candidates', () async {
    final low = _candidate(
        kind: AiProviderKind.llamaCpp,
        platforms: {PlatformKind.macos},
        priority: 1,
        engineId: 'low');
    final high = _candidate(
        kind: AiProviderKind.ollama,
        platforms: {PlatformKind.macos},
        priority: 9,
        engineId: 'high');
    final s = await gateway([low, high], PlatformKind.macos).select();
    expect(s.engine!.id, 'high');
  });

  test('skips an unavailable higher-priority provider', () async {
    final downHigh = _candidate(
        kind: AiProviderKind.ollama,
        platforms: {PlatformKind.windows},
        priority: 10,
        available: false,
        engineId: 'down');
    final upLow = _candidate(
        kind: AiProviderKind.cloud,
        platforms: {PlatformKind.windows},
        priority: 1,
        isCloud: true,
        engineId: 'up');
    final s = await gateway([downHigh, upLow], PlatformKind.windows)
        .select(mode: AiMode.hybrid);
    expect(s.engine!.id, 'up');
  });

  test('all fitting providers unavailable -> none(noneAvailable)', () async {
    final down = _candidate(
        kind: AiProviderKind.ollama,
        platforms: {PlatformKind.windows},
        available: false);
    final s = await gateway([down], PlatformKind.windows).select();
    expect(s.reason, NoProviderReason.noneAvailable);
  });
}
