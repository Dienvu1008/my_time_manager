@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/daos/ai_action_log_dao.dart';
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
import 'package:my_time_manager/data/repositories/sqlite_goal_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_habit_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a DB file created at schema v17 with the production DatabaseManager
/// (v18) and verifies the additive upgrade: habits + habit_occurrences tables,
/// index and triggers exist, existing data is preserved.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v17 → v18 adds habits + habit_occurrences, keeps data', () async {
    final dir = Directory.systemTemp.createTempSync('h1_mig');
    final path = p.join(dir.path, 'v17.db');
    try {
      // 1. Build a v17 database (same table set as v17 `_onCreate`).
      final v17 = await openDatabase(
        path,
        version: 17,
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
          await AiActionLogDao.createSchema(db);
        },
        singleInstance: false,
      );
      const now = '2026-01-01T00:00:00.000';
      await v17.insert('tasklists', {
        'id': 'list1',
        'title': 'Old list',
        'description': '',
        'color': 0xFFFFFFFF,
        'dataFiles': '[]',
        'updateTimeStamp': now,
      });
      await v17.insert('tasks', {
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
      await v17.insert('goals', {'id': 'g1', 'title': 'Old goal'});
      await v17.insert('ai_action_log', {
        'id': 'a1',
        'createdAt': '2026-01-02T00:00:00.000Z',
        'toolName': 'create_goal',
        'policyLevel': 'write',
        'outcome': 'executed',
      });
      await v17.close();

      // 2. Open with production schema → onUpgrade(17 → 18).
      await DatabaseManager().resetForTesting(path: path);
      final db = await DatabaseManager().database;

      final version =
          (await db.rawQuery('PRAGMA user_version')).first.values.first as int;
      expect(version, 18);

      Future<Set<String>> names(String type) async => (await db.rawQuery(
              'SELECT name FROM sqlite_master WHERE type = ?', [type]))
          .map((r) => r['name'] as String)
          .toSet();
      expect(await names('table'), containsAll(['habits', 'habit_occurrences']));
      expect(await names('index'), contains('idx_habit_occurrences_habit_date'));
      expect(
          await names('trigger'),
          containsAll(
              ['delete_goal_links_of_habit', 'delete_project_items_of_habit']));

      // Old data intact.
      expect(
          (await SqliteTaskRepository().getTasks()).single.title, 'Old task');
      expect((await SqliteGoalRepository().getGoal('g1'))!.title, 'Old goal');
      expect((await db.query('ai_action_log')).single['toolName'],
          'create_goal');

      // New tables usable through the repository.
      final habits = SqliteHabitRepository();
      final h = Habit(title: 'Meditate', startDate: DateTime(2026, 1, 1));
      await habits.createHabit(h);
      await habits.recordOutcome(
          h.id, DateTime(2026, 1, 2), HabitOutcome.completed);
      expect((await habits.occurrencesOf(h.id)).single.outcome,
          HabitOutcome.completed);

      // Backup integration.
      expect(DatabaseManager.allDataTables,
          containsAllInOrder(['habits', 'habit_occurrences']));
    } finally {
      await DatabaseManager().resetForTesting(inMemory: false);
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('fresh v18 schema matches upgraded schema for habit objects', () async {
    await DatabaseManager().resetForTesting(inMemory: true);
    final db = await DatabaseManager().database;
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name LIKE '%habit%'");
    expect(
        rows.map((r) => r['name']).toSet(),
        containsAll([
          'habits',
          'habit_occurrences',
          'idx_habit_occurrences_habit_date',
          'delete_goal_links_of_habit',
          'delete_project_items_of_habit',
        ]));
  });
}
