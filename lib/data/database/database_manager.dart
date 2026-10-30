import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_conversation.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_note.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/domain/models/models.dart';
import 'package:my_time_manager/domain/models/model_focus_session.dart';
import 'package:my_time_manager/screen_archive/model_archived_item.dart';
import 'package:my_time_manager/screen_trash/model_trashed_item.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {


  // Singleton pattern
  static final DatabaseManager _databaseManager = DatabaseManager._internal();
  factory DatabaseManager() => _databaseManager;
  DatabaseManager._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the DB first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  /// TEST-ONLY seam. Closes any open database and (optionally) reopens a fresh
  /// in-memory database using the SAME schema/migrations/version/config as
  /// production. This does not affect production code paths in any way — the
  /// [database] getter still opens the on-disk database via [_initDatabase].
  ///
  /// Requires an FFI factory to be configured by the caller (test setup does
  /// `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;`).
  @visibleForTesting
  Future<void> resetForTesting({bool inMemory = true}) async {
    final existing = _database;
    // Null the field first so a concurrent/late [database] getter never hands
    // back a handle that is mid-close. Then best-effort close the old handle.
    _database = null;
    if (existing != null) {
      try {
        await existing.close();
      } catch (_) {
        // Ignore: closing an already-closed/stale in-memory handle is benign
        // in tests and must not abort the reset.
      }
    }
    if (inMemory) {
      // Fresh in-memory database. `singleInstance: false` ensures sqflite does
      // not hand back a cached/closed handle across tests when the whole suite
      // runs in one `flutter test` process (all test files share this
      // singleton's static [_database]).
      _database = await openDatabase(
        inMemoryDatabasePath,
        version: _schemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        singleInstance: false,
      );
    }
  }

  /// The current schema version. Kept in one place so the production opener and
  /// the test seam cannot drift apart.
  static const int _schemaVersion = 12;

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(databasePath, 'app_database.db');

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return await openDatabase(
      path,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // v2: thêm bảng focus_sessions cho Pomodoro Focus Timer.
      // v3: thêm cột soft-delete (isDeleted, deletedAt) cho Thùng rác.
      // v4: thêm cột deviceId (ghi nhận thiết bị nguồn) cho tất cả các bảng,
      //     phục vụ tính năng export/import và xử lý xung đột khi nhập dữ liệu.
      // v5: thêm cột reminders (JSON danh sách số phút trước) cho timeintervals
      //     phục vụ tính năng nhắc bằng thông báo.
      // v6: thêm bảng notes (ghi chú dùng trình soạn thảo appflowy_editor).
      // v7: thêm cột descriptionDoc (JSON appflowy_editor cho mô tả có định
      //     dạng) cho tasklists, tasks, measurabletasks, taskswithsubtasks,
      //     timeintervals.
      // v8: thêm cột noteIds (JSON danh sách id ghi chú đính kèm) cho tasks,
      //     measurabletasks, taskswithsubtasks, timeintervals.
      // v9: GỘP 3 loại task thành 1 model Task duy nhất. Bỏ bảng
      //     measurabletasks và taskswithsubtasks; bảng tasks có thêm cột
      //     isMeasurable/target*/unit/howMuchHasBeenDone/subtasks; timeintervals
      //     đổi 3 FK (taskId/measurableTaskId/taskWithSubtasksId) thành
      //     taskId + subtaskId. KHÔNG migrate dữ liệu cũ (tạo lại schema sạch).
      // v10: thêm cột lưu trữ (isArchived, archivedAt) cho tasklists và tasks,
      //     phục vụ tính năng Archive (ẩn khỏi màn chính nhưng không xóa).
      // v11: thêm bảng calendar_events (model CalendarEvent tương thích Google
      //     Calendar). Event có thể thuộc một danh sách như task; hỗ trợ
      //     soft-delete, archive và các trường đồng bộ (googleEventId, etag,
      //     syncStatus...). Bảng 'events' cũ (đơn giản) vẫn giữ nguyên.
      // v12: thêm bảng conversations + chat_messages cho lịch sử chat AI
      //     (danh sách/mở lại/đổi tên/xóa cuộc trò chuyện, và tự xóa theo N
      //     ngày). chat_messages tham chiếu conversations với ON DELETE CASCADE.
      version: _schemaVersion,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Các bảng có hỗ trợ soft-delete (thùng rác).
  static const List<String> _softDeleteTables = [
    'tasklists',
    'tasks',
    'calendar_events',
  ];

  /// Tất cả các bảng dữ liệu (dùng cho export/import và cho migrate deviceId).
  static const List<String> allDataTables = [
    'tasklists',
    'tasks',
    'events',
    'calendar_events',
    'timeintervals',
    'focus_sessions',
    'notes',
  ];

  /// deviceId của thiết bị hiện tại. Được gán một lần lúc khởi động app (qua
  /// [setCurrentDeviceId]). Mọi bản ghi được ghi/insert từ máy này sẽ mang giá
  /// trị này ở cột deviceId nếu bản thân map chưa có sẵn deviceId.
  static String? _currentDeviceId;

  /// Đặt deviceId hiện tại (gọi một lần khi app khởi động).
  static void setCurrentDeviceId(String id) => _currentDeviceId = id;

  /// Gắn deviceId hiện tại vào [map] nếu map chưa có (không ghi đè giá trị đã
  /// có — quan trọng khi import: giữ nguyên deviceId nguồn từ file).
  Map<String, dynamic> _withDeviceId(Map<String, dynamic> map) {
    if (!map.containsKey('deviceId') || map['deviceId'] == null) {
      if (_currentDeviceId != null) {
        return {...map, 'deviceId': _currentDeviceId};
      }
    }
    return map;
  }

  /// Nâng cấp schema khi người dùng đã có DB cũ (giữ nguyên dữ liệu hiện có).
  /// Mỗi lần tăng version thêm một nhánh if tương ứng.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Bổ sung bảng focus_sessions cho các cài đặt đã tồn tại từ v1.
      await onCreateTableFocusSessions(db);
    }
    if (oldVersion < 3) {
      // Thêm cột soft-delete vào các bảng nội dung đã tồn tại. Dùng ALTER TABLE
      // để giữ nguyên toàn bộ dữ liệu hiện có của người dùng.
      // LƯU Ý: chỉ ALTER các bảng đã TỒN TẠI tại thời điểm v3 (tasklists, tasks).
      // KHÔNG dùng _softDeleteTables vì danh sách đó đã được mở rộng về sau
      // (thêm calendar_events ở v11) — bảng calendar_events chưa tồn tại ở v3
      // nên ALTER sẽ báo "no such table". calendar_events được tạo mới ở v11
      // với cột isDeleted/deletedAt sẵn có.
      const v3SoftDeleteTables = ['tasklists', 'tasks'];
      for (final table in v3SoftDeleteTables) {
        await db.execute(
            'ALTER TABLE $table ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0');
        await db.execute('ALTER TABLE $table ADD COLUMN deletedAt TEXT');
      }
    }
    if (oldVersion < 4) {
      // Thêm cột deviceId cho các bảng tồn tại từ v3 trở về trước. KHÔNG gồm
      // 'notes' (bảng này tạo mới ở v6, đã sẵn cột deviceId).
      const v4Tables = [
        'tasklists',
        'tasks',
        'measurabletasks',
        'taskswithsubtasks',
        'events',
        'timeintervals',
        'focus_sessions',
      ];
      for (final table in v4Tables) {
        await db.execute('ALTER TABLE $table ADD COLUMN deviceId TEXT');
      }
    }
    if (oldVersion < 5) {
      // Thêm cột reminders (JSON danh sách số phút trước) cho timeintervals.
      await db.execute('ALTER TABLE timeintervals ADD COLUMN reminders TEXT');
    }
    if (oldVersion < 6) {
      // Thêm bảng notes cho tính năng Ghi chú.
      await onCreateTableNotes(db);
    }
    if (oldVersion < 7) {
      // Thêm cột descriptionDoc (JSON appflowy_editor) cho các bảng có mô tả.
      const docTables = [
        'tasklists',
        'tasks',
        'measurabletasks',
        'taskswithsubtasks',
        'timeintervals',
      ];
      for (final table in docTables) {
        await db.execute('ALTER TABLE $table ADD COLUMN descriptionDoc TEXT');
      }
    }
    if (oldVersion < 8) {
      // Thêm cột noteIds (JSON danh sách id ghi chú đính kèm) cho các bảng có
      // thể đính kèm ghi chú.
      const noteTables = [
        'tasks',
        'measurabletasks',
        'taskswithsubtasks',
        'timeintervals',
      ];
      for (final table in noteTables) {
        await db.execute('ALTER TABLE $table ADD COLUMN noteIds TEXT');
      }
    }
    if (oldVersion < 9) {
      // GỘP 3 loại task thành 1. Người dùng đã đồng ý KHÔNG cần giữ dữ liệu cũ,
      // nên ta tạo lại schema sạch: xóa các trigger cũ, xóa các bảng task cũ và
      // timeintervals, rồi tạo lại theo schema mới.
      const oldTriggers = [
        'update_timeintervals_of_task_title_color_isImportant',
        'update_timeintervals_of_measurableTask_title_color_isImportant',
        'update_timeintervals_of_taskWithSubtasks_title_color_isImportant',
        'delete_timeintervals_of_task',
        'delete_timeintervals_of_measurableTask',
        'delete_timeintervals_of_taskWithSubtasks',
      ];
      for (final trigger in oldTriggers) {
        await db.execute('DROP TRIGGER IF EXISTS $trigger');
      }
      await db.execute('DROP TABLE IF EXISTS timeintervals');
      await db.execute('DROP TABLE IF EXISTS measurabletasks');
      await db.execute('DROP TABLE IF EXISTS taskswithsubtasks');
      await db.execute('DROP TABLE IF EXISTS tasks');

      // Tạo lại bảng tasks (schema gộp) + timeintervals (khóa mới) + trigger.
      await onCreateTableTasks(db);
      await onCreateTableTimeIntervals(db);
      await _createTaskTriggers(db);
    }
    if (oldVersion < 10) {
      // Thêm cột lưu trữ (isArchived, archivedAt) cho các bảng archivable đã
      // tồn tại. Dùng ALTER TABLE để giữ nguyên dữ liệu người dùng hiện có.
      // LƯU Ý: ở v10, calendar_events chưa tồn tại nên chỉ ALTER tasklists+tasks
      // (calendar_events sẽ được tạo mới ở v11 với đủ cột archive sẵn).
      const v10ArchiveTables = ['tasklists', 'tasks'];
      for (final table in v10ArchiveTables) {
        await db.execute(
            'ALTER TABLE $table ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
        await db.execute('ALTER TABLE $table ADD COLUMN archivedAt TEXT');
      }
    }
    if (oldVersion < 11) {
      // Tạo bảng calendar_events mới. Không đụng tới dữ liệu cũ.
      await onCreateTableCalendarEvents(db);
    }
    if (oldVersion < 12) {
      // Thêm bảng lịch sử chat AI: conversations + chat_messages.
      await onCreateTableConversations(db);
      await onCreateTableChatMessages(db);
    }
  }

  /// Tạo các trigger đồng bộ/xóa timeintervals theo tasks (dùng cho cả onCreate
  /// và onUpgrade v9).
  Future<void> _createTaskTriggers(Database db) async {
    await db.execute('''
  CREATE TRIGGER update_timeintervals_of_task_title_color_isImportant
  AFTER UPDATE OF title, color, isImportant ON tasks
  BEGIN
    UPDATE timeintervals
    SET title = NEW.title, color = NEW.color, isImportant = NEW.isImportant
    WHERE taskId = OLD.id AND subtaskId IS NULL;
  END;
''');
    await db.execute('''
  CREATE TRIGGER delete_timeintervals_of_task
  AFTER DELETE ON tasks
  BEGIN
    DELETE FROM timeintervals
    WHERE taskId = OLD.id;
  END;
''');
  }



//ON DELETE CASCADE doesn't work right. Why????
  Future<void> _onCreate(Database db, int version) async {
    // Run the CREATE {task lists} TABLE statement on the database.
    // await db.execute(
    //   '''
    //   CREATE TABLE tasklists (
    //     id TEXT PRIMARY KEY,
    //     title TEXT,
    //     description TEXT,
    //     color INTEGER,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT
    //     )
    //   ''',
    // );
    await onCreateTableTaskLists(db);
    await onCreateTableTasks(db);
    await onCreateTableEvents(db);
    await onCreateTableCalendarEvents(db);
    await onCreateTableTimeIntervals(db);
    await onCreateTableFocusSessions(db);
    await onCreateTableNotes(db);
    await onCreateTableConversations(db);
    await onCreateTableChatMessages(db);

    // KHÔNG gọi addSampleData() ở đây. Đó là hàm async seed dữ liệu mẫu, gọi
    // KHÔNG await và bên trong lại re-enter DatabaseManager().database (mở lại
    // DB) NGAY TRONG lúc onCreate đang chạy trong transaction mở của sqflite.
    // Việc này phá trạng thái transaction -> COMMIT lúc mở thất bại
    // ("no current transaction") -> sqflite đóng DB -> mọi truy vấn sau báo
    // database_closed. Người dùng thật cũng không cần dữ liệu mẫu.


    // Run the CREATE {tasks} TABLE statement on the database.
    // await db.execute(
    //   '''
    //   CREATE TABLE tasks (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     isCompleted INTEGER NOT NULL,
    //     isImportant INTEGER NOT NULL,
    //     title TEXT,
    //     description TEXT,
    //     location TEXT,
    //     color INTEGER,
    //     tags TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT,
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    //   CREATE TABLE measurabletasks (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     isCompleted INTEGER NOT NULL,
    //     isImportant INTEGER NOT NULL,
    //     title TEXT,
    //     description TEXT,
    //     location TEXT,
    //     color INTEGER,
    //     targetAtLeast REAL,
    //     targetAtMost REAL,
    //     targetType INTEGER NOT NULL,
    //     howMuchHasBeenDone REAL,
    //     unit TEXT,
    //     tags TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT,
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    //   CREATE TABLE taskswithsubtasks (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     title TEXT,
    //     description TEXT,
    //     location TEXT,
    //     color INTEGER,
    //     isCompleted INTEGER NOT NULL,
    //     isImportant INTEGER NOT NULL,
    //     subtasks TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT,
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    //   CREATE TABLE events (
    //     id TEXT PRIMARY KEY,
    //     taskListId TEXT,
    //     title TEXT,
    //     description TEXT,
    //     location TEXT,
    //     color INTEGER,
    //     startTimeStamp INTEGER,
    //     endTimeStamp INTEGER,
    //     tags TEXT,
    //     dataFiles TEXT,
    //     updateTimeStamp TEXT,
    //     FOREIGN KEY (taskListId) REFERENCES tasklists(id) ON DELETE CASCADE)
    //   ''',
    // );

    // await db.execute(
    //   '''
    // CREATE TABLE timeintervals (
    //   id TEXT PRIMARY KEY,
    //   isCompleted INTEGER NOT NULL,
    //   taskId TEXT,
    //   measurableTaskId TEXT,
    //   taskWithSubtasksId TEXT,
    //   location TEXT,
    //   color INTEGER,
    //   title TEXT,
    //   notes TEXT,
    //   startDate TEXT,
    //   endDate TEXT,
    //   startTime INTEGER,
    //   endTime INTEGER,
    //   isStartDateUndefined INTEGER NOT NULL,
    //   isEndDateUndefined INTEGER NOT NULL,
    //   isStartTimeUndefined INTEGER NOT NULL,
    //   isEndTimeUndefined INTEGER NOT NULL,
    //   targetAtLeast REAL,
    //   targetAtMost REAL,
    //   targetType INTEGER,
    //   unit TEXT,
    //   howMuchHasBeenDone REAL,
    //   subtasks TEXT,
    //   dataFiles TEXT,
    //   updateTimeStamp TEXT,
    //   timeZone TEXT,
    //   FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
    //   FOREIGN KEY (measurableTaskId) REFERENCES measurabletasks(id) ON DELETE CASCADE,
    //   FOREIGN KEY (taskWithSubtasksId) REFERENCES taskswithsubtasks(id) ON DELETE CASCADE)
    // ''',
    // );

    // Trigger đồng bộ tiêu đề/màu xuống interval của task cha + trigger xóa
    // interval khi xóa task.
    await _createTaskTriggers(db);
  }

  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_database.db');
    await databaseFactory.deleteDatabase(path);
  }

  // Define a function that inserts task lists into the database
  Future<void> insertTaskList(TaskList taskList) async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Insert the task list into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same task lists is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'tasklists',
      _withDeviceId(taskList.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    //printTaskLists();
  }

  Future<void> insertTask(Task task) async {
    final db = await _databaseManager.database;
    await db.insert(
      'tasks',
      _withDeviceId(task.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    //printTasks();
  }

  Future<void> insertTimeInterval(TimeInterval timeInterval) async {
    final db = await _databaseManager.database;
    await db.insert(
      'timeintervals',
      _withDeviceId(timeInterval.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Side-effect (lên lịch nhắc) được xử lý bởi SqliteTimeIntervalRepository
    // thông qua ReminderScheduler — DatabaseManager không gọi NotificationService
    // nữa (fix H3 trong Core Track C3).
  }

  Future<void> insertEvent(Event event) async {
    final db = await _databaseManager.database;
    await db.insert(
      'events',
      _withDeviceId(event.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------------
  // CALENDAR EVENTS (model CalendarEvent tương thích Google Calendar)
  // ------------------------------------------------------------------

  Future<void> insertCalendarEvent(CalendarEvent event) async {
    final db = await _databaseManager.database;
    await db.insert(
      'calendar_events',
      _withDeviceId(event.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCalendarEvent(CalendarEvent event) async {
    final db = await _databaseManager.database;
    await db.update(
      'calendar_events',
      _withDeviceId(event.toMap()),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Xóa vĩnh viễn (hard delete) một calendar event khỏi DB cục bộ.
  Future<void> deleteCalendarEvent(String id) async {
    final db = await _databaseManager.database;
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  /// Tất cả calendar event đang hiển thị (bỏ mục trong thùng rác và đã lưu trữ).
  Future<List<CalendarEvent>> calendarEvents() async {
    final db = await _databaseManager.database;
    final maps = await db.query('calendar_events',
        where: 'isDeleted = 0 AND isArchived = 0');
    return List.generate(
        maps.length, (index) => CalendarEvent.fromMap(maps[index]));
  }

  /// Một calendar event theo id cục bộ (không lọc trạng thái).
  Future<CalendarEvent?> calendarEvent(String id) async {
    final db = await _databaseManager.database;
    final maps = await db
        .query('calendar_events', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return CalendarEvent.fromMap(maps.first);
  }

  /// Các calendar event thuộc một danh sách (giống tasksOfTaskList).
  Future<List<CalendarEvent>> calendarEventsOfTaskList(
      String taskListId) async {
    final db = await _databaseManager.database;
    final maps = await db.query(
      'calendar_events',
      where: 'taskListId = ? AND isDeleted = 0 AND isArchived = 0',
      whereArgs: [taskListId],
    );
    return List.generate(
        maps.length, (index) => CalendarEvent.fromMap(maps[index]));
  }

  /// Các calendar event "tự do" (không thuộc danh sách nào) đang hiển thị.
  Future<List<CalendarEvent>> calendarEventsWithoutTaskList() async {
    final db = await _databaseManager.database;
    final maps = await db.query(
      'calendar_events',
      where: 'taskListId IS NULL AND isDeleted = 0 AND isArchived = 0',
    );
    return List.generate(
        maps.length, (index) => CalendarEvent.fromMap(maps[index]));
  }

  /// Đổi danh sách của một calendar event (null = đưa ra cấp cao nhất).
  Future<void> moveCalendarEvent(
      String eventId, String? newTaskListId) async {
    final db = await _databaseManager.database;
    await db.update(
      'calendar_events',
      {'taskListId': newTaskListId},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  // --- Hỗ trợ đồng bộ ---

  /// Các event cần đẩy lên máy chủ (mới tạo, sửa hoặc chờ xóa).
  Future<List<CalendarEvent>> calendarEventsPendingSync() async {
    final db = await _databaseManager.database;
    final maps = await db.query(
      'calendar_events',
      where: 'syncStatus IN (?, ?, ?)',
      whereArgs: [
        EventSyncStatus.localOnly.apiValue,
        EventSyncStatus.pendingUpdate.apiValue,
        EventSyncStatus.pendingDelete.apiValue,
      ],
    );
    return List.generate(
        maps.length, (index) => CalendarEvent.fromMap(maps[index]));
  }

  /// Tìm event cục bộ theo googleEventId (để khớp khi kéo dữ liệu về). Null nếu
  /// chưa có bản ghi tương ứng.
  Future<CalendarEvent?> calendarEventByGoogleId(String googleEventId) async {
    final db = await _databaseManager.database;
    final maps = await db.query('calendar_events',
        where: 'googleEventId = ?', whereArgs: [googleEventId], limit: 1);
    if (maps.isEmpty) return null;
    return CalendarEvent.fromMap(maps.first);
  }

  /// Đánh dấu một event đã đồng bộ xong: gán googleEventId/etag/calendarId (nếu
  /// có) và đặt syncStatus = synced.
  Future<void> markCalendarEventSynced(
    String id, {
    String? googleEventId,
    String? etag,
    String? calendarId,
    String? iCalUID,
  }) async {
    final db = await _databaseManager.database;
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

  // A method that retrieves all the task lists from the tasklists table.
  Future<List<TaskList>> taskLists() async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Query the table for all the TaskLists. Lọc bỏ mục đã ở thùng rác và mục
    // đã được lưu trữ (archive).
    final List<Map<String, dynamic>> maps = await db.query('tasklists',
        where: 'isDeleted = 0 AND isArchived = 0');

    // Convert the List<Map<String, dynamic> into a List<TaskList>.
    return List.generate(maps.length, (index) => TaskList.fromMap(maps[index]));
  }



  Future<List<Task>> tasks() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query('tasks',
        where: 'isDeleted = 0 AND isArchived = 0');
    return List.generate(maps.length, (index) => Task.fromMap(maps[index]));
  }

  Future<List<TimeInterval>> timeIntervals() async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Query the table for all the time intervals.
    final List<Map<String, dynamic>> maps = await db.query('timeintervals');

    // Convert the List<Map<String, dynamic> into a List<TaskList>.
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
  }

  Future<List<Event>> events() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (index) => Event.fromMap(maps[index]));
  }

  Future<TaskList> taskList(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('tasklists', where: 'id = ?', whereArgs: [id]);
    return TaskList.fromMap(maps[0]);
  }

  Future<Task> task(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return Task.fromMap(maps[0]);
  }

  Future<Event> event(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('events', where: 'id = ?', whereArgs: [id]);
    return Event.fromMap(maps[0]);
  }

  Future<TimeInterval> timeInterval(String id) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps =
        await db.query('timeintervals', where: 'id = ?', whereArgs: [id]);
    return TimeInterval.fromMap(maps[0]);
  }

  Future<List<Task>> tasksOfTaskList(String taskListId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'taskListId = ? AND isDeleted = 0 AND isArchived = 0',
      whereArgs: [taskListId],
    );
    return List.generate(maps.length, (index) => Task.fromMap(maps[index]));
  }

  /// Các task "tự do" (không thuộc danh sách nào) đang hiển thị.
  Future<List<Task>> tasksWithoutTaskList() async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'taskListId IS NULL AND isDeleted = 0 AND isArchived = 0',
    );
    return List.generate(maps.length, (index) => Task.fromMap(maps[index]));
  }

  /// Đổi danh sách của một task (null = đưa ra cấp cao nhất, không thuộc list).
  Future<void> moveTask(String taskId, String? newTaskListId) async {
    final db = await _databaseManager.database;
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

  Future<List<Event>> eventsOfTaskList(String taskListId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'taskListId = ?',
      whereArgs: [taskListId],
    );
    return List.generate(maps.length, (index) => Event.fromMap(maps[index]));
  }

  /// Các interval lập kế hoạch cho CHÍNH task cha (không tính interval của các
  /// công việc con — dùng [timeIntervalsOfSubtask] cho subtask).
  Future<List<TimeInterval>> timeIntervalsOfTask(String taskId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timeintervals',
      where: 'taskId = ? AND subtaskId IS NULL',
      whereArgs: [taskId],
    );
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
  }

  /// Tất cả interval thuộc một task (kể cả của các công việc con).
  Future<List<TimeInterval>> allTimeIntervalsOfTask(String taskId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timeintervals',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
  }

  /// Các interval lập kế hoạch cho MỘT công việc con cụ thể.
  Future<List<TimeInterval>> timeIntervalsOfSubtask(String subtaskId) async {
    final db = await _databaseManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timeintervals',
      where: 'subtaskId = ?',
      whereArgs: [subtaskId],
    );
    return List.generate(
        maps.length, (index) => TimeInterval.fromMap(maps[index]));
  }

  // A method that updates a task list data from the tasklists table.
  Future<void> updateTaskList(TaskList taskList) async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Update the given task list
    await db.update(
      'tasklists',
      taskList.toMap(),
      // Ensure that the task list has a matching id.
      where: 'id = ?',
      // Pass the tasklist's id as a whereArg to prevent SQL injection.
      whereArgs: [taskList.id],
    );
  }

  Future<void> updateTask(Task task) async {
    final db = await _databaseManager.database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> updateEvent(Event event) async {
    final db = await _databaseManager.database;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> updateTimeInterval(TimeInterval timeInterval) async {
    final db = await _databaseManager.database;
    await db.update(
      'timeintervals',
      timeInterval.toMap(),
      where: 'id = ?',
      whereArgs: [timeInterval.id],
    );
    // Side-effect (lên lịch lại nhắc) được xử lý bởi SqliteTimeIntervalRepository.
  }

  // A method that deletes a task list data from the tasklists table.
  Future<void> deleteTaskList(String id) async {
    // Get a reference to the database.
    final db = await _databaseManager.database;

    // Remove the task list from the database.
    await db.delete(
      'tasklists',
      // Use a `where` clause to delete a specific task list.
      where: 'id = ?',
      // Pass the tasklist's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
    //printTasks();
  }

  Future<void> deleteTask(String id) async {
    final db = await _databaseManager.database;

    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    //printTimeIntervals();
  }

  Future<void> deleteEvent(String id) async {
    final db = await _databaseManager.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTimeInterval(String id) async {
    final db = await _databaseManager.database;
    // Xóa row. Side-effect hủy nhắc được xử lý bởi SqliteTimeIntervalRepository
    // (đọc interval trước rồi gọi ReminderScheduler.cancel) — không cần làm ở đây.
    await db.delete('timeintervals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> onCreateTableTaskLists(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
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

  Future<void> onCreateTableTasks(Database db) async {
    // Run the CREATE {tasks} TABLE statement on the database.
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

  Future<void> onCreateTableEvents(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
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

  /// Bảng calendar_events — model [CalendarEvent] tương thích Google Calendar.
  /// Các object lồng (start/end/attendees/reminders/recurrence...) được lưu
  /// dưới dạng chuỗi JSON trong một cột TEXT (xem CalendarEvent.toMap). Có đủ
  /// cột soft-delete/archive để event hoạt động như task trong danh sách.
  Future<void> onCreateTableCalendarEvents(Database db) async {
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

  Future<void> onCreateTableTimeIntervals(Database db) async {
    // Run the CREATE {task lists} TABLE statement on the database.
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

  // ------------------------------------------------------------------
  // FOCUS SESSIONS (Pomodoro Focus Timer)
  // ------------------------------------------------------------------

  /// Tạo bảng lưu các phiên focus.
  ///
  /// Không đặt FOREIGN KEY tới bảng task vì taskId có thể trỏ tới 1 trong 3 loại
  /// bảng task khác nhau (hoặc null). Ta lưu kèm taskTitle để thống kê vẫn đúng
  /// kể cả khi task gốc bị xóa.
  Future<void> onCreateTableFocusSessions(Database db) async {
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

  // ------------------------------------------------------------------
  // NOTES (Ghi chú)
  // ------------------------------------------------------------------

  Future<void> onCreateTableNotes(Database db) async {
    await db.execute(
      '''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT,
        contentJson TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        deviceId TEXT
      )
      ''',
    );
  }

  /// Lấy tất cả ghi chú, mới cập nhật lên trước.
  Future<List<Note>> notes() async {
    final db = await _databaseManager.database;
    final maps = await db.query('notes', orderBy: 'updatedAt DESC');
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<Note?> note(String id) async {
    final db = await _databaseManager.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<void> insertNote(Note note) async {
    final db = await _databaseManager.database;
    await db.insert(
      'notes',
      _withDeviceId(note.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note note) async {
    final db = await _databaseManager.database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await _databaseManager.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // LỊCH SỬ CHAT AI (v12): conversations + chat_messages
  // ---------------------------------------------------------------------------

  /// Bảng cuộc trò chuyện (metadata). Nội dung tin nằm ở chat_messages.
  Future<void> onCreateTableConversations(Database db) async {
    await db.execute(
      '''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
      ''',
    );
  }

  /// Bảng tin nhắn chat. Xóa theo cuộc trò chuyện nhờ ON DELETE CASCADE (khóa
  /// ngoài + PRAGMA foreign_keys = ON đã bật ở onConfigure).
  Future<void> onCreateTableChatMessages(Database db) async {
    await db.execute(
      '''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT,
        toolCalls TEXT,
        toolCallId TEXT,
        name TEXT,
        isError INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT,
        FOREIGN KEY (conversationId) REFERENCES conversations (id) ON DELETE CASCADE
      )
      ''',
    );
    await db.execute(
      'CREATE INDEX idx_chat_messages_conversation ON chat_messages (conversationId, createdAt)',
    );
  }

  /// Danh sách cuộc trò chuyện, mới cập nhật lên đầu.
  Future<List<Conversation>> conversations() async {
    final db = await _databaseManager.database;
    final maps = await db.query('conversations', orderBy: 'updatedAt DESC');
    return maps.map((m) => Conversation.fromMap(m)).toList();
  }

  Future<Conversation?> conversation(String id) async {
    final db = await _databaseManager.database;
    final maps =
        await db.query('conversations', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Conversation.fromMap(maps.first);
  }

  Future<void> insertConversation(Conversation c) async {
    final db = await _databaseManager.database;
    await db.insert(
      'conversations',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateConversation(Conversation c) async {
    final db = await _databaseManager.database;
    await db.update(
      'conversations',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> deleteConversation(String id) async {
    final db = await _databaseManager.database;
    // chat_messages tự xóa theo ON DELETE CASCADE.
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  /// Xóa các cuộc trò chuyện có [updatedAt] cũ hơn [cutoff]. So sánh trên chuỗi
  /// ISO8601 (sắp xếp từ điển trùng thứ tự thời gian). Trả về số cuộc đã xóa.
  Future<int> deleteConversationsUpdatedBefore(DateTime cutoff) async {
    final db = await _databaseManager.database;
    return db.delete(
      'conversations',
      where: 'updatedAt < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  /// Các tin nhắn của một cuộc trò chuyện, cũ -> mới (theo thứ tự hiển thị).
  Future<List<ChatMessageRecord>> chatMessages(String conversationId) async {
    final db = await _databaseManager.database;
    final maps = await db.query(
      'chat_messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => ChatMessageRecord.fromMap(m)).toList();
  }

  Future<void> insertChatMessage(ChatMessageRecord message) async {
    final db = await _databaseManager.database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Thêm một phiên focus.
  Future<void> insertFocusSession(FocusSession session) async {
    final db = await _databaseManager.database;
    await db.insert(
      'focus_sessions',
      _withDeviceId(session.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cập nhật một phiên (ví dụ đánh dấu đã sync).
  Future<void> updateFocusSession(FocusSession session) async {
    final db = await _databaseManager.database;
    await db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Lấy tất cả phiên focus, mới nhất trước.
  Future<List<FocusSession>> focusSessions() async {
    final db = await _databaseManager.database;
    final maps = await db.query('focus_sessions', orderBy: 'startTime DESC');
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  /// Lấy các phiên focus trong khoảng [start, end) — dùng cho thống kê theo
  /// ngày/tuần/tháng. So sánh trên chuỗi ISO8601 hợp lệ vì định dạng này sắp
  /// xếp theo thứ tự từ điển đúng bằng thứ tự thời gian.
  Future<List<FocusSession>> focusSessionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseManager.database;
    final maps = await db.query(
      'focus_sessions',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime DESC',
    );
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  /// Lấy các phiên chưa được đồng bộ lên Firestore.
  Future<List<FocusSession>> unsyncedFocusSessions() async {
    final db = await _databaseManager.database;
    final maps = await db.query(
      'focus_sessions',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  // ------------------------------------------------------------------
  // THÙNG RÁC (soft-delete)
  // ------------------------------------------------------------------

  /// Đánh dấu một dòng là đã xóa (đưa vào thùng rác) trong [table].
  Future<void> _markDeleted(Database db, String table, String id) async {
    await db.update(
      table,
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft-delete một TaskList: đánh dấu chính nó VÀ tất cả task con là đã xóa.
  /// Ta làm cascade thủ công trong Dart (không dựa vào FK cascade, vốn chỉ áp
  /// dụng cho hard delete) để có thể khôi phục lại cả cụm sau này.
  Future<void> softDeleteTaskList(String id) async {
    final db = await _databaseManager.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final values = {'isDeleted': 1, 'deletedAt': now};
      await txn.update('tasklists', values, where: 'id = ?', whereArgs: [id]);
      // Chỉ đánh dấu các task con CHƯA bị xóa, để khi khôi phục list ta biết
      // được task nào bị xóa "theo list" và task nào người dùng đã tự xóa trước.
      final childWhere = 'taskListId = ? AND isDeleted = 0';
      await txn.update('tasks', values, where: childWhere, whereArgs: [id]);
    });
  }

  Future<void> softDeleteTask(String id) async {
    final db = await _databaseManager.database;
    await _markDeleted(db, 'tasks', id);
  }

  /// Khôi phục một dòng khỏi thùng rác trong [table].
  Future<void> _restore(Database db, String table, String id) async {
    await db.update(
      table,
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Khôi phục một TaskList: khôi phục chính nó và các task con đã bị xóa CÙNG
  /// thời điểm với nó (tức bị xóa "theo list"). So sánh deletedAt để không vô
  /// tình khôi phục những task mà người dùng đã tự xóa riêng trước đó.
  Future<void> restoreTaskList(String id) async {
    final db = await _databaseManager.database;
    // Lấy mốc thời gian xóa của chính list.
    final listRows = await db.query('tasklists',
        columns: ['deletedAt'], where: 'id = ?', whereArgs: [id]);
    final String? listDeletedAt =
        listRows.isNotEmpty ? listRows.first['deletedAt'] as String? : null;

    await db.transaction((txn) async {
      await txn.update('tasklists', {'isDeleted': 0, 'deletedAt': null},
          where: 'id = ?', whereArgs: [id]);
      if (listDeletedAt != null) {
        final childWhere =
            'taskListId = ? AND isDeleted = 1 AND deletedAt = ?';
        final restoreValues = {'isDeleted': 0, 'deletedAt': null};
        await txn.update('tasks', restoreValues,
            where: childWhere, whereArgs: [id, listDeletedAt]);
      }
    });
  }

  Future<void> restoreTask(String id) async {
    final db = await _databaseManager.database;
    await _restore(db, 'tasks', id);
  }

  /// Soft-delete một calendar event (đưa vào thùng rác).
  Future<void> softDeleteCalendarEvent(String id) async {
    final db = await _databaseManager.database;
    await _markDeleted(db, 'calendar_events', id);
  }

  Future<void> restoreCalendarEvent(String id) async {
    final db = await _databaseManager.database;
    await _restore(db, 'calendar_events', id);
  }

  /// Xóa vĩnh viễn một TaskList (và các task con bị xóa theo nó qua FK cascade).
  Future<void> permanentlyDeleteTaskList(String id) => deleteTaskList(id);

  Future<void> permanentlyDeleteTask(String id) => deleteTask(id);

  /// Lấy tất cả mục đang nằm trong thùng rác, mới xóa lên trước.
  Future<List<TrashedItem>> trashedItems() async {
    final db = await _databaseManager.database;
    final result = <TrashedItem>[];

    Future<void> collect(TrashedItemType type) async {
      final maps = await db.query(
        type.table,
        columns: ['id', 'title', 'deletedAt'],
        where: 'isDeleted = 1',
      );
      for (final m in maps) {
        final deletedAtStr = m['deletedAt'] as String?;
        result.add(TrashedItem(
          type: type,
          id: m['id'] as String,
          title: (m['title'] as String?) ?? '',
          deletedAt: deletedAtStr != null
              ? DateTime.parse(deletedAtStr)
              : DateTime.now(),
        ));
      }
    }

    await collect(TrashedItemType.taskList);
    await collect(TrashedItemType.task);
    await collect(TrashedItemType.calendarEvent);

    result.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return result;
  }

  /// Xóa VĨNH VIỄN các mục trong thùng rác đã quá hạn [retentionDays] ngày.
  /// Gọi khi mở app. Trả về số mục đã xóa.
  Future<int> purgeExpiredTrash(int retentionDays) async {
    final db = await _databaseManager.database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .toIso8601String();
    var deleted = 0;
    for (final table in _softDeleteTables) {
      deleted += await db.delete(
        table,
        where: 'isDeleted = 1 AND deletedAt IS NOT NULL AND deletedAt < ?',
        whereArgs: [cutoff],
      );
    }
    return deleted;
  }

  /// Dọn sạch toàn bộ thùng rác ngay lập tức (xóa vĩnh viễn mọi mục đã xóa).
  Future<void> emptyTrash() async {
    final db = await _databaseManager.database;
    for (final table in _softDeleteTables) {
      await db.delete(table, where: 'isDeleted = 1');
    }
  }

  // ------------------------------------------------------------------
  // LƯU TRỮ (archive) — ẩn khỏi màn chính nhưng KHÔNG xóa
  // ------------------------------------------------------------------

  /// Lưu trữ một TaskList: đánh dấu chính nó VÀ tất cả task con (chưa bị xóa,
  /// chưa được lưu trữ) là đã lưu trữ. Cascade thủ công để có thể bỏ lưu trữ
  /// lại cả cụm sau này (so cùng archivedAt), giống cách làm ở soft-delete.
  Future<void> archiveTaskList(String id) async {
    final db = await _databaseManager.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final values = {'isArchived': 1, 'archivedAt': now};
      await txn.update('tasklists', values, where: 'id = ?', whereArgs: [id]);
      // Chỉ lưu trữ các task con CHƯA bị xóa và CHƯA được lưu trữ, để khi bỏ
      // lưu trữ list ta biết task nào bị lưu trữ "theo list".
      final childWhere = 'taskListId = ? AND isDeleted = 0 AND isArchived = 0';
      await txn.update('tasks', values, where: childWhere, whereArgs: [id]);
    });
  }

  Future<void> archiveTask(String id) async {
    final db = await _databaseManager.database;
    await db.update(
      'tasks',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Bỏ lưu trữ một TaskList: khôi phục chính nó và các task con được lưu trữ
  /// CÙNG thời điểm với nó (bị lưu trữ "theo list"). So sánh archivedAt để không
  /// vô tình bỏ lưu trữ những task người dùng đã tự lưu trữ riêng trước đó.
  Future<void> unarchiveTaskList(String id) async {
    final db = await _databaseManager.database;
    final listRows = await db.query('tasklists',
        columns: ['archivedAt'], where: 'id = ?', whereArgs: [id]);
    final String? listArchivedAt =
        listRows.isNotEmpty ? listRows.first['archivedAt'] as String? : null;

    await db.transaction((txn) async {
      await txn.update('tasklists', {'isArchived': 0, 'archivedAt': null},
          where: 'id = ?', whereArgs: [id]);
      if (listArchivedAt != null) {
        final childWhere =
            'taskListId = ? AND isArchived = 1 AND archivedAt = ?';
        await txn.update('tasks', {'isArchived': 0, 'archivedAt': null},
            where: childWhere, whereArgs: [id, listArchivedAt]);
      }
    });
  }

  Future<void> unarchiveTask(String id) async {
    final db = await _databaseManager.database;
    await db.update(
      'tasks',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Lưu trữ một calendar event (ẩn khỏi màn chính, không xóa).
  Future<void> archiveCalendarEvent(String id) async {
    final db = await _databaseManager.database;
    await db.update(
      'calendar_events',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchiveCalendarEvent(String id) async {
    final db = await _databaseManager.database;
    await db.update(
      'calendar_events',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Lấy tất cả mục đang được lưu trữ, mới lưu trữ lên trước.
  Future<List<ArchivedItem>> archivedItems() async {
    final db = await _databaseManager.database;
    final result = <ArchivedItem>[];

    Future<void> collect(ArchivedItemType type) async {
      // Bỏ qua các mục đồng thời nằm trong thùng rác (đã xóa) để tránh trùng.
      final maps = await db.query(
        type.table,
        columns: ['id', 'title', 'archivedAt'],
        where: 'isArchived = 1 AND isDeleted = 0',
      );
      for (final m in maps) {
        final archivedAtStr = m['archivedAt'] as String?;
        result.add(ArchivedItem(
          type: type,
          id: m['id'] as String,
          title: (m['title'] as String?) ?? '',
          archivedAt: archivedAtStr != null
              ? DateTime.parse(archivedAtStr)
              : DateTime.now(),
        ));
      }
    }

    await collect(ArchivedItemType.taskList);
    await collect(ArchivedItemType.task);
    await collect(ArchivedItemType.calendarEvent);

    result.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
    return result;
  }

  // ------------------------------------------------------------------
  // EXPORT / IMPORT (map thô — dùng cho tính năng sao lưu & khôi phục)
  // ------------------------------------------------------------------

  /// Lấy TẤT CẢ bản ghi của [table] dưới dạng map thô (kể cả các mục đã bị
  /// soft-delete), phục vụ export đầy đủ. Trả về danh sách map có thể chỉnh sửa.
  Future<List<Map<String, dynamic>>> rawRows(String table) async {
    final db = await _databaseManager.database;
    final rows = await db.query(table);
    // db.query trả về danh sách read-only; sao chép để tầng trên có thể sửa.
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  /// Đọc một bản ghi theo id dưới dạng map thô, hoặc null nếu không tồn tại.
  Future<Map<String, dynamic>?> rawRowById(String table, String id) async {
    final db = await _databaseManager.database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  /// Ghi một map thô vào [table] (insert-or-replace theo khóa chính id). Dùng
  /// cho import: [row] đã chứa sẵn deviceId từ file nguồn nên KHÔNG gắn đè.
  ///
  /// Chỉ giữ lại các khóa là cột thực sự tồn tại trong bảng để tránh lỗi khi
  /// file import có thừa cột (ví dụ được tạo bởi phiên bản khác).
  Future<void> importRawRow(String table, Map<String, dynamic> row) async {
    final db = await _databaseManager.database;
    final columns = await _tableColumns(db, table);
    final filtered = <String, dynamic>{
      for (final entry in row.entries)
        if (columns.contains(entry.key)) entry.key: entry.value,
    };
    await db.insert(
      table,
      filtered,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ghi hàng loạt map thô trong một transaction (nhanh hơn khi import nhiều).
  Future<void> importRawRows(
      String table, List<Map<String, dynamic>> rows) async {
    final db = await _databaseManager.database;
    final columns = await _tableColumns(db, table);
    await db.transaction((txn) async {
      for (final row in rows) {
        final filtered = <String, dynamic>{
          for (final entry in row.entries)
            if (columns.contains(entry.key)) entry.key: entry.value,
        };
        await txn.insert(
          table,
          filtered,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Trả về tập tên cột của [table] (đọc qua PRAGMA table_info).
  Future<Set<String>> _tableColumns(Database db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.map((c) => c['name'] as String).toSet();
  }
}
