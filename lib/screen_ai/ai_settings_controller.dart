import 'package:flutter/foundation.dart';

import '../ai/config/ai_config.dart';
import '../ai/config/ai_config_service.dart';
import '../ai/core/ai_exception.dart';
import '../ai/providers/ollama/ollama_ai_engine.dart';

/// Loading/status of the settings screen.
enum AiSettingsStatus { idle, loadingModels, testing }

/// Drives the AI Settings screen: loads the saved [AiConfig], lets the user
/// edit endpoint/model/mode, fetches the installed models from the Ollama
/// server for a picker, tests connectivity, and saves.
///
/// It builds a throwaway [OllamaAiEngine] from the currently-edited endpoint to
/// query the server — so "list models" / "test" reflect the value being edited,
/// not the saved one.
class AiSettingsController extends ChangeNotifier {
  AiSettingsController({AiConfigService? service})
      : _service = service ?? AiConfigService();

  final AiConfigService _service;

  AiConfig _config = const AiConfig();
  AiConfig get config => _config;

  AiSettingsStatus _status = AiSettingsStatus.idle;
  AiSettingsStatus get status => _status;

  List<String> _models = [];
  List<String> get models => List.unmodifiable(_models);

  String? _message;
  String? get message => _message;

  bool get isBusy => _status != AiSettingsStatus.idle;

  /// Load the saved config and (best-effort) the model list.
  Future<void> init() async {
    _config = await _service.load();
    notifyListeners();
    await refreshModels();
  }

  void setEndpoint(String? endpoint) {
    final trimmed = endpoint?.trim();
    _config = _config.copyWith(
      endpoint: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    notifyListeners();
  }

  void setModel(String? model) {
    _config = _config.copyWith(defaultModel: model);
    notifyListeners();
  }

  void setMode(AiMode mode) {
    _config = _config.copyWith(mode: mode);
    notifyListeners();
  }

  /// Fetch installed models from the server using the edited endpoint.
  Future<void> refreshModels() async {
    _setStatus(AiSettingsStatus.loadingModels, null);
    final engine = OllamaAiEngine(config: _config);
    try {
      _models = await engine.listModels();
      // If no model is selected yet, default to the first available one.
      if ((_config.defaultModel == null || _config.defaultModel!.isEmpty) &&
          _models.isNotEmpty) {
        _config = _config.copyWith(defaultModel: _models.first);
      }
      _setStatus(AiSettingsStatus.idle,
          _models.isEmpty ? 'No models installed on the server.' : null);
    } on AiException catch (e) {
      _models = [];
      _setStatus(AiSettingsStatus.idle, e.message);
    } finally {
      engine.dispose();
    }
  }

  /// Test connectivity to the server at the edited endpoint.
  Future<void> testConnection() async {
    _setStatus(AiSettingsStatus.testing, null);
    final engine = OllamaAiEngine(config: _config);
    try {
      final ok = await engine.isAvailable();
      _setStatus(AiSettingsStatus.idle,
          ok ? 'Connected to Ollama.' : 'Could not reach the server.');
    } finally {
      engine.dispose();
    }
  }

  /// Persist the current config.
  Future<void> save() async {
    await _service.save(_config);
    _message = 'Saved.';
    notifyListeners();
  }

  void _setStatus(AiSettingsStatus status, String? message) {
    _status = status;
    _message = message;
    notifyListeners();
  }
}
