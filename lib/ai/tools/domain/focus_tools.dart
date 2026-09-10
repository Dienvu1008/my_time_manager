import '../../../domain/repositories/focus_repository.dart';
import '../../../domain/services/focus_statistics_service.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';

abstract class _FocusTool extends Tool {
  const _FocusTool(this.focus, this.stats);
  final FocusRepository focus;
  final FocusStatisticsService stats;

  Future<ToolResult> guarded(
      Future<ToolResult> Function(ToolArgs args) body, Map<String, dynamic> a) async {
    try {
      return await body(ToolArgs(a));
    } on ToolArgumentError catch (e) {
      return ToolResult.failure(ToolResult.codeInvalidArguments, e.message);
    }
  }
}

class ListFocusSessionsTool extends _FocusTool {
  const ListFocusSessionsTool(super.focus, super.stats);
  @override
  String get name => 'list_focus_sessions';
  @override
  String get description =>
      'List focus (Pomodoro) sessions, most recent first. Optionally restrict '
      'to an ISO date range [start, end).';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'start': {'type': 'string', 'description': 'ISO start (inclusive).'},
          'end': {'type': 'string', 'description': 'ISO end (exclusive).'},
          'limit': {'type': 'integer'},
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final start = args.optDateTime('start');
        final end = args.optDateTime('end');
        final limit = args.optInt('limit');
        var sessions = (start != null && end != null)
            ? await focus.sessionsBetween(start, end)
            : await focus.allSessions();
        if (limit != null && limit >= 0 && sessions.length > limit) {
          sessions = sessions.sublist(0, limit);
        }
        return ToolResult.ok({
          'count': sessions.length,
          'sessions': [
            for (final s in sessions)
              {
                'id': s.id,
                'taskId': s.taskId,
                'taskTitle': s.taskTitle,
                'startTime': s.startTime.toIso8601String(),
                'focusMinutes': s.focusMinutes,
                'completed': s.completed,
              }
          ],
        });
      }, a);
}

class GetFocusStatisticsTool extends _FocusTool {
  const GetFocusStatisticsTool(super.focus, super.stats);
  @override
  String get name => 'get_focus_statistics';
  @override
  String get description =>
      'Aggregated focus statistics over a range (deterministic, computed by the '
      'app). Give start+end ISO dates, or days for a recent window (default 7).';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'start': {'type': 'string'},
          'end': {'type': 'string'},
          'days': {'type': 'integer', 'description': 'Recent-window size.'},
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final start = args.optDateTime('start');
        final end = args.optDateTime('end');
        final s = (start != null && end != null)
            ? await stats.statisticsBetween(start, end)
            : await stats.recent(days: args.optInt('days') ?? 7);
        return ToolResult.ok(_statsJson(s));
      }, a);
}

/// Compact JSON of a [FocusStatistics].
Map<String, dynamic> _statsJson(FocusStatistics s) => {
      'start': s.start.toIso8601String(),
      'end': s.end.toIso8601String(),
      'sessionCount': s.sessionCount,
      'completedCount': s.completedCount,
      'completionRate': double.parse(s.completionRate.toStringAsFixed(4)),
      'totalFocusMinutes': s.totalFocusMinutes,
      'averageSessionMinutes':
          double.parse(s.averageSessionMinutes.toStringAsFixed(2)),
      'activeDays': s.activeDays,
      'perTask': [
        for (final t in s.perTask)
          {
            'taskId': t.taskId,
            'taskTitle': t.taskTitle,
            'sessionCount': t.sessionCount,
            'focusMinutes': t.focusMinutes,
          }
      ],
    };

List<Tool> focusTools(FocusRepository focus, FocusStatisticsService stats) => [
      ListFocusSessionsTool(focus, stats),
      GetFocusStatisticsTool(focus, stats),
    ];
