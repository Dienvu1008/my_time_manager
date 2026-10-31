import '../models/model_project.dart';
import '../models/model_project_item.dart';

/// Domain boundary for **projects** and their items (Core Track C6).
///
/// A project and its items (`project_items`) form one aggregate. An item
/// references an existing entity (task list, task, note, goal, calendar event)
/// by `entityType` + `entityId`; membership is many-to-many. Tasks of a linked
/// task list are implicitly part of the project (derived at read time by
/// ProjectWorkspaceService, never stored as items).
///
/// Callers depend on this interface, never on [DatabaseManager] / SQLite
/// directly. Implementations live in `lib/data/repositories/`.
///
/// Trash and archive of a project do NOT cascade to its items. Hard delete
/// removes only its items (FK cascade), NEVER the linked entities.
abstract class ProjectRepository {
  /// All visible projects (excludes trashed and archived), oldest first.
  Future<List<Project>> getProjects();

  /// A single project by id (any state), or null if it does not exist.
  Future<Project?> getProject(String id);

  /// Create a new project.
  Future<void> createProject(Project project);

  /// Update an existing project.
  Future<void> updateProject(Project project);

  /// Hard-delete a project (cascades to its items only; linked entities are
  /// untouched). Prefer [softDeleteProject] for user-facing deletes.
  Future<void> deleteProject(String id);

  // --- Trash (soft-delete) ---

  /// Move a project to trash (items are kept untouched).
  Future<void> softDeleteProject(String id);

  /// Restore a project from trash.
  Future<void> restoreProject(String id);

  /// Permanently delete a project (cascades to its items only).
  Future<void> permanentlyDeleteProject(String id);

  // --- Archive ---

  /// Archive a project (items are kept untouched).
  Future<void> archiveProject(String id);

  /// Unarchive a project.
  Future<void> unarchiveProject(String id);

  // --- Items ---

  /// Items of a project, ordered by sortOrder then createdAt.
  Future<List<ProjectItem>> getItems(String projectId);

  /// All items (across projects) that reference a given entity.
  Future<List<ProjectItem>> getItemsForEntity(
      String entityType, String entityId);

  /// Add an entity to a project. Upsert: an entity is in a project at most
  /// once; calling again only updates [sortOrder] when it is given. Throws
  /// [ArgumentError] if [projectId] does not exist or [entityType] is empty.
  /// Entity existence is not validated (types are extensible; read paths
  /// ignore dangling items).
  Future<ProjectItem> addItem(
      String projectId, String entityType, String entityId,
      {int? sortOrder});

  /// Remove an item by id.
  Future<void> removeItem(String itemId);

  /// Remove an entity from a project.
  Future<void> removeEntity(
      String projectId, String entityType, String entityId);
}
