import '../../domain/repositories/calendar_repository.dart';
import '../../domain/models/model_calendar_event.dart';
import '../database/database_manager.dart';
import '../database/daos/calendar_event_dao.dart';

class SqliteCalendarRepository implements CalendarRepository {
  SqliteCalendarRepository({DatabaseManager? databaseManager})
      : _dao = CalendarEventDao(() => (databaseManager ?? DatabaseManager()).database);

  final CalendarEventDao _dao;

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
  Future<void> createCalendarEvent(CalendarEvent event) => _dao.insert(event);

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) => _dao.update(event);

  @override
  Future<void> deleteCalendarEvent(String id) => _dao.delete(id);

  @override
  Future<void> moveCalendarEvent(String eventId, String? newTaskListId) =>
      _dao.move(eventId, newTaskListId);

  @override
  Future<void> softDeleteCalendarEvent(String id) => _dao.softDelete(id);

  @override
  Future<void> restoreCalendarEvent(String id) => _dao.restore(id);

  @override
  Future<void> archiveCalendarEvent(String id) => _dao.archive(id);

  @override
  Future<void> unarchiveCalendarEvent(String id) => _dao.unarchive(id);

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
