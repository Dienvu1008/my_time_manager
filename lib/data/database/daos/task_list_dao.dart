import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_list.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `tasklists` (Core Track C4 — trích từ `DatabaseManager`).
///
/// Soft-delete / archive của một TaskList cascade THỦ CÔNG xuống các task con
/// (bảng `tasks`) trong cùng transaction, đúng như hành vi gốc, để có thể khôi
/// phục cả cụm sau này.
class TaskListDao {
  TaskListDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Tạo bảng — gọi bởi DatabaseManager trong `_onCreate`.
  static Future<void> createTable(Database db) async {
    await db.execute(
      '''
    CREATE TABLE tasklists (
      id TEXT PRIMARY KEY, 
      title TEXT,
      description TEXT,
      descriptionDoc TEXT,
      color INTEGER,
      dataFiles TEXT,
      updateTimeStamp TEXT,
      isDeleted INTEGER NOT NULL DEFAULT 0,
      deletedAt TEXT,
      isArchived INTEGER NOT NULL DEFAULT 0,
      archivedAt TEXT,
      deviceId TEXT
      )
    ''',
    );
  }

  /// Các danh sách đang hiển thị (bỏ mục trong thùng rác và đã lưu trữ).
  Future<List<TaskList>> getAll() async {
    final db = await _getDatabase();
    final maps =
        await db.query('tasklists', where: 'isDeleted = 0 AND isArchived = 0');
    return List.generate(maps.length, (i) => TaskList.fromMap(maps[i]));
  }

  Future<TaskList> getById(String id) async {
    final db = await _getDatabase();
    final maps =
        await db.query('tasklists', where: 'id = ?', whereArgs: [id]);
    return TaskList.fromMap(maps[0]);
  }

  Future<void> insert(TaskList taskList) async {
    final db = await _getDatabase();
    await db.insert(
      'tasklists',
      withDeviceId(taskList.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(TaskList taskList) async {
    final db = await _getDatabase();
    await db.update(
      'tasklists',
      taskList.toMap(),
      where: 'id = ?',
      whereArgs: [taskList.id],
    );
  }

  /// Xóa cứng (task con bị xóa theo qua FK cascade).
  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('tasklists', where: 'id = ?', whereArgs: [id]);
  }

  /// Soft-delete: đánh dấu chính list VÀ các task con chưa bị xóa.
  Future<void> softDelete(String id) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final values = {'isDeleted': 1, 'deletedAt': now};
      await txn.update('tasklists', values, where: 'id = ?', whereArgs: [id]);
      // Chỉ đánh dấu các task con CHƯA bị xóa, để khi khôi phục list ta biết
      // được task nào bị xóa "theo list" và task nào người dùng đã tự xóa trước.
      const childWhere = 'taskListId = ? AND isDeleted = 0';
      await txn.update('tasks', values, where: childWhere, whereArgs: [id]);
    });
  }

  /// Khôi phục list và các task con bị xóa CÙNG thời điểm với nó.
  Future<void> restore(String id) async {
    final db = await _getDatabase();
    final listRows = await db.query('tasklists',
        columns: ['deletedAt'], where: 'id = ?', whereArgs: [id]);
    final String? listDeletedAt =
        listRows.isNotEmpty ? listRows.first['deletedAt'] as String? : null;

    await db.transaction((txn) async {
      await txn.update('tasklists', {'isDeleted': 0, 'deletedAt': null},
          where: 'id = ?', whereArgs: [id]);
      if (listDeletedAt != null) {
        const childWhere = 'taskListId = ? AND isDeleted = 1 AND deletedAt = ?';
        final restoreValues = {'isDeleted': 0, 'deletedAt': null};
        await txn.update('tasks', restoreValues,
            where: childWhere, whereArgs: [id, listDeletedAt]);
      }
    });
  }

  /// Xóa vĩnh viễn (= [delete]).
  Future<void> permanentlyDelete(String id) => delete(id);

  /// Lưu trữ list và các task con chưa bị xóa/chưa được lưu trữ.
  Future<void> archive(String id) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final values = {'isArchived': 1, 'archivedAt': now};
      await txn.update('tasklists', values, where: 'id = ?', whereArgs: [id]);
      const childWhere = 'taskListId = ? AND isDeleted = 0 AND isArchived = 0';
      await txn.update('tasks', values, where: childWhere, whereArgs: [id]);
    });
  }

  /// Bỏ lưu trữ list và các task con được lưu trữ CÙNG thời điểm với nó.
  Future<void> unarchive(String id) async {
    final db = await _getDatabase();
    final listRows = await db.query('tasklists',
        columns: ['archivedAt'], where: 'id = ?', whereArgs: [id]);
    final String? listArchivedAt =
        listRows.isNotEmpty ? listRows.first['archivedAt'] as String? : null;

    await db.transaction((txn) async {
      await txn.update('tasklists', {'isArchived': 0, 'archivedAt': null},
          where: 'id = ?', whereArgs: [id]);
      if (listArchivedAt != null) {
        const childWhere =
            'taskListId = ? AND isArchived = 1 AND archivedAt = ?';
        await txn.update('tasks', {'isArchived': 0, 'archivedAt': null},
            where: childWhere, whereArgs: [id, listArchivedAt]);
      }
    });
  }
}
