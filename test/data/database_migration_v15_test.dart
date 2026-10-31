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
import 'package:my_time_manager/data/database/daos/project_dao.dart';
import 'package:my_time_manager/data/database/daos/task_dao.dart';
import 'package:my_time_manager/data/database/daos/task_list_dao.dart';
import 'package:my_time_manager/data/database/daos/time_interval_dao.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_project_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a DB file created at schema v14 with the production DatabaseManager
/// (v15) and verifies the additive upgrade: learning tables/indexes/triggers
/// exist, existing data is preserved, and the FK cascade works.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v14 → v15 adds learning tables, keeps data, cascade works', () async {
    final dir = Directory.systemTemp.createTempSync('c7_mig');
    final path = p.join(dir.path, 'v14.db');
    try {
      // 1. Build a v14 database (same table set as v14 `_onCreate`).
      final v14 = await openDatabase(
        path,
        version: 14,
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
        },
        singleInstance: false,
      );
      const now = '2026-01-01T00:00:00.000';
      await v14.insert('tasklists', {
        'id': 'list1',
        'title': 'Old list',
        'description': '',
        'color': 0xFFFFFFFF,
        'dataFiles': '[]',
        'updateTimeStamp': now,
      });
      await v14.insert('tasks', {
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
      await v14.insert('goals', {
        'id': 'goal1',
        'title': 'Old goal',
        'status': 'active',
        'createdAt': now,
        'updateTimeStamp': now,
      });
      await v14.insert('projects', {
        'id': 'proj1',
        'title': 'Old project',
        'status': 'active',
        'createdAt': now,
        'updateTimeStamp': now,
      });
      await v14.close();

      // 2. Open with production schema → onUpgrade(14 → 15).
      await DatabaseManager().resetForTesting(path: path);
      final db = await DatabaseManager().database;

      final version = (await db.rawQuery('PRAGMA user_version')).first.values
          .first as int;
      expect(version, 15);

      Future<Set<String>> names(String type) async => (await db.rawQuery(
              'SELECT name FROM sqlite_master WHERE type = ?', [type]))
          .map((r) => r['name'] as String)
          .toSet();
      expect(
          await names('table'),
          containsAll(
              ['courses', 'course_modules', 'lessons', 'lesson_progress']));
      expect(
          await names('index'),
          containsAll(
              ['idx_course_modules_courseId', 'idx_lessons_moduleId']));
      expect(
          await names('trigger'),
          containsAll([
            'delete_goal_links_of_course',
            'delete_project_items_of_course',
          ]));

      // Old data intact.
      expect((await db.query('tasklists')).single['title'], 'Old list');
      expect((await SqliteTaskRepository().getTasks()).single.title,
          'Old task');
      expect((await SqliteGoalRepository().getGoal('goal1'))!.title,
          'Old goal');
      expect((await SqliteProjectRepository().getProject('proj1'))!.title,
          'Old project');

      // New tables usable (raw inserts) and hard delete cascades.
      await db.insert('courses', {
        'id': 'c1',
        'title': 'Course',
        'createdAt': now,
        'updateTimeStamp': now,
      });
      await db.insert('course_modules',
          {'id': 'm1', 'courseId': 'c1', 'title': 'M', 'createdAt': now});
      await db.insert('lessons',
          {'id': 'l1', 'moduleId': 'm1', 'title': 'L', 'createdAt': now});
      await db.insert('lesson_progress',
          {'id': 'l1', 'lessonId': 'l1', 'status': 'completed'});
      final course = (await db.query('courses')).single;
      expect(course['source'], 'manual');
      expect(course['status'], 'active');
      expect(course['isDeleted'], 0);

      await db.delete('courses', where: 'id = ?', whereArgs: ['c1']);
      for (final t in ['course_modules', 'lessons', 'lesson_progress']) {
        expect(await db.query(t), isEmpty, reason: t);
      }
    } finally {
      // Close the file DB so the temp dir can be removed.
      await DatabaseManager().resetForTesting(inMemory: false);
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
