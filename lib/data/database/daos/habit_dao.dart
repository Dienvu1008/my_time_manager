import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_habit.dart';
import '../../../domain/models/model_habit_occurrence.dart';
import '../device_id_helper.dart';

/// DAO for the Habit aggregate (Phase H1): owns `habits` and
/// `habit_occurrences`.
///
/// Rules:
/// - `habit_occurrences.habitId` → habits ON DELETE CASCADE.
/// - UNIQUE (habitId, localDate): one recorded outcome per habit per day.
/// - No trash: archive is the default removal and does NOT touch occurrences
///   (history is kept). Hard delete ([delete]) cascades occurrences via FK.
/// - Triggers `delete_goal_links_of_habit` / `delete_project_items_of_habit`:
///   hard-deleting a habit removes `entityType='habit'` goal links / project
///   items pointing at it.
/// - Inserts use the default ConflictAlgorithm.abort (never REPLACE): REPLACE
///   = DELETE + INSERT would fire the CASCADE and wipe a habit's history.
class HabitDao {
  HabitDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ------------------------------------------------------------------
  // SCHEMA (v18) — called by DatabaseManager from `_onCreate` and `_onUpgrade`
  // ------------------------------------------------------------------

  /// Creates the whole aggregate schema (2 tables + index + triggers). The
  /// ONLY function used by both `_onCreate` and the `_onUpgrade` v18 branch so
  /// the SQL is always identical. Requires `goal_links` and `project_items`
  /// to exist (for the triggers).
  static Future<void> createSchema(Database db) async {
    await createHabitsTable(db);
    await createHabitOccurrencesTable(db);
    await createHabitTriggers(db);
  }

  static Future<void> createHabitsTable(Database db) async {
    await db.execute('''
    CREATE TABLE habits (
      id TEXT PRIMARY KEY,
      title TEXT,
      description TEXT,
      color INTEGER,
      recurrence TEXT,
      targetAmount REAL,
      unit TEXT,
      partialCountsTowardStreak INTEGER NOT NULL DEFAULT 0,
      startDate TEXT NOT NULL,
      endDate TEXT,
      reminderTime TEXT,
      isArchived INTEGER NOT NULL DEFAULT 0,
      archivedAt TEXT,
      createdAt TEXT,
      updateTimeStamp TEXT,
      deviceId TEXT
      )
    ''');
  }

  static Future<void> createHabitOccurrencesTable(Database db) async {
    await db.execute('''
    CREATE TABLE habit_occurrences (
      id TEXT PRIMARY KEY,
      habitId TEXT NOT NULL,
      localDate TEXT NOT NULL,
      outcome TEXT NOT NULL CHECK (outcome IN
        ('completed', 'partial', 'skipped', 'missed', 'pending')),
      amount REAL,
      note TEXT,
      recordedAt TEXT,
      deviceId TEXT,
      FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');
    // UNIQUE index doubles as the (habitId, localDate) lookup/range index.
    await db.execute('CREATE UNIQUE INDEX idx_habit_occurrences_habit_date '
        'ON habit_occurrences(habitId, localDate)');
  }

  /// Hard-deleting a habit removes goal links / project items pointing at it
  /// (occurrences go via FK cascade).
  static Future<void> createHabitTriggers(Database db) async {
    const triggers = {
      'delete_goal_links_of_habit': 'goal_links',
      'delete_project_items_of_habit': 'project_items',
    };
    for (final entry in triggers.entries) {
      await db.execute('''
    CREATE TRIGGER ${entry.key}
    AFTER DELETE ON habits
    BEGIN
      DELETE FROM ${entry.value} WHERE entityType = 'habit' AND entityId = OLD.id;
    END;
    ''');
    }
  }

  // ------------------------------------------------------------------
  // HABITS
  // ------------------------------------------------------------------

  /// Active (non-archived) habits, oldest first.
  Future<List<Habit>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('habits',
        where: 'isArchived = 0', orderBy: 'createdAt ASC, id ASC');
    return maps.map(Habit.fromMap).toList();
  }

  /// Archived habits, most recently archived first.
  Future<List<Habit>> getArchived() async {
    final db = await _getDatabase();
    final maps = await db.query('habits',
        where: 'isArchived = 1', orderBy: 'archivedAt DESC, id ASC');
    return maps.map(Habit.fromMap).toList();
  }

  Future<Habit?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  Future<void> insert(Habit habit) async {
    final db = await _getDatabase();
    await db.insert('habits', withDeviceId(habit.toMap()));
  }

  Future<void> update(Habit habit) async {
    final db = await _getDatabase();
    await db.update('habits', habit.toMap(),
        where: 'id = ?', whereArgs: [habit.id]);
  }

  /// Hard delete (occurrences cascade via FK; links/items via triggers).
  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'habits',
      {'isArchived': 1, 'archivedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchive(String id) async {
    final db = await _getDatabase();
    await db.update(
      'habits',
      {'isArchived': 0, 'archivedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------------
  // OCCURRENCES
  // ------------------------------------------------------------------

  /// Upsert the outcome of [habitId] on [localDate] WITHOUT REPLACE:
  /// update the existing (habitId, localDate) row first, insert only when
  /// none exists, in one transaction. Returns the stored row.
  Future<HabitOccurrence> upsertOccurrence(HabitOccurrence occurrence) async {
    final db = await _getDatabase();
    return db.transaction((txn) async {
      final day = HabitDay.format(occurrence.localDate);
      final n = await txn.update(
        'habit_occurrences',
        {
          'outcome': occurrence.outcome.name,
          'amount': occurrence.amount,
          'note': occurrence.note,
          'recordedAt': occurrence.recordedAt.toIso8601String(),
        },
        where: 'habitId = ? AND localDate = ?',
        whereArgs: [occurrence.habitId, day],
      );
      if (n == 0) {
        await txn.insert(
            'habit_occurrences', withDeviceId(occurrence.toMap()));
      }
      final rows = await txn.query('habit_occurrences',
          where: 'habitId = ? AND localDate = ?',
          whereArgs: [occurrence.habitId, day]);
      return HabitOccurrence.fromMap(rows.first);
    });
  }

  Future<void> deleteOccurrence(String habitId, DateTime localDate) async {
    final db = await _getDatabase();
    await db.delete('habit_occurrences',
        where: 'habitId = ? AND localDate = ?',
        whereArgs: [habitId, HabitDay.format(localDate)]);
  }

  Future<HabitOccurrence?> getOccurrence(
      String habitId, DateTime localDate) async {
    final db = await _getDatabase();
    final rows = await db.query('habit_occurrences',
        where: 'habitId = ? AND localDate = ?',
        whereArgs: [habitId, HabitDay.format(localDate)]);
    if (rows.isEmpty) return null;
    return HabitOccurrence.fromMap(rows.first);
  }

  /// Recorded occurrences of [habitId], oldest day first, optionally limited
  /// to local days in `[from, to]` (inclusive). `yyyy-MM-dd` strings compare
  /// lexicographically in date order.
  Future<List<HabitOccurrence>> occurrencesOf(String habitId,
      {DateTime? from, DateTime? to}) async {
    final db = await _getDatabase();
    final where = StringBuffer('habitId = ?');
    final args = <Object?>[habitId];
    if (from != null) {
      where.write(' AND localDate >= ?');
      args.add(HabitDay.format(from));
    }
    if (to != null) {
      where.write(' AND localDate <= ?');
      args.add(HabitDay.format(to));
    }
    final rows = await db.query('habit_occurrences',
        where: where.toString(), whereArgs: args, orderBy: 'localDate ASC');
    return rows.map(HabitOccurrence.fromMap).toList();
  }
}
