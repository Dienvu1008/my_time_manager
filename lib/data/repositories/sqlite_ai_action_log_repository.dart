import '../../domain/models/model_ai_action_log.dart';
import '../../domain/repositories/ai_action_log_repository.dart';
import '../database/daos/ai_action_log_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [AiActionLogRepository] (Phase C8b) over [AiActionLogDao].
class SqliteAiActionLogRepository implements AiActionLogRepository {
  SqliteAiActionLogRepository({DatabaseManager? databaseManager})
      : _dao = AiActionLogDao(
            () => (databaseManager ?? DatabaseManager()).database);

  final AiActionLogDao _dao;

  @override
  Future<void> record(AiActionLogEntry entry) => _dao.insert(entry);

  @override
  Future<List<AiActionLogEntry>> getEntries({
    AiActionOutcome? outcome,
    int limit = 500,
  }) =>
      _dao.query(outcome: outcome, limit: limit);

  @override
  Future<AiActionLogEntry?> getEntry(String id) => _dao.getById(id);

  @override
  Future<int> clear() => _dao.clear();

  @override
  Future<int> purge({
    required DateTime now,
    int maxEntries = AiActionLogRetention.maxEntries,
    Duration maxAge = AiActionLogRetention.maxAge,
  }) =>
      _dao.purge(now: now, maxEntries: maxEntries, maxAge: maxAge);
}
