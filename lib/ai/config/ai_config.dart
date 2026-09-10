/// Which inference backend to use. The concrete engines are added in later
/// phases; this enum lets configuration and (Phase 10) routing refer to them
/// without importing provider code.
enum AiProviderKind {
  /// Local Ollama server (desktop-first). Phase 2.
  ollama,

  /// Embedded llama.cpp (mobile-first). Phase 9.
  llamaCpp,

  /// A remote cloud provider (optional fallback). Later phase.
  cloud;

  String get wireName => name;

  static AiProviderKind fromWireName(String value) =>
      AiProviderKind.values.firstWhere(
        (p) => p.wireName == value,
        orElse: () => throw ArgumentError('Unknown AiProviderKind: $value'),
      );
}

/// Privacy/execution mode. Local-first by default: personal data stays on the
/// device unless the user explicitly opts into a cloud provider.
enum AiMode {
  /// Only local providers may be used.
  localOnly,

  /// Prefer local, but a cloud provider may be used as a fallback.
  hybrid,

  /// Cloud is allowed (still requires an explicit provider choice).
  cloudOptional;

  String get wireName => name;

  static AiMode fromWireName(String value) => AiMode.values.firstWhere(
        (m) => m.wireName == value,
        orElse: () => throw ArgumentError('Unknown AiMode: $value'),
      );
}

/// Provider-independent AI configuration.
///
/// Holds the selected provider, mode, default model, and an optional endpoint
/// override. Defaults are conservative and local-first; nothing here is
/// hard-coded into logic — a provider reads [endpoint]/[defaultModel] at
/// construction and callers may override them. The default Ollama endpoint is
/// exposed as a named constant so it is configurable rather than buried.
class AiConfig {
  const AiConfig({
    this.provider = AiProviderKind.ollama,
    this.mode = AiMode.localOnly,
    this.defaultModel,
    this.endpoint,
    this.requestTimeout = const Duration(seconds: 60),
  });

  /// The conventional local Ollama endpoint. Used only as a fallback when
  /// [endpoint] is null; callers/providers may override.
  static const String defaultOllamaEndpoint = 'http://localhost:11434';

  final AiProviderKind provider;
  final AiMode mode;

  /// Default model id (e.g. an Ollama model tag). Null lets the provider decide.
  final String? defaultModel;

  /// Base endpoint for network providers (e.g. Ollama). Null = provider default.
  final String? endpoint;

  /// Default per-request timeout applied by providers that honor it.
  final Duration requestTimeout;

  /// True when cloud providers are permitted by the current [mode].
  bool get allowsCloud => mode != AiMode.localOnly;

  /// The effective endpoint for the current provider, applying provider-specific
  /// defaults when [endpoint] is not set.
  String? get effectiveEndpoint {
    if (endpoint != null) return endpoint;
    switch (provider) {
      case AiProviderKind.ollama:
        return defaultOllamaEndpoint;
      case AiProviderKind.llamaCpp:
      case AiProviderKind.cloud:
        return null;
    }
  }

  AiConfig copyWith({
    AiProviderKind? provider,
    AiMode? mode,
    String? defaultModel,
    String? endpoint,
    Duration? requestTimeout,
  }) {
    return AiConfig(
      provider: provider ?? this.provider,
      mode: mode ?? this.mode,
      defaultModel: defaultModel ?? this.defaultModel,
      endpoint: endpoint ?? this.endpoint,
      requestTimeout: requestTimeout ?? this.requestTimeout,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.wireName,
        'mode': mode.wireName,
        if (defaultModel != null) 'defaultModel': defaultModel,
        if (endpoint != null) 'endpoint': endpoint,
        'requestTimeoutMs': requestTimeout.inMilliseconds,
      };

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      provider: AiProviderKind.fromWireName(json['provider'] as String),
      mode: AiMode.fromWireName(json['mode'] as String),
      defaultModel: json['defaultModel'] as String?,
      endpoint: json['endpoint'] as String?,
      requestTimeout: Duration(
        milliseconds: (json['requestTimeoutMs'] as int?) ?? 60000,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiConfig &&
        other.provider == provider &&
        other.mode == mode &&
        other.defaultModel == defaultModel &&
        other.endpoint == endpoint &&
        other.requestTimeout == requestTimeout;
  }

  @override
  int get hashCode =>
      Object.hash(provider, mode, defaultModel, endpoint, requestTimeout);

  @override
  String toString() =>
      'AiConfig(provider: $provider, mode: $mode, model: $defaultModel, '
      'endpoint: $effectiveEndpoint)';
}
