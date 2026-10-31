import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_reminder_rule.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `reminder_rules` (Phase R, schema v16).
///
/// Quy tắc:
/// - KHÔNG có FK tới bảng thực thể (entityType mở rộng được, vd. 'habit');
///   các trigger `delete_reminder_rules_of_*` xóa rule khi xóa cứng
///   timeinterval / calendar event / task.
/// - Insert dùng ConflictAlgorithm.abort mặc định (KHÔNG replace); upsert là
///   update trước, không có thì insert.
class ReminderRuleDao {
  ReminderRuleDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  static const String table = 'reminder_rules';

  // ------------------------------------------------------------------
  // SCHEMA (v16) — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade`
  // ------------------------------------------------------------------

  /// Tạo toàn bộ schema (bảng + index + trigger). Hàm DUY NHẤT được gọi từ cả
  /// `_onCreate` và nhánh `_onUpgrade` v16 nên SQL luôn giống hệt nhau. Yêu
  /// cầu các bảng `timeintervals`, `calendar_events`, `tasks` đã tồn tại.
  static Future<void> createSchema(Database db) async {
    await createTable(db);
    await createTriggers(db);
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
    CREATE TABLE reminder_rules (
      id TEXT PRIMARY KEY,
      entityType TEXT NOT NULL,
      entityId TEXT NOT NULL,
      kind TEXT NOT NULL DEFAULT 'offset',
      offsetMinutes INTEGER,
      absoluteAt TEXT,
      enabled INTEGER NOT NULL DEFAULT 1,
      priority INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT,
      updateTimeStamp TEXT,
      deviceId TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_reminder_rules_entity '
        'ON reminder_rules(entityType, entityId)');
  }

  /// Trigger: xóa cứng một thực thể → xóa các rule nhắc của nó.
  static Future<void> createTriggers(Database db) async {
    const triggers = {
      'delete_reminder_rules_of_timeinterval':
          ('timeintervals', ReminderEntityType.timeInterval),
      'delete_reminder_rules_of_calendar_event':
          ('calendar_events', ReminderEntityType.calendarEvent),
      'delete_reminder_rules_of_task': ('tasks', ReminderEntityType.task),
    };
    for (final entry in triggers.entries) {
      final (target, entityType) = entry.value;
      await db.execute('''
    CREATE TRIGGER ${entry.key}
    AFTER DELETE ON $target
    BEGIN
      DELETE FROM reminder_rules WHERE entityType = '$entityType' AND entityId = OLD.id;
    END;
    ''');
    }
  }

  // ------------------------------------------------------------------
  // CRUD
  // ------------------------------------------------------------------

  Future<List<ReminderRule>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query(table, orderBy: 'createdAt ASC');
    return maps.map(ReminderRule.fromMap).toList();
  }

  Future<List<ReminderRule>> getFor(String entityType, String entityId) async {
    final db = await _getDatabase();
    final maps = await db.query(table,
        where: 'entityType = ? AND entityId = ?',
        whereArgs: [entityType, entityId],
        orderBy: 'createdAt ASC');
    return maps.map(ReminderRule.fromMap).toList();
  }

  Future<ReminderRule?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ReminderRule.fromMap(maps.first);
  }

  /// Upsert: update theo id, không có hàng nào thì insert.
  Future<void> save(ReminderRule rule) async {
    final db = await _getDatabase();
    await db.transaction((txn) => _save(txn, rule));
  }

  Future<void> _save(DatabaseExecutor exec, ReminderRule rule) async {
    final map = rule.toMap();
    final n =
        await exec.update(table, map, where: 'id = ?', whereArgs: [rule.id]);
    if (n == 0) await exec.insert(table, withDeviceId(map));
  }

  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Xóa rule [kind] hiện có của thực thể rồi ghi [rules], trong một
  /// transaction.
  Future<void> replaceFor(String entityType, String entityId,
      ReminderRuleKind kind, List<ReminderRule> rules) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.delete(table,
          where: 'entityType = ? AND entityId = ? AND kind = ?',
          whereArgs: [entityType, entityId, kind.name]);
      for (final rule in rules) {
        await _save(txn, rule);
      }
    });
  }
}
