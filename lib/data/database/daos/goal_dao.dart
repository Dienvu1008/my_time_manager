import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_goal.dart';
import '../../../domain/models/model_goal_link.dart';
import '../../../domain/models/model_milestone.dart';
import '../device_id_helper.dart';

/// DAO cho aggregate Mục tiêu (Core Track C5): sở hữu 3 bảng `goals`,
/// `milestones`, `goal_links` (tiền lệ: ConversationDao sở hữu 2 bảng).
///
/// Quy tắc:
/// - `milestones.goalId` → goals ON DELETE CASCADE.
/// - `goal_links.goalId` → goals ON DELETE CASCADE.
/// - `goal_links.milestoneId` → milestones ON DELETE SET NULL: xóa cột mốc KHÔNG
///   gỡ task khỏi mục tiêu, liên kết chỉ trở thành liên kết trực tiếp.
/// - Soft-delete / archive của Goal KHÔNG cascade: cột mốc và liên kết chỉ được
///   truy cập qua mục tiêu cha nên giữ nguyên và hiện lại khi khôi phục.
/// - Trigger `delete_goal_links_of_task`: xóa cứng task → xóa các liên kết
///   `entityType='task'` của nó.
/// - Insert dùng ConflictAlgorithm.abort mặc định (KHÔNG replace): REPLACE =
///   DELETE + INSERT sẽ kích hoạt CASCADE/SET NULL và xóa mất dữ liệu con.
class GoalDao {
  GoalDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ------------------------------------------------------------------
  // SCHEMA (v13) — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade`
  // ------------------------------------------------------------------

  /// Tạo toàn bộ schema của aggregate (3 bảng + index + trigger). Hàm DUY NHẤT
  /// được gọi từ cả `_onCreate` và nhánh `_onUpgrade` v13 nên SQL luôn giống
  /// hệt nhau. Yêu cầu bảng `tasks` đã tồn tại (cho trigger).
  static Future<void> createSchema(Database db) async {
    await createGoalsTable(db);
    await createMilestonesTable(db);
    await createGoalLinksTable(db);
    await createGoalLinkTriggers(db);
  }

  static Future<void> createGoalsTable(Database db) async {
    await db.execute('''
    CREATE TABLE goals (
      id TEXT PRIMARY KEY,
      title TEXT,
      description TEXT,
      color INTEGER,
      status TEXT NOT NULL DEFAULT 'active',
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

  static Future<void> createMilestonesTable(Database db) async {
    await db.execute('''
    CREATE TABLE milestones (
      id TEXT PRIMARY KEY,
      goalId TEXT NOT NULL,
      title TEXT,
      description TEXT,
      dueDate TEXT,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      completedAt TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      updateTimeStamp TEXT,
      deviceId TEXT,
      FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_milestones_goalId ON milestones(goalId)');
  }

  static Future<void> createGoalLinksTable(Database db) async {
    await db.execute('''
    CREATE TABLE goal_links (
      id TEXT PRIMARY KEY,
      goalId TEXT NOT NULL,
      milestoneId TEXT,
      entityType TEXT NOT NULL,
      entityId TEXT NOT NULL,
      createdAt TEXT,
      deviceId TEXT,
      FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
      FOREIGN KEY (milestoneId) REFERENCES milestones(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_goal_links_goalId ON goal_links(goalId)');
    await db.execute(
        'CREATE INDEX idx_goal_links_milestoneId ON goal_links(milestoneId)');
    await db.execute('CREATE UNIQUE INDEX idx_goal_links_entity '
        'ON goal_links(entityType, entityId, goalId)');
  }

  /// Trigger: xóa cứng một task → xóa các liên kết mục tiêu của task đó. Cũng
  /// chạy khi xóa cứng tasklist (FK cascade xuống tasks).
  static Future<void> createGoalLinkTriggers(Database db) async {
    await db.execute('''
    CREATE TRIGGER delete_goal_links_of_task
    AFTER DELETE ON tasks
    BEGIN
      DELETE FROM goal_links WHERE entityType = 'task' AND entityId = OLD.id;
    END;
    ''');
  }

  // ------------------------------------------------------------------
  // GOALS
  // ------------------------------------------------------------------

  /// Các mục tiêu đang hiển thị (bỏ mục trong thùng rác và đã lưu trữ).
  Future<List<Goal>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('goals',
        where: 'isDeleted = 0 AND isArchived = 0', orderBy: 'createdAt ASC');
    return maps.map(Goal.fromMap).toList();
  }

  /// Một mục tiêu theo id (không lọc trạng thái), hoặc null nếu không có.
  Future<Goal?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Goal.fromMap(maps.first);
  }

  Future<void> insert(Goal goal) async {
    final db = await _getDatabase();
    await db.insert('goals', withDeviceId(goal.toMap()));
  }

  Future<void> update(Goal goal) async {
    final db = await _getDatabase();
    await db.update('goals', goal.toMap(),
        where: 'id = ?', whereArgs: [goal.id]);
  }

  /// Xóa cứng (cột mốc + liên kết bị xóa theo qua FK cascade).
  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  /// Soft-delete: chỉ đánh dấu mục tiêu (KHÔNG cascade).
  Future<void> softDelete(String id) async {
    final db = await _getDatabase();
    await db.update(
      'goals',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _getDatabase();
    await db.update(
      'goals',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa vĩnh viễn (= [delete]).
  Future<void> permanentlyDelete(String id) => delete(id);

  /// Lưu trữ: chỉ đánh dấu mục tiêu (KHÔNG cascade).
  Future<void> archive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'goals',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'goals',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------------
  // MILESTONES
  // ------------------------------------------------------------------

  /// Các cột mốc của một mục tiêu, theo sortOrder rồi title.
  Future<List<Milestone>> milestonesOf(String goalId) async {
    final db = await _getDatabase();
    final maps = await db.query('milestones',
        where: 'goalId = ?',
        whereArgs: [goalId],
        orderBy: 'sortOrder ASC, title ASC');
    return maps.map(Milestone.fromMap).toList();
  }

  Future<Milestone?> getMilestone(String id) async {
    final db = await _getDatabase();
    final maps =
        await db.query('milestones', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Milestone.fromMap(maps.first);
  }

  Future<void> insertMilestone(Milestone milestone) async {
    final db = await _getDatabase();
    await db.insert('milestones', withDeviceId(milestone.toMap()));
  }

  Future<void> updateMilestone(Milestone milestone) async {
    final db = await _getDatabase();
    await db.update('milestones', milestone.toMap(),
        where: 'id = ?', whereArgs: [milestone.id]);
  }

  /// Xóa cột mốc (liên kết trỏ tới nó được SET NULL qua FK).
  Future<void> deleteMilestone(String id) async {
    final db = await _getDatabase();
    await db.delete('milestones', where: 'id = ?', whereArgs: [id]);
  }

  /// Đặt/bỏ cờ hoàn thành; completedAt = now/null.
  Future<void> setMilestoneCompleted(String id, bool completed) async {
    final db = await _getDatabase();
    final now = DateTime.now().toIso8601String();
    await db.update(
      'milestones',
      {
        'isCompleted': completed ? 1 : 0,
        'completedAt': completed ? now : null,
        'updateTimeStamp': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Sắp xếp lại các cột mốc: sortOrder = vị trí trong [orderedIds], trong một
  /// transaction. Id không thuộc [goalId] bị bỏ qua.
  Future<void> reorderMilestones(String goalId, List<String> orderedIds) async {
    final db = await _getDatabase();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'milestones',
          {'sortOrder': i, 'updateTimeStamp': now},
          where: 'id = ? AND goalId = ?',
          whereArgs: [orderedIds[i], goalId],
        );
      }
    });
  }

  // ------------------------------------------------------------------
  // GOAL LINKS
  // ------------------------------------------------------------------

  Future<List<GoalLink>> linksOf(String goalId) async {
    final db = await _getDatabase();
    final maps = await db.query('goal_links',
        where: 'goalId = ?', whereArgs: [goalId], orderBy: 'createdAt ASC');
    return maps.map(GoalLink.fromMap).toList();
  }

  Future<List<GoalLink>> linksOfMilestone(String milestoneId) async {
    final db = await _getDatabase();
    final maps = await db.query('goal_links',
        where: 'milestoneId = ?',
        whereArgs: [milestoneId],
        orderBy: 'createdAt ASC');
    return maps.map(GoalLink.fromMap).toList();
  }

  Future<List<GoalLink>> linksOfEntity(
      String entityType, String entityId) async {
    final db = await _getDatabase();
    final maps = await db.query('goal_links',
        where: 'entityType = ? AND entityId = ?',
        whereArgs: [entityType, entityId],
        orderBy: 'createdAt ASC');
    return maps.map(GoalLink.fromMap).toList();
  }

  /// Upsert theo (goalId, entityType, entityId): nếu đã có liên kết thì chỉ
  /// cập nhật milestoneId, ngược lại thêm mới. Trả về liên kết sau khi ghi.
  Future<GoalLink> link({
    required String goalId,
    required String entityType,
    required String entityId,
    String? milestoneId,
  }) async {
    final db = await _getDatabase();
    return db.transaction((txn) async {
      final rows = await txn.query('goal_links',
          where: 'goalId = ? AND entityType = ? AND entityId = ?',
          whereArgs: [goalId, entityType, entityId]);
      if (rows.isNotEmpty) {
        final existing = GoalLink.fromMap(rows.first);
        await txn.update('goal_links', {'milestoneId': milestoneId},
            where: 'id = ?', whereArgs: [existing.id]);
        return GoalLink(
          id: existing.id,
          goalId: existing.goalId,
          milestoneId: milestoneId,
          entityType: existing.entityType,
          entityId: existing.entityId,
          createdAt: existing.createdAt,
        );
      }
      final link = GoalLink(
        goalId: goalId,
        milestoneId: milestoneId,
        entityType: entityType,
        entityId: entityId,
      );
      await txn.insert('goal_links', withDeviceId(link.toMap()));
      return link;
    });
  }

  Future<void> unlink(String linkId) async {
    final db = await _getDatabase();
    await db.delete('goal_links', where: 'id = ?', whereArgs: [linkId]);
  }

  Future<void> unlinkEntity(
      String goalId, String entityType, String entityId) async {
    final db = await _getDatabase();
    await db.delete('goal_links',
        where: 'goalId = ? AND entityType = ? AND entityId = ?',
        whereArgs: [goalId, entityType, entityId]);
  }
}
