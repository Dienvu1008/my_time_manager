/// Thrown internally by [ToolArgs] when a required argument is missing or has
/// the wrong type. Tools catch this and convert it to a failed ToolResult with
/// code `invalid_arguments`, so it never escapes the tool boundary.
class ToolArgumentError implements Exception {
  const ToolArgumentError(this.message);
  final String message;
  @override
  String toString() => 'ToolArgumentError: $message';
}

/// A small, dependency-free helper for reading and validating tool arguments
/// from the decoded JSON map. Keeps every tool's validation consistent.
class ToolArgs {
  const ToolArgs(this._map);
  final Map<String, dynamic> _map;

  bool has(String key) => _map.containsKey(key) && _map[key] != null;

  /// Required string. Throws [ToolArgumentError] if missing/blank/not a string.
  String requireString(String key, {bool allowEmpty = false}) {
    final v = _map[key];
    if (v is! String) {
      throw ToolArgumentError('"$key" is required and must be a string.');
    }
    if (!allowEmpty && v.trim().isEmpty) {
      throw ToolArgumentError('"$key" must not be empty.');
    }
    return v;
  }

  /// Optional string, or null when absent.
  String? optString(String key) {
    final v = _map[key];
    if (v == null) return null;
    if (v is! String) {
      throw ToolArgumentError('"$key" must be a string.');
    }
    return v;
  }

  /// Optional bool with a [fallback] default.
  bool optBool(String key, {bool fallback = false}) {
    final v = _map[key];
    if (v == null) return fallback;
    if (v is! bool) {
      throw ToolArgumentError('"$key" must be a boolean.');
    }
    return v;
  }

  /// Optional int (accepts num), or null when absent.
  int? optInt(String key) {
    final v = _map[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    throw ToolArgumentError('"$key" must be an integer.');
  }

  /// Optional enum given by its `.name`, or null when absent. Throws on an
  /// unknown name (never silently defaults).
  T? optEnum<T extends Enum>(String key, List<T> values) {
    final raw = optString(key);
    if (raw == null) return null;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    throw ToolArgumentError(
        '"$key" must be one of: ${values.map((v) => v.name).join(', ')}.');
  }

  /// Required number as double.
  double requireDouble(String key) {
    final v = _map[key];
    if (v is num) return v.toDouble();
    throw ToolArgumentError('"$key" is required and must be a number.');
  }

  /// Optional ISO-8601 date/datetime, or null when absent. Throws on a present
  /// but unparseable value.
  DateTime? optDateTime(String key) {
    final v = _map[key];
    if (v == null) return null;
    if (v is! String) {
      throw ToolArgumentError('"$key" must be an ISO-8601 date string.');
    }
    final parsed = DateTime.tryParse(v);
    if (parsed == null) {
      throw ToolArgumentError('"$key" is not a valid ISO-8601 date: "$v".');
    }
    return parsed;
  }

  /// Required ISO-8601 date/datetime.
  DateTime requireDateTime(String key) {
    final v = optDateTime(key);
    if (v == null) {
      throw ToolArgumentError('"$key" is required (ISO-8601 date string).');
    }
    return v;
  }
}
