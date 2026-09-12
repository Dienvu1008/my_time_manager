import 'package:shared_preferences/shared_preferences.dart';

import 'ai_config.dart';

/// Persists and loads the user's [AiConfig] via SharedPreferences, so the AI
/// backend/model/endpoint choices survive restarts. Local-first defaults are
/// applied when nothing is stored.
///
/// Kept small and self-contained (like the app's other persistence helpers);
/// it does not depend on any provider implementation.
class AiConfigService {
  AiConfigService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _kProvider = 'ai.provider';
  static const _kMode = 'ai.mode';
  static const _kModel = 'ai.defaultModel';
  static const _kEndpoint = 'ai.endpoint';
  static const _kTimeoutMs = 'ai.requestTimeoutMs';
  static const _kTimezone = 'ai.timezone';
  static const _kRetentionDays = 'ai.chatHistoryRetentionDays';

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Load the stored config, falling back to safe local-first defaults.
  Future<AiConfig> load() async {
    final p = await _p;
    const defaults = AiConfig();
    return AiConfig(
      provider: _readProvider(p) ?? defaults.provider,
      mode: _readMode(p) ?? defaults.mode,
      defaultModel: p.getString(_kModel),
      endpoint: p.getString(_kEndpoint),
      requestTimeout: p.containsKey(_kTimeoutMs)
          ? Duration(milliseconds: p.getInt(_kTimeoutMs)!)
          : defaults.requestTimeout,
      timezone: p.getString(_kTimezone),
      chatHistoryRetentionDays:
          p.containsKey(_kRetentionDays) ? p.getInt(_kRetentionDays) : null,
    );
  }

  /// Persist the given config.
  Future<void> save(AiConfig config) async {
    final p = await _p;
    await p.setString(_kProvider, config.provider.wireName);
    await p.setString(_kMode, config.mode.wireName);
    if (config.defaultModel != null) {
      await p.setString(_kModel, config.defaultModel!);
    } else {
      await p.remove(_kModel);
    }
    if (config.endpoint != null) {
      await p.setString(_kEndpoint, config.endpoint!);
    } else {
      await p.remove(_kEndpoint);
    }
    await p.setInt(_kTimeoutMs, config.requestTimeout.inMilliseconds);
    if (config.timezone != null) {
      await p.setString(_kTimezone, config.timezone!);
    } else {
      await p.remove(_kTimezone);
    }
    if (config.chatHistoryRetentionDays != null) {
      await p.setInt(_kRetentionDays, config.chatHistoryRetentionDays!);
    } else {
      await p.remove(_kRetentionDays);
    }
  }

  AiProviderKind? _readProvider(SharedPreferences p) {
    final v = p.getString(_kProvider);
    if (v == null) return null;
    try {
      return AiProviderKind.fromWireName(v);
    } catch (_) {
      return null;
    }
  }

  AiMode? _readMode(SharedPreferences p) {
    final v = p.getString(_kMode);
    if (v == null) return null;
    try {
      return AiMode.fromWireName(v);
    } catch (_) {
      return null;
    }
  }
}
