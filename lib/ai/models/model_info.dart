/// The on-disk / runtime format of a model.
enum ModelFormat {
  /// A model managed by an Ollama server (identified by an Ollama tag).
  ollama,

  /// A GGUF file run by llama.cpp (Phase 9).
  gguf,

  /// A remote cloud model (no local file).
  cloud;

  String get wireName => name;

  static ModelFormat fromWireName(String value) =>
      ModelFormat.values.firstWhere(
        (f) => f.wireName == value,
        orElse: () => throw ArgumentError('Unknown ModelFormat: $value'),
      );
}

/// What a model can do (mirrors the shape of AiCapabilities but is about the
/// *model*, used for selection/routing).
class ModelCapabilities {
  const ModelCapabilities({
    this.toolCalling = false,
    this.streaming = true,
    this.contextLength,
  });

  final bool toolCalling;
  final bool streaming;
  final int? contextLength;

  Map<String, dynamic> toJson() => {
        'toolCalling': toolCalling,
        'streaming': streaming,
        if (contextLength != null) 'contextLength': contextLength,
      };

  factory ModelCapabilities.fromJson(Map<String, dynamic> json) =>
      ModelCapabilities(
        toolCalling: (json['toolCalling'] as bool?) ?? false,
        streaming: (json['streaming'] as bool?) ?? true,
        contextLength: json['contextLength'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is ModelCapabilities &&
      other.toolCalling == toolCalling &&
      other.streaming == streaming &&
      other.contextLength == contextLength;

  @override
  int get hashCode => Object.hash(toolCalling, streaming, contextLength);
}

/// Provider-independent description of a model the app knows about.
///
/// For Ollama models, [id] is the Ollama tag (e.g. `llama3:latest`) and no
/// [downloadUrl]/[checksum] is needed (Ollama manages the files). For GGUF
/// models (Phase 9), [downloadUrl] + [checksum] drive a real file download and
/// integrity check.
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.name,
    required this.format,
    this.sizeBytes,
    this.capabilities = const ModelCapabilities(),
    this.downloadUrl,
    this.checksum,
    this.platformSupport = const {},
    this.installed = false,
  });

  /// Stable identifier. For Ollama, the model tag.
  final String id;

  /// Human-friendly display name.
  final String name;

  final ModelFormat format;

  /// Size in bytes if known.
  final int? sizeBytes;

  final ModelCapabilities capabilities;

  /// Where to download the model file (GGUF); null for Ollama/cloud.
  final String? downloadUrl;

  /// Expected checksum (e.g. 'sha256:...') to verify a downloaded file.
  final String? checksum;

  /// Platform → supported flag (e.g. {'android': true, 'ios': false}). Empty =
  /// unspecified / assume supported.
  final Map<String, bool> platformSupport;

  /// Whether the model is currently installed/available.
  final bool installed;

  ModelInfo copyWith({
    String? id,
    String? name,
    ModelFormat? format,
    int? sizeBytes,
    ModelCapabilities? capabilities,
    String? downloadUrl,
    String? checksum,
    Map<String, bool>? platformSupport,
    bool? installed,
  }) {
    return ModelInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      capabilities: capabilities ?? this.capabilities,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      checksum: checksum ?? this.checksum,
      platformSupport: platformSupport ?? this.platformSupport,
      installed: installed ?? this.installed,
    );
  }

  /// True when [platform] is supported (or support is unspecified).
  bool supportsPlatform(String platform) =>
      platformSupport[platform] ?? true;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'format': format.wireName,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        'capabilities': capabilities.toJson(),
        if (downloadUrl != null) 'downloadUrl': downloadUrl,
        if (checksum != null) 'checksum': checksum,
        if (platformSupport.isNotEmpty) 'platformSupport': platformSupport,
        'installed': installed,
      };

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        format: ModelFormat.fromWireName(json['format'] as String),
        sizeBytes: json['sizeBytes'] as int?,
        capabilities: json['capabilities'] == null
            ? const ModelCapabilities()
            : ModelCapabilities.fromJson(
                json['capabilities'] as Map<String, dynamic>),
        downloadUrl: json['downloadUrl'] as String?,
        checksum: json['checksum'] as String?,
        platformSupport: (json['platformSupport'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as bool)) ??
            const {},
        installed: (json['installed'] as bool?) ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is ModelInfo &&
      other.id == id &&
      other.format == format &&
      other.installed == installed;

  @override
  int get hashCode => Object.hash(id, format, installed);

  @override
  String toString() =>
      'ModelInfo($id, ${format.wireName}, installed: $installed)';
}
