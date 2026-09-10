import '../../domain/repositories/calendar_repository.dart';
import '../database/database_manager.dart';
import '../models/model_calendar_event.dart';

/// SQLite-backed [CalendarRepository].
///
/// Thin adapter over the existing [DatabaseManager] singleton, delegating 1:1
/// so schema, visibility filters, and sync-support semantics are preserved.
class SqliteCalendarRepository implements CalendarRepository {
  SqliteCalendarRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<CalendarEvent>> getCalendarEvents() => _db.calendarEvents();

  @override
  Future<CalendarEvent?> getCalendarEvent(String id) => _db.calendarEvent(id);

  @override
  Future<List<CalendarEvent>> getCalendarEventsOfTaskList(String taskListId) =>
      _db.calendarEventsOfTaskList(taskListId);

  @override
  Future<List<CalendarEvent>> getCalendarEventsWithoutTaskList() =>
      _db.calendarEventsWithoutTaskList();

  @override
  Future<void> createCalendarEvent(CalendarEvent event) =>
      _db.insertCalendarEvent(event);

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) =>
      _db.updateCalendarEvent(event);

  @override
  Future<void> deleteCalendarEvent(String id) => _db.deleteCalendarEvent(id);

  @override
  Future<void> moveCalendarEvent(String eventId, String? newTaskListId) =>
      _db.moveCalendarEvent(eventId, newTaskListId);

  @override
  Future<void> softDeleteCalendarEvent(String id) =>
      _db.softDeleteCalendarEvent(id);

  @override
  Future<void> restoreCalendarEvent(String id) => _db.restoreCalendarEvent(id);

  @override
  Future<void> archiveCalendarEvent(String id) => _db.archiveCalendarEvent(id);

  @override
  Future<void> unarchiveCalendarEvent(String id) =>
      _db.unarchiveCalendarEvent(id);

  @override
  Future<List<CalendarEvent>> getEventsPendingSync() =>
      _db.calendarEventsPendingSync();

  @override
  Future<CalendarEvent?> getEventByGoogleId(String googleEventId) =>
      _db.calendarEventByGoogleId(googleEventId);

  @override
  Future<void> markSynced(
    String id, {
    String? googleEventId,
    String? etag,
    String? calendarId,
    String? iCalUID,
  }) =>
      _db.markCalendarEventSynced(
        id,
        googleEventId: googleEventId,
        etag: etag,
        calendarId: calendarId,
        iCalUID: iCalUID,
      );
}
