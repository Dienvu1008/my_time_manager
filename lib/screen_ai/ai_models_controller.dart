import 'package:flutter/foundation.dart';

import '../ai/config/ai_config.dart';
import '../ai/config/ai_config_service.dart';
import '../ai/models/model_info.dart';
import '../ai/models/ollama_model_manager.dart';

/// Drives the model-management screen: lists installed Ollama models, pulls new
/// ones (with progress), deletes them, and selects the active default.
///
/// Builds an [OllamaModelManager] from the saved [AiConfig] so it targets the
/// same server as the assistant.
class AiModelsController extends ChangeNotifier {
  AiModelsController({AiConfigService? configService})
      : _configService = configService ?? AiConfigService();

  final AiConfigService _configService;
  OllamaModelManager? _manager;

  List<ModelInfo> _models = [];
  List<ModelInfo> get models => List.unmodifiable(_models);

  String? _selectedId;
  String? get selectedId => _selectedId;

  bool _loading = false;
  bool get loading => _loading;

  String? _message;
  String? get message => _message;

  // Download progress for the model currently being pulled (null when idle).
  String? _pullingId;
  String? get pullingId => _pullingId;
  double? _pullFraction;
  double? get pullFraction => _pullFraction;

  Future<OllamaModelManager> _mgr() async {
    if (_manager != null) return _manager!;
    final config = await _configService.load();
    return _manager = OllamaModelManager(config: config);
  }

  Future<void> refresh() async {
    _loading = true;
    _message = null;
    notifyListeners();
    try {
      final mgr = await _mgr();
      _models = await mgr.list();
      _selectedId = await mgr.selected();
    } catch (e) {
      _models = [];
      _message = 'Could not load models: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> select(String modelId) async {
    final mgr = await _mgr();
    _selectedId = await mgr.select(modelId);
    _message = 'Selected "$modelId".';
    notifyListeners();
  }

  Future<void> delete(String modelId) async {
    try {
      final mgr = await _mgr();
      await mgr.delete(modelId);
      _message = 'Deleted "$modelId".';
      await refresh();
    } catch (e) {
      _message = 'Delete failed: $e';
      notifyListeners();
    }
  }

  /// Pull a model, updating [pullingId]/[pullFraction] as it progresses.
  Future<void> pull(String modelId) async {
    if (modelId.trim().isEmpty) return;
    _pullingId = modelId;
    _pullFraction = null;
    _message = null;
    notifyListeners();

    final mgr = await _mgr();
    await for (final p in mgr.download(modelId)) {
      if (p.isError) {
        _message = 'Pull failed: ${p.message}';
        break;
      }
      _pullFraction = p.fraction;
      if (p.isDone) {
        _message = 'Pulled "$modelId".';
        break;
      }
      notifyListeners();
    }
    _pullingId = null;
    _pullFraction = null;
    notifyListeners();
    await refresh();
  }

  @override
  void dispose() {
    _manager?.dispose();
    super.dispose();
  }
}
