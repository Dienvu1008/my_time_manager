import '../../domain/repositories/archive_repository.dart';
import '../../screen_archive/model_archived_item.dart';
import '../database/database_manager.dart';

/// SQLite-backed [ArchiveRepository]. Delegates to [DatabaseManager], preserving
/// its archive cascade / unarchive-by-timestamp semantics exactly.
class SqliteArchiveRepository implements ArchiveRepository {
  SqliteArchiveRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<ArchivedItem>> getArchivedItems() => _db.archivedItems();

  @override
  Future<void> unarchive(ArchivedItem item) {
    switch (item.type) {
      case ArchivedItemType.taskList:
        return _db.unarchiveTaskList(item.id);
      case ArchivedItemType.task:
        return _db.unarchiveTask(item.id);
      case ArchivedItemType.calendarEvent:
        return _db.unarchiveCalendarEvent(item.id);
    }
  }

  @override
  Future<void> moveToTrash(ArchivedItem item) async {
    // Unarchive first, then soft-delete, so the item shows correctly in trash.
    switch (item.type) {
      case ArchivedItemType.taskList:
        await _db.unarchiveTaskList(item.id);
        await _db.softDeleteTaskList(item.id);
        break;
      case ArchivedItemType.task:
        await _db.unarchiveTask(item.id);
        await _db.softDeleteTask(item.id);
        break;
      case ArchivedItemType.calendarEvent:
        await _db.unarchiveCalendarEvent(item.id);
        await _db.softDeleteCalendarEvent(item.id);
        break;
    }
  }
}
