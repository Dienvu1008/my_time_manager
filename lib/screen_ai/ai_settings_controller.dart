import 'package:flutter/foundation.dart';

import '../ai/config/ai_config.dart';
import '../ai/config/ai_config_service.dart';
import '../ai/config/device_timezone.dart' as tz;
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
  AiSettingsController({
    AiConfigService? service,
    tz.DeviceTimezoneResolver? timezoneResolver,
  })  : _service = service ?? AiConfigService(),
        _timezoneResolver = timezoneResolver ?? tz.deviceTimezone;

  final AiConfigService _service;
  final tz.DeviceTimezoneResolver _timezoneResolver;

  AiConfig _config = const AiConfig();
  AiConfig get config => _config;

  /// The device's IANA timezone (resolved on init, for display / the "device
  /// default" option).
  String _deviceTimezone = 'UTC';
  String get deviceTimezone => _deviceTimezone;

  /// The timezone actually in effect: the configured override, else the device
  /// one. Handy for the UI to show what the assistant will use.
  String get effectiveTimezoneName => _config.timezone ?? _deviceTimezone;

  /// A curated list of common IANA timezones for the picker (the device zone is
  /// always included even if not in this list).
  List<String> get availableTimezones {
    final set = {..._commonTimezones, _deviceTimezone};
    final list = set.toList()..sort();
    return list;
  }

  static const _commonTimezones = <String>[
    'UTC',
    'Asia/Ho_Chi_Minh',
    'Asia/Bangkok',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Asia/Seoul',
    'Asia/Shanghai',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Moscow',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Sao_Paulo',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  AiSettingsStatus _status = AiSettingsStatus.idle;
  AiSettingsStatus get status => _status;

  List<String> _models = [];
  List<String> get models => List.unmodifiable(_models);

  String? _message;
  String? get message => _message;

  bool get isBusy => _status != AiSettingsStatus.idle;

  /// Load the saved config, the device timezone, and (best-effort) the models.
  Future<void> init() async {
    _config = await _service.load();
    _deviceTimezone = await _timezoneResolver();
    notifyListeners();
    await refreshModels();
  }

  /// Set the timezone override. Pass null (or the device timezone) to use the
  /// device default (stored as null so it always tracks the device).
  void setTimezone(String? timezone) {
    if (timezone == null || timezone == _deviceTimezone) {
      _config = _config.copyWith(clearTimezone: true);
    } else {
      _config = _config.copyWith(timezone: timezone);
    }
    notifyListeners();
  }

  /// True when using the device default (no override stored).
  bool get usingDeviceTimezone => _config.timezone == null;

  /// The chat-history retention in days, or null = keep forever.
  int? get chatHistoryRetentionDays => _config.chatHistoryRetentionDays;

  /// Set how many days of chat history to keep. Pass null (or <= 0) to keep
  /// history forever (no auto-delete).
  void setChatHistoryRetentionDays(int? days) {
    if (days == null || days <= 0) {
      _config = _config.copyWith(clearChatHistoryRetentionDays: true);
    } else {
      _config = _config.copyWith(chatHistoryRetentionDays: days);
    }
    notifyListeners();
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
