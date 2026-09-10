import 'model_info.dart';

/// A catalog of known models (curated/suggested), independent of what is
/// actually installed. For Ollama this can list suggested tags to pull; for
/// GGUF (Phase 9) it lists downloadable files with URLs + checksums.
///
/// Kept simple: an in-memory list with lookup + platform filtering. The live
/// "what is installed" view comes from the ModelManager, not from here.
class ModelRegistry {
  ModelRegistry([Iterable<ModelInfo> models = const []])
      : _models = List.of(models);

  final List<ModelInfo> _models;

  List<ModelInfo> get all => List.unmodifiable(_models);

  ModelInfo? byId(String id) {
    for (final m in _models) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Models of a given [format].
  List<ModelInfo> ofFormat(ModelFormat format) =>
      _models.where((m) => m.format == format).toList();

  /// Models supported on [platform] (support unspecified counts as supported).
  List<ModelInfo> supportedOn(String platform) =>
      _models.where((m) => m.supportsPlatform(platform)).toList();

  void add(ModelInfo model) => _models.add(model);
}
