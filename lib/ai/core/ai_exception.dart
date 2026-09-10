/// Categories of AI engine failures, provider-independent. Higher layers can
/// react to the kind without knowing which backend produced it.
enum AiErrorKind {
  /// The engine/backend is not reachable or not running.
  unavailable,

  /// The request timed out.
  timeout,

  /// The caller cancelled the request.
  cancelled,

  /// The requested model was not found / not installed.
  modelNotFound,

  /// The request was rejected as invalid.
  invalidRequest,

  /// The backend returned an error response.
  backend,

  /// Failed to parse the backend's response.
  parsing,

  /// Anything else.
  unknown,
}

/// A provider-independent AI failure. Providers throw this (mapping their own
/// errors into an [AiErrorKind]) so the agent never needs to catch
/// backend-specific exception types.
class AiException implements Exception {
  const AiException(
    this.kind,
    this.message, {
    this.cause,
  });

  const AiException.unavailable(String message, {Object? cause})
      : this(AiErrorKind.unavailable, message, cause: cause);
  const AiException.timeout(String message, {Object? cause})
      : this(AiErrorKind.timeout, message, cause: cause);
  const AiException.cancelled([String message = 'Request cancelled'])
      : this(AiErrorKind.cancelled, message);
  const AiException.modelNotFound(String message, {Object? cause})
      : this(AiErrorKind.modelNotFound, message, cause: cause);

  final AiErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'AiException(${kind.name}: $message${cause != null ? ', cause: $cause' : ''})';
}
