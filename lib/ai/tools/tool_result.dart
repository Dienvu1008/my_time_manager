/// The outcome of executing a [Tool]. Structured so the agent can feed it back
/// to the model as a tool message and so failures never propagate as thrown
/// exceptions through the agent loop.
class ToolResult {
  const ToolResult._({
    required this.success,
    this.data,
    this.errorCode,
    this.errorMessage,
  });

  /// A successful result carrying structured [data] (JSON-serializable).
  const ToolResult.ok(Object? data)
      : this._(success: true, data: data);

  /// A failed result with a machine-readable [code] and human-readable
  /// [message].
  const ToolResult.failure(String code, String message)
      : this._(success: false, errorCode: code, errorMessage: message);

  final bool success;

  /// Structured payload on success (Map/List/scalar — JSON-serializable).
  final Object? data;

  /// Stable error code on failure (e.g. `invalid_arguments`, `not_found`).
  final String? errorCode;

  /// Human-readable error description on failure.
  final String? errorMessage;

  /// Common failure codes, kept as constants to avoid typos.
  static const codeInvalidArguments = 'invalid_arguments';
  static const codeNotFound = 'not_found';
  static const codeDomainError = 'domain_error';
  static const codeUnknownTool = 'unknown_tool';
  static const codePermissionDenied = 'permission_denied';

  /// A JSON view suitable for feeding back to the model as a tool result.
  Map<String, dynamic> toJson() => success
      ? {'success': true, 'data': data}
      : {
          'success': false,
          'error': {'code': errorCode, 'message': errorMessage},
        };

  @override
  String toString() => success
      ? 'ToolResult.ok($data)'
      : 'ToolResult.failure($errorCode: $errorMessage)';
}
