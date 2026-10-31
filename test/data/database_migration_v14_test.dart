@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/daos/calendar_event_dao.dart';
import 'package:my_time_manager/data/database/daos/conversation_dao.dart';
import 'package:my_time_manager/data/database/daos/event_dao.dart';
import 'package:my_time_manager/data/database/daos/focus_session_dao.dart';
import 'package:my_time_manager/data/database/daos/goal_dao.dart';
import 'package:my_time_manager/data/database/daos/note_dao.dart';
import 'package:my_time_manager/data/database/daos/task_dao.dart';
import 'package:my_time_manager/data/database/daos/task_list_dao.dart';
import 'package:my_time_manager/data/database/daos/time_interval_dao.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_project_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a DB file created at schema v13 with the production DatabaseManager
/// (v14) and verifies the additive upgrade: new tables/indexes/triggers exist
/// and existing data is preserved.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v13 → v14 adds project tables, keeps data, triggers work', () async {
    final dir = Directory.systemTemp.createTempSync('c6_mig');
    final path = p.join(dir.path, 'v13.db');
    try {
      // 1. Build a v13 database (same table set as v13 `_onCreate`).
      final v13 = await openDatabase(
        path,
        version: 13,
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
        },
        singleInstance: false,
      );
      const now = '2026-01-01T00:00:00.000';
      await v13.insert('tasklists', {
        'id': 'list1',
        'title': 'Old list',
        'description': '',
        'color': 0xFFFFFFFF,
        'dataFiles': '[]',
        'updateTimeStamp': now,
      });
      await v13.insert('tasks', {
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
      await v13.insert('goals', {
        'id': 'goal1',
        'title': 'Old goal',
        'status': 'active',
        'createdAt': now,
        'updateTimeStamp': now,
      });
      await v13.close();

      // 2. Open with production schema → onUpgrade(13 → 14).
      await DatabaseManager().resetForTesting(path: path);
      final db = await DatabaseManager().database;

      final version = (await db.rawQuery('PRAGMA user_version')).first.values
          .first as int;
      expect(version, greaterThanOrEqualTo(14));

      Future<Set<String>> names(String type) async => (await db.rawQuery(
              'SELECT name FROM sqlite_master WHERE type = ?', [type]))
          .map((r) => r['name'] as String)
          .toSet();
      expect(await names('table'), containsAll(['projects', 'project_items']));
      expect(
          await names('index'),
          containsAll([
            'idx_project_items_projectId',
            'idx_project_items_unique',
            'idx_project_items_entityRef',
          ]));
      expect(
          await names('trigger'),
          containsAll([
            'delete_project_items_of_tasklist',
            'delete_project_items_of_task',
            'delete_project_items_of_note',
            'delete_project_items_of_calendar_event',
            'delete_project_items_of_goal',
          ]));

      // Old data intact.
      final tl = await db.query('tasklists');
      expect(tl.single['title'], 'Old list');
      final tasks = SqliteTaskRepository();
      expect((await tasks.getTasks()).single.title, 'Old task');
      final goals = SqliteGoalRepository();
      expect((await goals.getGoal('goal1'))!.title, 'Old goal');

      // New tables usable; triggers fire on old entity deletes.
      final projects = SqliteProjectRepository();
      final proj = Project(title: 'New project');
      await projects.createProject(proj);
      await projects.addItem(proj.id, ProjectEntityType.task, 'task1');
      await projects.addItem(proj.id, ProjectEntityType.goal, 'goal1');
      expect(await projects.getItems(proj.id), hasLength(2));
      await tasks.deleteTask('task1');
      expect((await projects.getItems(proj.id)).single.entityId, 'goal1');
      await goals.deleteGoal('goal1');
      expect(await projects.getItems(proj.id), isEmpty);
    } finally {
      // Close the file DB so the temp dir can be removed.
      await DatabaseManager().resetForTesting(inMemory: false);
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
