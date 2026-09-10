import 'package:flutter/material.dart' show TimeOfDay;

import '../../../data/models/model_time_interval.dart';
import '../../../domain/repositories/time_interval_repository.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';
import 'tool_views.dart';

abstract class _TimeTool extends Tool {
  const _TimeTool(this.intervals);
  final TimeIntervalRepository intervals;

  Future<ToolResult> guarded(
      Future<ToolResult> Function(ToolArgs args) body, Map<String, dynamic> a) async {
    try {
      return await body(ToolArgs(a));
    } on ToolArgumentError catch (e) {
      return ToolResult.failure(ToolResult.codeInvalidArguments, e.message);
    }
  }
}

class ListTimeIntervalsTool extends _TimeTool {
  const ListTimeIntervalsTool(super.intervals);
  @override
  String get name => 'list_time_intervals';
  @override
  String get description =>
      'List planned time intervals. Optionally filter by taskId (includes the '
      "task's subtasks' intervals).";
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'taskId': {'type': 'string'}
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final taskId = args.optString('taskId');
        final items = taskId != null
            ? await intervals.getAllTimeIntervalsOfTask(taskId)
            : await intervals.getTimeIntervals();
        return ToolResult.ok({
          'count': items.length,
          'timeIntervals': items.map(ToolViews.timeInterval).toList(),
        });
      }, a);
}

class CreateTimeIntervalTool extends _TimeTool {
  const CreateTimeIntervalTool(super.intervals);
  @override
  String get name => 'create_time_interval';
  @override
  String get description =>
      'Schedule a time interval (a planned block, optionally for a task). '
      'Provide startDate (ISO date). For a timed block also give startTime and '
      'endTime as "HH:mm" plus an endDate; omit times for an all-day block.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'taskId': {'type': 'string'},
          'startDate': {'type': 'string', 'description': 'ISO date (YYYY-MM-DD).'},
          'endDate': {'type': 'string', 'description': 'ISO date; defaults to startDate.'},
          'startTime': {'type': 'string', 'description': '"HH:mm" for a timed block.'},
          'endTime': {'type': 'string', 'description': '"HH:mm" for a timed block.'},
        },
        'required': ['startDate'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final startDate = args.requireDateTime('startDate');
        final endDate = args.optDateTime('endDate') ?? startDate;
        final startTime = _parseHm(args.optString('startTime'));
        final endTime = _parseHm(args.optString('endTime'));

        // Timed only when both times supplied; otherwise a date-only block.
        final timed = startTime != null && endTime != null;
        try {
          final interval = TimeInterval(
            title: args.optString('title'),
            taskId: args.optString('taskId'),
            startDate: DateTime(startDate.year, startDate.month, startDate.day),
            endDate: DateTime(endDate.year, endDate.month, endDate.day),
            startTime: timed ? startTime : null,
            endTime: timed ? endTime : null,
            isStartTimeUndefined: !timed,
            isEndTimeUndefined: !timed,
          );
          await intervals.createTimeInterval(interval);
          return ToolResult.ok(ToolViews.timeInterval(interval));
        } on ArgumentError catch (e) {
          return ToolResult.failure(
              ToolResult.codeInvalidArguments, e.message.toString());
        }
      }, a);
}

class UpdateTimeIntervalTool extends _TimeTool {
  const UpdateTimeIntervalTool(super.intervals);
  @override
  String get name => 'update_time_interval';
  @override
  String get description =>
      'Reschedule an existing time interval by id. Provide startDate/endDate '
      '(ISO date) and optionally startTime/endTime ("HH:mm") to change it.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'title': {'type': 'string'},
          'startDate': {'type': 'string'},
          'endDate': {'type': 'string'},
          'startTime': {'type': 'string'},
          'endTime': {'type': 'string'},
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final TimeInterval existing;
        try {
          existing = await intervals.getTimeInterval(id);
        } catch (_) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No time interval with id "$id".');
        }

        final startDate = args.optDateTime('startDate') ?? existing.startDate;
        final endDate = args.optDateTime('endDate') ?? existing.endDate;
        final startTime = args.has('startTime')
            ? _parseHm(args.optString('startTime'))
            : existing.startTime;
        final endTime = args.has('endTime')
            ? _parseHm(args.optString('endTime'))
            : existing.endTime;
        final timed = startTime != null && endTime != null;

        try {
          final updated = TimeInterval(
            id: existing.id,
            taskId: existing.taskId,
            subtaskId: existing.subtaskId,
            isCompleted: existing.isCompleted,
            title: args.optString('title') ?? existing.title,
            description: existing.description,
            startDate: startDate == null
                ? null
                : DateTime(startDate.year, startDate.month, startDate.day),
            endDate: endDate == null
                ? null
                : DateTime(endDate.year, endDate.month, endDate.day),
            startTime: timed ? startTime : null,
            endTime: timed ? endTime : null,
            isStartDateUndefined: startDate == null,
            isEndDateUndefined: endDate == null,
            isStartTimeUndefined: !timed,
            isEndTimeUndefined: !timed,
            reminderMinutesBefore: existing.reminderMinutesBefore,
          );
          await intervals.updateTimeInterval(updated);
          return ToolResult.ok(ToolViews.timeInterval(updated));
        } on ArgumentError catch (e) {
          return ToolResult.failure(
              ToolResult.codeInvalidArguments, e.message.toString());
        }
      }, a);
}

/// Parse "HH:mm" into a [TimeOfDay]; null when input is null. Throws
/// [ToolArgumentError] on a malformed non-null value.
TimeOfDay? _parseHm(String? hm) {
  if (hm == null) return null;
  final parts = hm.split(':');
  if (parts.length != 2) {
    throw ToolArgumentError('Time "$hm" must be "HH:mm".');
  }
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    throw ToolArgumentError('Time "$hm" is not a valid "HH:mm".');
  }
  return TimeOfDay(hour: h, minute: m);
}

List<Tool> timePlanningTools(TimeIntervalRepository intervals) => [
      ListTimeIntervalsTool(intervals),
      CreateTimeIntervalTool(intervals),
      UpdateTimeIntervalTool(intervals),
    ];
