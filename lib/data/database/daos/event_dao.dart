import 'package:sqflite/sqflite.dart';

import '../../../domain/models/models.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `events` cũ (legacy) — Core Track C4.
class EventDao {
  EventDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Tạo bảng — gọi bởi DatabaseManager trong `_onCreate`.
  static Future<void> createTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        taskListId TEXT,
        title TEXT, 
        description TEXT,
        location TEXT, 
        color INTEGER,
        startTimeStamp INTEGER,
        endTimeStamp INTEGER,
        tags TEXT,
        dataFiles TEXT,
        updateTimeStamp TEXT, 
        deviceId TEXT,
        FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
      ''',
    );
  }

  Future<List<Event>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('events');
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<Event> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('events', where: 'id = ?', whereArgs: [id]);
    return Event.fromMap(maps[0]);
  }

  Future<void> insert(Event event) async {
    final db = await _getDatabase();
    await db.insert(
      'events',
      withDeviceId(event.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Event event) async {
    final db = await _getDatabase();
    await db.update('events', event.toMap(),
        where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Event>> ofTaskList(String taskListId) async {
    final db = await _getDatabase();
    final maps = await db
        .query('events', where: 'taskListId = ?', whereArgs: [taskListId]);
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }
}
