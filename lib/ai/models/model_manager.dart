import 'model_info.dart';

/// Progress of a long-running model operation (download / verify).
class ModelOperationProgress {
  const ModelOperationProgress({
    required this.modelId,
    required this.phase,
    this.receivedBytes,
    this.totalBytes,
    this.message,
  });

  final String modelId;

  /// e.g. 'downloading', 'verifying', 'done', 'error'.
  final String phase;
  final int? receivedBytes;
  final int? totalBytes;
  final String? message;

  /// Fraction complete in [0, 1] when byte counts are known, else null.
  double? get fraction {
    final total = totalBytes;
    final received = receivedBytes;
    if (total == null || received == null || total <= 0) return null;
    final f = received / total;
    return f < 0 ? 0 : (f > 1 ? 1 : f);
  }

  bool get isDone => phase == 'done';
  bool get isError => phase == 'error';

  @override
  String toString() =>
      'ModelOperationProgress($modelId, $phase, ${fraction ?? '?'})';
}

/// Manages the lifecycle of local models: listing installed ones, downloading
/// (installing) new ones, verifying integrity/availability, deleting, and
/// selecting the active one.
///
/// Provider-independent. The Ollama implementation talks to the Ollama server;
/// a future llama.cpp implementation (Phase 9) downloads GGUF files to disk and
/// verifies checksums. Large models are NEVER bundled in the app binary — they
/// are always fetched separately here.
abstract class ModelManager {
  /// A short id of the backing implementation (e.g. 'ollama').
  String get id;

  /// The models currently installed/available.
  Future<List<ModelInfo>> list();

  /// Install/download a model, streaming progress. The stream must end with a
  /// 'done' or 'error' event.
  Stream<ModelOperationProgress> download(String modelId);

  /// Verify a model is present and usable. Returns true if OK.
  Future<bool> verify(String modelId);

  /// Remove an installed model.
  Future<void> delete(String modelId);

  /// Select [modelId] as the active default (persisted). Returns the id chosen.
  Future<String> select(String modelId);

  /// The currently selected model id, if any.
  Future<String?> selected();
}
