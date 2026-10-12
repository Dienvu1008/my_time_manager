import '../../domain/repositories/focus_repository.dart';
import '../../screen_focus_timer/data/focus_sync_service.dart';
import '../../domain/models/model_focus_session.dart';
import '../database/database_manager.dart';

/// SQLite-backed [FocusRepository], following the LOCAL-FIRST principle.
///
/// - SQLite is the source of truth: every session is written to the DB first,
///   so the feature works fully offline / before Firebase is configured.
/// - After the local write, it best-effort syncs to the cloud via
///   [FocusSyncService]. If sync is unavailable or fails, the session stays
///   local with synced=false and is retried by [syncPending].
///
/// Thin adapter over the existing [DatabaseManager] singleton — it adds no new
/// persistence logic, preserving schema and sync semantics exactly.
class SqliteFocusRepository implements FocusRepository {
  SqliteFocusRepository({
    DatabaseManager? databaseManager,
    FocusSyncService? syncService,
  })  : _db = databaseManager ?? DatabaseManager(),
        _sync = syncService ?? const NoOpFocusSyncService();

  final DatabaseManager _db;
  final FocusSyncService _sync;

  @override
  Future<void> saveSession(FocusSession session) async {
    await _db.insertFocusSession(session);
    await _trySync(session);
  }

  /// Best-effort sync of a single session; marks it synced in the DB on success.
  Future<void> _trySync(FocusSession session) async {
    if (!_sync.isAvailable) return;
    final ok = await _sync.uploadSession(session);
    if (ok) {
      await _db.updateFocusSession(session.copyWith(synced: true));
    }
  }

  @override
  Future<void> syncPending() async {
    if (!_sync.isAvailable) return;
    final pending = await _db.unsyncedFocusSessions();
    for (final session in pending) {
      final ok = await _sync.uploadSession(session);
      if (ok) {
        await _db.updateFocusSession(session.copyWith(synced: true));
      }
    }
  }

  @override
  Future<List<FocusSession>> allSessions() => _db.focusSessions();

  @override
  Future<List<FocusSession>> sessionsBetween(DateTime start, DateTime end) =>
      _db.focusSessionsBetween(start, end);
}
