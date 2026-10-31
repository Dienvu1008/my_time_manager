import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_focus_session.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `focus_sessions` (Pomodoro Focus Timer) — Core Track C4.
class FocusSessionDao {
  FocusSessionDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Tạo bảng — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade` v2.
  ///
  /// Không đặt FOREIGN KEY tới bảng task; lưu kèm taskTitle để thống kê vẫn
  /// đúng kể cả khi task gốc bị xóa.
  static Future<void> createTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        taskType INTEGER NOT NULL,
        taskId TEXT,
        taskTitle TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        focusDurationSeconds INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        synced INTEGER NOT NULL,
        deviceId TEXT
      )
      ''',
    );
  }

  Future<void> insert(FocusSession session) async {
    final db = await _getDatabase();
    await db.insert(
      'focus_sessions',
      withDeviceId(session.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(FocusSession session) async {
    final db = await _getDatabase();
    await db.update('focus_sessions', session.toMap(),
        where: 'id = ?', whereArgs: [session.id]);
  }

  /// Tất cả phiên, mới nhất trước.
  Future<List<FocusSession>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('focus_sessions', orderBy: 'startTime DESC');
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  /// Các phiên trong khoảng [start, end) — so sánh chuỗi ISO8601.
  Future<List<FocusSession>> between(DateTime start, DateTime end) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'focus_sessions',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime DESC',
    );
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  /// Các phiên chưa được đồng bộ lên cloud.
  Future<List<FocusSession>> unsynced() async {
    final db = await _getDatabase();
    final maps =
        await db.query('focus_sessions', where: 'synced = ?', whereArgs: [0]);
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }
}
