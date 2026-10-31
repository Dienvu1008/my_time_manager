import '../../application/reminders/reminder_ids.dart';
import '../../application/reminders/reminder_reconcile_trigger.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/models/model_calendar_event.dart';
import '../database/database_manager.dart';
import '../database/daos/calendar_event_dao.dart';

/// SQLite-backed [CalendarRepository]. After every mutation it asks the
/// injected [ReminderReconcileTrigger] (Phase R) to reconcile reminders,
/// passing the candidate ids of the affected event as `alsoCancel`.
class SqliteCalendarRepository implements CalendarRepository {
  SqliteCalendarRepository({
    DatabaseManager? databaseManager,
    ReminderReconcileTrigger? reminderTrigger,
  })  : _dao = CalendarEventDao(
            () => (databaseManager ?? DatabaseManager()).database),
        _trigger = reminderTrigger ?? const NoOpReminderReconcileTrigger();

  final CalendarEventDao _dao;
  final ReminderReconcileTrigger _trigger;

  /// Reconcile with the candidate ids of [event] (none when unknown).
  Future<void> _reconcile(CalendarEvent? event) => _trigger.requestReconcile(
      alsoCancel: event == null ? const <int>[] : calendarCandidateIds(event));

  /// Reads the row before an id-only mutation (null if missing/unreadable).
  Future<CalendarEvent?> _before(String id) async {
    try {
      return await _dao.getById(id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents() => _dao.getAll();

  @override
  Future<CalendarEvent?> getCalendarEvent(String id) => _dao.getById(id);

  @override
  Future<List<CalendarEvent>> getCalendarEventsOfTaskList(String taskListId) =>
      _dao.ofTaskList(taskListId);

  @override
  Future<List<CalendarEvent>> getCalendarEventsWithoutTaskList() => _dao.withoutTaskList();

  @override
  Future<void> createCalendarEvent(CalendarEvent event) async {
    await _dao.insert(event);
    await _reconcile(event);
  }

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    await _dao.update(event);
    await _reconcile(event);
  }

  @override
  Future<void> deleteCalendarEvent(String id) async {
    final old = await _before(id);
    await _dao.delete(id);
    await _reconcile(old);
  }

  @override
  Future<void> moveCalendarEvent(String eventId, String? newTaskListId) async {
    final old = await _before(eventId);
    await _dao.move(eventId, newTaskListId);
    await _reconcile(old);
  }

  @override
  Future<void> softDeleteCalendarEvent(String id) async {
    final old = await _before(id);
    await _dao.softDelete(id);
    await _reconcile(old);
  }

  @override
  Future<void> restoreCalendarEvent(String id) async {
    final old = await _before(id);
    await _dao.restore(id);
    await _reconcile(old);
  }

  @override
  Future<void> archiveCalendarEvent(String id) async {
    final old = await _before(id);
    await _dao.archive(id);
    await _reconcile(old);
  }

  @override
  Future<void> unarchiveCalendarEvent(String id) async {
    final old = await _before(id);
    await _dao.unarchive(id);
    await _reconcile(old);
  }

  @override
  Future<List<CalendarEvent>> getEventsPendingSync() => _dao.pendingSync();

  @override
  Future<CalendarEvent?> getEventByGoogleId(String googleEventId) => _dao.byGoogleId(googleEventId);

  @override
  Future<void> markSynced(String id,
          {String? googleEventId,
          String? etag,
          String? calendarId,
          String? iCalUID}) =>
      _dao.markSynced(id,
          googleEventId: googleEventId,
          etag: etag,
          calendarId: calendarId,
          iCalUID: iCalUID);
}
