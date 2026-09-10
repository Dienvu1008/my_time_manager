import '../../screen_archive/model_archived_item.dart';

/// Domain boundary for the **archive** feature.
///
/// Like trash, archive is cross-entity (task lists, tasks, calendar events) and
/// exposes an aggregate list plus type-dispatched operations. That aggregate
/// capability earns its own boundary; per-entity archive/unarchive still lives
/// on the entity repositories.
abstract class ArchiveRepository {
  /// All archived items, most recently archived first.
  Future<List<ArchivedItem>> getArchivedItems();

  /// Unarchive an item, returning it to the main screens (dispatches by type).
  Future<void> unarchive(ArchivedItem item);

  /// Move an archived item into the trash: unarchive it, then soft-delete it so
  /// it appears correctly in the trash (dispatches by type).
  Future<void> moveToTrash(ArchivedItem item);
}
