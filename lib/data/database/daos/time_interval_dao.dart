import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_time_interval.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `timeintervals` (Core Track C4 — trích từ `DatabaseManager`).
///
/// Thuần SQL. Side-effect nhắc nhở (thông báo) do
/// `SqliteTimeIntervalRepository` điều phối qua `ReminderScheduler`.
class TimeIntervalDao {
  TimeIntervalDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Tạo bảng — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade` v9.
  static Future<void> createTable(Database db) async {
    await db.execute(
      '''
    CREATE TABLE timeintervals (
      id TEXT PRIMARY KEY,
      isCompleted INTEGER NOT NULL,
      isImportant INTEGER NOT NULL,
      taskId TEXT,
      subtaskId TEXT,
      location TEXT,
      color INTEGER,
      title TEXT, 
      description TEXT,
      descriptionDoc TEXT,
      startDate TEXT,
      endDate TEXT,
      startTime INTEGER,
      endTime INTEGER,
      isStartDateUndefined INTEGER NOT NULL,
      isEndDateUndefined INTEGER NOT NULL,
      isStartTimeUndefined INTEGER NOT NULL,
      isEndTimeUndefined INTEGER NOT NULL,
      targetAtLeast REAL,
      targetAtMost REAL,
      targetType INTEGER,
      unit TEXT,
      howMuchHasBeenDone REAL,
      subtasks TEXT,
      dataFiles TEXT,
      noteIds TEXT,
      updateTimeStamp TEXT,
      timeZone TEXT,
      deviceId TEXT,
      reminders TEXT,
      FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE)
    ''',
    );
  }

  Future<List<TimeInterval>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('timeintervals');
    return List.generate(maps.length, (i) => TimeInterval.fromMap(maps[i]));
  }

  Future<TimeInterval> getById(String id) async {
    final db = await _getDatabase();
    final maps =
        await db.query('timeintervals', where: 'id = ?', whereArgs: [id]);
    return TimeInterval.fromMap(maps[0]);
  }

  Future<void> insert(TimeInterval timeInterval) async {
    final db = await _getDatabase();
    await db.insert(
      'timeintervals',
      withDeviceId(timeInterval.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(TimeInterval timeInterval) async {
    final db = await _getDatabase();
    await db.update(
      'timeintervals',
      timeInterval.toMap(),
      where: 'id = ?',
      whereArgs: [timeInterval.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('timeintervals', where: 'id = ?', whereArgs: [id]);
  }

  /// Các interval của CHÍNH task cha (không tính interval của công việc con).
  Future<List<TimeInterval>> ofTask(String taskId) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'timeintervals',
      where: 'taskId = ? AND subtaskId IS NULL',
      whereArgs: [taskId],
    );
    return List.generate(maps.length, (i) => TimeInterval.fromMap(maps[i]));
  }

  /// Tất cả interval thuộc một task (kể cả của các công việc con).
  Future<List<TimeInterval>> allOfTask(String taskId) async {
    final db = await _getDatabase();
    final maps = await db
        .query('timeintervals', where: 'taskId = ?', whereArgs: [taskId]);
    return List.generate(maps.length, (i) => TimeInterval.fromMap(maps[i]));
  }

  /// Các interval của MỘT công việc con cụ thể.
  Future<List<TimeInterval>> ofSubtask(String subtaskId) async {
    final db = await _getDatabase();
    final maps = await db
        .query('timeintervals', where: 'subtaskId = ?', whereArgs: [subtaskId]);
    return List.generate(maps.length, (i) => TimeInterval.fromMap(maps[i]));
  }
}
