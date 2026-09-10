import 'dart:async';
import 'dart:io';

import '../config/ai_config_service.dart';
import 'gguf_model_downloader.dart';
import 'model_info.dart';
import 'model_manager.dart';
import 'model_registry.dart';

/// Resolves the directory where GGUF model files are stored. Injectable so
/// tests can point at a temp dir without depending on path_provider/platform.
typedef ModelsDirResolver = Future<Directory> Function();

/// [ModelManager] for GGUF models run by llama.cpp. Unlike the Ollama manager,
/// it owns the files: it downloads them (with checksum verification) to a
/// models directory, lists what is on disk, deletes files, and selects the
/// active model (persisted).
///
/// The [registry] provides download URLs + checksums for known models. This
/// manager is pure Dart (file IO + the [GgufModelDownloader]) and unit-testable
/// with a temp directory and a mock HTTP client — no native llama.cpp needed to
/// exercise the management logic.
class LlamaCppModelManager implements ModelManager {
  LlamaCppModelManager({
    required ModelRegistry registry,
    required ModelsDirResolver modelsDir,
    GgufModelDownloader? downloader,
    AiConfigService? configService,
  })  : _registry = registry,
        _modelsDir = modelsDir,
        _downloader = downloader ?? GgufModelDownloader(),
        _configService = configService ?? AiConfigService();

  final ModelRegistry _registry;
  final ModelsDirResolver _modelsDir;
  final GgufModelDownloader _downloader;
  final AiConfigService _configService;

  @override
  String get id => 'llama_cpp';

  /// The local file path a model id maps to.
  Future<String> pathFor(String modelId) async {
    final dir = await _modelsDir();
    return '${dir.path}${Platform.pathSeparator}$modelId';
  }

  @override
  Future<List<ModelInfo>> list() async {
    final dir = await _modelsDir();
    if (!await dir.exists()) return const [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.toLowerCase().endsWith('.gguf'))
        .toList();
    return [
      for (final f in files)
        _mergeWithRegistry(_idFromPath(f.path))
            .copyWith(installed: true, sizeBytes: await _sizeOf(f as File)),
    ];
  }

  @override
  Stream<ModelOperationProgress> download(String modelId) async* {
    final info = _registry.byId(modelId);
    if (info == null || info.downloadUrl == null) {
      yield ModelOperationProgress(
        modelId: modelId,
        phase: 'error',
        message: 'No download URL known for "$modelId".',
      );
      return;
    }
    final dest = await pathFor(modelId);
    yield* _downloader.download(
      modelId: modelId,
      url: info.downloadUrl!,
      destinationPath: dest,
      expectedSha256: info.checksum,
    );
  }

  @override
  Future<bool> verify(String modelId) async {
    final path = await pathFor(modelId);
    return File(path).exists();
  }

  @override
  Future<void> delete(String modelId) async {
    final path = await pathFor(modelId);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<String> select(String modelId) async {
    final current = await _configService.load();
    await _configService.save(current.copyWith(defaultModel: modelId));
    return modelId;
  }

  @override
  Future<String?> selected() async {
    final current = await _configService.load();
    return current.defaultModel;
  }

  ModelInfo _mergeWithRegistry(String id) {
    final known = _registry.byId(id);
    if (known != null) return known;
    return ModelInfo(id: id, name: id, format: ModelFormat.gguf);
  }

  static String _idFromPath(String path) {
    final sep = Platform.pathSeparator;
    final name = path.contains(sep) ? path.split(sep).last : path;
    return name;
  }

  static Future<int> _sizeOf(File f) async {
    try {
      return await f.length();
    } catch (_) {
      return 0;
    }
  }

  void dispose() => _downloader.dispose();
}
