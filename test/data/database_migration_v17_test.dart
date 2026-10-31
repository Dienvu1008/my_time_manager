@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/daos/calendar_event_dao.dart';
import 'package:my_time_manager/data/database/daos/conversation_dao.dart';
import 'package:my_time_manager/data/database/daos/event_dao.dart';
import 'package:my_time_manager/data/database/daos/focus_session_dao.dart';
import 'package:my_time_manager/data/database/daos/goal_dao.dart';
import 'package:my_time_manager/data/database/daos/learning_dao.dart';
import 'package:my_time_manager/data/database/daos/note_dao.dart';
import 'package:my_time_manager/data/database/daos/project_dao.dart';
import 'package:my_time_manager/data/database/daos/reminder_rule_dao.dart';
import 'package:my_time_manager/data/database/daos/task_dao.dart';
import 'package:my_time_manager/data/database/daos/task_list_dao.dart';
import 'package:my_time_manager/data/database/daos/time_interval_dao.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a DB file created at schema v16 with the production DatabaseManager
/// (v17) and verifies the additive upgrade: ai_action_log table + index
/// exist, existing data is preserved and the table is excluded from backup.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v16 → v17 adds ai_action_log, keeps data', () async {
    final dir = Directory.systemTemp.createTempSync('c8b_mig');
    final path = p.join(dir.path, 'v16.db');
    try {
      // 1. Build a v16 database (same table set as v16 `_onCreate`).
      final v16 = await openDatabase(
        path,
        version: 16,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await TaskListDao.createTable(db);
          await TaskDao.createTable(db);
          await EventDao.createTable(db);
          await CalendarEventDao.createTable(db);
          await TimeIntervalDao.createTable(db);
          await FocusSessionDao.createTable(db);
          await NoteDao.createTable(db);
          await ConversationDao.createConversationsTable(db);
          await ConversationDao.createChatMessagesTable(db);
          await GoalDao.createSchema(db);
          await ProjectDao.createSchema(db);
          await LearningDao.createSchema(db);
          await ReminderRuleDao.createSchema(db);
        },
        singleInstance: false,
      );
      const now = '2026-01-01T00:00:00.000';
      await v16.insert('tasklists', {
        'id': 'list1',
        'title': 'Old list',
        'description': '',
        'color': 0xFFFFFFFF,
        'dataFiles': '[]',
        'updateTimeStamp': now,
      });
      await v16.insert('tasks', {
        'id': 'task1',
        'taskListId': 'list1',
        'isCompleted': 0,
        'isImportant': 0,
        'title': 'Old task',
        'description': '',
        'color': 0xFFFFFFFF,
        'tags': '[]',
        'dataFiles': '[]',
        'updateTimeStamp': now,
      });
      await v16.insert('reminder_rules', {
        'id': 'r1',
        'entityType': 'task',
        'entityId': 'task1',
        'offsetMinutes': 10,
      });
      await v16.close();

      // 2. Open with production schema → onUpgrade(16 → 17).
      await DatabaseManager().resetForTesting(path: path);
      final db = await DatabaseManager().database;

      final version =
          (await db.rawQuery('PRAGMA user_version')).first.values.first as int;
      expect(version, 17);

      Future<Set<String>> names(String type) async => (await db.rawQuery(
              'SELECT name FROM sqlite_master WHERE type = ?', [type]))
          .map((r) => r['name'] as String)
          .toSet();
      expect(await names('table'), contains('ai_action_log'));
      expect(await names('index'), contains('idx_ai_action_log_created'));

      // Old data intact.
      expect(
          (await SqliteTaskRepository().getTasks()).single.title, 'Old task');
      expect((await db.query('reminder_rules')).single['offsetMinutes'], 10);

      // New table usable (raw insert).
      await db.insert('ai_action_log', {
        'id': 'a1',
        'createdAt': '2026-01-02T00:00:00.000Z',
        'toolName': 'create_goal',
        'policyLevel': 'write',
        'outcome': 'executed',
      });
      expect(
          (await db.query('ai_action_log')).single['toolName'], 'create_goal');

      // Device-local audit data: excluded from backup/import.
      expect(DatabaseManager.allDataTables, isNot(contains('ai_action_log')));
    } finally {
      await DatabaseManager().resetForTesting(inMemory: false);
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
