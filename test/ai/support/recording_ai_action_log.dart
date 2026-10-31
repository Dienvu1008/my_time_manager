import 'package:my_time_manager/ai/policy/ai_action_log.dart';
import 'package:my_time_manager/domain/models/model_ai_action_log.dart';

/// In-memory [AiActionLog] for tests (Phase C8b). Optionally throws on every
/// record to prove the executor swallows sink errors.
class RecordingAiActionLog implements AiActionLog {
  RecordingAiActionLog({this.throwOnRecord = false});

  final bool throwOnRecord;
  final List<AiActionLogEntry> entries = [];

  @override
  Future<void> record(AiActionLogEntry entry) async {
    if (throwOnRecord) throw StateError('sink failure');
    entries.add(entry);
  }
}
