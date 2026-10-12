import '../models/model_calendar_event.dart';

/// Domain boundary for **calendar events** (the Google-Calendar-compatible
/// [CalendarEvent] model).
///
/// Callers (UI, blocs, controllers, the calendar sync services, and — in the
/// future — AI tools) depend on this interface, never on [DatabaseManager] /
/// SQLite directly.
///
/// This repository intentionally also exposes the **sync-support** operations
/// (`getEventsPendingSync`, `getEventByGoogleId`, `markSynced`). They are real
/// capabilities of the calendar domain that the Google/device sync services
/// need; keeping them here avoids the sync layer reaching into the database
/// directly.
///
/// Trash (soft-delete) and archive are modelled here as capabilities of the
/// calendar domain rather than as separate repositories.
abstract class CalendarRepository {
  /// All visible events (excludes trashed and archived).
  Future<List<CalendarEvent>> getCalendarEvents();

  /// A single event by local id (no status filtering), or null if missing.
  Future<CalendarEvent?> getCalendarEvent(String id);

  /// Visible events belonging to a given list.
  Future<List<CalendarEvent>> getCalendarEventsOfTaskList(String taskListId);

  /// Visible events not attached to any list.
  Future<List<CalendarEvent>> getCalendarEventsWithoutTaskList();

  /// Create a new event.
  Future<void> createCalendarEvent(CalendarEvent event);

  /// Update an existing event.
  Future<void> updateCalendarEvent(CalendarEvent event);

  /// Hard-delete an event. Prefer [softDeleteCalendarEvent] for user deletes.
  Future<void> deleteCalendarEvent(String id);

  /// Move an event to another list (null = detach to top level).
  Future<void> moveCalendarEvent(String eventId, String? newTaskListId);

  // --- Trash (soft-delete) ---

  Future<void> softDeleteCalendarEvent(String id);
  Future<void> restoreCalendarEvent(String id);

  // --- Archive ---

  Future<void> archiveCalendarEvent(String id);
  Future<void> unarchiveCalendarEvent(String id);

  // --- Sync support (used by the calendar sync services) ---

  /// Events that need to be pushed to a server (localOnly/pendingUpdate/
  /// pendingDelete).
  Future<List<CalendarEvent>> getEventsPendingSync();

  /// Find a local event by its remote (Google/device) event id, or null.
  Future<CalendarEvent?> getEventByGoogleId(String googleEventId);

  /// Mark an event as synced, recording remote identifiers.
  Future<void> markSynced(
    String id, {
    String? googleEventId,
    String? etag,
    String? calendarId,
    String? iCalUID,
  });
}
