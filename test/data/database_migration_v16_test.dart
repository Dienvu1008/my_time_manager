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
import 'package:my_time_manager/data/database/daos/task_dao.dart';
import 'package:my_time_manager/data/database/daos/task_list_dao.dart';
import 'package:my_time_manager/data/database/daos/time_interval_dao.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_learning_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a DB file created at schema v15 with the production DatabaseManager
/// (v16) and verifies the additive upgrade: reminder_rules table/index/
/// triggers exist, existing data is preserved, defaults apply and the
/// hard-delete trigger removes rules.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v15 → v16 adds reminder_rules, keeps data, trigger works', () async {
    final dir = Directory.systemTemp.createTempSync('r1_mig');
    final path = p.join(dir.path, 'v15.db');
    try {
      // 1. Build a v15 database (same table set as v15 `_onCreate`).
      final v15 = await openDatabase(
        path,
        version: 15,
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
        },
        singleInstance: false,
      );
      const now = '2026-01-01T00:00:00.000';
      await v15.insert('tasklists', {
        'id': 'list1',
        'title': 'Old list',
        'description': '',
        'color': 0xFFFFFFFF,
        'dataFiles': '[]',
        'updateTimeStamp': now,
      });
      await v15.insert('tasks', {
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
      await v15.insert('courses', {
        'id': 'c1',
        'title': 'Old course',
        'createdAt': now,
        'updateTimeStamp': now,
      });
      await v15.close();

      // 2. Open with production schema → onUpgrade(15 → 16).
      await DatabaseManager().resetForTesting(path: path);
      final db = await DatabaseManager().database;

      final version = (await db.rawQuery('PRAGMA user_version')).first.values
          .first as int;
      expect(version, 16);

      Future<Set<String>> names(String type) async => (await db.rawQuery(
              'SELECT name FROM sqlite_master WHERE type = ?', [type]))
          .map((r) => r['name'] as String)
          .toSet();
      expect(await names('table'), contains('reminder_rules'));
      expect(await names('index'), contains('idx_reminder_rules_entity'));
      expect(
          await names('trigger'),
          containsAll([
            'delete_reminder_rules_of_timeinterval',
            'delete_reminder_rules_of_calendar_event',
            'delete_reminder_rules_of_task',
          ]));

      // Old data intact.
      expect((await db.query('tasklists')).single['title'], 'Old list');
      expect(
          (await SqliteTaskRepository().getTasks()).single.title, 'Old task');
      expect((await SqliteLearningRepository().getCourse('c1'))!.title,
          'Old course');

      // New table usable (raw insert) with defaults.
      await db.insert('reminder_rules', {
        'id': 'r1',
        'entityType': 'task',
        'entityId': 'task1',
        'offsetMinutes': 10,
      });
      final rule = (await db.query('reminder_rules')).single;
      expect(rule['kind'], 'offset');
      expect(rule['enabled'], 1);
      expect(rule['priority'], 0);

      // Hard-deleting the task removes its rule.
      await db.delete('tasks', where: 'id = ?', whereArgs: ['task1']);
      expect(await db.query('reminder_rules'), isEmpty);
    } finally {
      // Close the file DB so the temp dir can be removed.
      await DatabaseManager().resetForTesting(inMemory: false);
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
