import '../../domain/models/model_project.dart';
import '../../domain/models/model_project_item.dart';
import '../../domain/repositories/project_repository.dart';
import '../database/daos/project_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [ProjectRepository] (Core Track C6) over [ProjectDao].
class SqliteProjectRepository implements ProjectRepository {
  SqliteProjectRepository({DatabaseManager? databaseManager})
      : _dao =
            ProjectDao(() => (databaseManager ?? DatabaseManager()).database);

  final ProjectDao _dao;

  @override
  Future<List<Project>> getProjects() => _dao.getAll();

  @override
  Future<Project?> getProject(String id) => _dao.getById(id);

  @override
  Future<void> createProject(Project project) => _dao.insert(project);

  @override
  Future<void> updateProject(Project project) => _dao.update(project);

  @override
  Future<void> deleteProject(String id) => _dao.delete(id);

  @override
  Future<void> softDeleteProject(String id) => _dao.softDelete(id);

  @override
  Future<void> restoreProject(String id) => _dao.restore(id);

  @override
  Future<void> permanentlyDeleteProject(String id) =>
      _dao.permanentlyDelete(id);

  @override
  Future<void> archiveProject(String id) => _dao.archive(id);

  @override
  Future<void> unarchiveProject(String id) => _dao.unarchive(id);

  @override
  Future<List<ProjectItem>> getItems(String projectId) =>
      _dao.itemsOf(projectId);

  @override
  Future<List<ProjectItem>> getItemsForEntity(
          String entityType, String entityId) =>
      _dao.itemsOfEntity(entityType, entityId);

  @override
  Future<ProjectItem> addItem(
      String projectId, String entityType, String entityId,
      {int? sortOrder}) async {
    if (entityType.trim().isEmpty) {
      throw ArgumentError.value(
          entityType, 'entityType', 'Entity type must not be empty');
    }
    if (await _dao.getById(projectId) == null) {
      throw ArgumentError.value(
          projectId, 'projectId', 'Project does not exist');
    }
    return _dao.addItem(
      projectId: projectId,
      entityType: entityType,
      entityId: entityId,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<void> removeItem(String itemId) => _dao.removeItem(itemId);

  @override
  Future<void> removeEntity(
          String projectId, String entityType, String entityId) =>
      _dao.removeEntity(projectId, entityType, entityId);
}
