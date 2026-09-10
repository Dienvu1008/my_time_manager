import '../../domain/repositories/trash_repository.dart';
import '../../screen_trash/model_trashed_item.dart';
import '../database/database_manager.dart';

/// SQLite-backed [TrashRepository]. Delegates to [DatabaseManager], preserving
/// its soft-delete cascade and restore-by-timestamp semantics exactly.
class SqliteTrashRepository implements TrashRepository {
  SqliteTrashRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<TrashedItem>> getTrashedItems() => _db.trashedItems();

  @override
  Future<void> restore(TrashedItem item) {
    switch (item.type) {
      case TrashedItemType.taskList:
        return _db.restoreTaskList(item.id);
      case TrashedItemType.task:
        return _db.restoreTask(item.id);
      case TrashedItemType.calendarEvent:
        return _db.restoreCalendarEvent(item.id);
    }
  }

  @override
  Future<void> permanentlyDelete(TrashedItem item) {
    switch (item.type) {
      case TrashedItemType.taskList:
        return _db.permanentlyDeleteTaskList(item.id);
      case TrashedItemType.task:
        return _db.permanentlyDeleteTask(item.id);
      case TrashedItemType.calendarEvent:
        return _db.deleteCalendarEvent(item.id);
    }
  }

  @override
  Future<void> emptyTrash() => _db.emptyTrash();

  @override
  Future<int> purgeExpiredTrash(int retentionDays) =>
      _db.purgeExpiredTrash(retentionDays);
}
