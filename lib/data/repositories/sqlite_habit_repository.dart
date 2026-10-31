import '../../domain/models/model_habit.dart';
import '../../domain/models/model_habit_occurrence.dart';
import '../../domain/repositories/habit_repository.dart';
import '../database/daos/habit_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [HabitRepository] (Phase H1) over [HabitDao].
class SqliteHabitRepository implements HabitRepository {
  SqliteHabitRepository({DatabaseManager? databaseManager})
      : _dao = HabitDao(() => (databaseManager ?? DatabaseManager()).database);

  final HabitDao _dao;

  @override
  Future<List<Habit>> getHabits() => _dao.getAll();

  @override
  Future<List<Habit>> getArchivedHabits() => _dao.getArchived();

  @override
  Future<Habit?> getHabit(String id) => _dao.getById(id);

  @override
  Future<void> createHabit(Habit habit) => _dao.insert(habit);

  @override
  Future<void> updateHabit(Habit habit) => _dao.update(habit);

  @override
  Future<void> archiveHabit(String id) => _dao.archive(id);

  @override
  Future<void> unarchiveHabit(String id) => _dao.unarchive(id);

  @override
  Future<void> deleteHabitPermanently(String id) => _dao.delete(id);

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
    return _dao.upsertOccurrence(HabitOccurrence(
      habitId: habitId,
      localDate: localDate,
      outcome: outcome,
      amount: amount,
      note: note,
    ));
  }

  @override
  Future<void> clearOutcome(String habitId, DateTime localDate) =>
      _dao.deleteOccurrence(habitId, localDate);

  @override
  Future<HabitOccurrence?> getOccurrence(String habitId, DateTime localDate) =>
      _dao.getOccurrence(habitId, localDate);

  @override
  Future<List<HabitOccurrence>> occurrencesOf(String habitId,
          {DateTime? from, DateTime? to}) =>
      _dao.occurrencesOf(habitId, from: from, to: to);
}
