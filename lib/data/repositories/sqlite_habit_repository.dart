import '../../application/reminders/reminder_reconcile_trigger.dart';
import '../../domain/models/model_habit.dart';
import '../../domain/models/model_habit_occurrence.dart';
import '../../domain/repositories/habit_repository.dart';
import '../database/daos/habit_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [HabitRepository] (Phase H1) over [HabitDao].
///
/// Phase H3: every write that can change the desired habit reminders (habit
/// create / update / archive / unarchive / delete, outcome record / clear)
/// asks [ReminderReconcileTrigger] for an incremental reconcile after the
/// write, like `SqliteTaskRepository`. The reminder engine reads habits
/// through a hook-less instance, so reconciling never re-triggers itself.
class SqliteHabitRepository implements HabitRepository {
  SqliteHabitRepository({
    DatabaseManager? databaseManager,
    ReminderReconcileTrigger? reminderTrigger,
  })  : _dao = HabitDao(() => (databaseManager ?? DatabaseManager()).database),
        _trigger = reminderTrigger ?? const NoOpReminderReconcileTrigger();

  final HabitDao _dao;
  final ReminderReconcileTrigger _trigger;

  @override
  Future<List<Habit>> getHabits() => _dao.getAll();

  @override
  Future<List<Habit>> getArchivedHabits() => _dao.getArchived();

  @override
  Future<Habit?> getHabit(String id) => _dao.getById(id);

  @override
  Future<void> createHabit(Habit habit) async {
    await _dao.insert(habit);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _dao.update(habit);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> archiveHabit(String id) async {
    await _dao.archive(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> unarchiveHabit(String id) async {
    await _dao.unarchive(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> deleteHabitPermanently(String id) async {
    await _dao.delete(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<HabitOccurrence> recordOutcome(
    String habitId,
    DateTime localDate,
    HabitOutcome outcome, {
    double? amount,
    String? note,
  }) async {
    if (await _dao.getById(habitId) == null) {
      throw ArgumentError.value(habitId, 'habitId', 'Habit does not exist');
    }
    final occurrence = await _dao.upsertOccurrence(HabitOccurrence(
      habitId: habitId,
      localDate: localDate,
      outcome: outcome,
      amount: amount,
      note: note,
    ));
    await _trigger.requestReconcile();
    return occurrence;
  }

  @override
  Future<void> clearOutcome(String habitId, DateTime localDate) async {
    await _dao.deleteOccurrence(habitId, localDate);
    await _trigger.requestReconcile();
  }

  @override
  Future<HabitOccurrence?> getOccurrence(String habitId, DateTime localDate) =>
      _dao.getOccurrence(habitId, localDate);

  @override
  Future<List<HabitOccurrence>> occurrencesOf(String habitId,
          {DateTime? from, DateTime? to}) =>
      _dao.occurrencesOf(habitId, from: from, to: to);
}
