import '../../../domain/models/model_calendar_event.dart';
import '../../../domain/repositories/calendar_repository.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';
import 'tool_views.dart';

abstract class _CalendarTool extends Tool {
  const _CalendarTool(this.calendar);
  final CalendarRepository calendar;

  Future<ToolResult> guarded(
      Future<ToolResult> Function(ToolArgs args) body, Map<String, dynamic> a) async {
    try {
      return await body(ToolArgs(a));
    } on ToolArgumentError catch (e) {
      return ToolResult.failure(ToolResult.codeInvalidArguments, e.message);
    }
  }

  /// Build an [EventDateTime] from an ISO string, honoring the all-day flag.
  EventDateTime eventDateTime(DateTime dt, {required bool allDay}) => allDay
      ? EventDateTime(date: DateTime(dt.year, dt.month, dt.day))
      : EventDateTime(dateTime: dt);
}

class ListCalendarEventsTool extends _CalendarTool {
  const ListCalendarEventsTool(super.calendar);
  @override
  String get name => 'list_calendar_events';
  @override
  String get description =>
      'List visible calendar events (excludes trashed/archived). Optionally '
      'filter by taskListId.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'taskListId': {'type': 'string'}
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final listId = args.optString('taskListId');
        final items = listId != null
            ? await calendar.getCalendarEventsOfTaskList(listId)
            : await calendar.getCalendarEvents();
        return ToolResult.ok({
          'count': items.length,
          'events': items.map(ToolViews.calendarEvent).toList(),
        });
      }, a);
}

class GetCalendarEventTool extends _CalendarTool {
  const GetCalendarEventTool(super.calendar);
  @override
  String get name => 'get_calendar_event';
  @override
  String get description => 'Get a single calendar event by id.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'}
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final event = await calendar.getCalendarEvent(id);
        if (event == null) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No calendar event with id "$id".');
        }
        return ToolResult.ok(ToolViews.calendarEvent(event));
      }, a);
}

class CreateCalendarEventTool extends _CalendarTool {
  const CreateCalendarEventTool(super.calendar);
  @override
  String get name => 'create_calendar_event';
  @override
  String get description =>
      'Create a calendar event. Requires title, start and end as ISO-8601 '
      'timestamps. Set isAllDay for a date-only event. end must be after start.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'start': {'type': 'string', 'description': 'ISO-8601 start.'},
          'end': {'type': 'string', 'description': 'ISO-8601 end.'},
          'isAllDay': {'type': 'boolean'},
          'taskListId': {'type': 'string'},
          'location': {'type': 'string'},
        },
        'required': ['title', 'start', 'end'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final start = args.requireDateTime('start');
        final end = args.requireDateTime('end');
        if (!end.isAfter(start)) {
          return ToolResult.failure(ToolResult.codeInvalidArguments,
              'end must be after start.');
        }
        final allDay = args.optBool('isAllDay');
        final event = CalendarEvent(
          title: args.requireString('title'),
          taskListId: args.optString('taskListId'),
          location: args.optString('location'),
          start: eventDateTime(start, allDay: allDay),
          end: eventDateTime(end, allDay: allDay),
        );
        await calendar.createCalendarEvent(event);
        return ToolResult.ok(ToolViews.calendarEvent(event));
      }, a);
}

class UpdateCalendarEventTool extends _CalendarTool {
  const UpdateCalendarEventTool(super.calendar);
  @override
  String get name => 'update_calendar_event';
  @override
  String get description =>
      'Update a calendar event by id. Provide only fields to change: title, '
      'start, end, location. If start/end change, both must keep end after start.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'title': {'type': 'string'},
          'start': {'type': 'string'},
          'end': {'type': 'string'},
          'isAllDay': {'type': 'boolean'},
          'location': {'type': 'string'},
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final existing = await calendar.getCalendarEvent(id);
        if (existing == null) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No calendar event with id "$id".');
        }
        final allDay = args.has('isAllDay')
            ? args.optBool('isAllDay')
            : existing.start.isAllDay;
        final newStartDt = args.optDateTime('start');
        final newEndDt = args.optDateTime('end');
        final start = newStartDt != null
            ? eventDateTime(newStartDt, allDay: allDay)
            : existing.start;
        final end = newEndDt != null
            ? eventDateTime(newEndDt, allDay: allDay)
            : existing.end;
        if (!end.effective.isAfter(start.effective)) {
          return ToolResult.failure(ToolResult.codeInvalidArguments,
              'end must be after start.');
        }
        final updated = CalendarEvent(
          id: existing.id,
          taskListId: existing.taskListId,
          title: args.optString('title') ?? existing.title,
          description: existing.description,
          location: args.optString('location') ?? existing.location,
          color: existing.color,
          start: start,
          end: end,
          status: existing.status,
          googleEventId: existing.googleEventId,
          calendarId: existing.calendarId,
          etag: existing.etag,
          syncStatus: existing.syncStatus,
        );
        await calendar.updateCalendarEvent(updated);
        return ToolResult.ok(ToolViews.calendarEvent(updated));
      }, a);
}

class DeleteCalendarEventTool extends _CalendarTool {
  const DeleteCalendarEventTool(super.calendar);
  @override
  String get name => 'delete_calendar_event';
  @override
  String get description =>
      'Move a calendar event to the trash by id (soft delete — the user can '
      'restore it from the Trash). Destructive: always requires explicit user '
      'approval.';
  @override
  ToolRisk get risk => ToolRisk.destructive;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'}
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final existing = await calendar.getCalendarEvent(id);
        if (existing == null) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No calendar event with id "$id".');
        }
        await calendar.softDeleteCalendarEvent(id);
        return ToolResult.ok({'id': id, 'deleted': true});
      }, a);
}

List<Tool> calendarTools(CalendarRepository calendar) => [
      ListCalendarEventsTool(calendar),
      GetCalendarEventTool(calendar),
      CreateCalendarEventTool(calendar),
      UpdateCalendarEventTool(calendar),
      DeleteCalendarEventTool(calendar),
    ];
