import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_ai_action_log.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `ai_action_log` (Phase C8b, schema v17).
///
/// - KHÔNG có FK (xóa một cuộc trò chuyện vẫn giữ nhật ký kiểm toán).
/// - Insert dùng ConflictAlgorithm.abort mặc định, gắn deviceId qua
///   [withDeviceId].
/// - Bảng KHÔNG nằm trong `DatabaseManager.allDataTables` / import (dữ liệu
///   kiểm toán cục bộ của thiết bị).
class AiActionLogDao {
  AiActionLogDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  static const String table = 'ai_action_log';

  /// Nguồn SQL DUY NHẤT, gọi từ cả `_onCreate` và nhánh `_onUpgrade` v17.
  static Future<void> createSchema(Database db) async {
    await db.execute('''
    CREATE TABLE ai_action_log (
      id TEXT PRIMARY KEY,
      createdAt TEXT NOT NULL,
      toolName TEXT NOT NULL,
      policyLevel TEXT NOT NULL,
      policyMode TEXT,
      argsSummary TEXT,
      outcome TEXT NOT NULL,
      resultSummary TEXT,
      errorMessage TEXT,
      conversationId TEXT,
      deviceId TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_ai_action_log_created '
        'ON ai_action_log(createdAt)');
  }

  static const String _order = 'createdAt DESC, rowid DESC';

  Future<void> insert(AiActionLogEntry entry) async {
    final db = await _getDatabase();
    await db.insert(table, withDeviceId(entry.toMap()));
  }

  Future<List<AiActionLogEntry>> query({
    AiActionOutcome? outcome,
    int limit = 500,
  }) async {
    final db = await _getDatabase();
    final maps = await db.query(
      table,
      where: outcome == null ? null : 'outcome = ?',
      whereArgs: outcome == null ? null : [outcome.name],
      orderBy: _order,
      limit: limit,
    );
    return maps.map(AiActionLogEntry.fromMap).toList();
  }

  Future<AiActionLogEntry?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return AiActionLogEntry.fromMap(maps.first);
  }

  Future<int> clear() async {
    final db = await _getDatabase();
    return db.delete(table);
  }

  Future<int> purge({
    required DateTime now,
    required int maxEntries,
    required Duration maxAge,
  }) async {
    final db = await _getDatabase();
    return db.transaction((txn) async {
      final cutoff = now.subtract(maxAge).toUtc().toIso8601String();
      final byAge =
          await txn.delete(table, where: 'createdAt < ?', whereArgs: [cutoff]);
      final byCount = await txn.rawDelete(
        'DELETE FROM $table WHERE id NOT IN '
        '(SELECT id FROM $table ORDER BY $_order LIMIT ?)',
        [maxEntries < 0 ? 0 : maxEntries],
      );
      return byAge + byCount;
    });
  }
}
