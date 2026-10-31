import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_project.dart';
import '../../../domain/models/model_project_item.dart';
import '../device_id_helper.dart';

/// DAO cho aggregate Dự án (Core Track C6): sở hữu 2 bảng `projects` và
/// `project_items` (tiền lệ: GoalDao sở hữu 3 bảng).
///
/// Quy tắc:
/// - `project_items.projectId` → projects ON DELETE CASCADE: xóa cứng dự án chỉ
///   xóa các mục liên kết của nó, KHÔNG BAO GIỜ xóa thực thể được liên kết.
/// - `project_items` KHÔNG có FK tới bảng thực thể (entityType mở rộng được);
///   các trigger `delete_project_items_of_*` xóa liên kết khi xóa cứng
///   tasklist / task / note / calendar event / goal. Read path vẫn bỏ qua liên
///   kết tới thực thể thiếu / trong thùng rác / đã lưu trữ.
/// - Soft-delete / archive của Project KHÔNG cascade: các mục giữ nguyên và
///   hiện lại khi khôi phục.
/// - Insert dùng ConflictAlgorithm.abort mặc định (KHÔNG replace): REPLACE =
///   DELETE + INSERT sẽ kích hoạt CASCADE và xóa mất các mục của dự án.
class ProjectDao {
  ProjectDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ------------------------------------------------------------------
  // SCHEMA (v14) — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade`
  // ------------------------------------------------------------------

  /// Tạo toàn bộ schema của aggregate (2 bảng + index + trigger). Hàm DUY NHẤT
  /// được gọi từ cả `_onCreate` và nhánh `_onUpgrade` v14 nên SQL luôn giống
  /// hệt nhau. Yêu cầu các bảng `tasklists`, `tasks`, `notes`,
  /// `calendar_events` và `goals` đã tồn tại (cho trigger).
  static Future<void> createSchema(Database db) async {
    await createProjectsTable(db);
    await createProjectItemsTable(db);
    await createProjectItemTriggers(db);
  }

  static Future<void> createProjectsTable(Database db) async {
    await db.execute('''
    CREATE TABLE projects (
      id TEXT PRIMARY KEY,
      title TEXT,
      description TEXT,
      color INTEGER,
      status TEXT NOT NULL DEFAULT 'active',
      startDate TEXT,
      targetDate TEXT,
      createdAt TEXT,
      updateTimeStamp TEXT,
      isDeleted INTEGER NOT NULL DEFAULT 0,
      deletedAt TEXT,
      isArchived INTEGER NOT NULL DEFAULT 0,
      archivedAt TEXT,
      deviceId TEXT
      )
    ''');
  }

  static Future<void> createProjectItemsTable(Database db) async {
    await db.execute('''
    CREATE TABLE project_items (
      id TEXT PRIMARY KEY,
      projectId TEXT NOT NULL,
      entityType TEXT NOT NULL,
      entityId TEXT NOT NULL,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT,
      deviceId TEXT,
      FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_project_items_projectId ON project_items(projectId)');
    await db.execute('CREATE UNIQUE INDEX idx_project_items_unique '
        'ON project_items(projectId, entityType, entityId)');
    await db.execute('CREATE INDEX idx_project_items_entityRef '
        'ON project_items(entityType, entityId)');
  }

  /// Trigger: xóa cứng một thực thể → xóa các mục dự án trỏ tới nó. Xóa cứng
  /// tasklist cascade (FK) xuống tasks/calendar_events nên trigger của chúng
  /// cũng chạy.
  static Future<void> createProjectItemTriggers(Database db) async {
    const triggers = {
      'delete_project_items_of_tasklist': ('tasklists', 'taskList'),
      'delete_project_items_of_task': ('tasks', 'task'),
      'delete_project_items_of_note': ('notes', 'note'),
      'delete_project_items_of_calendar_event':
          ('calendar_events', 'calendarEvent'),
      'delete_project_items_of_goal': ('goals', 'goal'),
    };
    for (final entry in triggers.entries) {
      final (table, entityType) = entry.value;
      await db.execute('''
    CREATE TRIGGER ${entry.key}
    AFTER DELETE ON $table
    BEGIN
      DELETE FROM project_items WHERE entityType = '$entityType' AND entityId = OLD.id;
    END;
    ''');
    }
  }

  // ------------------------------------------------------------------
  // PROJECTS
  // ------------------------------------------------------------------

  /// Các dự án đang hiển thị (bỏ mục trong thùng rác và đã lưu trữ).
  Future<List<Project>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('projects',
        where: 'isDeleted = 0 AND isArchived = 0', orderBy: 'createdAt ASC');
    return maps.map(Project.fromMap).toList();
  }

  /// Một dự án theo id (không lọc trạng thái), hoặc null nếu không có.
  Future<Project?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<void> insert(Project project) async {
    final db = await _getDatabase();
    await db.insert('projects', withDeviceId(project.toMap()));
  }

  Future<void> update(Project project) async {
    final db = await _getDatabase();
    await db.update('projects', project.toMap(),
        where: 'id = ?', whereArgs: [project.id]);
  }

  /// Xóa cứng (chỉ các mục dự án bị xóa theo qua FK cascade).
  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  /// Soft-delete: chỉ đánh dấu dự án (KHÔNG cascade).
  Future<void> softDelete(String id) async {
    final db = await _getDatabase();
    await db.update(
      'projects',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _getDatabase();
    await db.update(
      'projects',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa vĩnh viễn (= [delete]).
  Future<void> permanentlyDelete(String id) => delete(id);

  /// Lưu trữ: chỉ đánh dấu dự án (KHÔNG cascade).
  Future<void> archive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'projects',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'projects',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------------
  // PROJECT ITEMS
  // ------------------------------------------------------------------

  /// Các mục của một dự án, theo sortOrder rồi createdAt.
  Future<List<ProjectItem>> itemsOf(String projectId) async {
    final db = await _getDatabase();
    final maps = await db.query('project_items',
        where: 'projectId = ?',
        whereArgs: [projectId],
        orderBy: 'sortOrder ASC, createdAt ASC');
    return maps.map(ProjectItem.fromMap).toList();
  }

  /// Các mục (thuộc mọi dự án) trỏ tới một thực thể.
  Future<List<ProjectItem>> itemsOfEntity(
      String entityType, String entityId) async {
    final db = await _getDatabase();
    final maps = await db.query('project_items',
        where: 'entityType = ? AND entityId = ?',
        whereArgs: [entityType, entityId],
        orderBy: 'createdAt ASC');
    return maps.map(ProjectItem.fromMap).toList();
  }

  /// Upsert theo (projectId, entityType, entityId): nếu đã có thì chỉ cập nhật
  /// sortOrder (khi được truyền), ngược lại thêm mới với `sortOrder ?? 0`.
  /// Trả về mục sau khi ghi.
  Future<ProjectItem> addItem({
    required String projectId,
    required String entityType,
    required String entityId,
    int? sortOrder,
  }) async {
    final db = await _getDatabase();
    return db.transaction((txn) async {
      final rows = await txn.query('project_items',
          where: 'projectId = ? AND entityType = ? AND entityId = ?',
          whereArgs: [projectId, entityType, entityId]);
      if (rows.isNotEmpty) {
        final existing = ProjectItem.fromMap(rows.first);
        if (sortOrder == null) return existing;
        await txn.update('project_items', {'sortOrder': sortOrder},
            where: 'id = ?', whereArgs: [existing.id]);
        return existing.copyWith(sortOrder: sortOrder);
      }
      final item = ProjectItem(
        projectId: projectId,
        entityType: entityType,
        entityId: entityId,
        sortOrder: sortOrder ?? 0,
      );
      await txn.insert('project_items', withDeviceId(item.toMap()));
      return item;
    });
  }

  Future<void> removeItem(String itemId) async {
    final db = await _getDatabase();
    await db.delete('project_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<void> removeEntity(
      String projectId, String entityType, String entityId) async {
    final db = await _getDatabase();
    await db.delete('project_items',
        where: 'projectId = ? AND entityType = ? AND entityId = ?',
        whereArgs: [projectId, entityType, entityId]);
  }
}
