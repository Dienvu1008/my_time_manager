import '../../domain/models/model_ai_action_log.dart';
import '../../domain/repositories/ai_action_log_repository.dart';
import '../tools/tool_result.dart';

/// Sink for the AI action audit log (Phase C8b). The [ToolExecutor] records
/// one entry per WRITE / DESTRUCTIVE tool execution attempt. Implementations
/// must not throw (the executor also guards against it).
abstract interface class AiActionLog {
  Future<void> record(AiActionLogEntry entry);
}

/// Default sink: records nothing.
class NoOpAiActionLog implements AiActionLog {
  const NoOpAiActionLog();

  @override
  Future<void> record(AiActionLogEntry entry) async {}
}

/// Persists entries through an [AiActionLogRepository]; errors are swallowed
/// so auditing can never break the agent loop.
class RepositoryAiActionLog implements AiActionLog {
  const RepositoryAiActionLog(this._repository);

  final AiActionLogRepository _repository;

  @override
  Future<void> record(AiActionLogEntry entry) async {
    try {
      await _repository.record(entry);
    } catch (_) {
      // Best-effort audit; never propagate.
    }
  }
}

/// Redaction / length limits for what goes into the log. Free text the user
/// authored (descriptions, note content…) is never stored verbatim.
class AiActionLogFormat {
  const AiActionLogFormat._();

  static const int maxArgsLength = 500;
  static const int maxResultLength = 200;
  static const int maxErrorLength = 300;
  static const int maxTitleLength = 40;
  static const int maxScalarLength = 64;

  static const Set<String> _titleKeys = {'title', 'name', 'query'};
  static const Set<String> _freeTextKeys = {
    'description',
    'content',
    'location',
    'notes',
    'note',
    'text',
    'body',
  };

  static String _cap(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  static bool _isIdKey(String key) => key == 'id' || key.endsWith('Id');

  static String _value(String key, Object? v) {
    if (v == null) return 'null';
    if (v is num || v is bool) return '$v';
    if (v is List) return '[${v.length} items]';
    if (v is Map) return '{…}';
    final s = v.toString();
    if (_isIdKey(key)) return _cap(s, maxScalarLength);
    if (_titleKeys.contains(key)) return _cap(s, maxTitleLength);
    if (_freeTextKeys.contains(key)) return '<${s.length} chars>';
    // Short enum-like tokens (no whitespace) are kept; everything else is
    // free text and only its length is recorded.
    if (s.length <= 32 && !s.contains(RegExp(r'\s'))) return s;
    return '<${s.length} chars>';
  }

  /// `{key: value, …}` with keys sorted and values redacted, ≤ 500 chars.
  static String summarizeArgs(Map<String, dynamic> args) {
    final keys = args.keys.toList()..sort();
    final body = keys.map((k) => '$k: ${_value(k, args[k])}').join(', ');
    return _cap('{$body}', maxArgsLength);
  }

  /// Short success summary: ids / title from a Map result, else `ok`.
  static String? summarizeResult(ToolResult result) {
    if (!result.success) return null;
    final data = result.data;
    if (data is Map) {
      final parts = <String>[
        for (final k in const ['id', 'ruleId', 'lessonId'])
          if (data[k] != null) '$k: ${_cap('${data[k]}', maxScalarLength)}',
        if (data['title'] is String)
          'title: ${_cap(data['title'] as String, maxTitleLength)}',
      ];
      if (parts.isNotEmpty) return _cap(parts.join(', '), maxResultLength);
    }
    return 'ok';
  }

  /// `code: message`, ≤ 300 chars, or null on success.
  static String? errorOf(ToolResult result) {
    if (result.success) return null;
    return _cap('${result.errorCode}: ${result.errorMessage}', maxErrorLength);
  }
}
