@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/daos/calendar_event_dao.dart';
import 'package:my_time_manager/data/database/daos/conversation_dao.dart';
import 'package:my_time_manager/data/database/daos/event_dao.dart';
import 'package:my_time_manager/data/database/daos/focus_session_dao.dart';
import 'package:my_time_manager/data/database/daos/note_dao.dart';
import 'package:my_time_manager/data/database/daos/task_dao.dart';
import 'package:my_time_manager/data/database/daos/task_list_dao.dart';
import 'package:my_time_manager/data/database/daos/time_interval_dao.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a DB file created at schema v12 with the production DatabaseManager
/// (v13) and verifies the additive upgrade: new tables/indexes/trigger exist and
/// existing data is preserved.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v12 → v13 adds goal tables, keeps data, trigger works', () async {
    final dir = Directory.systemTemp.createTempSync('c5_mig');
    final path = p.join(dir.path, 'v12.db');
    try {
      // 1. Build a v12 database (same table set as v12 `_onCreate`).
      final v12 = await openDatabase(
        path,
        version: 12,
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
        },
        singleInstance: false,
      );
      const now = '2026-01-01T00:00:00.000';
      await v12.insert('tasklists', {
        'id': 'list1',
        'title': 'Old list',
        'description': '',
        'color': 0xFFFFFFFF,
        'dataFiles': '[]',
        'updateTimeStamp': now,
      });
      await v12.insert('tasks', {
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
      await v12.close();

      // 2. Open with production schema → onUpgrade(12 → 13).
      await DatabaseManager().resetForTesting(path: path);
      final db = await DatabaseManager().database;

      final version = (await db.rawQuery('PRAGMA user_version')).first.values
          .first as int;
      expect(version, 13);

      Future<Set<String>> names(String type) async => (await db.rawQuery(
              'SELECT name FROM sqlite_master WHERE type = ?', [type]))
          .map((r) => r['name'] as String)
          .toSet();
      expect(await names('table'),
          containsAll(['goals', 'milestones', 'goal_links']));
      expect(
          await names('index'),
          containsAll([
            'idx_milestones_goalId',
            'idx_goal_links_goalId',
            'idx_goal_links_milestoneId',
            'idx_goal_links_entity',
          ]));
      expect(await names('trigger'), contains('delete_goal_links_of_task'));

      // Old data intact.
      final tl = await db.query('tasklists');
      expect(tl.single['title'], 'Old list');
      final tasks = SqliteTaskRepository();
      expect((await tasks.getTasks()).single.title, 'Old task');

      // New tables usable; trigger fires on old task delete.
      final goals = SqliteGoalRepository();
      final g = Goal(title: 'New goal');
      await goals.createGoal(g);
      await goals.linkTask(g.id, 'task1');
      expect(await goals.getLinks(g.id), hasLength(1));
      await tasks.deleteTask('task1');
      expect(await goals.getLinks(g.id), isEmpty);
    } finally {
      // Close the file DB so the temp dir can be removed.
      await DatabaseManager().resetForTesting(inMemory: false);
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
