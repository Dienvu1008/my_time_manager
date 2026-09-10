import 'dart:async';

/// A minimal, dependency-free cooperative cancellation signal.
///
/// The caller holds an [AiCancellationToken] and calls [cancel]. A provider
/// checks [isCancelled] at safe points and/or awaits [whenCancelled] to abort
/// in-flight work (e.g. close an HTTP stream). Cancellation is one-way and
/// idempotent.
class AiCancellationToken {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes when cancellation is requested. Never completes with an error.
  Future<void> get whenCancelled => _completer.future;

  /// Request cancellation. Safe to call multiple times.
  void cancel() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// Throws [StateError]-free helper: run [action] unless already cancelled.
  /// Returns null when cancelled without running.
  T? guard<T>(T Function() action) => isCancelled ? null : action();
}
