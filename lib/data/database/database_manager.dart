import 'package:my_time_manager/screen_archive/model_archived_item.dart';
import 'package:my_time_manager/screen_trash/model_trashed_item.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'daos/task_list_dao.dart';
import 'daos/task_dao.dart';
import 'daos/event_dao.dart';
import 'daos/calendar_event_dao.dart';
import 'daos/time_interval_dao.dart';
import 'daos/focus_session_dao.dart';
import 'daos/note_dao.dart';
import 'daos/conversation_dao.dart';
import 'daos/goal_dao.dart';
import 'device_id_helper.dart' as device_id;

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
  /// If [path] is given, that database FILE is opened instead of a fresh
  /// in-memory one (same version/onCreate/onUpgrade/FK config) — used by
  /// migration tests to upgrade a DB created at an older schema version.
  ///
  /// Requires an FFI factory to be configured by the caller (test setup does
  /// `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;`).
  @visibleForTesting
  Future<void> resetForTesting({bool inMemory = true, String? path}) async {
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
    if (path != null) {
      _database = await openDatabase(
        path,
        version: _schemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        singleInstance: false,
      );
    } else if (inMemory) {
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
  static const int _schemaVersion = 13;

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
      // v13: thêm bảng goals + milestones + goal_links (Mục tiêu / Cột mốc /
      //     liên kết mục tiêu–task), các index và trigger
      //     delete_goal_links_of_task (xóa cứng task → xóa liên kết). Hoàn
      //     toàn bổ sung: không đổi cột của bảng cũ nào.
      version: _schemaVersion,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Các bảng có hỗ trợ soft-delete (thùng rác).
  static const List<String> _softDeleteTables = [
    'tasklists',
    'tasks',
    'calendar_events',
    'goals',
  ];

  /// Tất cả các bảng dữ liệu (dùng cho export/import và cho migrate deviceId).
  /// Thứ tự tôn trọng khóa ngoại: cha trước, con sau (goals → milestones →
  /// goal_links).
  static const List<String> allDataTables = [
    'tasklists',
    'tasks',
    'events',
    'calendar_events',
    'timeintervals',
    'focus_sessions',
    'notes',
    'goals',
    'milestones',
    'goal_links',
  ];

  /// Đặt deviceId hiện tại (gọi một lần khi app khởi động). Uỷ thác cho
  /// [device_id_helper] để các DAO dùng chung mà không phụ thuộc DatabaseManager.
  static void setCurrentDeviceId(String id) => device_id.setCurrentDeviceId(id);

  /// Nâng cấp schema khi người dùng đã có DB cũ (giữ nguyên dữ liệu hiện có).
  /// Mỗi lần tăng version thêm một nhánh if tương ứng.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Bổ sung bảng focus_sessions cho các cài đặt đã tồn tại từ v1.
      await FocusSessionDao.createTable(db);
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
      await NoteDao.createTable(db);
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
      await TaskDao.createTable(db);
      await TimeIntervalDao.createTable(db);
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
      await CalendarEventDao.createTable(db);
    }
    if (oldVersion < 12) {
      // Thêm bảng lịch sử chat AI: conversations + chat_messages.
      await ConversationDao.createConversationsTable(db);
      await ConversationDao.createChatMessagesTable(db);
    }
    if (oldVersion < 13) {
      // Thêm 3 bảng mới goals + milestones + goal_links, các index và trigger
      // xóa liên kết khi xóa cứng task. Không đụng tới bảng/cột cũ nào. Bảng
      // tasks chắc chắn đã tồn tại ở đây (tạo lại ở nhánh v9 phía trên, trước
      // khi trigger được tạo nên không mất trigger).
      await GoalDao.createSchema(db);
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
    await TaskListDao.createTable(db);
    await TaskDao.createTable(db);
    await EventDao.createTable(db);
    await CalendarEventDao.createTable(db);
    await TimeIntervalDao.createTable(db);
    await FocusSessionDao.createTable(db);
    await NoteDao.createTable(db);
    await ConversationDao.createConversationsTable(db);
    await ConversationDao.createChatMessagesTable(db);
    // Mục tiêu / cột mốc / liên kết (v13). Phải sau TaskDao (trigger trên tasks).
    await GoalDao.createSchema(db);


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

  // ------------------------------------------------------------------
  // CRUD theo aggregate đã được tách sang các DAO trong `daos/` (Core Track
  // C4). DatabaseManager chỉ còn: mở DB, schema/migration, trigger, các truy
  // vấn liên-bảng của thùng rác/lưu trữ, và export/import map thô.
  // ------------------------------------------------------------------

  // ------------------------------------------------------------------
  // THÙNG RÁC (soft-delete) — truy vấn liên-bảng
  // ------------------------------------------------------------------

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
    await collect(TrashedItemType.goal);

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
  // LƯU TRỮ (archive) — truy vấn liên-bảng
  // ------------------------------------------------------------------

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
    await collect(ArchivedItemType.goal);

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
    await _writeImportRow(db, table, filtered);
  }

  /// Các bảng import theo kiểu "update trước, không có thì insert" thay vì
  /// INSERT OR REPLACE. Lý do: REPLACE = DELETE + INSERT, sẽ kích hoạt
  /// ON DELETE CASCADE / SET NULL — ghi đè một goal sẽ xóa mất các milestone /
  /// liên kết cục bộ của nó (hoặc làm null milestoneId của liên kết). Không
  /// dùng `ON CONFLICT DO UPDATE` vì cần SQLite 3.24 (quá mới với vài bản
  /// Android). Các bảng khác giữ nguyên REPLACE (không đổi hành vi).
  static const Set<String> _updateFirstImportTables = {
    'goals',
    'milestones',
    'goal_links',
  };

  /// Ghi một hàng import đã lọc cột vào [table] qua [exec] (db hoặc txn).
  Future<void> _writeImportRow(DatabaseExecutor exec, String table,
      Map<String, dynamic> filtered) async {
    if (_updateFirstImportTables.contains(table)) {
      final n = await exec.update(table, filtered,
          where: 'id = ?', whereArgs: [filtered['id']]);
      if (n == 0) await exec.insert(table, filtered);
      return;
    }
    await exec.insert(
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
        await _writeImportRow(txn, table, filtered);
      }
    });
  }

  /// Trả về tập tên cột của [table] (đọc qua PRAGMA table_info).
  Future<Set<String>> _tableColumns(Database db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.map((c) => c['name'] as String).toSet();
  }
}
