import '../../domain/repositories/focus_repository.dart';
import '../../screen_focus_timer/data/focus_sync_service.dart';
import '../../domain/models/model_focus_session.dart';
import '../database/database_manager.dart';
import '../database/daos/focus_session_dao.dart';

class SqliteFocusRepository implements FocusRepository {
  SqliteFocusRepository({
    DatabaseManager? databaseManager,
    FocusSyncService? syncService,
  })  : _dao = FocusSessionDao(() => (databaseManager ?? DatabaseManager()).database),
        _sync = syncService ?? const NoOpFocusSyncService();

  final FocusSessionDao _dao;
  final FocusSyncService _sync;

  @override
  Future<void> saveSession(FocusSession session) async {
    await _dao.insert(session);
    await _trySync(session);
  }

  Future<void> _trySync(FocusSession session) async {
    if (!_sync.isAvailable) return;
    final ok = await _sync.uploadSession(session);
    if (ok) {
      await _dao.update(session.copyWith(synced: true));
    }
  }

  @override
  Future<void> syncPending() async {
    if (!_sync.isAvailable) return;
    final pending = await _dao.unsynced();
    for (final session in pending) {
      final ok = await _sync.uploadSession(session);
      if (ok) {
        await _dao.update(session.copyWith(synced: true));
      }
    }
  }

  @override
  Future<List<FocusSession>> allSessions() => _dao.getAll();

  @override
  Future<List<FocusSession>> sessionsBetween(DateTime start, DateTime end) =>
      _dao.between(start, end);
}
