import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_calendar_event.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `calendar_events` (model [CalendarEvent] tương thích Google
/// Calendar) — Core Track C4, trích từ `DatabaseManager`.
class CalendarEventDao {
  CalendarEventDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Tạo bảng — gọi bởi DatabaseManager trong `_onCreate` và `_onUpgrade` v11.
  /// Các object lồng (start/end/attendees/reminders/recurrence...) được lưu
  /// dưới dạng chuỗi JSON trong một cột TEXT (xem CalendarEvent.toMap).
  static Future<void> createTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE calendar_events (
        id TEXT PRIMARY KEY,
        taskListId TEXT,
        title TEXT,
        description TEXT,
        location TEXT,
        color INTEGER,
        colorId TEXT,
        startDateTime TEXT,
        endDateTime TEXT,
        isAllDay INTEGER NOT NULL DEFAULT 0,
        recurrence TEXT,
        recurringEventId TEXT,
        originalStartTime TEXT,
        attendees TEXT,
        organizerEmail TEXT,
        organizerDisplayName TEXT,
        creatorEmail TEXT,
        status TEXT,
        visibility TEXT,
        transparency TEXT,
        guestsCanInviteOthers INTEGER NOT NULL DEFAULT 1,
        guestsCanModify INTEGER NOT NULL DEFAULT 0,
        guestsCanSeeOtherGuests INTEGER NOT NULL DEFAULT 1,
        reminders TEXT,
        conferenceUrl TEXT,
        dataFiles TEXT,
        noteIds TEXT,
        iCalUID TEXT,
        googleEventId TEXT,
        calendarId TEXT,
        etag TEXT,
        sequence INTEGER NOT NULL DEFAULT 0,
        created TEXT,
        updated TEXT,
        syncStatus TEXT,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        deletedAt TEXT,
        isArchived INTEGER NOT NULL DEFAULT 0,
        archivedAt TEXT,
        deviceId TEXT,
        FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
      ''',
    );
  }

  /// Tất cả event đang hiển thị (bỏ mục trong thùng rác và đã lưu trữ).
  Future<List<CalendarEvent>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('calendar_events',
        where: 'isDeleted = 0 AND isArchived = 0');
    return List.generate(maps.length, (i) => CalendarEvent.fromMap(maps[i]));
  }

  /// Một event theo id (không lọc trạng thái).
  Future<CalendarEvent?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db
        .query('calendar_events', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return CalendarEvent.fromMap(maps.first);
  }

  Future<List<CalendarEvent>> ofTaskList(String taskListId) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'calendar_events',
      where: 'taskListId = ? AND isDeleted = 0 AND isArchived = 0',
      whereArgs: [taskListId],
    );
    return List.generate(maps.length, (i) => CalendarEvent.fromMap(maps[i]));
  }

  /// Các event "tự do" (không thuộc danh sách nào) đang hiển thị.
  Future<List<CalendarEvent>> withoutTaskList() async {
    final db = await _getDatabase();
    final maps = await db.query(
      'calendar_events',
      where: 'taskListId IS NULL AND isDeleted = 0 AND isArchived = 0',
    );
    return List.generate(maps.length, (i) => CalendarEvent.fromMap(maps[i]));
  }

  Future<void> insert(CalendarEvent event) async {
    final db = await _getDatabase();
    await db.insert(
      'calendar_events',
      withDeviceId(event.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(CalendarEvent event) async {
    final db = await _getDatabase();
    await db.update(
      'calendar_events',
      withDeviceId(event.toMap()),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Xóa vĩnh viễn (hard delete).
  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  /// Đổi danh sách của event (null = đưa ra cấp cao nhất).
  Future<void> move(String eventId, String? newTaskListId) async {
    final db = await _getDatabase();
    await db.update(
      'calendar_events',
      {'taskListId': newTaskListId},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> softDelete(String id) async {
    final db = await _getDatabase();
    await db.update(
      'calendar_events',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _getDatabase();
    await db.update(
      'calendar_events',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> archive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'calendar_events',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'calendar_events',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Hỗ trợ đồng bộ ---

  /// Các event cần đẩy lên máy chủ (mới tạo, sửa hoặc chờ xóa).
  Future<List<CalendarEvent>> pendingSync() async {
    final db = await _getDatabase();
    final maps = await db.query(
      'calendar_events',
      where: 'syncStatus IN (?, ?, ?)',
      whereArgs: [
        EventSyncStatus.localOnly.apiValue,
        EventSyncStatus.pendingUpdate.apiValue,
        EventSyncStatus.pendingDelete.apiValue,
      ],
    );
    return List.generate(maps.length, (i) => CalendarEvent.fromMap(maps[i]));
  }

  Future<CalendarEvent?> byGoogleId(String googleEventId) async {
    final db = await _getDatabase();
    final maps = await db.query('calendar_events',
        where: 'googleEventId = ?', whereArgs: [googleEventId], limit: 1);
    if (maps.isEmpty) return null;
    return CalendarEvent.fromMap(maps.first);
  }

  /// Đánh dấu đã đồng bộ: gán googleEventId/etag/calendarId/iCalUID (nếu có)
  /// và đặt syncStatus = synced.
  Future<void> markSynced(
    String id, {
    String? googleEventId,
    String? etag,
    String? calendarId,
    String? iCalUID,
  }) async {
    final db = await _getDatabase();
    final values = <String, dynamic>{
      'syncStatus': EventSyncStatus.synced.apiValue,
      if (googleEventId != null) 'googleEventId': googleEventId,
      if (etag != null) 'etag': etag,
      if (calendarId != null) 'calendarId': calendarId,
      if (iCalUID != null) 'iCalUID': iCalUID,
    };
    await db
        .update('calendar_events', values, where: 'id = ?', whereArgs: [id]);
  }
}
