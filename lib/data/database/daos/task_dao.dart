import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_task.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `tasks` (Core Track C4 — trích từ `DatabaseManager`).
class TaskDao {
  TaskDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Tạo bảng — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade` v9.
  static Future<void> createTable(Database db) async {
    await db.execute(
      '''
    CREATE TABLE tasks (
      id TEXT PRIMARY KEY,
      taskListId TEXT,
      isCompleted INTEGER NOT NULL,
      isImportant INTEGER NOT NULL,  
      title TEXT, 
      description TEXT,
      descriptionDoc TEXT,
      location TEXT, 
      color INTEGER,
      tags TEXT,
      dataFiles TEXT,
      noteIds TEXT,
      isMeasurable INTEGER NOT NULL DEFAULT 0,
      targetAtLeast REAL,
      targetAtMost REAL,
      targetType INTEGER,
      unit TEXT,
      howMuchHasBeenDone REAL,
      subtasks TEXT,
      updateTimeStamp TEXT, 
      isDeleted INTEGER NOT NULL DEFAULT 0,
      deletedAt TEXT,
      isArchived INTEGER NOT NULL DEFAULT 0,
      archivedAt TEXT,
      deviceId TEXT,
      FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    ''',
    );
  }

  /// Các task đang hiển thị (bỏ mục trong thùng rác và đã lưu trữ).
  Future<List<Task>> getAll() async {
    final db = await _getDatabase();
    final maps =
        await db.query('tasks', where: 'isDeleted = 0 AND isArchived = 0');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<Task> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return Task.fromMap(maps[0]);
  }

  Future<List<Task>> ofTaskList(String taskListId) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'tasks',
      where: 'taskListId = ? AND isDeleted = 0 AND isArchived = 0',
      whereArgs: [taskListId],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  /// Các task "tự do" (không thuộc danh sách nào) đang hiển thị.
  Future<List<Task>> withoutTaskList() async {
    final db = await _getDatabase();
    final maps = await db.query(
      'tasks',
      where: 'taskListId IS NULL AND isDeleted = 0 AND isArchived = 0',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<void> insert(Task task) async {
    final db = await _getDatabase();
    await db.insert(
      'tasks',
      withDeviceId(task.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Task task) async {
    final db = await _getDatabase();
    await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }

  /// Đổi danh sách của task (null = đưa ra cấp cao nhất).
  Future<void> move(String taskId, String? newTaskListId) async {
    final db = await _getDatabase();
    await db.update(
      'tasks',
      {
        'taskListId': newTaskListId,
        'updateTimeStamp': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDelete(String id) async {
    final db = await _getDatabase();
    await db.update(
      'tasks',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _getDatabase();
    await db.update(
      'tasks',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa vĩnh viễn (= [delete]).
  Future<void> permanentlyDelete(String id) => delete(id);

  Future<void> archive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'tasks',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'tasks',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
