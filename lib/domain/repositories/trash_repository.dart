import '../../screen_trash/model_trashed_item.dart';

/// Domain boundary for the **trash** (soft-delete) feature.
///
/// Trash is inherently *cross-entity*: it aggregates task lists, tasks, and
/// calendar events into one list, and supports "empty trash" / auto-purge that
/// span all of them. That aggregate capability does not belong to any single
/// entity repository, so it earns its own boundary here.
///
/// Per-entity soft-delete/restore (e.g. `TaskRepository.softDeleteTask`) still
/// lives on the entity repositories; this repository provides the unified
/// aggregate view and the type-dispatched restore / permanent-delete used by
/// the Trash screen and, in the future, by AI tools.
abstract class TrashRepository {
  /// All items currently in the trash, most recently deleted first.
  Future<List<TrashedItem>> getTrashedItems();

  /// Restore a trashed item (dispatches by [TrashedItem.type]).
  Future<void> restore(TrashedItem item);

  /// Permanently delete a trashed item (dispatches by [TrashedItem.type]).
  Future<void> permanentlyDelete(TrashedItem item);

  /// Permanently delete every item currently in the trash.
  Future<void> emptyTrash();

  /// Permanently delete trashed items older than [retentionDays]. Returns the
  /// number of rows removed. Called at app startup.
  Future<int> purgeExpiredTrash(int retentionDays);
}
