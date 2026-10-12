import '../models/models.dart';

/// Domain boundary for the **legacy `events` table** ([Event] model).
///
/// This is a small, legacy entity (distinct from the newer [CalendarEvent]).
/// Only list-by-task-list is consumed by the app today; reads are exposed for a
/// coherent boundary. Write operations are intentionally omitted until a caller
/// needs them (avoiding speculative surface).
abstract class EventRepository {
  /// Events belonging to a given list.
  Future<List<Event>> getEventsOfTaskList(String taskListId);
}
